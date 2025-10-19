#!/bin/bash

# Generate Self-Signed Certificates for Traefik
# This script creates SSL certificates for local development and testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 Generating Self-Signed SSL Certificates for Traefik${NC}"
echo "======================================================"

# Check if .env file exists to get domain
if [ -f ".env" ]; then
    source .env
    DOMAIN=${BASE_DOMAIN_NAME:-"coach-bg.com"}
else
    DOMAIN="coach-bg.com"
fi

echo -e "${YELLOW}📋 Using domain: $DOMAIN${NC}"

# Create certs directory if it doesn't exist
CERTS_DIR="traefik/certs"
mkdir -p "$CERTS_DIR"

# Certificate configuration
CERT_FILE="$CERTS_DIR/selfsigned.crt"
KEY_FILE="$CERTS_DIR/selfsigned.key"
CONFIG_FILE="$CERTS_DIR/cert.conf"

echo -e "${YELLOW}📝 Creating certificate configuration...${NC}"

# Create certificate configuration file
cat > "$CONFIG_FILE" << EOF
[req]
distinguished_name = req_distinguished_name
x509_extensions = v3_req
prompt = no

[req_distinguished_name]
C = BG
ST = Sofia
L = Sofia
O = Development
OU = IT Department
CN = *.$DOMAIN

[v3_req]
keyUsage = critical, digitalSignature, keyAgreement
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = *.$DOMAIN
DNS.3 = localhost
DNS.4 = traefik.$DOMAIN
DNS.5 = wordpress.$DOMAIN
DNS.6 = n8n.$DOMAIN
DNS.7 = phpmyadmin.internal.$DOMAIN
IP.1 = 127.0.0.1
IP.2 = ::1
EOF

echo -e "${YELLOW}🔑 Generating private key...${NC}"
openssl genrsa -out "$KEY_FILE" 2048

echo -e "${YELLOW}📜 Generating certificate...${NC}"
openssl req -new -x509 -key "$KEY_FILE" -out "$CERT_FILE" -days 365 -config "$CONFIG_FILE"

# Set proper permissions
chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

echo -e "${GREEN}✅ Certificates generated successfully!${NC}"
echo ""
echo -e "${BLUE}📁 Certificate files:${NC}"
echo "   Certificate: $CERT_FILE"
echo "   Private Key: $KEY_FILE"
echo ""

# Verify the certificate
echo -e "${BLUE}🔍 Certificate verification:${NC}"
echo "Subject: $(openssl x509 -in "$CERT_FILE" -noout -subject)"
echo "Issuer:  $(openssl x509 -in "$CERT_FILE" -noout -issuer)"
echo "Valid from: $(openssl x509 -in "$CERT_FILE" -noout -startdate | cut -d= -f2)"
echo "Valid to:   $(openssl x509 -in "$CERT_FILE" -noout -enddate | cut -d= -f2)"
echo ""

# Show SANs
echo -e "${BLUE}🌐 Subject Alternative Names:${NC}"
openssl x509 -in "$CERT_FILE" -noout -text | grep -A 10 "Subject Alternative Name" | grep -E "(DNS:|IP:)" | sed 's/^[[:space:]]*/   /'
echo ""

# Clean up config file
rm "$CONFIG_FILE"

echo -e "${GREEN}🎉 SSL certificate setup complete!${NC}"
echo ""
echo -e "${YELLOW}💡 Next steps:${NC}"
echo "   1. Restart Traefik: ./manage-apps.sh restart traefik"
echo "   2. Your browser will show a security warning (this is normal for self-signed certificates)"
echo "   3. Click 'Advanced' and 'Proceed to site' to accept the certificate"
echo ""
echo -e "${YELLOW}🔒 Security Note:${NC}"
echo "   These are self-signed certificates for development only."
echo "   For production, use Let's Encrypt or certificates from a trusted CA."