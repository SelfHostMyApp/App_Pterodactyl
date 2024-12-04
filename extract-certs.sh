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

# Extract and write fullchain certificate
sudo jq -r --arg domain "$SUBDOMAIN" '.[] | select(.domain.main == $domain) | .certificate' "$ACME_JSON_PATH" | base64 -d >certs/fullchain.pem

# Extract and write private key
sudo jq -r --arg domain "$SUBDOMAIN" '.[] | select(.domain.main == $domain) | .key' "$ACME_JSON_PATH" | base64 -d >certs/privkey.pem

echo "Certificates extracted for $SUBDOMAIN:"
echo "- Full chain certificate: certs/fullchain.pem"
echo "- Private key: certs/privkey.pem"
