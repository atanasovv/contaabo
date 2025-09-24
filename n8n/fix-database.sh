#!/bin/bash

# PostgreSQL Database Maintenance Script
# Fixes collation version mismatch and other database issues

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Function to check if PostgreSQL is running
check_postgres_running() {
    if ! docker compose ps postgres | grep -q "Up"; then
        log_error "PostgreSQL container is not running"
        echo "Please start PostgreSQL first with: docker compose up -d postgres"
        exit 1
    fi
}

# Function to fix collation version mismatch
fix_collation_version() {
    log_info "Fixing PostgreSQL collation version mismatch..."
    
    # Load environment variables
    if [[ -f .env ]]; then
        source .env
    else
        log_error ".env file not found"
        exit 1
    fi
    
    # Execute the collation fix
    log_info "Running ALTER DATABASE command to refresh collation version..."
    
    docker compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ALTER DATABASE $POSTGRES_DB REFRESH COLLATION VERSION;" 2>/dev/null || {
        log_warning "Command failed, trying alternative method..."
        docker compose exec postgres psql -U "$POSTGRES_USER" -c "ALTER DATABASE $POSTGRES_DB REFRESH COLLATION VERSION;" 2>/dev/null || {
            log_error "Failed to fix collation version"
            log_info "This might require a full database rebuild in severe cases"
            return 1
        }
    }
    
    log_success "Collation version updated successfully"
}

# Function to analyze database
analyze_database() {
    log_info "Analyzing database for potential issues..."
    
    if [[ -f .env ]]; then
        source .env
    else
        log_error ".env file not found"
        exit 1
    fi
    
    echo
    log_info "Database Statistics:"
    docker compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
        SELECT 
            schemaname,
            tablename,
            pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
        FROM pg_tables 
        WHERE schemaname NOT IN ('information_schema', 'pg_catalog')
        ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
    " 2>/dev/null
    
    echo
    log_info "Database Connection Info:"
    docker compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
        SELECT 
            current_database() as database,
            current_user as user,
            version() as postgresql_version;
    " 2>/dev/null
}

# Function to create database backup
create_backup() {
    log_info "Creating database backup..."
    
    if [[ -f .env ]]; then
        source .env
    else
        log_error ".env file not found"
        exit 1
    fi
    
    # Create backups directory
    mkdir -p backups
    
    BACKUP_FILE="backups/n8n_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    log_info "Backing up database to: $BACKUP_FILE"
    
    docker compose exec postgres pg_dump -U "$POSTGRES_NON_ROOT_USER" -d "$POSTGRES_DB" > "$BACKUP_FILE"
    
    if [[ $? -eq 0 ]]; then
        # Compress the backup
        gzip "$BACKUP_FILE"
        log_success "Backup created successfully: ${BACKUP_FILE}.gz"
        
        # Show backup size
        BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
        log_info "Backup size: $BACKUP_SIZE"
    else
        log_error "Backup failed"
        return 1
    fi
}

# Function to restart N8N with clean state
restart_n8n_clean() {
    log_info "Restarting N8N with clean state..."
    
    log_info "Stopping N8N..."
    docker compose stop n8n
    
    log_info "Removing N8N container..."
    docker compose rm -f n8n
    
    log_info "Starting N8N..."
    docker compose up -d n8n
    
    log_success "N8N restarted successfully"
    
    # Wait a moment and show logs
    sleep 5
    log_info "Recent N8N logs:"
    docker compose logs --tail=10 n8n
}

# Function to show service status
show_status() {
    log_info "Service Status:"
    docker compose ps
    
    echo
    log_info "Recent logs from all services:"
    docker compose logs --tail=5
}

# Main menu
show_menu() {
    echo
    echo "=== N8N Database Maintenance ==="
    echo
    echo "1) Fix PostgreSQL collation version mismatch"
    echo "2) Create database backup"
    echo "3) Analyze database"
    echo "4) Restart N8N (clean state)"
    echo "5) Show service status"
    echo "6) View PostgreSQL logs"
    echo "7) View N8N logs"
    echo "0) Exit"
    echo
}

# Main script
main() {
    echo -e "${GREEN}=== N8N Database Maintenance Script ===${NC}"
    
    while true; do
        show_menu
        read -p "Enter choice [0-7]: " choice
        
        case $choice in
            1) 
                check_postgres_running
                fix_collation_version 
                ;;
            2) 
                check_postgres_running
                create_backup 
                ;;
            3) 
                check_postgres_running
                analyze_database 
                ;;
            4) restart_n8n_clean ;;
            5) show_status ;;
            6) 
                check_postgres_running
                docker compose logs --tail=20 postgres 
                ;;
            7) docker compose logs --tail=20 n8n ;;
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

# Check prerequisites
if ! command -v docker compose &> /dev/null; then
    log_error "docker compose not found"
    exit 1
fi

# Run main function
main