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
base_PATH=$(pwd)
TRAEFIK_PATH="$base_PATH/traefik"
WORDPRESS_PATH="$base_PATH/wordpress"
N8N_PATH="$base_PATH/n8n"

# Function to display container status with colors
show_container_status() {
    local filter_pattern="$1"
    local title="$2"
    
    echo -e "${BLUE}$title${NC}"
    
    # Get all containers first
    local all_containers
    all_containers=$(docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}")
    
    # Filter containers (with error handling)
    local containers
    containers=$(echo "$all_containers" | grep -E "$filter_pattern" 2>/dev/null || true)
    
    if [ -n "$containers" ]; then
        # Count lines to see if we have more than just header
        local line_count
        line_count=$(echo "$containers" | wc -l)
        
        if [ "$line_count" -gt 1 ]; then
            # Show header if it exists
            if echo "$containers" | head -1 | grep -q "NAMES"; then
                echo "$containers" | head -1
                # Process data lines with colors
                echo "$containers" | tail -n +2 | while read -r line; do
                    if [ -n "$line" ]; then
                        if echo "$line" | grep -q "Up"; then
                            echo -e "${GREEN}$line${NC}"
                        elif echo "$line" | grep -q "Exited"; then
                            echo -e "${RED}$line${NC}"
                        else
                            echo -e "${YELLOW}$line${NC}"
                        fi
                    fi
                done
            else
                # No header, just show the containers
                echo "$containers" | while read -r line; do
                    if [ -n "$line" ]; then
                        if echo "$line" | grep -q "Up"; then
                            echo -e "${GREEN}$line${NC}"
                        elif echo "$line" | grep -q "Exited"; then
                            echo -e "${RED}$line${NC}"
                        else
                            echo -e "${YELLOW}$line${NC}"
                        fi
                    fi
                done
            fi
        else
            echo -e "${YELLOW}No containers found${NC}"
        fi
    else
        echo -e "${YELLOW}No containers found${NC}"
    fi
    echo ""
}

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
            docker compose --env-file "../.env" up -d traefik error-page
            ;;
        "wordpress")
            echo -e "${GREEN}🐳 Starting WordPress stack...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose --env-file "../.env" up -d wordpress db
            ;;
        "n8n")
            echo -e "${GREEN}🤖 Starting n8n...${NC}"
            cd "$N8N_PATH"
            if [ -f "docker-compose.yml" ]; then
                docker compose --env-file "../.env" up -d n8n postgres
            else
                echo -e "${YELLOW}⚠️  n8n configuration not found${NC}"
            fi
            ;;
        "phpmyadmin")
            echo -e "${GREEN}🗃️  Starting phpMyAdmin...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose --env-file "../.env" up -d phpmyadmin
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
            docker compose --env-file "../.env" down traefik error-page
            ;;
        "wordpress")
            echo -e "${YELLOW}🛑 Stopping WordPress stack...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose --env-file "../.env" down
            ;;
        "n8n")
            echo -e "${YELLOW}🛑 Stopping n8n...${NC}"
            cd "$N8N_PATH"
            if [ -f "docker-compose.yml" ]; then
                docker compose --env-file "../.env" down n8n postgres
            else
                echo -e "${YELLOW}⚠️  n8n configuration not found${NC}"
            fi
            ;;
        "phpmyadmin")
            echo -e "${YELLOW}🛑 Stopping phpMyAdmin...${NC}"
            cd "$WORDPRESS_PATH"
            docker compose --env-file "../.env" stop phpmyadmin
            docker compose --env-file "../.env" rm -f phpmyadmin
            ;;
        "all")
            echo -e "${YELLOW}🛑 Stopping all services...${NC}"
            stop_service "n8n"
            stop_service "wordpress"  
            stop_service "traefik"
            stop_service "phpmyadmin"
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
            show_container_status "(traefik|Names)" "📡 Traefik Status:"
            ;;
        "wordpress")
            show_container_status "(wordpress|mysql|Names)" "🐳 WordPress Stack Status:"
            ;;
        "n8n")
            show_container_status "(n8n|postgres|Names)" "🤖 n8n Stack Status:"
            ;;
        "phpmyadmin")
            show_container_status "(phpmyadmin|Names)" "🗃️  phpMyAdmin Status:"
            ;;
        "all")
            show_container_status "(traefik|wordpress|mysql|phpmyadmin|n8n|postgres|Names)" "📊 All Services Status:"
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