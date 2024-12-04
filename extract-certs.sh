#!/bin/bash

# Check if required arguments are provided
if [ $# -ne 2 ]; then
    echo "Usage: $0 <path/to/acme.json> <subdomain>"
    exit 1
fi

ACME_JSON_PATH="$1"
SUBDOMAIN="$2"

# Create output directory if it doesn't exist
mkdir -p certs

# Verbose extraction with error checking
cert=$(jq -r --arg domain "$SUBDOMAIN" '.[] | select(.domain.main == $domain) | .certificate' "$ACME_JSON_PATH")
key=$(jq -r --arg domain "$SUBDOMAIN" '.[] | select(.domain.main == $domain) | .key' "$ACME_JSON_PATH")

# Check if certificate or key is empty or null
if [ -z "$cert" ] || [ "$cert" = "null" ]; then
    echo "Error: No certificate found for $SUBDOMAIN"
    exit 1
fi

if [ -z "$key" ] || [ "$key" = "null" ]; then
    echo "Error: No private key found for $SUBDOMAIN"
    exit 1
fi

# Decode and write with verbose error checking
echo "$cert" | base64 -d >certs/fullchain.pem
if [ $? -ne 0 ]; then
    echo "Error decoding certificate"
    exit 1
fi

echo "$key" | base64 -d >certs/privkey.pem
if [ $? -ne 0 ]; then
    echo "Error decoding private key"
    exit 1
fi

# Verify file contents
if [ ! -s certs/fullchain.pem ] || [ ! -s certs/privkey.pem ]; then
    echo "Warning: Generated files are empty"
    exit 1
fi

echo "Certificates extracted for $SUBDOMAIN:"
echo "- Full chain certificate: certs/fullchain.pem"
echo "- Private key: certs/privkey.pem"

# Optional: display file sizes
ls -l certs/
