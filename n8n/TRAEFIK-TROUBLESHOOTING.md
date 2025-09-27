# Traefik Troubleshooting Guide

## Common Issues and Fixes

### 1. "Middleware does not exist" Error

```
ERR error="middleware \"default-rate-limit@file\" does not exist"
```

**Solution:**
- Ensure the dynamic configuration files are correctly loaded
- Check that you've set `--providers.file.directory` and `--providers.file.watch=true`
- Make sure file extensions are `.yaml` or `.yml`
- Verify the syntax of your dynamic configuration files

### 2. Let's Encrypt Certificate Challenges

#### Issue: TLS Challenge Failure
```
ERR Unable to obtain ACME certificate... Cannot negotiate ALPN protocol "acme-tls/1" for tls-alpn-01 challenge
```

**Solution:**
- Use HTTP challenge instead of TLS challenge:
  ```yaml
  - "--certificatesresolvers.mytlschallenge.acme.httpchallenge=true"
  - "--certificatesresolvers.mytlschallenge.acme.httpchallenge.entrypoint=web"
  ```

#### Issue: HTTP Challenge Failure
```
ERR Unable to obtain ACME certificate... Invalid response from http://traefik.example.com/.well-known/acme-challenge/... 404
```

**Solution:**
1. **Temporarily disable HTTP to HTTPS redirection:**
   ```yaml
   # Comment out these lines until you have certificates
   # - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
   # - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
   ```

2. **Verify DNS is pointing correctly**
   - Make sure your domain resolves to your server's public IP
   - Try: `host traefik.example.com`

3. **Check port 80 is accessible**
   - Ensure your firewall allows port 80 traffic
   - Test with: `curl -v http://traefik.example.com`

4. **Clean Traefik's ACME data and try again**
   - Stop Traefik: `docker compose -f treafik.docker-compose.yml down`
   - Remove the volume: `docker volume rm traefik_data`
   - Restart Traefik: `docker compose -f treafik.docker-compose.yml up -d`
   
5. **Use the provided helper script:**
   ```bash
   ./fix-traefik-certs.sh
   ```

### 3. Configuration Errors

#### Issue: Timeout Parameter Not Supported
```
error: command traefik error: failed to decode configuration from flags: field not found, node: timeout
```

**Solution:**
- Remove the unsupported timeout parameter:
  ```yaml
  # Remove this line
  - "--certificatesresolvers.mytlschallenge.acme.httpchallenge.timeout=180"
  ```
- Traefik v3.0 may have a different syntax for timeouts or may not support this parameter
- Check the documentation for your specific Traefik version

### 4. Deprecated Middlewares

```
WRN Middleware "traefik-ip-whitelist@docker" of type IPWhiteList is deprecated, please use IPAllowList instead.
```

**Solution:**
- Update any occurrences of `ipwhitelist` to `ipallowlist`:
  ```yaml
  # From:
  - "traefik.http.middlewares.traefik-ip-whitelist.ipwhitelist.sourcerange=127.0.0.1/32,192.168.1.0/24"
  
  # To:
  - "traefik.http.middlewares.traefik-ip-whitelist.ipallowlist.sourcerange=127.0.0.1/32,192.168.1.0/24"
  ```

### 4. Traefik Version Compatibility

- The latest Traefik versions (v3.x) may have syntax differences
- Stick to well-tested versions like v2.10.4 or v3.0 for stability
- Check the Traefik documentation for your specific version

### 5. Password Escaping in Docker Compose

- Remember to escape dollar signs in password hashes:
  - Original: `admin:$apr1$rO5oPdXm$UzGzM7rVzNDrbF3kGt2JY/`
  - Escaped: `admin:$$apr1$$rO5oPdXm$$UzGzM7rVzNDrbF3kGt2JY/`

### 5. Debugging Tips

1. **Check Traefik logs:**
   ```bash
   docker logs traefik
   ```

2. **Enable debug logging:**
   Add `--log.level=DEBUG` to the command section

3. **Verify dynamic configuration:**
   ```bash
   docker exec -it traefik cat /etc/traefik/dynamic_conf/middlewares.yaml
   ```

4. **Check if Traefik can access the Docker socket:**
   ```bash
   docker exec -it traefik ls -la /var/run/docker.sock
   ```

5. **Test HTTP challenge manually:**
   ```bash
   curl -v http://yourdomain/.well-known/acme-challenge/test
   ```