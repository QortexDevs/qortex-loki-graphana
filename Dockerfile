# Dockerfile for Loki/Grafana monitoring stack
# This image packages all configurations and uses the host's Docker daemon
# to run the services via docker-compose

FROM alpine:3.19

# Install docker-compose, docker-cli, and required tools
RUN apk add --no-cache \
    docker-compose \
    docker-cli \
    bash \
    curl \
    ca-certificates \
    tini

# Set working directory
WORKDIR /app

# Copy all configuration files
COPY docker-compose.yml ./
COPY loki-config.yml ./
COPY promtail-config.yml ./
COPY grafana/ ./grafana/

# Create entrypoint script
RUN cat > /app/entrypoint.sh << 'EOF'
#!/bin/bash
set -e

echo "=========================================="
echo "Loki/Grafana Monitoring Stack"
echo "=========================================="

# Check if Docker socket is available
if [ ! -S /var/run/docker.sock ]; then
    echo "ERROR: Docker socket not found at /var/run/docker.sock"
    echo "Make sure to mount the Docker socket: -v /var/run/docker.sock:/var/run/docker.sock"
    exit 1
fi

# Verify we can communicate with Docker daemon
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Cannot communicate with Docker daemon"
    echo "Check Docker socket permissions and ensure Docker is running"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: docker-compose not found"
    exit 1
fi

echo "Docker daemon connection: OK"
echo "Starting services with docker-compose..."
echo ""

# Change to app directory and start services
cd /app

# Handle shutdown gracefully
trap 'echo "Shutting down..."; docker-compose down; exit 0' SIGTERM SIGINT

# Start services in foreground
exec docker-compose up
EOF

RUN chmod +x /app/entrypoint.sh

# Expose ports for Grafana and Loki
EXPOSE 3000 3100 9080

# Use tini as init system for proper signal handling
ENTRYPOINT ["/sbin/tini", "--", "/app/entrypoint.sh"]
