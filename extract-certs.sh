#!/bin/bash

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <path/to/acme.json> <subdomain>"
    exit 1
fi

ACME_JSON_PATH="$1"
SUBDOMAIN="$2"

# Create output directory if it doesn't exist
mkdir -p config/daemon/certs

# Extract certificate and key
cert=$(sudo jq -r --arg domain "$SUBDOMAIN" '.sslresolver.Certificates[] | select(.domain.main == $domain) | .certificate' "$ACME_JSON_PATH")
key=$(sudo jq -r --arg domain "$SUBDOMAIN" '.sslresolver.Certificates[] | select(.domain.main == $domain) | .key' "$ACME_JSON_PATH")

# Check if certificate or key is empty or null
if [ -z "$cert" ] || [ "$cert" = "null" ]; then
    echo "Error: No certificate found for $SUBDOMAIN"
    exit 1
fi

if [ -z "$key" ] || [ "$key" = "null" ]; then
    echo "Error: No private key found for $SUBDOMAIN"
    exit 1
fi

# Ensure certificate and key have proper headers and footers
cert="-----BEGIN CERTIFICATE-----\\n$(echo "$cert" | fold -w 64)\\n-----END CERTIFICATE-----"
key="-----BEGIN PRIVATE KEY-----\\n$(echo "$key" | fold -w 64)\\n-----END PRIVATE KEY-----"
# Debug: Print extracted values
echo "Extracted certificate: $cert"
echo "\n"
echo "Extracted key: $key"

# Write certificate and key to temporary files for validation
echo "$cert" >/tmp/fullchain.pem
echo "$key" >/tmp/privkey.pem

# Set appropriate permissions
chmod 600 /tmp/fullchain.pem /tmp/privkey.pem

# Validate certificate and private key
openssl x509 -in /tmp/fullchain.pem -noout >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Invalid certificate format"
    rm -f /tmp/fullchain.pem /tmp/privkey.pem
    exit 1
fi

openssl rsa -in /tmp/privkey.pem -check -noout >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Error: Invalid private key format"
    rm -f /tmp/fullchain.pem /tmp/privkey.pem
    exit 1
fi

# Ensure the certificate and key match
openssl x509 -noout -modulus -in /tmp/fullchain.pem | openssl md5 >/tmp/cert_modulus
openssl rsa -noout -modulus -in /tmp/privkey.pem | openssl md5 >/tmp/key_modulus
if ! diff /tmp/cert_modulus /tmp/key_modulus >/dev/null; then
    echo "Error: Certificate and private key do not match"
    rm -f /tmp/fullchain.pem /tmp/privkey.pem /tmp/cert_modulus /tmp/key_modulus
    exit 1
fi

# Clean up temporary files
rm -f /tmp/cert_modulus /tmp/key_modulus

# Write validated certificate and key to files
echo "$cert" >config/daemon/certs/fullchain.pem
echo "$key" >config/daemon/certs/privkey.pem
if [ $? -ne 0 ]; then
    echo "Error writing files"
    rm -f /tmp/fullchain.pem /tmp/privkey.pem
    exit 1
fi

# Set appropriate permissions on final files
chmod 600 config/daemon/certs/fullchain.pem config/daemon/certs/privkey.pem

# Verify final file contents
if [ ! -s config/daemon/certs/fullchain.pem ] || [ ! -s config/daemon/certs/privkey.pem ]; then
    echo "Warning: Generated files are empty"
    exit 1
fi

# Clean up temporary files
rm -f /tmp/fullchain.pem /tmp/privkey.pem

echo "Certificates extracted and validated for $SUBDOMAIN:"
echo "- Full chain certificate: config/daemon/certs/fullchain.pem"
echo "- Private key: config/daemon/certs/privkey.pem"

# Optional: display file sizes
ls -l config/daemon/certs/
