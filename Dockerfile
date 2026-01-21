# Keycloak Server Dockerfile for Railway deployment
FROM quay.io/keycloak/keycloak:26.0.7 AS builder

# Set build-time environment variables
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_HTTP_ENABLED=true
ENV KC_DB=postgres

# Build optimized Keycloak with PostgreSQL support
RUN /opt/keycloak/bin/kc.sh build

# Production image
FROM quay.io/keycloak/keycloak:26.0.7

# Copy built artifacts from builder
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Use custom entrypoint to handle Railway's dynamic PORT
COPY --chmod=755 entrypoint.sh /opt/keycloak/entrypoint.sh

ENTRYPOINT ["/opt/keycloak/entrypoint.sh"]
