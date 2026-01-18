# Authentik Server Dockerfile for Railway deployment
# Uses the official Authentik image without modifying entrypoint

FROM ghcr.io/goauthentik/server:2024.10.4

# Expose the default Authentik port
EXPOSE 9000

# Don't override ENTRYPOINT or CMD - use the base image defaults
