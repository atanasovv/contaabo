# Traefik Advanced Plugin Guide for WordPress and n8n

This guide explains the various plugins included in your Traefik setup and how they can help secure and optimize your WordPress and n8n services.

## Overview of Installed Plugins

Your Traefik setup now includes these powerful plugins:

1. **Cloudflare Real IP** - Extract real client IPs when behind Cloudflare
2. **Rate Limiting** - Prevent brute force attacks and API abuse
3. **Rewrite Headers** - Fix common WordPress/n8n proxy issues
4. **Maintenance Page** - Show maintenance pages during updates
5. **GeoBlock** - Block or allow traffic based on country
6. **Cache** - Speed up your site by caching static assets

## How These Plugins Help WordPress

### Security Enhancements
- **Rate Limiting** protects wp-login.php from brute force attacks
- **GeoBlock** reduces spam by limiting access to specific countries
- **Cloudflare Real IP** ensures proper IP logging in WordPress

### Performance Improvements
- **Cache** reduces server load by caching static assets
- **Rewrite Headers** fixes WordPress redirects and ensures HTTPS works correctly

### Maintenance
- **Maintenance Page** allows you to show a professional maintenance page while updating WordPress

## How These Plugins Help n8n

### Security Enhancements
- **Rate Limiting** prevents API abuse
- **GeoBlock** restricts access to your automation server
- **Cloudflare Real IP** ensures proper IP logging for workflow triggers

### Reliability
- **Rewrite Headers** ensures webhooks and API calls work properly
- **Maintenance Page** allows for maintenance without losing workflow execution state

## Plugin Configuration Files

Each plugin is configured in its own file in the `traefik_dynamic_conf` directory:

| File | Purpose |
|------|---------|
| `cloudflare-plugin.yaml` | Extracts real client IPs |
| `rate-limit.yaml` | Configures various rate limits |
| `rewrite-headers.yaml` | Fixes HTTP header issues |
| `maintenance-page.yaml` | Configures maintenance pages |
| `geoblock.yaml` | Controls country-based access |
| `cache.yaml` | Configures static asset caching |
| `wordpress.yaml` | WordPress-specific routing rules |
| `n8n.yaml` | n8n-specific routing rules |

## Common Tasks

### Enabling Maintenance Mode

Edit `maintenance-page.yaml` and set `enabled: true` for the desired service:

```yaml
wordpress-maintenance:
  plugin:
    maintenancepage:
      enabled: true  # Change to true to enable
```

Restart Traefik or trigger a config reload:
```bash
docker kill -s SIGHUP traefik
```

### Blocking Countries

Edit `geoblock.yaml` and set `enabled: false`, then list allowed countries:

```yaml
country-whitelist:
  plugin:
    geoip:
      enabled: false  # Set to false to enable blocking
      allow:
        - "BG"  # Bulgaria
        - "US"  # United States
```

### Customizing Rate Limits

Edit `rate-limit.yaml` to adjust limits for different paths:

```yaml
wp-login-ratelimit:
  plugin:
    ratelimit:
      average: 5     # Requests per period
      period: 20s    # Time period
      burst: 10      # Allowed burst
```

## Best Practices

1. **Test configuration changes** on a staging environment before deploying to production

2. **Monitor Traefik logs** for any plugin issues:
   ```bash
   docker logs traefik | grep "plugin"
   ```

3. **Back up configuration files** before making changes:
   ```bash
   cp -r traefik_dynamic_conf traefik_dynamic_conf_backup
   ```

4. **Use middleware chains** to apply multiple plugins in a specific order

5. **Update Cloudflare IP ranges** periodically:
   ```bash
   ./setup-traefik-cloudflare.sh
   # Choose option 1 to update IP ranges
   ```

## Troubleshooting

### Plugin Not Working

Check Traefik logs for plugin errors:
```bash
docker logs traefik | grep -i error
```

### Configuration Not Applied

Traefik watches for file changes, but sometimes needs a manual reload:
```bash
docker kill -s SIGHUP traefik
```

### Rate Limiting Too Aggressive

Adjust the `average`, `period`, and `burst` values in `rate-limit.yaml` to be more permissive.

### Maintenance Mode Blocking Your Access

Add your IP to the `allowedIPs` list in the maintenance plugin configuration:
```yaml
allowedIPs:
  - "127.0.0.1"
  - "your.public.ip.here"
```