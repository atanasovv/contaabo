#!/bin/bash

# Script to help configure phpMyAdmin access restrictions

echo "=== phpMyAdmin IP Restriction Setup ==="
echo

# Function to get public IP
get_public_ip() {
    echo "Detecting your current public IP address..."
    
    # Try multiple services to get public IP
    IP=$(curl -s ipinfo.io/ip 2>/dev/null || curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null)
    
    if [[ -n "$IP" ]]; then
        echo "Your current public IP address is: $IP"
        echo "For single IP access, use: $IP/32"
        echo "For subnet access (e.g., your ISP range), use: $IP/24"
    else
        echo "Could not detect your public IP automatically."
        echo "Please find your public IP manually by visiting: https://whatismyipaddress.com/"
    fi
    echo
}

# Function to generate basic auth
generate_basic_auth() {
    echo "Generating Basic Authentication credentials..."
    echo "Note: You need htpasswd installed (part of apache2-utils package)"
    echo
    
    read -p "Enter username for phpMyAdmin access: " username
    read -s -p "Enter password: " password
    echo
    
    if command -v htpasswd >/dev/null 2>&1; then
        # Generate htpasswd hash
        hash=$(htpasswd -nb "$username" "$password")
        echo "Generated Basic Auth string:"
        echo "PMA_BASIC_AUTH=$hash"
        echo
        echo "Add this to your .env file!"
    else
        echo "htpasswd not found. Install it with:"
        echo "Ubuntu/Debian: sudo apt install apache2-utils"
        echo "CentOS/RHEL: sudo yum install httpd-tools"
        echo "macOS: brew install httpd"
        echo
        echo "Then run this script again to generate the hash."
    fi
}

# Function to create .env file
create_env_file() {
    echo "Creating .env file from template..."
    
    if [[ ! -f .env.example ]]; then
        echo "Error: .env.example not found in current directory"
        return 1
    fi
    
    if [[ -f .env ]]; then
        echo "Warning: .env file already exists"
        read -p "Do you want to backup and replace it? (y/N): " confirm
        if [[ $confirm =~ ^[Yy]$ ]]; then
            cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
            echo "Backup created"
        else
            echo "Keeping existing .env file"
            return 0
        fi
    fi
    
    cp .env.example .env
    echo ".env file created from template"
    echo "Please edit .env file and replace the placeholder values:"
    echo "- YOUR_HOME_IP_HERE with your actual IP"
    echo "- Database passwords with secure passwords"
    echo "- PMA_BASIC_AUTH with generated hash"
}

# Function to test IP format
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}(/[0-9]{1,2})?$ ]]; then
        echo "IP format looks valid: $ip"
    else
        echo "Warning: IP format might be incorrect: $ip"
        echo "Expected format: 192.168.1.1/32 or 192.168.1.0/24"
    fi
}

# Main menu
while true; do
    echo "Choose an option:"
    echo "1) Detect current public IP"
    echo "2) Generate Basic Auth credentials"
    echo "3) Create .env file from template"
    echo "4) Validate IP format"
    echo "5) Show complete example"
    echo "0) Exit"
    echo
    read -p "Enter choice [0-5]: " choice
    
    case $choice in
        1) get_public_ip ;;
        2) generate_basic_auth ;;
        3) create_env_file ;;
        4) 
            read -p "Enter IP to validate (e.g., 192.168.1.1/32): " test_ip
            validate_ip "$test_ip"
            echo
            ;;
        5)
            echo "Complete example configuration:"
            echo "PMA_ALLOWED_IPS=203.0.113.1/32,203.0.113.2/32"
            echo "PMA_BASIC_AUTH=admin:\$2y\$10\$xxxxxxxxxxxxxxxxxxxxxxxxxxx"
            echo
            ;;
        0) echo "Goodbye!"; break ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
done