# Authentik Server Dockerfile for Railway deployment
FROM ghcr.io/goauthentik/server:2024.10.4

# Railway injects PORT at runtime, Authentik needs to listen on it
# We use a startup script to handle the dynamic PORT
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Default command - Railway will set PORT env var
CMD ["/start.sh"]
