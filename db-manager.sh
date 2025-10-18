
#!/bin/bash

# Database Management Script for WordPress MySQL Container
# 
# This script manages MySQL database backups and restores for the WordPress application.
# - Uses docker exec to connect to the MySQL container
# - Reads credentials from container environment variables (secure)
# - Stores backups in ./Wordpress/data/mysql/backup/ directory
# - Supports backup, restore, and list operations

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color 

# Compatible echo function that handles escape sequences
echocolor() {
    printf "%b\n" "$1"
}

# Configuration
BASE_PATH=$(dirname "$(realpath "$0")")
WORDPRESS_PATH="$BASE_PATH/wordpress"
BACKUP_DIR="$WORDPRESS_PATH/data/mysql/backup"
DB_CONTAINER="wordpress_db"
DEFAULT_DB="wordpress_db"

# Function to show usage
show_usage() {
    echocolor "${BLUE}📋 Database Management Script${NC}"
    echo ""
    echocolor "${GREEN}Usage:${NC}"
    echo "  $0 backup [database_name]           - Backup database (default: $DEFAULT_DB)"
    echo "  $0 restore <filename> [database_name] - Restore from backup file"
    echo "  $0 list                             - List available backups"
    echo ""
    echocolor "${GREEN}Examples:${NC}"
    echo "  $0 backup                           # Backup default database ($DEFAULT_DB)"
    echo "  $0 backup my_custom_db              # Backup specific database"
    echo "  $0 restore backup_2024-10-18.sql   # Restore from specific file"
    echo "  $0 list                             # Show all backup files"
    echo ""
    echocolor "${GREEN}Notes:${NC}"
    echo "  • Backups are stored in: $BACKUP_DIR"
    echo "  • Files are compressed with gzip (.sql.gz)"
    echo "  • Container must be running: $DB_CONTAINER"
}
# Function to check if container is running
check_container() {
    if ! docker ps | grep -q "$DB_CONTAINER"; then
        echocolor "${RED}❌ Database container '$DB_CONTAINER' is not running${NC}"
        echocolor "${YELLOW}Start it with: ${GREEN}./manage-apps.sh start wordpress${NC}"
        exit 1
    fi
}

# Function to ensure backup directory exists
ensure_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        echocolor "${YELLOW}📁 Created backup directory: $BACKUP_DIR${NC}"
    fi
}

# Function to backup database
backup_database() {
    local DB_NAME=${1:-$DEFAULT_DB}
    local TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    local BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$TIMESTAMP.sql.gz"
    
    echocolor "${YELLOW}💾 Backing up database '$DB_NAME'...${NC}"
    
    # Check if database exists
    if ! docker exec "$DB_CONTAINER" sh -c "mysql -u\$MYSQL_USER -p\$MYSQL_PASSWORD -e 'USE $DB_NAME;'" >/dev/null 2>&1; then
        echocolor "${RED}❌ Database '$DB_NAME' does not exist${NC}"
        exit 1
    fi
    
    # Create backup
    docker exec "$DB_CONTAINER" sh -c "mysqldump -u\$MYSQL_USER -p\$MYSQL_PASSWORD --single-transaction --routines --triggers $DB_NAME" | gzip > "$BACKUP_FILE"
    
    if [ -f "$BACKUP_FILE" ]; then
        local FILE_SIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
        echocolor "${GREEN}✅ Backup completed successfully${NC}"
        echocolor "${GREEN}   File: $(basename "$BACKUP_FILE")${NC}"
        echocolor "${GREEN}   Size: $FILE_SIZE${NC}"
        echocolor "${GREEN}   Path: $BACKUP_FILE${NC}"
    else
        echocolor "${RED}❌ Backup failed${NC}"
        exit 1
    fi
}
# Function to restore database
restore_database() {
    local BACKUP_FILENAME="$1"
    local DB_NAME="${2:-$DEFAULT_DB}"
    
    if [ -z "$BACKUP_FILENAME" ]; then
        echocolor "${RED}❌ Backup filename is required for restore${NC}"
        echocolor "${YELLOW}Available backups:${NC}"
        list_backups
        echo ""
        echocolor "${YELLOW}Usage: $0 restore <filename> [database_name]${NC}"
        exit 1
    fi
    
    # Handle different filename formats
    local BACKUP_FILE_PATH
    case "$BACKUP_FILENAME" in
        *.sql.gz)
            BACKUP_FILE_PATH="$BACKUP_DIR/$BACKUP_FILENAME"
            ;;
        *.sql)
            BACKUP_FILE_PATH="$BACKUP_DIR/$BACKUP_FILENAME"
            ;;
        *)
            # Try adding .sql.gz extension
            if [ -f "$BACKUP_DIR/${BACKUP_FILENAME}.sql.gz" ]; then
                BACKUP_FILE_PATH="$BACKUP_DIR/${BACKUP_FILENAME}.sql.gz"
            elif [ -f "$BACKUP_DIR/${BACKUP_FILENAME}.sql" ]; then
                BACKUP_FILE_PATH="$BACKUP_DIR/${BACKUP_FILENAME}.sql"
            else
                BACKUP_FILE_PATH="$BACKUP_DIR/$BACKUP_FILENAME"
            fi
            ;;
    esac
    
    if [ ! -f "$BACKUP_FILE_PATH" ]; then
        echocolor "${RED}❌ Backup file not found: $BACKUP_FILE_PATH${NC}"
        echocolor "${YELLOW}Available backups:${NC}"
        list_backups
        exit 1
    fi
    
    echocolor "${YELLOW}♻️  Restoring database '$DB_NAME' from '$(basename "$BACKUP_FILE_PATH")'...${NC}"
    echocolor "${YELLOW}⚠️  This will overwrite existing data in database '$DB_NAME'${NC}"
    echocolor "${YELLOW}Continue? (y/N): ${NC}"
    read -r CONFIRM
    
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echocolor "${YELLOW}📋 Restore cancelled${NC}"
        exit 0
    fi
    
    # Restore based on file extension
    case "$BACKUP_FILE_PATH" in
        *.gz)
            gunzip < "$BACKUP_FILE_PATH" | docker exec -i "$DB_CONTAINER" sh -c "mysql -u\$MYSQL_USER -p\$MYSQL_PASSWORD $DB_NAME"
            ;;
        *)
            docker exec -i "$DB_CONTAINER" sh -c "mysql -u\$MYSQL_USER -p\$MYSQL_PASSWORD $DB_NAME" < "$BACKUP_FILE_PATH"
            ;;
    esac
    
    echocolor "${GREEN}✅ Restore completed successfully${NC}"
    echocolor "${GREEN}   Database: $DB_NAME${NC}"
    echocolor "${GREEN}   From: $(basename "$BACKUP_FILE_PATH")${NC}"
}

# Function to list backup files
list_backups() {
    echocolor "${YELLOW}📂 Listing backups from container: /var/backups/mysql${NC}"
    echo ""
    
    # Check if any backup files exist using container
    local BACKUP_COUNT
    BACKUP_COUNT=$(docker exec "$DB_CONTAINER" sh -c "find /var/backups/mysql -name '*.sql.gz' -o -name '*.sql' 2>/dev/null | wc -l" 2>/dev/null || echo "0")
    
    if [ "$BACKUP_COUNT" -eq 0 ]; then
        echocolor "${YELLOW}   No backup files found in container${NC}"
        echocolor "${YELLOW}   Create a backup with: ${GREEN}$0 backup${NC}"
        echocolor "${YELLOW}   Container path: /var/backups/mysql${NC}"
        echocolor "${YELLOW}   Host path: $BACKUP_DIR${NC}"
        return 0
    fi
    
    # Display files with details from container
    printf "%-40s %-10s %-20s\n" "Filename" "Size" "Date"
    echo "================================================================"
    
    # List files from inside the container
    docker exec "$DB_CONTAINER" sh -c "
        find /var/backups/mysql -name '*.sql.gz' -o -name '*.sql' 2>/dev/null | sort -r | while read -r backup_file; do
            if [ -f \"\$backup_file\" ]; then
                basename_file=\$(basename \"\$backup_file\")
                size=\$(ls -lh \"\$backup_file\" | awk '{print \$5}')
                date=\$(ls -l --time-style='+%Y-%m-%d %H:%M' \"\$backup_file\" | awk '{print \$6, \$7}')
                printf '%-40s %-10s %-20s\n' \"\$basename_file\" \"\$size\" \"\$date\"
            fi
        done
    " 2>/dev/null || {
        echocolor "${RED}❌ Error accessing backup directory in container${NC}"
        echocolor "${YELLOW}   Fallback: Checking host directory...${NC}"
        
        # Fallback to host directory check
        if [ -d "$BACKUP_DIR" ]; then
            find "$BACKUP_DIR" -name "*.sql.gz" -o -name "*.sql" | sort -r | while read -r BACKUP_FILE; do
                if [ -f "$BACKUP_FILE" ]; then
                    local BASENAME=$(basename "$BACKUP_FILE")
                    local SIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
                    local DATE=$(ls -l --time-style="+%Y-%m-%d %H:%M" "$BACKUP_FILE" | awk '{print $6, $7}')
                    printf "%-40s %-10s %-20s\n" "$BASENAME" "$SIZE" "$DATE"
                fi
            done
        else
            echocolor "${RED}   Host backup directory not found: $BACKUP_DIR${NC}"
        fi
    }
    
    echo ""
    echocolor "${GREEN}Total: $BACKUP_COUNT backup file(s)${NC}"
    echocolor "${BLUE}Container path: /var/backups/mysql${NC}"
    echocolor "${BLUE}Host path: $BACKUP_DIR${NC}"
}

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

# Initialize
check_container
ensure_backup_dir

COMMAND=$1

case $COMMAND in
    backup)
        backup_database "$2"
        ;;
    restore)
        restore_database "$2" "$3"
        ;;
    list)
        list_backups
        ;;
    *)
        echocolor "${RED}❌ Unknown command: $COMMAND${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac