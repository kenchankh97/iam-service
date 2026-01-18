# Authentik Server Dockerfile for Railway deployment
# This wraps the official Authentik image with Railway-specific configuration

FROM ghcr.io/goauthentik/server:2024.10.4

# Railway uses PORT environment variable - Authentik listens on 9000 by default
# We'll use a startup script to handle the port mapping

# Expose the default Authentik port
EXPOSE 9000

# Use the official entrypoint with server command
# The base image has /usr/local/bin/ak as the entrypoint
ENTRYPOINT ["/usr/local/bin/ak"]
CMD ["server"]
