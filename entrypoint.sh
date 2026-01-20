#!/bin/bash
set -e

echo "=== Keycloak Startup Script ==="
echo "PORT: ${PORT}"
echo "KC_DB_URL: ${KC_DB_URL}"
echo "KC_HOSTNAME: ${KC_HOSTNAME}"
echo "================================"

# Railway provides PORT environment variable
# Keycloak needs to listen on this port
export KC_HTTP_PORT="${PORT:-8080}"

echo "Starting Keycloak on port ${KC_HTTP_PORT}..."

# Start Keycloak in production mode
exec /opt/keycloak/bin/kc.sh start \
  --optimized \
  --http-port="${KC_HTTP_PORT}" \
  --hostname-strict=false \
  --http-enabled=true \
  --proxy-headers=xforwarded
