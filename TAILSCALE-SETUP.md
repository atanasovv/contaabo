# Tailscale Setup Guide for WordPress Project

This guide shows how to set up Tailscale on your Ubuntu server to securely access phpMyAdmin and Traefik dashboard.

## 1. Install Tailscale on Ubuntu Server

```bash
# Download and install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Start Tailscale and authenticate
sudo tailscale up

# (Optional) Set a stable hostname
sudo tailscale up --hostname=coach-bg-server
```

## 2. Install Tailscale on Your Devices

### Laptop/Desktop:
- Download from: https://tailscale.com/download
- Sign in with the same account you used on the server

### Mobile:
- Install Tailscale app from App Store/Google Play
- Sign in with the same account

## 3. Verify Tailscale Connection

```bash
# On your server - check Tailscale status
sudo tailscale status

# Example output:
# 100.64.1.100  coach-bg-server  your-email@domain.com  linux   -
# 100.64.1.101  your-laptop      your-email@domain.com  windows active; relay "fra", tx 2468 rx 1234

# Check your server's Tailscale IP
ip addr show tailscale0
```

## 4. Update Your Local Hosts File

Add these entries to your laptop's hosts file:

### Windows: `C:\Windows\System32\drivers\etc\hosts`
### Mac/Linux: `/etc/hosts`

```
# Replace 100.64.1.100 with your server's actual Tailscale IP
100.64.1.100  phpmyadmin.internal.coach-bg.com
100.64.1.100  traefik.internal.coach-bg.com
100.64.1.100  wordpress.coach-bg.com
```

## 5. Deploy Services

Use the application management script to start your services:

```bash
# Make scripts executable (if not already done)
chmod +x /mnt/data2/AI-Projects/contaabo/deploy-tailscale.sh
chmod +x /mnt/data2/AI-Projects/contaabo/manage-apps.sh

# Start all services
./manage-apps.sh start all

# Or start individual services
./manage-apps.sh start traefik
./manage-apps.sh start wordpress
./manage-apps.sh start phpmyadmin

# Check status
./manage-apps.sh status all
```

## 6. Application Management

The `manage-apps.sh` script provides comprehensive service management:

```bash
# Usage
./manage-apps.sh {start|stop|restart|status} {all|traefik|wordpress|n8n|phpmyadmin}

# Examples
./manage-apps.sh start all           # Start all services
./manage-apps.sh stop wordpress      # Stop WordPress stack
./manage-apps.sh restart traefik     # Restart Traefik
./manage-apps.sh status all          # Show status of all services
```

## 7. Access Your Services

Once Tailscale is running and hosts file is updated:

- **WordPress (Public)**: https://wordpress.coach-bg.com
- **phpMyAdmin (VPN only)**: https://phpmyadmin.internal.coach-bg.com
- **Traefik Dashboard (VPN only)**: https://traefik.internal.coach-bg.com

## 8. Security Features Enabled

✅ **IP Whitelisting**: Only Tailscale IPs (100.64.0.0/10) can access admin services  
✅ **Basic Authentication**: Traefik dashboard requires username/password  
✅ **HTTPS**: All traffic encrypted via self-signed certificates  
✅ **Zero public ports**: Admin services not accessible from internet  

## 9. Troubleshooting

### Check Tailscale IP:
```bash
tailscale ip -4
```

### Test connectivity:
```bash
# From your laptop, ping the server
ping 100.64.1.100

# Test access (replace with your server's Tailscale IP)
curl -k https://100.64.1.100/api/rawdata
```

### Check service status:
```bash
./manage-apps.sh status all
```

## 10. Advanced: Enable MagicDNS (Optional)

In Tailscale admin console (https://login.tailscale.com/admin):
1. Go to DNS settings
2. Enable MagicDNS
3. Access services via: `https://coach-bg-server:443`

## 11. Security Best Practices

- **Regular updates**: Keep Tailscale updated: `sudo tailscale update`
- **Device management**: Remove old devices from Tailscale admin console
- **Key rotation**: Tailscale handles this automatically
- **Monitoring**: Check Tailscale admin console for active connections

## Benefits of This Setup

🔒 **Zero Attack Surface**: Admin tools not exposed to internet  
🌐 **Access Anywhere**: Works from any location with internet  
⚡ **High Performance**: Direct connections when possible  
🔄 **Auto-reconnect**: Handles network changes automatically  
📱 **Multi-device**: Same setup works on all your devices  
🆓 **Free**: Up to 20 devices for personal use  

Your WordPress site remains publicly accessible while admin tools are secured behind Tailscale VPN.