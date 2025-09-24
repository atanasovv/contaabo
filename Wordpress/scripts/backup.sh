#!/bin/sh

# WordPress Automated Backup Script
# This script is executed by the backup-scheduler container

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=/backups
LOG_FILE=$BACKUP_DIR/backup_$DATE.log

# Ensure backup directory exists
mkdir -p $BACKUP_DIR

echo "$(date): Starting backup process" | tee $LOG_FILE

# Create WordPress files backup
echo "$(date): Creating WordPress files backup..." | tee -a $LOG_FILE
if tar -czf $BACKUP_DIR/wordpress_files_$DATE.tar.gz -C /wordpress . 2>>$LOG_FILE; then
    echo "$(date): WordPress files backup completed" | tee -a $LOG_FILE
else
    echo "$(date): WordPress files backup failed" | tee -a $LOG_FILE
    exit 1
fi

# Create database backup
echo "$(date): Creating database backup..." | tee -a $LOG_FILE
if mysqldump -h db -u $WP_DB_USER -p$WP_DB_PASSWORD $WP_DB_NAME > $BACKUP_DIR/wordpress_db_$DATE.sql 2>>$LOG_FILE; then
    gzip $BACKUP_DIR/wordpress_db_$DATE.sql
    echo "$(date): Database backup completed" | tee -a $LOG_FILE
else
    echo "$(date): Database backup failed" | tee -a $LOG_FILE
    exit 1
fi

# Clean old backups
echo "$(date): Cleaning old backups (keeping $BACKUP_RETENTION_DAYS days)..." | tee -a $LOG_FILE
find $BACKUP_DIR -name "wordpress_*" -type f -mtime +$BACKUP_RETENTION_DAYS -delete 2>>$LOG_FILE

# Calculate backup sizes
FILES_SIZE=$(du -h $BACKUP_DIR/wordpress_files_$DATE.tar.gz | cut -f1)
DB_SIZE=$(du -h $BACKUP_DIR/wordpress_db_$DATE.sql.gz | cut -f1)

echo "$(date): Backup process completed successfully" | tee -a $LOG_FILE
echo "$(date): Files backup size: $FILES_SIZE" | tee -a $LOG_FILE
echo "$(date): Database backup size: $DB_SIZE" | tee -a $LOG_FILE
echo "$(date): Total backups in directory: $(ls -1 $BACKUP_DIR/wordpress_* 2>/dev/null | wc -l)" | tee -a $LOG_FILE