# Keycloak Server Dockerfile for Railway deployment
FROM quay.io/keycloak/keycloak:26.0.7

# Set environment variables for production mode
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_HTTP_ENABLED=true
ENV KC_PROXY_HEADERS=xforwarded

# Build optimized Keycloak
RUN /opt/keycloak/bin/kc.sh build

# Use custom entrypoint to handle Railway's dynamic PORT
COPY --chmod=755 entrypoint.sh /opt/keycloak/entrypoint.sh

ENTRYPOINT ["/opt/keycloak/entrypoint.sh"]
