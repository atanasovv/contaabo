#!/bin/bash
# Tailscale installation script

set -e

echo "� Installing and configuring Tailscale..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Tailscale is installed
if ! command -v tailscale &> /dev/null; then
    echo -e "${YELLOW}Tailscale not found. Installing...${NC}"
    curl -fsSL https://tailscale.com/install.sh | sh
    echo -e "${GREEN}Tailscale installed successfully!${NC}"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Authenticate Tailscale: ${GREEN}sudo tailscale up --hostname=coach-bg-server${NC}"
    echo "2. Use the app management script to start services"
    echo ""
    exit 0
fi

# Check if Tailscale is authenticated
if ! sudo tailscale status &> /dev/null; then
    echo -e "${YELLOW}Tailscale is installed but not authenticated.${NC}"
    echo "Please run: ${GREEN}sudo tailscale up --hostname=coach-bg-server${NC}"
    echo ""
    exit 1
fi

# Get Tailscale IP
TAILSCALE_IP=$(tailscale ip -4)
echo -e "${GREEN}✅ Tailscale is ready!${NC}"
echo -e "${GREEN}Tailscale IP: ${TAILSCALE_IP}${NC}"
echo ""
echo "🔗 Add this to your hosts file:"
echo "-------------------------------------------"
echo "${TAILSCALE_IP}  wordpress.coach-bg.com"
echo "${TAILSCALE_IP}  phpmyadmin.internal.coach-bg.com"
echo "${TAILSCALE_IP}  traefik.internal.coach-bg.com"
echo ""
echo "📝 Hosts file location:"
echo "   • Windows: C:\\Windows\\System32\\drivers\\etc\\hosts"
echo "   • Mac/Linux: /etc/hosts"
echo ""
echo -e "${GREEN}🔒 Tailscale VPN is configured and ready!${NC}"