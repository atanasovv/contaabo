# Project Scripts Overview

## 📁 Script Files

### 🔧 `deploy-tailscale.sh`
**Purpose**: Install and configure Tailscale VPN
**Usage**: `./deploy-tailscale.sh`
**Features**:
- Installs Tailscale if not present
- Checks authentication status
- Shows Tailscale IP for hosts file
- Provides setup instructions

### 🚀 `manage-apps.sh`
**Purpose**: Manage all application services
**Usage**: `./manage-apps.sh {command} {service}`

**Commands**:
- `start` - Start services
- `stop` - Stop services  
- `restart` - Restart services
- `status` - Show service status

**Services**:
- `all` - All services
- `traefik` - Reverse proxy
- `wordpress` - WordPress + MySQL + phpMyAdmin
- `n8n` - Automation platform (if configured)
- `phpmyadmin` - Database management (standalone)

## 🎯 Quick Start

1. **Install Tailscale**:
   ```bash
   ./deploy-tailscale.sh
   sudo tailscale up --hostname=coach-bg-server
   ```

2. **Start services**:
   ```bash
   ./manage-apps.sh start all
   ```

3. **Check status**:
   ```bash
   ./manage-apps.sh status all
   ```

## 📋 Common Operations

```bash
# Start everything
./manage-apps.sh start all

# Start only WordPress (includes MySQL + phpMyAdmin)
./manage-apps.sh start wordpress

# Start only Traefik
./manage-apps.sh start traefik

# Stop everything
./manage-apps.sh stop all

# Restart Traefik (useful after config changes)
./manage-apps.sh restart traefik

# Check what's running
./manage-apps.sh status all
```

## 🔗 Access URLs

After adding to your hosts file:
- **WordPress**: https://wordpress.coach-bg.com (public)
- **phpMyAdmin**: https://phpmyadmin.internal.coach-bg.com (VPN only)
- **Traefik Dashboard**: https://traefik.internal.coach-bg.com (VPN only)

## 🛡️ Security

- Admin services (phpMyAdmin, Traefik) are VPN-only
- WordPress remains publicly accessible
- All traffic uses HTTPS with self-signed certificates
- IP whitelisting restricts access to Tailscale network