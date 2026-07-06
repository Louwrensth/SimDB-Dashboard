#!/usr/bin/env sh
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
SSL_DIR="$REPO_ROOT/docker/nginx/ssl"
CERT_FILE="$SSL_DIR/cert.crt"
KEY_FILE="$SSL_DIR/cert.key"

DAYS="${CERT_DAYS:-3650}"

DOMAIN_NAME="${DOMAIN_NAME:-$(hostname -f 2>/dev/null || hostname --fqdn 2>/dev/null || hostname 2>/dev/null || echo localhost)}"
CERT_CN=${CERT_CN:-$DOMAIN_NAME}

if ! command -v openssl >/dev/null 2>&1; then
    echo "Error: openssl is required but was not found in PATH." >&2
    exit 1
fi

mkdir -p "$SSL_DIR"

openssl req \
    -x509 \
    -nodes \
    -newkey rsa:2048 \
    -sha256 \
    -days "$DAYS" \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -subj "/CN=$CERT_CN"

chmod 600 "$KEY_FILE"
chmod 644 "$CERT_FILE"

echo "Created self-signed certificate files:"
echo "- $CERT_FILE"
echo "- $KEY_FILE"
