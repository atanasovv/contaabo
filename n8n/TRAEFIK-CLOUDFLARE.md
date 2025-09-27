# Traefik with Cloudflare Integration Guide

This guide explains how to properly configure Traefik when your site is behind Cloudflare.

## Overview

When your site is behind Cloudflare:
- Client IPs are replaced with Cloudflare IPs
- Traditional IP whitelisting won't work without special configuration
- You need to extract the real client IP from Cloudflare headers

## Setup Steps

### 1. Configure Cloudflare

1. Log into your Cloudflare dashboard
2. Navigate to your domain's settings
3. Under "SSL/TLS", set the mode to "Full (strict)"
4. Under "Network", ensure these options are enabled:
   - IP Geolocation
   - WebSockets
   - HTTP/3 (QUIC)

### 2. Traefik Configuration

Our setup includes:
- A custom Dockerfile that builds Traefik with the Cloudflare Real IP plugin
- Dynamic configuration for the plugin with Cloudflare IP ranges
- Middlewares that extract the real client IP and apply security

### 3. IP Whitelisting with Cloudflare

With this setup, you can now use IP whitelisting even behind Cloudflare:
```yaml
- "traefik.http.middlewares.traefik-ip-whitelist.ipallowlist.sourcerange=127.0.0.1/32,192.168.1.0/24"
```

The real client IP will be used instead of Cloudflare's IP.

## Troubleshooting

### 1. Verify the Plugin is Working

To check if the real IP is being extracted correctly:

```bash
# Check Traefik logs
docker logs traefik | grep "real-ip"

# Test your site with a request
curl -v -H "CF-Connecting-IP: 192.168.1.100" https://your-domain.com
```

### 2. Update Cloudflare IP Ranges

Cloudflare occasionally updates their IP ranges. Update `cloudflare-plugin.yaml` with the latest ranges from:
https://www.cloudflare.com/ips/

### 3. Common Issues

- **Plugin not loading**: Check the Traefik logs for plugin-related errors
- **IP whitelisting not working**: Ensure the middlewares are in the correct order (cloudflare-real-ip should be first)
- **Certificate issues**: Make sure you've correctly configured SSL settings in Cloudflare

## Security Considerations

- The CF-Connecting-IP header can be spoofed if requests don't come through Cloudflare
- Always verify that incoming requests are actually from Cloudflare IPs
- Consider using Cloudflare Access for additional security

## References

- [Traefik Cloudflare Real IP Plugin](https://github.com/BetaHuhn/traefik-cloudflare-real-ip)
- [Cloudflare IP Ranges](https://www.cloudflare.com/ips/)