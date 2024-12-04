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

# Platform-specific base64 decoding command
case "$(uname)" in
'Linux')
    CMD_DECODE_BASE64="base64 -d"
    ;;
*)
    CMD_DECODE_BASE64="base64 --decode"
    ;;
esac

# Extract certificate and key using jq
cert=$(jq -e -r --arg domain "$SUBDOMAIN" '.sslresolver.Certificates[] | select(.domain.main == $domain) | .certificate' "$ACME_JSON_PATH") || {
    echo "Error: Failed to extract certificate from $ACME_JSON_PATH"
    exit 2
}

key=$(jq -e -r --arg domain "$SUBDOMAIN" '.sslresolver.Certificates[] | select(.domain.main == $domain) | .key' "$ACME_JSON_PATH") || {
    echo "Error: Failed to extract private key from $ACME_JSON_PATH"
    exit 2
}

# Check if certificate or key is empty or null
if [ -z "$cert" ] || [ "$cert" = "null" ]; then
    echo "Error: No certificate found for $SUBDOMAIN"
    exit 1
fi

if [ -z "$key" ] || [ "$key" = "null" ]; then
    echo "Error: No private key found for $SUBDOMAIN"
    exit 1
fi

# Decode the certificate and key from base64 and format them as PEM
echo "-----BEGIN CERTIFICATE-----" >/tmp/fullchain.pem
echo "$cert" | $CMD_DECODE_BASE64 >>/tmp/fullchain.pem
echo "-----END CERTIFICATE-----" >>/tmp/fullchain.pem

echo "-----BEGIN PRIVATE KEY-----" >/tmp/privkey.pem
echo "$key" | $CMD_DECODE_BASE64 >>/tmp/privkey.pem
echo "-----END PRIVATE KEY-----" >>/tmp/privkey.pem

# Debug: Print extracted and formatted certificate and key
echo "Extracted certificate and key formatted as PEM"
cat /tmp/fullchain.pem
cat /tmp/privkey.pem

# Set appropriate permissions
chmod 600 /tmp/fullchain.pem /tmp/privkey.pem

# Validate certificate and private key formats
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

# Move validated certificate and key to the final location
mv /tmp/fullchain.pem config/daemon/certs/fullchain.pem
mv /tmp/privkey.pem config/daemon/certs/privkey.pem

# Set appropriate permissions on final files
chmod 600 config/daemon/certs/fullchain.pem config/daemon/certs/privkey.pem

# Verify final file contents
if [ ! -s config/daemon/certs/fullchain.pem ] || [ ! -s config/daemon/certs/privkey.pem ]; then
    echo "Warning: Generated files are empty"
    exit 1
fi

echo "Certificates extracted and validated for $SUBDOMAIN:"
echo "- Full chain certificate: config/daemon/certs/fullchain.pem"
echo "- Private key: config/daemon/certs/privkey.pem"

# Optional: display file sizes
ls -l config/daemon/certs/
