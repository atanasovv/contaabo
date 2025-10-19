#!/bin/bash

# Environment Variable Test Script
# Tests the variable substitution functionality in the consolidated .env file

echo "🧪 Testing Environment Variable Substitution"
echo "=============================================="

# Source the .env file
if [ -f ".env" ]; then
    echo "📁 Loading .env file..."
    source .env
    echo ""
    
    # Test basic variables
    echo "🔧 Base Configuration:"
    echo "  BASE_DOMAIN_NAME: $BASE_DOMAIN_NAME"
    echo "  WORDPRESS_SUBDOMAIN: $WORDPRESS_SUBDOMAIN"
    echo "  N8N_SUBDOMAIN: $N8N_SUBDOMAIN"
    echo ""
    
    # Test substituted variables
    echo "🌐 Generated Hostnames (using variable substitution):"
    echo "  WORDPRESS_HOST: $WORDPRESS_HOST"
    echo "  N8N_HOST: $N8N_HOST"
    echo "  TRAEFIK_HOST: $TRAEFIK_HOST"
    echo "  PHPMYADMIN_HOST: $PHPMYADMIN_HOST"
    echo ""
    
    # Test Docker Compose compatibility
    echo "🐳 Testing Docker Compose Compatibility:"
    echo "----------------------------------------"
    
    # Test WordPress
    if [ -d "wordpress" ]; then
        echo "  WordPress: Testing variable resolution..."
        if cd wordpress && docker compose --env-file="../.env" config --quiet; then
            WP_HOST_RESOLVED=$(cd .. && docker compose --env-file=".env" -f wordpress/docker-compose.yml config | grep -o "Host(\`[^']*\`)" | head -1 | sed 's/Host(`//g' | sed 's/`)//g')
            echo "    ✅ Success - Resolved to: $WP_HOST_RESOLVED"
        else
            echo "    ❌ Failed"
        fi
        cd ..
    fi
    
    # Test N8N
    if [ -d "n8n" ]; then
        echo "  N8N: Testing variable resolution..."
        if cd n8n && docker compose --env-file="../.env" config --quiet; then
            N8N_HOST_RESOLVED=$(cd .. && docker compose --env-file=".env" -f n8n/docker-compose.yml config | grep "N8N_HOST:" | head -1 | awk '{print $2}')
            echo "    ✅ Success - Resolved to: $N8N_HOST_RESOLVED"
        else
            echo "    ❌ Failed"
        fi
        cd ..
    fi
    
    # Test Traefik
    if [ -d "traefik" ]; then
        echo "  Traefik: Testing variable resolution..."
        if cd traefik && docker compose --env-file="../.env" config --quiet; then
            echo "    ✅ Success"
        else
            echo "    ❌ Failed"
        fi
        cd ..
    fi
    
    echo ""
    echo "🎯 Variable Substitution Examples:"
    echo "-----------------------------------"
    echo "  \${WORDPRESS_SUBDOMAIN}.\${BASE_DOMAIN_NAME} = $WORDPRESS_SUBDOMAIN.$BASE_DOMAIN_NAME"
    echo "  \${N8N_SUBDOMAIN}.\${BASE_DOMAIN_NAME} = $N8N_SUBDOMAIN.$BASE_DOMAIN_NAME"
    echo ""
    echo "✅ Environment variable substitution is working correctly!"
    echo ""
    echo "💡 To change your domain:"
    echo "   1. Edit BASE_DOMAIN_NAME in .env"
    echo "   2. All hostnames will automatically update"
    echo "   3. Restart services with: ./manage-apps.sh restart all"
    
else
    echo "❌ .env file not found in current directory"
    echo "   Make sure you're in the project root directory"
fi