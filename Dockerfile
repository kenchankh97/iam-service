# Authentik Server Dockerfile for Railway deployment
FROM ghcr.io/goauthentik/server:2024.10.4

# Set environment variable for Railway's dynamic port
ENV AUTHENTIK_LISTEN__HTTP=0.0.0.0:${PORT:-9000}

# Expose port
EXPOSE ${PORT:-9000}
