#!/bin/bash
# Startup script for Authentik on Railway
# Railway sets PORT dynamically, we need to configure Authentik to use it

# Set the listen address based on Railway's PORT variable
export AUTHENTIK_LISTEN__HTTP="0.0.0.0:${PORT:-9000}"
export AUTHENTIK_LISTEN__HTTPS=""

# Log the configuration for debugging
echo "Starting Authentik..."
echo "PORT: ${PORT:-9000}"
echo "AUTHENTIK_LISTEN__HTTP: ${AUTHENTIK_LISTEN__HTTP}"
echo "AUTHENTIK_POSTGRESQL__HOST: ${AUTHENTIK_POSTGRESQL__HOST}"
echo "AUTHENTIK_REDIS__HOST: ${AUTHENTIK_REDIS__HOST}"

# Run database migrations first
echo "Running database migrations..."
/usr/local/bin/ak migrate

# Start the Authentik server
echo "Starting Authentik server..."
exec /usr/local/bin/ak server
