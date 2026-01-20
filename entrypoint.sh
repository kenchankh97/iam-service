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

# Start the worker in the background (needed for blueprints and background tasks)
echo "Starting Authentik worker in background..."
python -m lifecycle.ak worker &
WORKER_PID=$!
echo "Worker started with PID: ${WORKER_PID}"

# Give worker time to initialize and apply blueprints
echo "Waiting for worker to initialize..."
sleep 10

# Start the server (this will be the main process)
echo "Starting Authentik server on port ${PORT:-9000}..."
exec python -m lifecycle.ak server
