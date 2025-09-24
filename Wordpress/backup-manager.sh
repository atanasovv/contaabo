#!/bin/bash

# WordPress Backup Management Script
# Provides easy management of backup operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    if ! command -v docker-compose &> /dev/null; then
        log_error "docker-compose not found"
        exit 1
    fi

    if [[ ! -f .env ]]; then
        log_error ".env file not found"
        echo "Please create .env file from .env.example"
        exit 1
    fi

    # Create backups directory
    mkdir -p backups
}

# Manual backup
run_manual_backup() {
    log_info "Starting manual backup..."
    docker-compose --profile backup run --rm backup
    
    if [[ $? -eq 0 ]]; then
        log_success "Manual backup completed!"
        list_recent_backups
    else
        log_error "Manual backup failed!"
        return 1
    fi
}

# Start scheduled backup service
start_scheduled_backup() {
    log_info "Starting scheduled backup service..."
    docker-compose --profile scheduled-backup up -d backup-scheduler
    
    if [[ $? -eq 0 ]]; then
        log_success "Scheduled backup service started!"
        show_backup_schedule
    else
        log_error "Failed to start scheduled backup service!"
        return 1
    fi
}

# Stop scheduled backup service
stop_scheduled_backup() {
    log_info "Stopping scheduled backup service..."
    docker-compose --profile scheduled-backup down
    log_success "Scheduled backup service stopped!"
}

# Show backup schedule
show_backup_schedule() {
    if [[ -f .env ]]; then
        SCHEDULE=$(grep "BACKUP_SCHEDULE=" .env | cut -d'=' -f2 | tr -d '"' || echo "0 2 * * *")
        RETENTION=$(grep "BACKUP_RETENTION_DAYS=" .env | cut -d'=' -f2 | tr -d '"' || echo "7")
        
        echo
        log_info "Backup Configuration:"
        echo "  Schedule: $SCHEDULE"
        echo "  Retention: $RETENTION days"
        
        # Decode cron schedule
        case "$SCHEDULE" in
            "0 2 * * *") echo "  Human readable: Daily at 2:00 AM" ;;
            "0 */6 * * *") echo "  Human readable: Every 6 hours" ;;
            "0 3 * * 0") echo "  Human readable: Weekly on Sunday at 3:00 AM" ;;
            "0 1 * * *") echo "  Human readable: Daily at 1:00 AM" ;;
            *) echo "  Human readable: Custom schedule" ;;
        esac
    fi
}

# List backup files
list_backups() {
    echo
    log_info "Available backup files:"
    
    if [[ -d backups && $(ls -A backups/ 2>/dev/null) ]]; then
        echo
        printf "%-25s %-20s %-15s %s\n" "TYPE" "DATE/TIME" "SIZE" "FILENAME"
        printf "%s\n" "--------------------------------------------------------------------------------------------------------"
        
        for file in backups/wordpress_*; do
            if [[ -f "$file" ]]; then
                filename=$(basename "$file")
                size=$(du -h "$file" | cut -f1)
                
                if [[ $filename == *"files"* ]]; then
                    type="FILES"
                elif [[ $filename == *"db"* ]]; then
                    type="DATABASE"
                elif [[ $filename == *"backup_"* ]]; then
                    type="LOG"
                else
                    type="UNKNOWN"
                fi
                
                # Extract date from filename
                date_part=$(echo $filename | grep -o '[0-9]\{8\}_[0-9]\{6\}' || echo "Unknown")
                if [[ $date_part != "Unknown" ]]; then
                    formatted_date=$(echo $date_part | sed 's/\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)_\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)/\1-\2-\3 \4:\5:\6/')
                else
                    formatted_date="Unknown"
                fi
                
                printf "%-25s %-20s %-15s %s\n" "$type" "$formatted_date" "$size" "$filename"
            fi
        done
    else
        log_warning "No backup files found in ./backups/"
    fi
}

# List recent backups
list_recent_backups() {
    echo
    log_info "Recent backup files (last 5):"
    if [[ -d backups && $(ls -A backups/ 2>/dev/null) ]]; then
        ls -lt backups/ | head -6
    else
        log_warning "No backup files found"
    fi
}

# Check backup service status
check_backup_status() {
    log_info "Checking backup service status..."
    
    # Check if scheduled backup is running
    if docker-compose --profile scheduled-backup ps backup-scheduler | grep -q "Up"; then
        log_success "Scheduled backup service is running"
        
        # Show recent logs
        echo
        log_info "Recent backup scheduler logs:"
        docker-compose --profile scheduled-backup logs --tail=10 backup-scheduler
    else
        log_warning "Scheduled backup service is not running"
        echo "Use option 2 to start the scheduled backup service"
    fi
}

# Restore backup (now functional)
restore_backup() {
    echo
    log_info "WordPress Backup Restore Options:"
    echo
    echo "1) List available backups"
    echo "2) Restore both files and database (full restore)"
    echo "3) Restore only WordPress files"
    echo "4) Restore only database"
    echo "5) Back to main menu"
    echo
    
    read -p "Choose restore option [1-5]: " restore_choice
    
    case $restore_choice in
        1)
            docker-compose --profile restore run --rm restore -l
            ;;
        2)
            echo
            log_warning "⚠️  FULL RESTORE WARNING ⚠️"
            echo "This will replace ALL WordPress files and database content!"
            echo "Current data will be backed up before restore."
            echo
            read -p "Enter backup timestamp (YYYYMMDD_HHMMSS): " timestamp
            if [[ -n "$timestamp" ]]; then
                read -p "Are you sure you want to proceed? (yes/no): " confirm
                if [[ "$confirm" == "yes" ]]; then
                    log_info "Starting full restore..."
                    docker-compose --profile restore run --rm restore -a "$timestamp"
                else
                    log_info "Restore cancelled"
                fi
            else
                log_error "Invalid timestamp"
            fi
            ;;
        3)
            echo
            log_warning "⚠️  FILES RESTORE WARNING ⚠️"
            echo "This will replace ALL WordPress files (themes, plugins, uploads, etc.)"
            echo "Current files will be backed up before restore."
            echo
            read -p "Enter files backup filename: " files_backup
            if [[ -n "$files_backup" ]]; then
                read -p "Are you sure you want to proceed? (yes/no): " confirm
                if [[ "$confirm" == "yes" ]]; then
                    log_info "Starting files restore..."
                    docker-compose --profile restore run --rm restore -f "$files_backup"
                else
                    log_info "Restore cancelled"
                fi
            else
                log_error "Invalid filename"
            fi
            ;;
        4)
            echo
            log_warning "⚠️  DATABASE RESTORE WARNING ⚠️"
            echo "This will replace ALL database content!"
            echo "Current database will be backed up before restore."
            echo
            read -p "Enter database backup filename: " db_backup
            if [[ -n "$db_backup" ]]; then
                read -p "Are you sure you want to proceed? (yes/no): " confirm
                if [[ "$confirm" == "yes" ]]; then
                    log_info "Starting database restore..."
                    docker-compose --profile restore run --rm restore -d "$db_backup"
                else
                    log_info "Restore cancelled"
                fi
            else
                log_error "Invalid filename"
            fi
            ;;
        5)
            return 0
            ;;
        *)
            log_error "Invalid choice"
            ;;
    esac
}

# Cleanup old backups
cleanup_old_backups() {
    echo
    read -p "Enter days to keep (default 7): " days
    days=${days:-7}
    
    log_info "Cleaning up backups older than $days days..."
    
    deleted_count=0
    if [[ -d backups ]]; then
        while IFS= read -r -d '' file; do
            rm "$file"
            deleted_count=$((deleted_count + 1))
            log_info "Deleted: $(basename "$file")"
        done < <(find backups/ -name 'wordpress_*' -type f -mtime +$days -print0 2>/dev/null)
    fi
    
    if [[ $deleted_count -gt 0 ]]; then
        log_success "Cleaned up $deleted_count old backup files"
    else
        log_info "No old backup files found to clean up"
    fi
}

# Main menu
show_menu() {
    echo
    echo "=== WordPress Backup Management ==="
    echo
    echo "1) Run manual backup now"
    echo "2) Start scheduled backup service"
    echo "3) Stop scheduled backup service"
    echo "4) List all backups"
    echo "5) Check backup service status"
    echo "6) Show backup schedule"
    echo "7) Restore from backup"
    echo "8) Cleanup old backups"
    echo "0) Exit"
    echo
}

# Main script
main() {
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter choice [0-8]: " choice
        
        case $choice in
            1) run_manual_backup ;;
            2) start_scheduled_backup ;;
            3) stop_scheduled_backup ;;
            4) list_backups ;;
            5) check_backup_status ;;
            6) show_backup_schedule ;;
            7) restore_backup ;;
            8) cleanup_old_backups ;;
            0) 
                echo
                log_success "Goodbye!"
                break 
                ;;
            *) 
                log_error "Invalid choice. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run main function
main