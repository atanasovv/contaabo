# Traefik Docker Compose - Usage Guide

## Understanding the Dollar Sign Escaping Issue

When using basic authentication with Traefik in Docker Compose, you'll encounter an issue with dollar signs (`$`) in password hashes. This is because Docker Compose treats `$` as variable substitution markers.

### The Problem:
- A typical htpasswd output looks like: `admin:$apr1$rO5oPdXm$UzGzM7rVzNDrbF3kGt2JY/`
- Docker Compose interprets `$apr1`, `$rO5oPdXm`, etc. as environment variables
- This causes "variable not set" warnings and authentication failure

### The Solution:
- **Escape each `$` with another `$`** in your .env file
- Example: `admin:$$apr1$$rO5oPdXm$$UzGzM7rVzNDrbF3kGt2JY/`

## Setup Instructions

1. Generate proper credentials using the provided script:
   ```bash
   ./setup-traefik-auth.sh
   ```
   This script will:
   - Generate a secure password hash using htpasswd
   - Properly escape dollar signs for Docker Compose
   - Update your .env file with the escaped credentials
   - Configure IP whitelisting for admin access

2. Start Traefik:
   ```bash
   docker compose -f treafik.docker-compose.yml up -d
   ```

## Manual Setup (if needed)

If you prefer to set up manually:

1. Generate a password hash:
   ```bash
   htpasswd -nb admin yourpassword
   ```

2. Escape each `$` by doubling it:
   ```
   # Original: admin:$apr1$rO5oPdXm$UzGzM7rVzNDrbF3kGt2JY/
   # Escaped:  admin:$$apr1$$rO5oPdXm$$UzGzM7rVzNDrbF3kGt2JY/
   ```

3. Add this to your .env file:
   ```
   TRAEFIK_BASIC_AUTH=admin:$$apr1$$rO5oPdXm$$UzGzM7rVzNDrbF3kGt2JY/
   ```

## Troubleshooting

If you see warnings like:
```
WARN[0000] The "apr1" variable is not set. Defaulting to a blank string.
```

It means the dollar signs in your password hash aren't properly escaped in the .env file.

## Security Recommendations

- Use a complex password (the setup script will help you create one)
- Restrict dashboard access to specific IP addresses
- Keep your Traefik installation updated
- Review logs regularly for unauthorized access attempts