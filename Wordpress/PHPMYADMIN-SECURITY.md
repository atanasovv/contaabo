# phpMyAdmin IP Restriction Setup Guide

## Overview
This configuration enables phpMyAdmin with IP-based access restrictions, allowing only your home IP address to access the database management interface.

## Security Features Implemented
1. **IP Whitelist**: Only specified IP addresses can access phpMyAdmin
2. **Basic Authentication**: Additional username/password protection
3. **HTTPS Only**: All traffic encrypted via Traefik/Let's Encrypt
4. **Security Headers**: XSS protection, frame denial, etc.
5. **Network Isolation**: phpMyAdmin runs in isolated Docker networks

## Quick Setup Steps

### 1. Find Your Home IP Address
```bash
# Run the setup helper script
./setup-phpmyadmin.sh

# Or manually check your IP
curl ifconfig.me
```

### 2. Configure Environment Variables
Copy and edit the environment file:
```bash
cp .env.example .env
```

Edit `.env` file and set:
- `PMA_ALLOWED_IPS`: Your home IP (e.g., `203.0.113.1/32`)
- `PMA_BASIC_AUTH`: Username:password hash (generate with htpasswd)

### 3. Generate Basic Auth Credentials
```bash
# Install htpasswd if not available
sudo apt install apache2-utils  # Ubuntu/Debian
# or
sudo yum install httpd-tools     # CentOS/RHEL

# Generate the hash
htpasswd -nb admin your_password
```

### 4. Example Configuration
In your `.env` file:
```bash
# Allow single IP
PMA_ALLOWED_IPS=203.0.113.1/32

# Allow IP range (your ISP's subnet)
PMA_ALLOWED_IPS=203.0.113.0/24

# Allow multiple specific IPs
PMA_ALLOWED_IPS=203.0.113.1/32,203.0.113.2/32

# Basic auth (generated with htpasswd)
PMA_BASIC_AUTH=admin:$2y$10$xxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 5. Start the Services
```bash
docker-compose up -d phpmyadmin
```

## Access phpMyAdmin
- URL: `https://pma.example.com` (replace with your domain)
- Login: Use the basic auth credentials you set
- Then: Use MySQL database credentials to access databases

## Security Considerations

### IP Address Changes
- Home IP addresses may change (dynamic IP from ISP)
- Monitor your IP and update `.env` file when needed
- Consider using a DynDNS service for dynamic IPs

### Network Security
- Only your specified IP(s) can access phpMyAdmin
- All other IPs will receive a 403 Forbidden error
- Traffic is encrypted with HTTPS/TLS

### Additional Security
- Use strong passwords for both basic auth and MySQL
- Regularly update phpMyAdmin image
- Monitor access logs for suspicious activity
- Consider using VPN instead of IP restrictions

## Troubleshooting

### Cannot Access phpMyAdmin
1. Check your current IP: `curl ifconfig.me`
2. Verify IP in `.env` file matches your current IP
3. Restart containers: `docker-compose restart phpmyadmin`
4. Check Traefik logs for 403 errors

### IP Changed
1. Update `PMA_ALLOWED_IPS` in `.env` file
2. Restart phpMyAdmin: `docker-compose restart phpmyadmin`

### Forgot Basic Auth Password
1. Generate new hash: `htpasswd -nb username newpassword`
2. Update `PMA_BASIC_AUTH` in `.env` file
3. Restart phpMyAdmin: `docker-compose restart phpmyadmin`

## Alternative Access Methods

### Temporary Access
If you need temporary access from a different IP:
```bash
# Add temporary IP to allowed list
PMA_ALLOWED_IPS=203.0.113.1/32,temporary.ip.here/32

# Restart service
docker-compose restart phpmyadmin

# Remember to remove temporary IP later
```

### VPN Access
Instead of IP restrictions, consider:
1. Set up a VPN server
2. Allow VPN subnet in IP restrictions
3. Connect via VPN to access phpMyAdmin

## Monitoring
- Check access logs: `docker-compose logs phpmyadmin`
- Monitor failed access attempts in Traefik logs
- Set up alerts for repeated 403 errors (possible attacks)