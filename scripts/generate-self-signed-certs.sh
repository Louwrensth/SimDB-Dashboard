#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
# Directory where generated TLS assets are to be stored.
SSL_DIR="$REPO_ROOT/docker/nginx/ssl"
CERT_FILE="$SSL_DIR/cert.crt"
KEY_FILE="$SSL_DIR/cert.key"
# Temporary OpenSSL config file used for SAN and extensions.
CNF_FILE="$SSL_DIR/san.cnf"

# Certificate validity period in days.
CERT_DAYS="${CERT_DAYS:-3650}"

# Primary DNS name for SAN/CN; auto-detected with localhost fallback.
DOMAIN_NAME="${DOMAIN_NAME:-$(hostname -f 2>/dev/null || hostname --fqdn 2>/dev/null || hostname 2>/dev/null || echo localhost)}"
# Certificate common name; defaults to DOMAIN_NAME.
CERT_CN=${CERT_CN:-$DOMAIN_NAME}

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: openssl is required but was not found in PATH." >&2
    exit 1
fi

mkdir -p "$SSL_DIR"

cat > "$CNF_FILE" <<EOF
[req]
# Reference to the DN section used for subject fields.
distinguished_name = dn
# X.509 extension section to apply to the generated cert.
x509_extensions = v3_req
# Disable interactive prompts; values are provided in this file.
prompt = no

[dn]
# Subject common name for the certificate.
CN = $CERT_CN

[v3_req]
# Mark cert as an end-entity certificate (not a CA).
basicConstraints = critical,CA:FALSE
# Allow TLS key exchange and handshake signing.
keyUsage = critical,digitalSignature,keyEncipherment
# Restrict usage to TLS server authentication.
extendedKeyUsage = serverAuth
# Auto-generate a subject key identifier from the public key.
subjectKeyIdentifier = hash
# Include authority key identifier from issuer/key metadata.
authorityKeyIdentifier = keyid,issuer
# Pull SAN values from the alt_names section below.
subjectAltName = @alt_names

[alt_names]
# Primary DNS alias (supports wildcard values like *.example.org).
DNS.1 = $CERT_CN
# Resolved hostname alias.
DNS.2 = $DOMAIN_NAME
# Localhost DNS alias.
DNS.3 = localhost
# IPv4 loopback alias.
IP.1  = 127.0.0.1
# IPv6 loopback alias.
IP.2 = 0:0:0:0:0:0:0:1
EOF

openssl req \
    -x509 \
    -nodes \
    -newkey rsa:2048 \
    -sha256 \
    -days "$CERT_DAYS" \
    -config "$CNF_FILE" \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE"

chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

echo "Created self-signed certificate files:"
echo "- $CERT_FILE"
echo "- $KEY_FILE"
echo "- $CNF_FILE"
