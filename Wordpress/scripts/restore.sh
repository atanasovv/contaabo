#!/bin/sh

# WordPress Restore Script
# This script restores WordPress from backup files

BACKUP_DIR=/backups
RESTORE_LOG="/backups/restore_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages
log_message() {
    echo "$(date): $1" | tee -a $RESTORE_LOG
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -f, --files BACKUP_FILE     Restore WordPress files from specified backup"
    echo "  -d, --database BACKUP_FILE  Restore database from specified backup"
    echo "  -a, --all TIMESTAMP         Restore both files and database from timestamp (YYYYMMDD_HHMMSS)"
    echo "  -l, --list                  List available backups"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -l                                    # List available backups"
    echo "  $0 -a 20240924_020000                    # Restore both from timestamp"
    echo "  $0 -f wordpress_files_20240924_020000.tar.gz"
    echo "  $0 -d wordpress_db_20240924_020000.sql.gz"
}

# Function to list available backups
list_backups() {
    log_message "Available backup files:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR 2>/dev/null)" ]; then
        log_message "No backup files found in $BACKUP_DIR"
        return 1
    fi
    
    printf "%-10s %-20s %-15s %s\n" "TYPE" "TIMESTAMP" "SIZE" "FILENAME"
    printf "%s\n" "----------------------------------------------------------------"
    
    for file in $BACKUP_DIR/wordpress_*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            size=$(du -h "$file" | cut -f1)
            
            if echo "$filename" | grep -q "files"; then
                type="FILES"
            elif echo "$filename" | grep -q "db"; then
                type="DATABASE"
            else
                type="OTHER"
            fi
            
            # Extract timestamp
            timestamp=$(echo $filename | grep -o '[0-9]\{8\}_[0-9]\{6\}' || echo "Unknown")
            
            printf "%-10s %-20s %-15s %s\n" "$type" "$timestamp" "$size" "$filename"
        fi
    done
    echo ""
}

# Function to restore WordPress files
restore_files() {
    local backup_file="$1"
    
    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        log_message "ERROR: Backup file not found: $BACKUP_DIR/$backup_file"
        return 1
    fi
    
    log_message "Starting WordPress files restore from: $backup_file"
    
    # Create backup of current files before restore
    current_backup="/backups/pre_restore_files_$(date +%Y%m%d_%H%M%S).tar.gz"
    log_message "Creating backup of current files: $current_backup"
    tar -czf $current_backup -C /wordpress . 2>>$RESTORE_LOG
    
    # Clear current WordPress directory (except wp-config.php)
    log_message "Clearing current WordPress files..."
    find /wordpress -mindepth 1 -not -name 'wp-config.php' -delete 2>>$RESTORE_LOG
    
    # Extract backup
    log_message "Extracting backup files..."
    if tar -xzf $BACKUP_DIR/$backup_file -C /wordpress 2>>$RESTORE_LOG; then
        log_message "WordPress files restored successfully"
        return 0
    else
        log_message "ERROR: Failed to extract backup files"
        return 1
    fi
}

# Function to restore database
restore_database() {
    local backup_file="$1"
    
    if [ ! -f "$BACKUP_DIR/$backup_file" ]; then
        log_message "ERROR: Database backup file not found: $BACKUP_DIR/$backup_file"
        return 1
    fi
    
    log_message "Starting database restore from: $backup_file"
    
    # Create backup of current database before restore
    current_db_backup="/backups/pre_restore_db_$(date +%Y%m%d_%H%M%S).sql.gz"
    log_message "Creating backup of current database: $current_db_backup"
    mysqldump -h db -u $WP_DB_USER -p$WP_DB_PASSWORD $WP_DB_NAME 2>>$RESTORE_LOG | gzip > $current_db_backup
    
    # Restore database
    log_message "Restoring database..."
    if gunzip -c $BACKUP_DIR/$backup_file | mysql -h db -u $WP_DB_USER -p$WP_DB_PASSWORD $WP_DB_NAME 2>>$RESTORE_LOG; then
        log_message "Database restored successfully"
        return 0
    else
        log_message "ERROR: Failed to restore database"
        return 1
    fi
}

# Function to restore both files and database
restore_all() {
    local timestamp="$1"
    
    local files_backup="wordpress_files_${timestamp}.tar.gz"
    local db_backup="wordpress_db_${timestamp}.sql.gz"
    
    log_message "Starting full restore for timestamp: $timestamp"
    
    # Check if both files exist
    if [ ! -f "$BACKUP_DIR/$files_backup" ]; then
        log_message "ERROR: Files backup not found: $files_backup"
        return 1
    fi
    
    if [ ! -f "$BACKUP_DIR/$db_backup" ]; then
        log_message "ERROR: Database backup not found: $db_backup"
        return 1
    fi
    
    # Restore files first
    if restore_files "$files_backup"; then
        log_message "Files restore completed"
    else
        log_message "ERROR: Files restore failed"
        return 1
    fi
    
    # Restore database
    if restore_database "$db_backup"; then
        log_message "Database restore completed"
    else
        log_message "ERROR: Database restore failed - files were restored but database restore failed"
        return 1
    fi
    
    log_message "Full restore completed successfully"
    return 0
}

# Main script logic
log_message "WordPress restore script started"

# Parse command line arguments
case "$1" in
    -l|--list)
        list_backups
        ;;
    -f|--files)
        if [ -z "$2" ]; then
            echo "ERROR: Files backup filename required"
            show_usage
            exit 1
        fi
        restore_files "$2"
        ;;
    -d|--database)
        if [ -z "$2" ]; then
            echo "ERROR: Database backup filename required"
            show_usage
            exit 1
        fi
        restore_database "$2"
        ;;
    -a|--all)
        if [ -z "$2" ]; then
            echo "ERROR: Timestamp required (format: YYYYMMDD_HHMMSS)"
            show_usage
            exit 1
        fi
        restore_all "$2"
        ;;
    -h|--help|"")
        show_usage
        ;;
    *)
        echo "ERROR: Unknown option: $1"
        show_usage
        exit 1
        ;;
esac

log_message "WordPress restore script completed"