# Authentik Server Dockerfile for Railway deployment
FROM ghcr.io/goauthentik/server:2024.10.4

# Railway will set PORT at runtime
# Authentik will read AUTHENTIK_LISTEN__HTTP from environment variables
# No need to override CMD - use the default from base image
