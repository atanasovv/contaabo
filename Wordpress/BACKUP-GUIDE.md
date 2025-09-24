# WordPress Backup System Documentation

## Overview
The WordPress backup system provides comprehensive backup and restore functionality with both manual and automated scheduled options.

## 🏗️ **System Architecture**

### **Services**
- **backup**: Manual backup execution (one-time)
- **backup-scheduler**: Automated scheduled backups with cron
- **restore**: Interactive restore service
- **WordPress**: Now uses Apache (not PHP-FPM) for direct Traefik integration
- **No Nginx**: Removed as you're using Traefik from n8n configuration

### **Scripts Structure**
```
scripts/
├── backup.sh    # Backup execution logic
└── restore.sh   # Restore execution logic

# Wrapper scripts
├── run-backup.sh      # Simple manual backup
├── backup-manager.sh  # Interactive backup/restore manager  
└── restore.sh         # Command-line restore tool
```

### 📋 **What Gets Backed Up**
1. **WordPress Files**: All WordPress files, themes, plugins, uploads
2. **Database**: Complete MySQL database dump
3. **Logs**: Backup operation logs with timestamps

### 💾 **Backup Storage**
- **Location**: `./backups/` directory
- **File Format**: 
  - Files: `wordpress_files_YYYYMMDD_HHMMSS.tar.gz`
  - Database: `wordpress_db_YYYYMMDD_HHMMSS.sql.gz`
  - Logs: `backup_YYYYMMDD_HHMMSS.log`

## 🚀 **How to Execute Backups**

### **Method 1: Manual Script Execution**
```bash
# Simple manual backup
./run-backup.sh
```

### **Method 2: Docker Compose Direct**
```bash
# Run backup service once
docker-compose --profile backup run --rm backup

# Or start and remove container after completion
docker-compose --profile backup up backup
```

### **Method 3: Interactive Backup Manager**
```bash
# Run the comprehensive backup manager
./backup-manager.sh
```

## 🕐 **Automated Scheduled Backups**

### **Enable Scheduled Backups**
I've added a `backup-scheduler` service that provides automated backups:

```bash
# Start scheduled backup service
docker-compose --profile scheduled-backup up -d backup-scheduler

# Or use the backup manager
./backup-manager.sh  # Choose option 2
```

### **Configure Schedule**
Edit your `.env` file:
```bash
# Daily at 2 AM (default)
BACKUP_SCHEDULE=0 2 * * *

# Every 6 hours
BACKUP_SCHEDULE=0 */6 * * *

# Weekly on Sunday at 3 AM
BACKUP_SCHEDULE=0 3 * * 0

# Keep backups for 7 days (default)
BACKUP_RETENTION_DAYS=7
```

### **Common Cron Schedule Examples**
```bash
# Every day at 2:00 AM
0 2 * * *

# Every day at 1:30 AM
30 1 * * *

# Every 6 hours
0 */6 * * *

# Every Sunday at 3 AM
0 3 * * 0

# Twice daily (6 AM and 6 PM)
0 6,18 * * *

# Every weekday at 2 AM
0 2 * * 1-5
```

## 🔧 **Backup Management Commands**

### **Check Status**
```bash
# Check if scheduled backup is running
docker-compose --profile scheduled-backup ps

# View backup logs
docker-compose --profile scheduled-backup logs backup-scheduler
```

### **Manual Operations**
```bash
# List backup files
ls -la backups/

# Check disk usage
du -sh backups/*

# Clean old backups (older than 7 days)
find backups/ -name 'wordpress_*' -mtime +7 -delete
```

### **Stop Scheduled Backups**
```bash
# Stop scheduled backup service
docker-compose --profile scheduled-backup down

# Or use backup manager
./backup-manager.sh  # Choose option 3
```

## 📊 **Monitoring and Logs**

### **View Backup Logs**
```bash
# Real-time logs
docker-compose --profile scheduled-backup logs -f backup-scheduler

# Recent logs
docker-compose --profile scheduled-backup logs --tail=50 backup-scheduler
```

### **Check Backup Success**
```bash
# Look for recent backup files
ls -lt backups/ | head -10

# Check log files for errors
grep -i error backups/backup_*.log
```

## 🔄 **Restore Operations**

### **Command Line Restore**
```bash
# List available backups
./restore.sh list

# Full restore (files + database)
./restore.sh full 20240924_020000

# Restore only files
./restore.sh files wordpress_files_20240924_020000.tar.gz

# Restore only database  
./restore.sh database wordpress_db_20240924_020000.sql.gz
```

### **Interactive Restore**
```bash
# Use the backup manager for guided restore
./backup-manager.sh
# Choose option 7: "Restore from backup"
```

### **Docker Compose Direct**
```bash
# List backups
docker-compose --profile restore run --rm restore -l

# Full restore
docker-compose --profile restore run --rm restore -a 20240924_020000

# Files only
docker-compose --profile restore run --rm restore -f wordpress_files_20240924_020000.tar.gz

# Database only
docker-compose --profile restore run --rm restore -d wordpress_db_20240924_020000.sql.gz
```

## 🛡️ **Safety Features**

### **Pre-Restore Backups**
Before any restore operation, the system automatically:
1. **Files**: Creates backup of current WordPress files
2. **Database**: Creates backup of current database
3. **Logs**: Records all restore operations

### **Restore Process**
1. **Validation**: Checks if backup files exist
2. **Pre-backup**: Saves current state
3. **Restoration**: Performs the restore operation
4. **Logging**: Records all steps and results

## 🛡️ **Best Practices**

### **Security**
1. **Encrypt backups** for off-site storage
2. **Test restore procedures** regularly
3. **Secure backup directory** permissions
4. **Monitor backup logs** for failures

### **Storage Management**
1. **Regular cleanup** of old backups
2. **Off-site backup** copies
3. **Monitor disk space** usage
4. **Compress backups** to save space

### **Scheduling**
1. **Non-peak hours**: Schedule during low traffic
2. **Regular frequency**: Daily for active sites
3. **Retention policy**: Keep 7-30 days locally
4. **Long-term storage**: Monthly backups off-site

## 🔍 **Troubleshooting**

### **Common Issues**

#### **Backup Fails with Permission Errors**
```bash
# Check/fix backup directory permissions
mkdir -p backups
chmod 755 backups
```

#### **Database Connection Fails**
```bash
# Verify environment variables in .env
grep -E "WP_DB_|MYSQL_" .env

# Check database container health
docker-compose ps db
```

#### **Disk Space Issues**
```bash
# Check available space
df -h

# Clean old backups
find backups/ -mtime +7 -delete
```

#### **Scheduled Backup Not Running**
```bash
# Check if service is up
docker-compose --profile scheduled-backup ps

# Check logs for errors
docker-compose --profile scheduled-backup logs backup-scheduler

# Restart scheduler
docker-compose --profile scheduled-backup restart backup-scheduler
```

## 📝 **Quick Reference**

| Task | Command |
|------|---------|
| Manual backup | `./run-backup.sh` |
| Start scheduler | `docker-compose --profile scheduled-backup up -d backup-scheduler` |
| Stop scheduler | `docker-compose --profile scheduled-backup down` |
| Check status | `docker-compose --profile scheduled-backup ps` |
| View logs | `docker-compose --profile scheduled-backup logs backup-scheduler` |
| List backups | `ls -la backups/` |
| Interactive manager | `./backup-manager.sh` |

## 🎯 **Recommendations**

For your WordPress installation, I recommend:

1. **Use the scheduled backup service** for automated daily backups
2. **Set schedule to 2 AM daily** (low traffic time)
3. **Keep 7 days of local backups** for quick recovery
4. **Copy backups off-site weekly** for disaster recovery
5. **Test restore process monthly** to ensure backups work
6. **Monitor backup logs** for any failures