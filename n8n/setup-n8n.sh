#!/bin/bash

# N8N Setup Script
# Helps with initial configuration and environment setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to generate secure password
generate_password() {
    local length=${1:-24}
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length}
}

# Function to generate encryption key
generate_encryption_key() {
    openssl rand -base64 32 | tr -d "=+/"
}

# Function to validate email format
validate_email() {
    local email=$1
    if [[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate domain format
validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to create .env file
create_env_file() {
    echo
    log_info "Creating N8N environment configuration..."
    echo

    # Check if .env already exists
    if [[ -f .env ]]; then
        log_warning ".env file already exists"
        read -p "Do you want to backup and replace it? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
            log_success "Backup created"
        else
            log_info "Keeping existing .env file"
            return 0
        fi
    fi

    # Get domain configuration
    echo
    log_info "Domain Configuration:"
    read -p "Enter your domain name (e.g., example.com): " domain_name
    
    while ! validate_domain "$domain_name"; do
        log_error "Invalid domain format"
        read -p "Enter your domain name (e.g., example.com): " domain_name
    done
    
    read -p "Enter N8N subdomain (default: n8n): " subdomain
    subdomain=${subdomain:-n8n}
    
    # Get SSL email
    echo
    log_info "SSL Configuration:"
    read -p "Enter email for SSL certificates: " ssl_email
    
    while ! validate_email "$ssl_email"; do
        log_error "Invalid email format"
        read -p "Enter email for SSL certificates: " ssl_email
    done
    
    # Get timezone
    echo
    log_info "Timezone Configuration:"
    echo "Common timezones:"
    echo "  UTC"
    echo "  Europe/London"
    echo "  Europe/Berlin"
    echo "  Europe/Sofia"
    echo "  America/New_York"
    echo "  America/Los_Angeles"
    echo "  Asia/Tokyo"
    echo
    read -p "Enter timezone (default: UTC): " timezone
    timezone=${timezone:-UTC}
    
    # Generate passwords
    echo
    log_info "Generating secure passwords..."
    postgres_root_password=$(generate_password 24)
    postgres_user_password=$(generate_password 24)
    encryption_key=$(generate_encryption_key)
    
    # Create .env file
    cat > .env << EOF
# N8N Docker Environment Configuration
# Generated on $(date)

# Domain and SSL Configuration
DOMAIN_NAME=${domain_name}
SUBDOMAIN=${subdomain}
SSL_EMAIL=${ssl_email}

# N8N will be accessible at: https://${subdomain}.${domain_name}

# Timezone Configuration
GENERIC_TIMEZONE=${timezone}

# PostgreSQL Configuration
POSTGRES_USER=n8n_root
POSTGRES_PASSWORD=${postgres_root_password}
POSTGRES_DB=n8n

POSTGRES_NON_ROOT_USER=n8n_user
POSTGRES_NON_ROOT_PASSWORD=${postgres_user_password}

# N8N Encryption Key (keep this secure!)
N8N_ENCRYPTION_KEY=${encryption_key}

# Optional: N8N Basic Auth (uncomment to enable)
# N8N_BASIC_AUTH_ACTIVE=true
# N8N_BASIC_AUTH_USER=admin
# N8N_BASIC_AUTH_PASSWORD=$(generate_password 16)
EOF

    log_success ".env file created successfully!"
    echo
    log_info "Configuration Summary:"
    echo "  N8N URL: https://${subdomain}.${domain_name}"
    echo "  SSL Email: ${ssl_email}"
    echo "  Timezone: ${timezone}"
    echo "  Database: PostgreSQL with secure passwords"
    echo
    log_warning "Important Security Notes:"
    echo "  1. Keep your .env file secure and never commit it to version control"
    echo "  2. Your passwords and encryption key have been generated securely"
    echo "  3. The encryption key is critical - back it up safely!"
    echo
}

# Function to start services
start_services() {
    log_info "Starting N8N services..."
    
    if [[ ! -f .env ]]; then
        log_error ".env file not found. Please create it first."
        return 1
    fi
    
    # Create necessary directories
    mkdir -p local-files
    
    # Start services
    docker-compose up -d
    
    if [[ $? -eq 0 ]]; then
        log_success "Services started successfully!"
        echo
        log_info "Service Status:"
        docker-compose ps
        echo
        log_info "Access your N8N installation:"
        source .env
        echo "  URL: https://${SUBDOMAIN}.${DOMAIN_NAME}"
        echo "  Dashboard: http://localhost:8090 (Traefik)"
        echo
        log_warning "Note: It may take a few minutes for SSL certificates to be issued"
    else
        log_error "Failed to start services"
        return 1
    fi
}

# Function to stop services
stop_services() {
    log_info "Stopping N8N services..."
    docker-compose down
    log_success "Services stopped"
}

# Function to show logs
show_logs() {
    echo
    log_info "Available services: n8n, postgres, traefik"
    read -p "Enter service name (or 'all' for all services): " service
    
    if [[ "$service" == "all" ]]; then
        docker-compose logs -f
    else
        docker-compose logs -f "$service"
    fi
}

# Function to check system requirements
check_requirements() {
    log_info "Checking system requirements..."
    
    # Check Docker
    if command -v docker &> /dev/null; then
        log_success "Docker is installed"
        docker --version
    else
        log_error "Docker is not installed"
        echo "Please install Docker: https://docs.docker.com/get-docker/"
        return 1
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        log_success "Docker Compose is installed"
        docker-compose --version
    else
        log_error "Docker Compose is not installed"
        echo "Please install Docker Compose"
        return 1
    fi
    
    # Check openssl for password generation
    if command -v openssl &> /dev/null; then
        log_success "OpenSSL is available for secure password generation"
    else
        log_warning "OpenSSL not found - passwords will be less secure"
    fi
    
    # Check available ports
    if netstat -tuln 2>/dev/null | grep -q ":80 "; then
        log_warning "Port 80 is already in use"
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":443 "; then
        log_warning "Port 443 is already in use"
    fi
    
    if netstat -tuln 2>/dev/null | grep -q ":5432 "; then
        log_warning "Port 5432 is already in use"
    fi
}

# Main menu
show_menu() {
    echo
    echo "=== N8N Setup Script ==="
    echo
    echo "1) Check system requirements"
    echo "2) Create .env configuration file"
    echo "3) Start N8N services"
    echo "4) Stop N8N services"
    echo "5) View service logs"
    echo "6) Show service status"
    echo "0) Exit"
    echo
}

# Main script
main() {
    echo -e "${GREEN}=== N8N Docker Setup Script ===${NC}"
    echo "This script helps you configure and manage your N8N installation"
    
    while true; do
        show_menu
        read -p "Enter choice [0-6]: " choice
        
        case $choice in
            1) check_requirements ;;
            2) create_env_file ;;
            3) start_services ;;
            4) stop_services ;;
            5) show_logs ;;
            6) 
                if [[ -f .env ]]; then
                    docker-compose ps
                else
                    log_error ".env file not found"
                fi
                ;;
            0) 
                echo
                log_success "Goodbye!"
                break 
                ;;
            *) 
                log_error "Invalid choice. Please try again."
                ;;
        esac
        
        echo
        read -p "Press Enter to continue..."
    done
}

# Run main function
main