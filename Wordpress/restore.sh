#!/bin/bash

# WordPress Restore Wrapper Script
# Provides easy command-line access to restore functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== WordPress Restore Tool ===${NC}"
echo

# Check prerequisites
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: docker-compose not found${NC}"
    exit 1
fi

if [[ ! -f .env ]]; then
    echo -e "${RED}Error: .env file not found${NC}"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Function to run restore with parameters
run_restore() {
    echo -e "${YELLOW}Running restore command...${NC}"
    docker-compose --profile restore run --rm restore "$@"
}

# Parse command line arguments
case "${1:-help}" in
    list|ls|-l|--list)
        echo "📋 Listing available backups..."
        run_restore -l
        ;;
    full|-a|--all)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Timestamp required${NC}"
            echo "Usage: $0 full YYYYMMDD_HHMMSS"
            echo "Example: $0 full 20240924_020000"
            exit 1
        fi
        echo -e "${YELLOW}⚠️  WARNING: Full restore will replace all WordPress data!${NC}"
        echo "Timestamp: $2"
        read -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            run_restore -a "$2"
        else
            echo "Restore cancelled"
        fi
        ;;
    files|-f|--files)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Files backup filename required${NC}"
            echo "Usage: $0 files wordpress_files_YYYYMMDD_HHMMSS.tar.gz"
            exit 1
        fi
        echo -e "${YELLOW}⚠️  WARNING: This will replace all WordPress files!${NC}"
        echo "Backup file: $2"
        read -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            run_restore -f "$2"
        else
            echo "Restore cancelled"
        fi
        ;;
    database|db|-d|--database)
        if [[ -z "$2" ]]; then
            echo -e "${RED}Error: Database backup filename required${NC}"
            echo "Usage: $0 database wordpress_db_YYYYMMDD_HHMMSS.sql.gz"
            exit 1
        fi
        echo -e "${YELLOW}⚠️  WARNING: This will replace all database content!${NC}"
        echo "Backup file: $2"
        read -p "Are you sure? (yes/no): " confirm
        if [[ "$confirm" == "yes" ]]; then
            run_restore -d "$2"
        else
            echo "Restore cancelled"
        fi
        ;;
    help|-h|--help|*)
        echo "WordPress Restore Tool"
        echo
        echo "Usage: $0 COMMAND [OPTIONS]"
        echo
        echo "Commands:"
        echo "  list                          List available backup files"
        echo "  full TIMESTAMP                Restore both files and database"
        echo "  files BACKUP_FILE             Restore only WordPress files"  
        echo "  database BACKUP_FILE          Restore only database"
        echo "  help                          Show this help message"
        echo
        echo "Examples:"
        echo "  $0 list                                           # List backups"
        echo "  $0 full 20240924_020000                           # Full restore"
        echo "  $0 files wordpress_files_20240924_020000.tar.gz   # Files only"
        echo "  $0 database wordpress_db_20240924_020000.sql.gz   # Database only"
        echo
        echo -e "${YELLOW}⚠️  Always backup current data before restore operations!${NC}"
        echo -e "${YELLOW}⚠️  Test restore procedures in staging environment first!${NC}"
        ;;
esac