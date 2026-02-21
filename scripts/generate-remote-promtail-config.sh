#!/bin/bash
# Script to generate Promtail configuration for remote servers

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <LOKI_HOST> <SERVER_NAME> [OUTPUT_FILE]"
    echo ""
    echo "Arguments:"
    echo "  LOKI_HOST    - IP address or hostname of central Loki server (e.g., 192.168.1.100)"
    echo "  SERVER_NAME  - Unique identifier for this server (e.g., server1, web-01, db-prod)"
    echo "  OUTPUT_FILE  - Output file path (default: promtail-config-remote.yml)"
    echo ""
    echo "Example:"
    echo "  $0 192.168.1.100 web-server-01"
    exit 1
fi

LOKI_HOST="$1"
SERVER_NAME="$2"
OUTPUT_FILE="${3:-promtail-config-remote.yml}"

echo "Generating Promtail configuration..."
echo "  Loki Host: $LOKI_HOST"
echo "  Server Name: $SERVER_NAME"
echo "  Output File: $OUTPUT_FILE"
echo ""

# Check if template exists
TEMPLATE_FILE="promtail-config-remote.yml"
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file '$TEMPLATE_FILE' not found"
    exit 1
fi

# Generate config by replacing placeholders
sed -e "s/LOKI_HOST/$LOKI_HOST/g" \
    -e "s/SERVER_NAME/$SERVER_NAME/g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Configuration generated successfully: $OUTPUT_FILE"
echo ""
echo "Next steps:"
echo "  1. Review the generated configuration"
echo "  2. Copy it to your remote server"
echo "  3. Start Promtail: docker-compose -f docker-compose.promtail-remote.yml up -d"
