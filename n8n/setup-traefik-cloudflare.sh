#!/bin/bash

# Script to build and deploy Traefik with Cloudflare Real IP plugin
# This script helps rebuild and update Traefik when behind Cloudflare

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Traefik Cloudflare Integration Setup${NC}"
echo "This script will help you build and deploy Traefik with Cloudflare Real IP plugin"

# Check if docker and docker compose are installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Update Cloudflare IP ranges (optional)
update_cf_ips() {
    echo -e "${BLUE}Updating Cloudflare IP ranges...${NC}"
    
    # Create a backup of the current file
    if [ -f "traefik_dynamic_conf/cloudflare-plugin.yaml" ]; then
        cp traefik_dynamic_conf/cloudflare-plugin.yaml traefik_dynamic_conf/cloudflare-plugin.yaml.bak
    fi
    
    # Fetch IPv4 ranges
    IPV4_RANGES=$(curl -s https://www.cloudflare.com/ips-v4)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to fetch Cloudflare IPv4 ranges.${NC}"
        return 1
    fi
    
    # Fetch IPv6 ranges
    IPV6_RANGES=$(curl -s https://www.cloudflare.com/ips-v6)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to fetch Cloudflare IPv6 ranges.${NC}"
        return 1
    fi
    
    # Create the new configuration file with updated IP ranges
    cat > traefik_dynamic_conf/cloudflare-plugin.yaml << EOF
#### YAML Reference for Traefik Cloudflare Real IP Plugin
# This file configures the Cloudflare Real IP plugin for Traefik
# The plugin allows Traefik to extract real client IPs when behind Cloudflare
# Updated on: $(date)

http:
  middlewares:
    cloudflare-real-ip:
      plugin:
        traefik-cloudflare-real-ip:
          # List of known Cloudflare IP address ranges
          # Updated automatically from https://www.cloudflare.com/ips/
          ipRanges:
EOF

    # Add IPv4 ranges
    while IFS= read -r line; do
        echo "            - \"$line\"" >> traefik_dynamic_conf/cloudflare-plugin.yaml
    done <<< "$IPV4_RANGES"
    
    # Add IPv6 ranges
    while IFS= read -r line; do
        echo "            - \"$line\"" >> traefik_dynamic_conf/cloudflare-plugin.yaml
    done <<< "$IPV6_RANGES"
    
    echo -e "${GREEN}Cloudflare IP ranges updated successfully.${NC}"
    return 0
}

# Build and deploy Traefik
build_and_deploy() {
    echo -e "${BLUE}Building and deploying Traefik with Cloudflare plugin...${NC}"
    
    # Stop the existing Traefik container
    docker compose -f treafik.docker-compose.yml down
    
    # Build the custom Traefik image
    docker compose -f treafik.docker-compose.yml build
    
    # Start Traefik with the new configuration
    docker compose -f treafik.docker-compose.yml up -d
    
    # Check if Traefik started successfully
    if docker ps | grep -q traefik; then
        echo -e "${GREEN}Traefik with Cloudflare plugin deployed successfully!${NC}"
    else
        echo -e "${RED}Failed to deploy Traefik. Check the logs with: docker logs traefik${NC}"
        return 1
    fi
    
    return 0
}

# Menu
echo -e "${YELLOW}Choose an option:${NC}"
echo "1) Update Cloudflare IP ranges and deploy Traefik"
echo "2) Deploy Traefik without updating IP ranges"
echo "3) Only update Cloudflare IP ranges"
echo "4) Exit"

read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        update_cf_ips && build_and_deploy
        ;;
    2)
        build_and_deploy
        ;;
    3)
        update_cf_ips
        ;;
    4)
        echo -e "${BLUE}Exiting without changes.${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid choice. Exiting.${NC}"
        exit 1
        ;;
esac

echo -e "${YELLOW}Additional steps:${NC}"
echo "1. Verify Traefik is working correctly: docker logs traefik"
echo "2. Check that your dashboard is accessible at https://${TRAEFIK_DASHBOARD_HOST:-traefik.example.com}"
echo "3. For more information, refer to TRAEFIK-CLOUDFLARE.md"