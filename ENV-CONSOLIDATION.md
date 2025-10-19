# Environment Variables Consolidation Guide

## Overview

All environment variables for the entire project have been consolidated into a single `.env` file at the root level. This simplifies configuration management and ensures consistency across all services.

## Structure

```
/contaabo/
├── .env                    # ← Single environment file for all services
├── .env.example           # ← Template with all variables
├── manage-apps.sh         # ← Updated to use root .env
├── db-manager.sh          # ← Database management
├── wp-url-changer.sh      # ← WordPress URL changer
├── wordpress/
│   ├── docker-compose.yml # ← Updated to use ../env
│   └── (removed .env.example)
├── n8n/
│   ├── docker-compose.yml # ← Updated to use ../env  
│   └── (removed .env.example)
└── traefik/
    ├── docker-compose.yml # ← Updated to use ../env
    └── (removed .env.example)
```

## Quick Setup

1. **Copy the example file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit your configuration:**
   ```bash
   nano .env  # or your preferred editor
   ```

3. **Update critical values:**
   - `BASE_DOMAIN_NAME` - Your main domain
   - All password fields with strong passwords
   - `SSL_EMAIL` - Your email for Let's Encrypt
   - `GENERIC_TIMEZONE` - Your timezone

4. **Start services:**
   ```bash
   ./manage-apps.sh start all
   ```

## Variable Substitution

The .env file supports variable substitution using `${VARIABLE_NAME}` syntax. This allows you to define base values and compose them into more complex variables:

```bash
# Base configuration
BASE_DOMAIN_NAME=example.com
WORDPRESS_SUBDOMAIN=wordpress

# Composed variables (automatically resolved)
WORDPRESS_HOST=${WORDPRESS_SUBDOMAIN}.${BASE_DOMAIN_NAME}
# Results in: wordpress.example.com
```

### Benefits:
- **DRY Principle**: Define domain once, use everywhere
- **Easy Updates**: Change domain in one place
- **Consistency**: Automatic hostname generation
- **Flexibility**: Easy environment switching (dev/staging/prod)

### Syntax Rules:
- Use `${VAR_NAME}` for variable substitution
- Variables must be defined before they're referenced
- Works with Docker Compose and shell environments
- Can combine multiple variables: `${SUB}.${DOMAIN}`

## Key Variables by Service

### WordPress & MySQL
- `WP_DB_NAME`, `WP_DB_USER`, `WP_DB_PASSWORD`
- `MYSQL_ROOT_PASSWORD`
- `WORDPRESS_HOST`

### N8N & PostgreSQL  
- `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- `POSTGRES_NON_ROOT_USER`, `POSTGRES_NON_ROOT_PASSWORD`
- `N8N_HOST`, `N8N_ENCRYPTION_KEY`
- `GENERIC_TIMEZONE`

### Traefik
- `TRAEFIK_HOST`
- `TRAEFIK_BASIC_AUTH`
- `ADMIN_IP_RANGE`

### Security & Access
- `ADMIN_IP_RANGE` - IP whitelist for admin access (Tailscale VPN)
- `PMA_BASIC_AUTH` - phpMyAdmin authentication
- All password fields

## Changes Made

### Docker Compose Files
All `docker-compose.yml` files now include:
```yaml
env_file:
  - ../.env
```

### Management Scripts
The `manage-apps.sh` script now uses:
```bash
docker compose --env-file "../.env" up -d service_name
```

### Variable Consolidation
- **Before:** 3 separate `.env` files in each service directory
- **After:** 1 consolidated `.env` file at the root
- **Result:** Single source of truth for all configuration

## Security Improvements

### Default Configuration
- All hostnames now use variables instead of hardcoded values
- IP whitelists centralized for consistent VPN access  
- Password templates provided for all services

### Production Checklist
- [ ] Strong passwords (16+ characters)
- [ ] Unique passwords per service
- [ ] Proper domain configuration
- [ ] Timezone set correctly
- [ ] htpasswd hashes generated
- [ ] IP ranges configured for your network

## Password Generation

Generate secure passwords:
```bash
# For regular passwords
openssl rand -base64 32

# For htpasswd authentication  
htpasswd -nb username password
# Remember to escape $ as $$ in .env files
```

## Testing Configuration

1. **Check environment loading:**
   ```bash
   cd wordpress && docker compose --env-file="../.env" config
   ```

2. **Verify services start:**
   ```bash
   ./manage-apps.sh start all
   ./manage-apps.sh status all
   ```

3. **Test database access:**
   ```bash
   ./db-manager.sh list
   ```

4. **Verify URL configuration:**
   ```bash  
   ./wp-url-changer.sh show
   ```

## Troubleshooting

### Common Issues

1. **Services won't start:**
   - Check `.env` file exists in root
   - Verify no syntax errors in `.env`
   - Ensure all required variables are set

2. **Authentication failures:**
   - Verify htpasswd hashes are properly escaped ($ → $$)
   - Check usernames don't contain special characters
   - Regenerate hashes if needed

3. **Database connection issues:**
   - Confirm database passwords match in `.env`
   - Check container health status
   - Verify network connectivity

### Debug Commands

```bash
# Check loaded environment variables
docker compose --env-file=".env" config

# View container logs
docker logs container_name

# Test database connection
docker exec wordpress_db mysql -u$WP_DB_USER -p$WP_DB_PASSWORD -e "SHOW DATABASES;"
```

## Migration from Old Setup

If migrating from the old multi-.env setup:

1. **Backup existing configurations:**
   ```bash
   cp wordpress/.env wordpress/.env.backup
   cp n8n/.env n8n/.env.backup  
   cp traefik/.env traefik/.env.backup
   ```

2. **Merge values into root .env:**
   - Copy passwords from old files
   - Update domain names as needed
   - Consolidate any custom settings

3. **Test the new setup:**
   - Start services with new configuration
   - Verify all services are accessible
   - Check database connections

4. **Clean up old files:**
   ```bash
   rm wordpress/.env n8n/.env traefik/.env
   ```

## Benefits

✅ **Single Configuration Source** - All settings in one file  
✅ **Simplified Management** - One file to edit and backup  
✅ **Consistency** - Same variables used across all services  
✅ **Version Control Safe** - Only .env.example in git  
✅ **Easier Deployment** - Copy one file to new environments  
✅ **Reduced Errors** - No more inconsistent configurations