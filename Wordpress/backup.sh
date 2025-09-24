#!/bin/bash

# WordPress Backup Script
# Usage: ./backup.sh

set -e

echo "Starting WordPress backup..."

# Create timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Run backup service
docker-compose --profile backup run --rm backup

echo "Backup completed: wordpress_files_${TIMESTAMP}.tar.gz and wordpress_db_${TIMESTAMP}.sql.gz"
echo "Backup files are stored in ./backups/"

# Optional: Clean up old backups (keep last 7 days)
find ./backups/ -name "wordpress_*" -mtime +7 -delete 2>/dev/null || true

echo "Old backups cleaned up (kept last 7 days)"