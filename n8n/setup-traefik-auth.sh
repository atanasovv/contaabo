#!/bin/bash

# Script to generate secure password for Traefik basic authentication
# and update the .env file

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if htpasswd is installed
if ! command -v htpasswd &> /dev/null; then
    echo -e "${YELLOW}The htpasswd command is not installed. Installing apache2-utils...${NC}"
    sudo apt-get update
    sudo apt-get install -y apache2-utils
    if [ $? -ne 0 ]; then
        echo "Failed to install apache2-utils. Please install it manually."
        exit 1
    fi
fi

# Check if .env file exists, if not, create it from template
if [ ! -f .env ]; then
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}Created .env file from .env.example${NC}"
    else
        echo "No .env.example file found. Please create a .env file manually."
        exit 1
    fi
fi

echo -e "${YELLOW}This script will set up a secure password for your Traefik dashboard.${NC}"

# Ask for username (default: admin)
read -p "Enter username for Traefik dashboard [admin]: " username
username=${username:-admin}

# Ask for password
read -s -p "Enter password for $username: " password
echo
read -s -p "Confirm password: " password2
echo

# Check if passwords match
if [ "$password" != "$password2" ]; then
    echo "Passwords do not match. Please try again."
    exit 1
fi

# Generate password hash
hashed_auth=$(htpasswd -nb "$username" "$password")

# Ask for admin IP range
read -p "Enter your admin IP range for whitelist access [current IP only]: " ip_range

# If no IP range is provided, use the current public IP
if [ -z "$ip_range" ]; then
    echo "Getting your current public IP..."
    ip_range=$(curl -s https://api.ipify.org)
    if [ -z "$ip_range" ]; then
        echo "Failed to get your public IP. Using 127.0.0.1 (localhost only)."
        ip_range="127.0.0.1"
    fi
    ip_range="${ip_range}/32"
fi

# Update the .env file
if grep -q "TRAEFIK_BASIC_AUTH=" .env; then
    sed -i "s|TRAEFIK_BASIC_AUTH=.*|TRAEFIK_BASIC_AUTH=${hashed_auth}|" .env
else
    echo "TRAEFIK_BASIC_AUTH=${hashed_auth}" >> .env
fi

if grep -q "ADMIN_IP_RANGE=" .env; then
    sed -i "s|ADMIN_IP_RANGE=.*|ADMIN_IP_RANGE=${ip_range}|" .env
else
    echo "ADMIN_IP_RANGE=${ip_range}" >> .env
fi

echo -e "${GREEN}Authentication credentials updated successfully!${NC}"
echo -e "${GREEN}Admin access restricted to IP range: ${ip_range}${NC}"
echo -e "${YELLOW}You can now start Traefik with:${NC}"
echo -e "  docker compose -f treafik.docker-compose.yml up -d"