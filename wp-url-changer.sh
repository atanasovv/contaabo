#!/bin/bash

# WordPress URL Changer Script
# 
# This script changes the WordPress site URL in the database.
# It updates both 'siteurl' and 'home' options in the wp_options table.
# - Uses docker exec to connect to the MySQL container
# - Reads credentials from container environment variables (secure)
# - Provides backup option before making changes
# - Validates URLs and shows current configuration

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
DB_CONTAINER="wordpress_db"
DEFAULT_DB="wordpress_db"

# Function to show usage
show_usage() {
    echocolor "${BLUE}🔗 WordPress URL Changer Script${NC}"
    echo ""
    echocolor "${GREEN}Usage:${NC}"
    echo "  $0 show                           - Show current WordPress URLs"
    echo "  $0 change <new_url> [database]    - Change WordPress URLs"
    echo "  $0 backup-change <new_url> [db]   - Backup database first, then change URLs"
    echo ""
    echocolor "${GREEN}Examples:${NC}"
    echo "  $0 show                                    # Show current URLs"
    echo "  $0 change https://mynewdomain.com         # Change to new URL"
    echo "  $0 change https://localhost:8080          # Change to local development"
    echo "  $0 backup-change https://newsite.com      # Backup first, then change"
    echo ""
    echocolor "${GREEN}Notes:${NC}"
    echo "  • URL should include protocol (http:// or https://)"
    echo "  • No trailing slash needed - will be removed automatically"
    echo "  • Updates both 'siteurl' and 'home' WordPress options"
    echo "  • Database container must be running: $DB_CONTAINER"
    echo "  • Use backup-change for safety in production"
    echo ""
}

# Function to check if database container is running
check_container() {
    if ! docker ps --format "table {{.Names}}" | grep -q "^$DB_CONTAINER$"; then
        echocolor "${RED}❌ Database container '$DB_CONTAINER' is not running${NC}"
        echocolor "${YELLOW}Start it with: ${GREEN}./manage-apps.sh start wordpress${NC}"
        exit 1
    fi
}

# Function to validate URL format
validate_url() {
    local url="$1"
    
    # Check if URL starts with http:// or https://
    case "$url" in
        http://*|https://*)
            # Remove trailing slash if present
            url="${url%/}"
            echo "$url"
            return 0
            ;;
        *)
            echocolor "${RED}❌ Invalid URL format. Must start with http:// or https://${NC}" >&2
            echocolor "${YELLOW}Example: https://example.com${NC}" >&2
            return 1
            ;;
    esac
}

# Function to get WordPress table prefix
get_wp_table_prefix() {
    local DB_NAME="$1"
    
    # Try to find the options table with any prefix
    local options_table
    options_table=$(docker exec "$DB_CONTAINER" sh -c "mysql -u\$MYSQL_USER -p\$MYSQL_PASSWORD $DB_NAME -e \"
        SHOW TABLES LIKE '%options';
    \" -N 2>/dev/null" | grep "options" | head -1)
    
    if [ -n "$options_table" ]; then
        # Extract prefix by removing 'options' from the end
        echo "${options_table%options}"
    else
        # Default to wp_ if not found
        echo "wp_"
    fi
}

# Function to show current WordPress URLs
show_current_urls() {
    local DB_NAME="${1:-$DEFAULT_DB}"
    
    echocolor "${BLUE}🔍 Current WordPress URLs in database '$DB_NAME':${NC}"
    echo ""
    
    # Get table prefix
    local table_prefix
    table_prefix=$(get_wp_table_prefix "$DB_NAME")
    local options_table="${table_prefix}options"
    
    echocolor "${YELLOW}   Using table: $options_table${NC}"
    echo ""
    
    # Get current URLs from database
    local current_urls
    current_urls=$(docker exec "$DB_CONTAINER" sh -c "mysql -u\$MYSQL_USER -p\$MYSQL_PASSWORD $DB_NAME -e \"
        SELECT option_name, option_value 
        FROM $options_table 
        WHERE option_name IN ('siteurl', 'home') 
        ORDER BY option_name;
    \" 2>/dev/null" || {
        echocolor "${RED}❌ Failed to retrieve URLs from database${NC}"
        echocolor "${YELLOW}   Table: $options_table${NC}"
        return 1
    })
    
    if [ -n "$current_urls" ]; then
        echo "$current_urls" | grep -v "option_name" | while IFS=$'\t' read -r option_name option_value; do
            if [ -n "$option_name" ] && [ -n "$option_value" ]; then
                case "$option_name" in
                    "siteurl")
                        echocolor "${GREEN}  🏠 Site URL: ${YELLOW}$option_value${NC}"
                        ;;
                    "home")
                        echocolor "${GREEN}  🌐 Home URL: ${YELLOW}$option_value${NC}"
                        ;;
                esac
            fi
        done
    else
        echocolor "${YELLOW}⚠️  No WordPress URLs found in database${NC}"
        echocolor "${YELLOW}   Check if WordPress is properly installed${NC}"
    fi
    echo ""
}

# Function to change WordPress URLs
change_wordpress_urls() {
    local new_url="$1"
    local DB_NAME="${2:-$DEFAULT_DB}"
    
    # Validate and clean URL
    new_url=$(validate_url "$new_url")
    if [ $? -ne 0 ]; then
        exit 1
    fi
    
    # Get table prefix
    local table_prefix
    table_prefix=$(get_wp_table_prefix "$DB_NAME")
    local options_table="${table_prefix}options"
    
    echocolor "${YELLOW}🔄 Changing WordPress URLs in database '$DB_NAME'...${NC}"
    echocolor "${YELLOW}   New URL: ${GREEN}$new_url${NC}"
    echocolor "${YELLOW}   Using table: $options_table${NC}"
    echo ""
    
    # Show current URLs first
    show_current_urls "$DB_NAME"
    
    # Confirm the change
    echocolor "${YELLOW}⚠️  This will update the WordPress site URLs in the database${NC}"
    echocolor "${YELLOW}Continue with URL change? (y/N): ${NC}"
    read -r CONFIRM
    
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echocolor "${YELLOW}📋 URL change cancelled${NC}"
        exit 0
    fi
    
    # Update the URLs in database
    local update_result
    update_result=$(docker exec "$DB_CONTAINER" sh -c "mysql -u\$MYSQL_USER -p\$MYSQL_PASSWORD $DB_NAME -e \"
        UPDATE $options_table SET option_value = '$new_url' WHERE option_name = 'siteurl';
        UPDATE $options_table SET option_value = '$new_url' WHERE option_name = 'home';
        SELECT ROW_COUNT() as affected_rows;
    \" 2>/dev/null" || {
        echocolor "${RED}❌ Failed to update URLs in database${NC}"
        echocolor "${YELLOW}   Table: $options_table${NC}"
        exit 1
    })
    
    echocolor "${GREEN}✅ WordPress URLs updated successfully!${NC}"
    echo ""
    
    # Show updated URLs
    echocolor "${BLUE}🔍 Updated URLs:${NC}"
    show_current_urls "$DB_NAME"
    
    echocolor "${GREEN}🎉 URL change completed successfully!${NC}"
    echocolor "${YELLOW}💡 You may need to:${NC}"
    echocolor "${YELLOW}   • Clear any caching plugins${NC}"
    echocolor "${YELLOW}   • Update .htaccess if using permalinks${NC}"
    echocolor "${YELLOW}   • Check SSL certificate configuration${NC}"
    echocolor "${YELLOW}   • Update any hardcoded links in content${NC}"
}

# Function to backup database before changing URLs
backup_and_change_urls() {
    local new_url="$1"
    local DB_NAME="${2:-$DEFAULT_DB}"
    
    echocolor "${BLUE}💾 Creating backup before URL change...${NC}"
    
    # Create backup using the db-manager script
    if [ -f "./db-manager.sh" ]; then
        ./db-manager.sh backup "$DB_NAME"
        if [ $? -eq 0 ]; then
            echocolor "${GREEN}✅ Backup completed successfully${NC}"
            echo ""
            # Proceed with URL change
            change_wordpress_urls "$new_url" "$DB_NAME"
        else
            echocolor "${RED}❌ Backup failed - URL change cancelled${NC}"
            exit 1
        fi
    else
        echocolor "${RED}❌ db-manager.sh script not found${NC}"
        echocolor "${YELLOW}Run URL change without backup? (y/N): ${NC}"
        read -r CONFIRM
        
        if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
            change_wordpress_urls "$new_url" "$DB_NAME"
        else
            echocolor "${YELLOW}📋 URL change cancelled${NC}"
            exit 0
        fi
    fi
}

# Check if container is running
check_container

# Main script logic
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    "show")
        show_current_urls "${2:-$DEFAULT_DB}"
        ;;
    "change")
        if [ -z "$2" ]; then
            echocolor "${RED}❌ New URL is required${NC}"
            echocolor "${YELLOW}Usage: $0 change <new_url> [database_name]${NC}"
            exit 1
        fi
        change_wordpress_urls "$2" "${3:-$DEFAULT_DB}"
        ;;
    "backup-change")
        if [ -z "$2" ]; then
            echocolor "${RED}❌ New URL is required${NC}"
            echocolor "${YELLOW}Usage: $0 backup-change <new_url> [database_name]${NC}"
            exit 1
        fi
        backup_and_change_urls "$2" "${3:-$DEFAULT_DB}"
        ;;
    *)
        echocolor "${RED}❌ Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac