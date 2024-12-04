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

# Write certificate and key to files
echo "$cert" >config/daemon/certs/fullchain.pem
if [ $? -ne 0 ]; then
    echo "Error writing certificate to file"
    exit 1
fi

echo "$key" >config/daemon/certs/privkey.pem
if [ $? -ne 0 ]; then
    echo "Error writing private key to file"
    exit 1
fi

# Verify file contents
if [ ! -s config/daemon/certs/fullchain.pem ] || [ ! -s config/daemon/certs/privkey.pem ]; then
    echo "Warning: Generated files are empty"
    exit 1
fi

echo "Certificates extracted for $SUBDOMAIN:"
echo "- Full chain certificate: config/daemon/certs/fullchain.pem"
echo "- Private key: config/daemon/certs/privkey.pem"

# Optional: display file sizes
ls -l config/daemon/certs/
