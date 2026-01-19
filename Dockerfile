# Authentik Server Dockerfile for Railway deployment
FROM ghcr.io/goauthentik/server:2024.10.4

# Copy custom entrypoint script
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# Use our custom entrypoint
ENTRYPOINT ["/entrypoint.sh"]
