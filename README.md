# Qortex Loki & Grafana

A complete setup for container monitoring and log processing using Grafana Loki and Grafana.

## Overview

This submodule provides:
- **Loki**: Log aggregation system designed to work efficiently with Grafana
- **Grafana**: Visualization and analytics platform
- **Promtail**: Log shipper that collects logs from Docker containers and sends them to Loki

## Architecture

```
Docker Containers → Promtail → Loki → Grafana
```

- **Promtail** monitors Docker containers and collects their logs
- **Loki** stores and indexes the logs
- **Grafana** provides visualization and querying interface

## Prerequisites

- Docker and Docker Compose installed
- Access to Docker socket (`/var/run/docker.sock`) for Promtail to discover containers

## Quick Start

1. **Start the services:**
   ```bash
   docker-compose up -d
   ```

2. **Access Grafana:**
   - Open http://localhost:3000 in your browser
   - Default credentials:
     - Username: `admin`
     - Password: `admin`
   - You'll be prompted to change the password on first login

3. **View logs:**
   - The "Container Logs Dashboard" is automatically provisioned
   - Navigate to Dashboards → Container Logs Dashboard
   - You can filter by container name and stream (stdout/stderr)

## Services

### Loki (Port 3100)
- Log aggregation and storage
- Query API available at http://localhost:3100
- Configuration: `loki-config.yml`

### Grafana (Port 3000)
- Web UI: http://localhost:3000
- Pre-configured Loki datasource
- Pre-loaded container logs dashboard
- Data persisted in `grafana-data` volume

### Promtail
- Collects logs from all running Docker containers
- Automatically discovers new containers
- Configuration: `promtail-config.yml`

## Configuration

### Loki Configuration (`loki-config.yml`)
- Storage: Filesystem-based (persisted in `loki-data` volume)
- Retention: Configurable via `compactor.retention_enabled`
- Limits: Adjustable ingestion rates and query limits

### Promtail Configuration (`promtail-config.yml`)
- Monitors Docker socket for container discovery
- Collects logs from `/var/lib/docker/containers/`
- Adds labels: `container`, `container_id`, `compose_project`, `compose_service`, `stream`
- Parses JSON logs and extracts log levels

### Grafana Provisioning
- **Datasources**: Automatically configured in `grafana/provisioning/datasources/`
- **Dashboards**: Automatically loaded from `grafana/dashboards/`

## Dashboard Features

The Container Logs Dashboard includes:
- **Log Viewer**: Real-time log stream with filtering
- **Log Volume by Container**: Time series showing log volume per container
- **Log Volume by Stream**: Breakdown of stdout vs stderr
- **Metrics**: Total logs, active containers, error/warning counts
- **Filters**: Container name and stream (stdout/stderr) dropdowns

## Querying Logs

### In Grafana Explore
1. Go to Explore (compass icon in left menu)
2. Select Loki datasource
3. Use LogQL queries, for example:
   - `{container="container-name"}` - All logs from a container
   - `{container=~".+"} |= "error"` - All error logs
   - `{container="app"} | json | level="error"` - JSON parsed error logs

### LogQL Examples
```logql
# All logs from a specific container
{container="my-app"}

# Error logs from all containers
{container=~".+"} |= "error"

# Logs with specific log level
{container="my-app"} | json | level="error"

# Logs from Docker Compose project
{compose_project="myproject"}

# Logs from specific service
{compose_service="api"}
```

## Data Persistence

Data is persisted in Docker volumes:
- `loki-data`: Loki chunks and indexes
- `grafana-data`: Grafana dashboards, users, and settings

To remove all data:
```bash
docker-compose down -v
```

## Stopping Services

```bash
# Stop services (keeps data)
docker-compose stop

# Stop and remove containers (keeps data)
docker-compose down

# Stop and remove everything including volumes
docker-compose down -v
```

## Customization

### Adding Custom Dashboards
1. Create JSON dashboard files in `grafana/dashboards/`
2. Restart Grafana or wait for auto-reload
3. Dashboards will appear in Grafana UI

### Modifying Log Collection
Edit `promtail-config.yml` to:
- Add custom labels
- Filter specific containers
- Parse custom log formats
- Add additional scrape configs

### Adjusting Loki Limits
Edit `loki-config.yml` to modify:
- Ingestion rates (`ingestion_rate_mb`)
- Retention periods (`retention_period`)
- Query limits (`max_entries_limit_per_query`)

## Security Notes

⚠️ **Important**: This setup is configured for development/testing:
- Default Grafana credentials are `admin/admin`
- Loki has authentication disabled
- Promtail has access to Docker socket

For production:
1. Change Grafana admin password
2. Enable Loki authentication
3. Restrict Docker socket access
4. Use environment variables for sensitive configuration
5. Enable HTTPS/TLS
6. Set up proper network isolation

## Troubleshooting

### Promtail not collecting logs
- Verify Docker socket is accessible: `ls -la /var/run/docker.sock`
- Check Promtail logs: `docker logs promtail`
- Ensure containers are running: `docker ps`

### No logs in Grafana
- Verify Loki is running: `docker logs loki`
- Check datasource connection in Grafana: Configuration → Data Sources → Loki → Test
- Verify Promtail is sending logs: `docker logs promtail`

### High memory usage
- Adjust Loki limits in `loki-config.yml`
- Reduce retention period
- Limit number of containers being monitored

## Integration with Parent Project

This submodule can be integrated into a parent project's `docker-compose.yml`:

```yaml
services:
  # ... your services ...
  
  loki:
    extends:
      file: ./qortex-loki-graphana/docker-compose.yml
      service: loki
  
  grafana:
    extends:
      file: ./qortex-loki-graphana/docker-compose.yml
      service: grafana
  
  promtail:
    extends:
      file: ./qortex-loki-graphana/docker-compose.yml
      service: promtail
```

Or include the entire stack:
```yaml
include:
  - path: ./qortex-loki-graphana/docker-compose.yml
```

## License

Part of the Qortex project.
