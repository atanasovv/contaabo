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

### 2. TLS Certificate Challenges

```
ERR Unable to obtain ACME certificate... Cannot negotiate ALPN protocol "acme-tls/1" for tls-alpn-01 challenge
```

**Solution:**
- Use HTTP challenge instead of TLS challenge:
  ```yaml
  - "--certificatesresolvers.mytlschallenge.acme.httpchallenge=true"
  - "--certificatesresolvers.mytlschallenge.acme.httpchallenge.entrypoint=web"
  ```
- Make sure port 80 is accessible from the internet
- Don't redirect HTTP to HTTPS until the certificate is generated

### 3. Traefik Version Compatibility

- The latest Traefik versions (v3.x) may have syntax differences
- Stick to well-tested versions like v2.10.4 or v3.0 for stability
- Check the Traefik documentation for your specific version

### 4. Password Escaping in Docker Compose

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