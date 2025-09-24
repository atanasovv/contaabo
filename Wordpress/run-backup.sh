#!/bin/bash

# WordPress Backup Script - Manual Execution
# This script runs the backup service manually

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== WordPress Backup Script ==="
echo "Starting backup process..."
echo "Timestamp: $(date)"
echo

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "Error: docker-compose not found"
    exit 1
fi

# Check if .env file exists
if [[ ! -f .env ]]; then
    echo "Error: .env file not found"
    echo "Please create .env file from .env.example"
    exit 1
fi

# Create backups directory if it doesn't exist
mkdir -p backups

# Run the backup
echo "Running backup service..."
docker-compose --profile backup run --rm backup

# Check if backup was successful
if [[ $? -eq 0 ]]; then
    echo
    echo "✅ Backup completed successfully!"
    echo "Backup files are stored in: $(pwd)/backups/"
    echo
    echo "Recent backup files:"
    ls -la backups/ | tail -5
else
    echo "❌ Backup failed!"
    exit 1
fi

echo
echo "=== Backup Process Completed ==="