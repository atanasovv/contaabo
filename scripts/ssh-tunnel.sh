#!/bin/bash
# SSH tunnel script for secure access to services

# Create SSH tunnels to your server
# Usage: ./tunnel.sh [start|stop]

SERVER_IP="your-server-ip"
SSH_USER="your-username"
SSH_KEY="~/.ssh/your-key"

case "$1" in
    start)
        echo "Starting SSH tunnels..."
        # Tunnel for Traefik dashboard
        ssh -f -N -L 8080:localhost:8080 -i $SSH_KEY $SSH_USER@$SERVER_IP
        
        # Tunnel for phpMyAdmin  
        ssh -f -N -L 8081:localhost:8081 -i $SSH_KEY $SSH_USER@$SERVER_IP
        
        echo "Tunnels active:"
        echo "- Traefik dashboard: http://localhost:8080"
        echo "- phpMyAdmin: http://localhost:8081"
        ;;
    stop)
        echo "Stopping SSH tunnels..."
        pkill -f "ssh.*8080:localhost:8080"
        pkill -f "ssh.*8081:localhost:8081"
        echo "Tunnels stopped."
        ;;
    *)
        echo "Usage: $0 {start|stop}"
        exit 1
        ;;
esac