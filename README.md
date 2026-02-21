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

## Building Docker Image for Server Deployment

To build a Docker image that packages all configurations for server deployment:

### Build the Image

**Linux/macOS:**
```bash
./build-and-run.sh
```

**Windows (PowerShell):**
```powershell
.\build-and-run.ps1
```

**Manual build:**
```bash
docker build -t qortex-loki-grafana:latest .
```

### Run the Built Image

The built image requires access to the host's Docker socket to discover containers:

```bash
docker run -d \
  --name monitoring-stack \
  -p 3000:3000 \
  -p 3100:3100 \
  -p 9080:9080 \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /var/lib/docker/containers:/var/lib/docker/containers:ro \
  -v loki-data:/loki \
  -v grafana-data:/var/lib/grafana \
  qortex-loki-grafana:latest
```

**Or use the deployment compose file:**
```bash
docker-compose -f docker-compose.deploy.yml up -d
```

### Image Details

The Dockerfile creates an image that:
- Packages all configuration files (Loki, Grafana, Promtail)
- Includes docker-compose for orchestrating services
- Automatically starts all services on container startup
- Requires host Docker socket access for container discovery

**Note:** The image runs docker-compose internally, so it needs access to the host's Docker daemon to start the individual service containers.

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

## Distributed Logging (Multiple Servers)

This setup supports collecting logs from multiple servers across your local network. Each remote server runs Promtail to collect logs and send them to the central Loki instance.

### Architecture

```
Remote Server 1 → Promtail → ┐
Remote Server 2 → Promtail → ├→ Central Loki → Grafana
Remote Server 3 → Promtail → ┘
```

### Setup Instructions

#### 1. Configure Central Loki Server

The Loki configuration has been updated to accept remote connections (binds to `0.0.0.0`). Ensure the central Loki server is accessible on your network:

- Loki should be reachable at `http://<LOKI_IP>:3100` from remote servers
- Check firewall rules to allow TCP port 3100

#### 2. Set Up Promtail on Remote Servers

**Option A: Using the Configuration Generator Script**

**Linux/macOS:**
```bash
./scripts/generate-remote-promtail-config.sh <LOKI_IP> <SERVER_NAME>
```

**Windows (PowerShell):**
```powershell
.\scripts\generate-remote-promtail-config.ps1 -LokiHost <LOKI_IP> -ServerName <SERVER_NAME>
```

**Example:**
```bash
./scripts/generate-remote-promtail-config.sh 192.168.1.100 web-server-01
```

This generates a `promtail-config-remote.yml` file with the correct settings.

**Option B: Manual Configuration**

1. Copy `promtail-config-remote.yml` to your remote server
2. Edit the file and replace:
   - `LOKI_HOST` with your central Loki server IP (e.g., `192.168.1.100`)
   - `SERVER_NAME` with a unique identifier for this server (e.g., `web-01`, `db-prod`)

#### 3. Deploy Promtail on Remote Server

Copy these files to your remote server:
- `promtail-config-remote.yml` (generated or manually configured)
- `docker-compose.promtail-remote.yml`

Then start Promtail:
```bash
docker-compose -f docker-compose.promtail-remote.yml up -d
```

#### 4. Verify Remote Log Collection

1. Check Promtail logs on remote server:
   ```bash
   docker logs promtail-remote
   ```

2. In Grafana, query logs with server label:
   ```logql
   {server="web-server-01"}
   ```

3. View logs from all servers:
   ```logql
   {server=~".+"}
   ```

### Remote Server Configuration Details

The remote Promtail configuration:
- Collects logs from Docker containers on the remote server
- Adds a `server` label to identify the source server
- Sends logs to central Loki over TCP/IP
- Maintains the same container labels (container, compose_project, etc.)

### Network Requirements

- **Port 3100**: Must be open on the central Loki server for incoming connections
- **Port 9080**: Optional, for Promtail metrics/health checks on remote servers
- **Network**: Remote servers must be able to reach the central Loki server via TCP

### Querying Distributed Logs

Use the `server` label to filter logs by source:

```logql
# All logs from a specific server
{server="web-server-01"}

# Error logs from a specific server
{server="web-server-01"} |= "error"

# Logs from multiple servers
{server=~"web-.*"}

# Logs from a specific container across all servers
{container="my-app", server=~".+"}

# Compare logs across servers
{container="api"} | json | server="web-01" or server="web-02"
```

### Security Considerations

For production distributed setups:

1. **Network Security**: Use VPN or private network for log transmission
2. **Authentication**: Enable Loki authentication (update `loki-config.yml`)
3. **TLS/HTTPS**: Configure TLS for Loki API endpoint
4. **Firewall**: Restrict access to Loki port (3100) to known IPs
5. **Rate Limiting**: Adjust `limits_config` in Loki for multiple remote sources

### Troubleshooting Remote Logs

**Promtail can't connect to Loki:**
- Verify network connectivity: `curl http://<LOKI_IP>:3100/ready`
- Check firewall rules on both servers
- Verify Loki is bound to `0.0.0.0` (not `127.0.0.1`)

**No logs appearing from remote server:**
- Check Promtail logs: `docker logs promtail-remote`
- Verify Promtail config has correct Loki URL
- Check Loki logs for incoming connections: `docker logs loki`
- Test with: `{server="<SERVER_NAME>"}` in Grafana

**High latency or missing logs:**
- Check network latency between servers
- Verify Promtail positions file is being written
- Increase Promtail batch size if needed
- Check Loki ingestion limits

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
