#!/bin/bash

# Script to help troubleshoot and fix Let's Encrypt certificate issues with Traefik
# This script will guide you through common steps to resolve certificate challenges

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Traefik Let's Encrypt Certificate Troubleshooter${NC}"
echo "This script will help diagnose and fix certificate issues."

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo -e "${RED}The curl command is not installed. Installing curl...${NC}"
    sudo apt-get update
    sudo apt-get install -y curl
    if [ $? -ne 0 ]; then
        echo "Failed to install curl. Please install it manually."
        exit 1
    fi
fi

# Check if docker is running
if ! docker ps &> /dev/null; then
    echo -e "${RED}Docker is not running or you don't have permissions.${NC}"
    echo "Please make sure Docker is running and you have the proper permissions."
    exit 1
fi

# Check if traefik container exists
if ! docker ps | grep traefik &> /dev/null; then
    echo -e "${RED}Traefik container is not running.${NC}"
    echo "Would you like to start it now? (y/n)"
    read -r answer
    if [[ "$answer" == "y" ]]; then
        docker compose -f treafik.docker-compose.yml up -d
    else
        echo "Please start the Traefik container manually."
        exit 1
    fi
fi

# Get domain information from .env file
if [ -f .env ]; then
    source .env
else
    echo -e "${YELLOW}No .env file found. Please enter your domain information:${NC}"
    read -p "Enter your domain name (e.g., example.com): " DOMAIN_NAME
    read -p "Enter your Traefik dashboard subdomain (e.g., traefik): " TRAEFIK_DASHBOARD_HOST
    TRAEFIK_DASHBOARD_HOST="${TRAEFIK_DASHBOARD_HOST:-traefik}.${DOMAIN_NAME}"
fi

DOMAIN=${TRAEFIK_DASHBOARD_HOST:-traefik.${DOMAIN_NAME}}

echo -e "${BLUE}Checking connectivity to ${DOMAIN}...${NC}"
if host ${DOMAIN} &> /dev/null; then
    echo -e "${GREEN}DNS resolution for ${DOMAIN} is working.${NC}"
else
    echo -e "${RED}Cannot resolve ${DOMAIN}.${NC}"
    echo "Please make sure your DNS settings are correct and pointing to this server's IP."
    read -p "Enter your server's public IP address: " SERVER_IP
    echo -e "${YELLOW}Make sure ${DOMAIN} points to ${SERVER_IP}${NC}"
    echo "Would you like to continue anyway? (y/n)"
    read -r answer
    if [[ "$answer" != "y" ]]; then
        exit 1
    fi
fi

echo -e "${BLUE}Checking if port 80 is accessible...${NC}"
curl -s -o /dev/null -w "%{http_code}" http://${DOMAIN} > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Port 80 is accessible from this machine.${NC}"
else
    echo -e "${RED}Port 80 is not accessible.${NC}"
    echo "Please check your firewall settings and make sure port 80 is open."
    echo "This port is required for Let's Encrypt HTTP challenge."
fi

echo -e "${BLUE}Checking Traefik configuration...${NC}"
docker exec -it traefik cat /etc/traefik/dynamic_conf/middlewares.yaml &> /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Dynamic configuration files are accessible.${NC}"
else
    echo -e "${RED}Cannot access dynamic configuration files.${NC}"
    echo "Please check your volume mounts and file permissions."
fi

echo -e "${YELLOW}Would you like to reset Traefik's ACME data and try again? (y/n)${NC}"
read -r answer
if [[ "$answer" == "y" ]]; then
    echo -e "${BLUE}Stopping Traefik...${NC}"
    docker compose -f treafik.docker-compose.yml down

    echo -e "${BLUE}Removing ACME data...${NC}"
    docker volume rm traefik_data
    
    # Update the Docker Compose file to disable HTTP to HTTPS redirection temporarily
    sed -i 's/^.*--entrypoints.web.http.redirections.entryPoint.to=websecure.*$/      # Temporarily disabled for certificate setup\n      # - "--entrypoints.web.http.redirections.entryPoint.to=websecure"/' treafik.docker-compose.yml
    sed -i 's/^.*--entrypoints.web.http.redirections.entrypoint.scheme=https.*$/      # Temporarily disabled for certificate setup\n      # - "--entrypoints.web.http.redirections.entrypoint.scheme=https"/' treafik.docker-compose.yml
    
    echo -e "${BLUE}Starting Traefik with clean state...${NC}"
    docker compose -f treafik.docker-compose.yml up -d
    
    echo -e "${YELLOW}Waiting for 30 seconds to allow certificate generation...${NC}"
    sleep 30
    
    echo -e "${BLUE}Checking certificate status...${NC}"
    docker logs traefik | grep "Certificates obtained"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Certificates have been obtained successfully!${NC}"
        
        # Re-enable HTTP to HTTPS redirection
        sed -i 's/^.*# Temporarily disabled for certificate setup.*$//' treafik.docker-compose.yml
        sed -i 's/^.*# - "--entrypoints.web.http.redirections.entryPoint.to=websecure".*$/      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"/' treafik.docker-compose.yml
        sed -i 's/^.*# - "--entrypoints.web.http.redirections.entrypoint.scheme=https".*$/      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"/' treafik.docker-compose.yml
        
        echo -e "${BLUE}Re-enabling HTTP to HTTPS redirection...${NC}"
        docker compose -f treafik.docker-compose.yml up -d
    else
        echo -e "${RED}Certificates could not be obtained.${NC}"
        echo "Please check the Traefik logs for more information:"
        echo "docker logs traefik"
    fi
else
    echo -e "${BLUE}No changes made to Traefik configuration.${NC}"
fi

echo -e "${YELLOW}Troubleshooting tips:${NC}"
echo "1. Make sure your domain is pointing to this server's public IP"
echo "2. Check that ports 80 and 443 are open on your firewall"
echo "3. Temporarily disable HTTP to HTTPS redirection while getting certificates"
echo "4. Check if your domain has CAA records that might block Let's Encrypt"
echo "5. Verify that your server can be accessed from the internet"
echo ""
echo -e "${GREEN}For more detailed help, check the TRAEFIK-TROUBLESHOOTING.md file${NC}"