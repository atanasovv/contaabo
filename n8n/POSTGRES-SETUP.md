# PostgreSQL Database Setup for n8n

This document explains the PostgreSQL database configuration for n8n and how the initialization works.

## Overview

n8n uses PostgreSQL as its database backend. The setup involves:

1. A root PostgreSQL user for administration
2. A non-root PostgreSQL user for n8n to connect with
3. An initialization script that sets up the necessary permissions

## Configuration Files

The setup involves these key files:

- `.env`: Contains database credentials and configuration
- `docker-compose.yml`: Defines the PostgreSQL service
- `init-data.sh`: Initializes the database when the container first starts

## Database Users

Two database users are configured:

1. **Root User** (`POSTGRES_USER`): 
   - Has full administrative access to PostgreSQL
   - Used for initial setup and maintenance

2. **Non-Root User** (`POSTGRES_NON_ROOT_USER`):
   - Used by n8n to connect to the database
   - Has limited permissions to only what n8n needs
   - More secure than using the root user

## The init-data.sh Script

The `init-data.sh` script is automatically executed when the PostgreSQL container is first created. It:

1. Creates the non-root user if it doesn't exist
2. Grants appropriate permissions on the database
3. Sets up default privileges for future objects
4. Creates necessary PostgreSQL extensions

## Security Best Practices

1. **Strong Passwords**: Use strong, unique passwords for both database users
2. **Least Privilege**: The non-root user has only the permissions it needs
3. **Internal Network**: The database is not exposed to the public internet
4. **Regular Backups**: Ensure you back up your database regularly

## Troubleshooting

If you encounter database connection issues:

1. Verify the credentials in the `.env` file match what's expected
2. Check if the initialization script ran successfully
3. Inspect PostgreSQL logs with: `docker logs n8n-postgres-1`
4. Connect to the database directly: `docker exec -it n8n-postgres-1 psql -U postgres`

## Database Maintenance

### Backup

To backup your database:

```bash
docker exec -t n8n-postgres-1 pg_dump -U postgres -d n8n > n8n_backup_$(date +%Y%m%d).sql
```

### Restore

To restore from a backup:

```bash
cat n8n_backup.sql | docker exec -i n8n-postgres-1 psql -U postgres -d n8n
```

### Accessing the Database

```bash
docker exec -it n8n-postgres-1 psql -U postgres -d n8n
```

## Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `POSTGRES_USER` | Root PostgreSQL username | `n8n_root` |
| `POSTGRES_PASSWORD` | Root PostgreSQL password | *(set in .env)* |
| `POSTGRES_DB` | Database name | `n8n` |
| `POSTGRES_NON_ROOT_USER` | Username for n8n connection | `n8n` |
| `POSTGRES_NON_ROOT_PASSWORD` | Password for n8n connection | *(set in .env)* |