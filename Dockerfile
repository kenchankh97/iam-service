# Authentik Server Dockerfile for Railway deployment
FROM ghcr.io/goauthentik/server:2024.10.4

# Use shell form CMD to allow environment variable expansion at runtime
# Railway sets PORT dynamically, we configure Authentik to listen on it
CMD AUTHENTIK_LISTEN__HTTP="0.0.0.0:${PORT:-9000}" AUTHENTIK_LISTEN__HTTPS="" /usr/local/bin/ak server
