#!/bin/bash
set -e

echo "=== Authentik Startup Script ==="
echo "PORT: ${PORT}"
echo "AUTHENTIK_POSTGRESQL__HOST: ${AUTHENTIK_POSTGRESQL__HOST}"
echo "AUTHENTIK_REDIS__HOST: ${AUTHENTIK_REDIS__HOST}"
echo "================================"

# Set listen address using Railway's PORT
export AUTHENTIK_LISTEN__HTTP="0.0.0.0:${PORT:-9000}"
export AUTHENTIK_LISTEN__HTTPS=""

echo "Updated AUTHENTIK_LISTEN__HTTP to: ${AUTHENTIK_LISTEN__HTTP}"

# Run migrations
echo "Running database migrations..."
python -m lifecycle.migrate

# Start the server (blueprints are applied automatically on startup)
echo "Starting Authentik server on port ${PORT:-9000}..."
exec python -m lifecycle.ak server
