# Authentik Server Dockerfile for Railway deployment
# This wraps the official Authentik image with Railway-specific configuration

FROM ghcr.io/goauthentik/server:2024.10.4

# Set environment variables for Railway
ENV AUTHENTIK_REDIS__HOST=${REDIS_HOST:-redis}
ENV AUTHENTIK_POSTGRESQL__HOST=${PGHOST:-postgres}
ENV AUTHENTIK_POSTGRESQL__PORT=${PGPORT:-5432}
ENV AUTHENTIK_POSTGRESQL__USER=${PGUSER:-authentik}
ENV AUTHENTIK_POSTGRESQL__NAME=${PGDATABASE:-authentik}
ENV AUTHENTIK_POSTGRESQL__PASSWORD=${PGPASSWORD}
ENV AUTHENTIK_SECRET_KEY=${AUTHENTIK_SECRET_KEY}

# Railway uses PORT environment variable
ENV AUTHENTIK_LISTEN__HTTP=0.0.0.0:${PORT:-9000}

# Expose the port
EXPOSE ${PORT:-9000}

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:${PORT:-9000}/-/health/live/ || exit 1

# Start the server
CMD ["server"]
