# N8N Docker Setup with Traefik

This setup provides a production-ready N8N installation with:
- **Traefik** reverse proxy with automatic SSL certificates
- **PostgreSQL** database for data persistence  
- **N8N** workflow automation platform
- **Security headers** and HTTPS enforcement

## 🚀 Quick Start

### 1. Create Environment Configuration
```bash
# Copy example file
cp .env.example .env

# Edit with your settings
nano .env
```

### 2. Run Setup Script (Recommended)
```bash
# Interactive setup with guided configuration
./setup-n8n.sh
```

### 3. Manual Setup (Alternative)
```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps
```

## 📋 Configuration Options

### Required Settings
```bash
# Your domain configuration
DOMAIN_NAME=your-domain.com
SUBDOMAIN=n8n                    # Creates: n8n.your-domain.com
SSL_EMAIL=admin@your-domain.com

# Database credentials (use strong passwords!)
POSTGRES_PASSWORD=your-secure-password
POSTGRES_NON_ROOT_PASSWORD=another-secure-password
```

### Optional Settings
```bash
# Timezone for scheduling
GENERIC_TIMEZONE=Europe/Sofia

# N8N Basic Authentication (recommended for public deployments)
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=secure-admin-password

# Encryption key for sensitive data (generate randomly)
N8N_ENCRYPTION_KEY=your-32-character-encryption-key
```

## 🔐 Security Features

### SSL/TLS
- **Automatic SSL** certificates via Let's Encrypt
- **HTTP to HTTPS** redirect
- **Modern TLS** configuration

### Security Headers
- **HSTS** (HTTP Strict Transport Security)
- **XSS Protection**
- **Content Type Sniffing** protection
- **SSL Redirect** enforcement

### Database Security
- **Non-root user** for N8N application
- **Password-protected** PostgreSQL
- **Network isolation** between services

## 🌐 Service Access

After successful deployment:

- **N8N Interface**: `https://n8n.your-domain.com`
- **Traefik Dashboard**: `http://your-server-ip:8090`
- **PostgreSQL**: `localhost:5432` (if needed for backups)

## 📁 Directory Structure

```
n8n/
├── .env                 # Your configuration (create from .env.example)
├── .env.example         # Configuration template
├── docker-compose.yml   # Service definitions
├── setup-n8n.sh        # Interactive setup script
├── local-files/         # N8N local file storage
├── init-data.sh/        # PostgreSQL initialization (empty directory)
└── README.md           # This file
```

## 🔧 Management Commands

### Service Management
```bash
# Start all services
docker-compose up -d

# Stop all services
docker-compose down

# Restart specific service
docker-compose restart n8n

# View service status
docker-compose ps
```

### Logs and Monitoring
```bash
# View all logs
docker-compose logs

# Follow logs for specific service
docker-compose logs -f n8n
docker-compose logs -f postgres
docker-compose logs -f traefik

# View last 50 lines
docker-compose logs --tail=50
```

### Database Management
```bash
# Access PostgreSQL shell
docker-compose exec postgres psql -U n8n_root -d n8n

# Create database backup
docker-compose exec postgres pg_dump -U n8n_user n8n > n8n_backup_$(date +%Y%m%d).sql

# Restore from backup
docker-compose exec -T postgres psql -U n8n_user n8n < n8n_backup.sql
```

## 🔄 Updates and Maintenance

### Update N8N
```bash
# Pull latest image
docker-compose pull n8n

# Restart with new image
docker-compose up -d n8n
```

### Backup Data
```bash
# Backup N8N data volume
docker run --rm -v n8n_n8n_data:/data -v $(pwd):/backup alpine tar czf /backup/n8n_data_backup.tar.gz /data

# Backup PostgreSQL database
docker-compose exec postgres pg_dump -U n8n_user n8n | gzip > n8n_db_backup_$(date +%Y%m%d).sql.gz
```

### SSL Certificate Management
SSL certificates are automatically managed by Traefik and Let's Encrypt:
- **Auto-renewal**: Certificates are renewed automatically
- **Storage**: Certificates stored in `traefik_data` volume
- **Logs**: Check Traefik logs for certificate issues

## 🚨 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check which process is using port 80/443
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443

# Stop conflicting services
sudo systemctl stop apache2  # or nginx
```

#### SSL Certificate Issues
```bash
# Check Traefik logs
docker-compose logs traefik

# Verify DNS resolution
nslookup n8n.your-domain.com

# Test port accessibility
curl -I http://your-domain.com
```

#### Database Connection Issues
```bash
# Check PostgreSQL logs
docker-compose logs postgres

# Test database connection
docker-compose exec postgres pg_isready -U n8n_user -d n8n

# Reset database (WARNING: destroys data)
docker-compose down -v
docker-compose up -d
```

#### N8N Access Issues
```bash
# Check N8N logs
docker-compose logs n8n

# Verify environment variables
docker-compose exec n8n env | grep N8N

# Test internal connectivity
docker-compose exec n8n curl -I http://localhost:5678
```

### Reset Everything
```bash
# WARNING: This destroys all data!
docker-compose down -v
docker system prune -f
# Then recreate with: docker-compose up -d
```

## 🔒 Production Deployment Tips

### Security Enhancements
1. **Enable N8N Basic Auth** for additional protection
2. **Use Docker secrets** instead of environment variables
3. **Remove PostgreSQL port exposure** (`5432:5432` line)
4. **Enable fail2ban** for brute force protection
5. **Use Cloudflare** or similar for DDoS protection

### Performance Optimization
1. **Resource limits**: Set memory/CPU limits for containers
2. **SSD storage**: Use SSD for database storage
3. **Monitoring**: Add Prometheus/Grafana monitoring
4. **Log rotation**: Configure log rotation for containers

### Backup Strategy
1. **Automated backups**: Set up daily database backups
2. **Off-site storage**: Store backups remotely (S3, etc.)
3. **Restore testing**: Regularly test backup restoration
4. **Disaster recovery**: Document recovery procedures

## 📞 Support

For issues and questions:
- **N8N Documentation**: https://docs.n8n.io/
- **Traefik Documentation**: https://doc.traefik.io/traefik/
- **Docker Compose**: https://docs.docker.com/compose/

## 🏷️ Version Information

- **N8N**: Latest (automatically updated)
- **PostgreSQL**: 16
- **Traefik**: Latest
- **Compose Version**: 3.8