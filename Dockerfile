# Authentik Server Dockerfile for Railway deployment
FROM ghcr.io/goauthentik/server:2024.10.4

# Railway injects PORT at runtime, Authentik needs to listen on it
# Set the script with proper permissions during COPY (--chmod flag)
COPY --chmod=755 start.sh /start.sh

# Default command - Railway will set PORT env var
CMD ["/start.sh"]
