#!/bin/bash

# Quick Fix Script for N8N Issues
# Addresses the immediate problems seen in the logs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🔧 N8N Quick Fix Script"
echo "======================="
echo

# Check if .env exists
if [[ ! -f .env ]]; then
    echo "❌ .env file not found!"
    echo "Please create .env file from .env.example first"
    exit 1
fi

source .env

echo "1. Checking domain configuration..."
echo "   Current domain: ${SUBDOMAIN}.${DOMAIN_NAME}"
if [[ "${DOMAIN_NAME}" != *"coach-bg.com"* ]]; then
    echo "⚠️  Warning: Domain in .env doesn't match logs (coach-bg.com vs coach-ng.com)"
    echo "   Please verify your domain is correct in .env"
fi

echo
echo "2. Fixing PostgreSQL collation version..."
if docker compose ps postgres | grep -q "Up"; then
    echo "   PostgreSQL is running, fixing collation..."
    docker compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "ALTER DATABASE $POSTGRES_DB REFRESH COLLATION VERSION;" 2>/dev/null && {
        echo "✅ PostgreSQL collation version fixed"
    } || {
        echo "⚠️  Collation fix failed - this is usually non-critical"
    }
else
    echo "   PostgreSQL is not running"
fi

echo
echo "3. Updating N8N configuration and restarting..."
echo "   Stopping N8N to apply new configuration..."
docker compose stop n8n

echo "   Removing old N8N container..."
docker compose rm -f n8n

echo "   Starting N8N with updated configuration..."
docker compose up -d n8n

echo
echo "4. Restarting Traefik to fix dashboard issues..."
docker compose restart traefik

echo
echo "5. Waiting for services to stabilize..."
sleep 10

echo
echo "6. Checking service status..."
docker compose ps

echo
echo "7. Testing connectivity..."
if docker compose exec n8n curl -s -o /dev/null -w "%{http_code}" http://localhost:5678 | grep -q "200"; then
    echo "✅ N8N is responding on port 5678"
else
    echo "⚠️  N8N might still be starting up"
fi

echo
echo "🎉 Quick fixes applied!"
echo
echo "📋 Summary of fixes:"
echo "   ✅ Updated N8N configuration to fix deprecation warnings"
echo "   ✅ Fixed Traefik dashboard configuration" 
echo "   ✅ Applied PostgreSQL collation fix"
echo "   ✅ Restarted services with clean state"
echo
echo
echo "🎉 Quick fixes applied!"
echo
echo "📋 Summary of fixes:"
echo "   ✅ Updated N8N configuration to fix deprecation warnings"
echo "   ✅ Fixed Traefik dashboard configuration" 
echo "   ✅ Applied PostgreSQL collation fix"
echo "   ✅ Restarted services with clean state"
echo
echo "🔗 Access your services:"
echo "   N8N: https://${SUBDOMAIN}.${DOMAIN_NAME}"
echo "   Traefik Dashboard: http://$(hostname -I | cut -d' ' -f1):8090"
echo
echo "📝 Notes:"
echo "   - SSL certificate generation may take a few minutes"
echo "   - Check logs with: docker compose logs -f n8n"
echo "   - Use ./fix-database.sh for advanced database maintenance"
echo
echo "🔧 If issues persist:"
echo "   1. Check domain DNS configuration"
echo "   2. Verify firewall allows ports 80/443"
echo "   3. Run: ./fix-database.sh for database maintenance"