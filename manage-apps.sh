#!/bin/bash
# Application management script for the project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
TRAEFIK_PATH="/mnt/data2/AI-Projects/contaabo/n8n"
WORDPRESS_PATH="/mnt/data2/AI-Projects/contaabo/Wordpress"
N8N_PATH="/mnt/data2/AI-Projects/contaabo/n8n"

# Function to show usage
show_usage() {
    echo -e "${BLUE}📋 Application Management Script${NC}"
    echo ""
    echo "Usage: $0 {start|stop|restart|status} {all|traefik|wordpress|n8n|phpmyadmin}"
    echo ""
    echo "Commands:"
    echo "  start    - Start services"
    echo "  stop     - Stop services"
    echo "  restart  - Restart services"
    echo "  status   - Show status of services"
    echo ""
    echo "Services:"
    echo "  all         - All services"
    echo "  traefik     - Traefik reverse proxy"
    echo "  wordpress   - WordPress + MySQL + phpMyAdmin"
    echo "  n8n         - n8n automation (if configured)"
    echo "  phpmyadmin  - phpMyAdmin only"
    echo ""
    echo "Examples:"
    echo "  $0 start all"
    echo "  $0 stop wordpress"
    echo "  $0 restart traefik"
    echo "  $0 status all"
}

# Function to start services
start_service() {
    case $1 in
        "traefik")
            echo -e "${GREEN}📡 Starting Traefik...${NC}"
            cd "$TRAEFIK_PATH"
            docker compose up -d traefik
            ;;
        "wordpress")
            echo -e "${GREEN}🐳 Starting WordPress stack...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose up -d
            ;;
        "n8n")
            echo -e "${GREEN}🤖 Starting n8n...${NC}"
            cd "$N8N_PATH"
            if [ -f "docker-compose.yml" ]; then
                docker compose up -d n8n
            else
                echo -e "${YELLOW}⚠️  n8n configuration not found${NC}"
            fi
            ;;
        "phpmyadmin")
            echo -e "${GREEN}🗃️  Starting phpMyAdmin...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose up -d phpmyadmin
            ;;
        "all")
            echo -e "${GREEN}🚀 Starting all services...${NC}"
            start_service "traefik"
            start_service "wordpress"
            start_service "n8n"
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Function to stop services
stop_service() {
    case $1 in
        "traefik")
            echo -e "${YELLOW}🛑 Stopping Traefik...${NC}"
            cd "$TRAEFIK_PATH"
            docker compose down traefik
            ;;
        "wordpress")
            echo -e "${YELLOW}🛑 Stopping WordPress stack...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose down
            ;;
        "n8n")
            echo -e "${YELLOW}🛑 Stopping n8n...${NC}"
            cd "$N8N_PATH"
            if [ -f "docker-compose.yml" ]; then
                docker compose down n8n
            else
                echo -e "${YELLOW}⚠️  n8n configuration not found${NC}"
            fi
            ;;
        "phpmyadmin")
            echo -e "${YELLOW}🛑 Stopping phpMyAdmin...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose stop phpmyadmin
            docker compose rm -f phpmyadmin
            ;;
        "all")
            echo -e "${YELLOW}🛑 Stopping all services...${NC}"
            stop_service "n8n"
            stop_service "wordpress"  
            stop_service "traefik"
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Function to restart services
restart_service() {
    echo -e "${BLUE}🔄 Restarting $1...${NC}"
    stop_service "$1"
    sleep 2
    start_service "$1"
}

# Function to show status
show_status() {
    case $1 in
        "traefik")
            echo -e "${BLUE}📡 Traefik Status:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(traefik|Names)" || echo "Traefik not running"
            ;;
        "wordpress")
            echo -e "${BLUE}🐳 WordPress Stack Status:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(wordpress|mysql|phpmyadmin|Names)" || echo "WordPress stack not running"
            ;;
        "n8n")
            echo -e "${BLUE}🤖 n8n Status:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(n8n|Names)" || echo "n8n not running"
            ;;
        "phpmyadmin")
            echo -e "${BLUE}🗃️  phpMyAdmin Status:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(phpmyadmin|Names)" || echo "phpMyAdmin not running"
            ;;
        "all")
            echo -e "${BLUE}📊 All Services Status:${NC}"
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(traefik|wordpress|mysql|phpmyadmin|n8n|Names)" || echo "No services running"
            echo ""
            # Show Tailscale status if available
            if command -v tailscale &> /dev/null; then
                echo -e "${BLUE}🔗 Tailscale Status:${NC}"
                if tailscale status &> /dev/null; then
                    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "N/A")
                    echo -e "${GREEN}✅ Connected - IP: $TAILSCALE_IP${NC}"
                else
                    echo -e "${YELLOW}⚠️  Not authenticated${NC}"
                fi
            fi
            ;;
        *)
            echo -e "${RED}❌ Unknown service: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
}

# Check arguments
if [ $# -ne 2 ]; then
    show_usage
    exit 1
fi

COMMAND=$1
SERVICE=$2

# Execute command
case $COMMAND in
    "start")
        start_service "$SERVICE"
        echo -e "${GREEN}✅ Start command completed${NC}"
        ;;
    "stop")
        stop_service "$SERVICE"
        echo -e "${GREEN}✅ Stop command completed${NC}"
        ;;
    "restart")
        restart_service "$SERVICE"
        echo -e "${GREEN}✅ Restart command completed${NC}"
        ;;
    "status")
        show_status "$SERVICE"
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
        show_usage
        exit 1
        ;;
esac