#!/bin/bash
# Build and run script for the monitoring stack

set -e

IMAGE_NAME="qortex-loki-grafana"
IMAGE_TAG="${1:-latest}"

echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"

# Build the image
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo ""
echo "Image built successfully!"
echo ""
echo "To run the container, use:"
echo "  docker run -d \\"
echo "    --name monitoring-stack \\"
echo "    -p 3000:3000 \\"
echo "    -p 3100:3100 \\"
echo "    -p 9080:9080 \\"
echo "    -v /var/run/docker.sock:/var/run/docker.sock:ro \\"
echo "    -v /var/lib/docker/containers:/var/lib/docker/containers:ro \\"
echo "    -v loki-data:/loki \\"
echo "    -v grafana-data:/var/lib/grafana \\"
echo "    ${IMAGE_NAME}:${IMAGE_TAG}"
echo ""
echo "Or use docker-compose:"
echo "  docker-compose -f docker-compose.deploy.yml up -d"
