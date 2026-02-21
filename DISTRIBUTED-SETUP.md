# Distributed Logging Setup Guide

Quick reference for setting up distributed logging across multiple servers.

## Quick Start

### Central Server (Loki)

1. **Start the central stack:**
   ```bash
   docker-compose up -d
   ```

2. **Note the server IP address:**
   ```bash
   # Linux/macOS
   hostname -I | awk '{print $1}'
   
   # Or check your network interface
   ip addr show
   ```

3. **Verify Loki is accessible:**
   ```bash
   curl http://<YOUR_IP>:3100/ready
   ```

### Remote Servers (Promtail)

For each remote server:

1. **Generate configuration:**
   ```bash
   # Linux/macOS
   ./scripts/generate-remote-promtail-config.sh <LOKI_IP> <SERVER_NAME>
   
   # Windows
   .\scripts\generate-remote-promtail-config.ps1 -LokiHost <LOKI_IP> -ServerName <SERVER_NAME>
   ```

2. **Copy files to remote server:**
   - `promtail-config-remote.yml` (generated)
   - `docker-compose.promtail-remote.yml`

3. **Start Promtail:**
   ```bash
   docker-compose -f docker-compose.promtail-remote.yml up -d
   ```

4. **Verify it's working:**
   ```bash
   docker logs promtail-remote
   ```

## Example Setup

### Scenario: 3 Servers

- **Central Server**: `192.168.1.100` (runs Loki + Grafana)
- **Web Server 1**: `192.168.1.101` (runs Promtail)
- **Web Server 2**: `192.168.1.102` (runs Promtail)
- **Database Server**: `192.168.1.103` (runs Promtail)

#### On Central Server (192.168.1.100):
```bash
cd qortex-loki-graphana
docker-compose up -d
```

#### On Web Server 1 (192.168.1.101):
```bash
# Generate config
./scripts/generate-remote-promtail-config.sh 192.168.1.100 web-01

# Start Promtail
docker-compose -f docker-compose.promtail-remote.yml up -d
```

#### On Web Server 2 (192.168.1.102):
```bash
./scripts/generate-remote-promtail-config.sh 192.168.1.100 web-02
docker-compose -f docker-compose.promtail-remote.yml up -d
```

#### On Database Server (192.168.1.103):
```bash
./scripts/generate-remote-promtail-config.sh 192.168.1.100 db-01
docker-compose -f docker-compose.promtail-remote.yml up -d
```

## Querying in Grafana

Once set up, query logs by server:

```logql
# All logs from web-01
{server="web-01"}

# Error logs from all web servers
{server=~"web-.*"} |= "error"

# Logs from specific container across all servers
{container="api", server=~".+"}

# Compare database logs across servers
{container="postgres", server=~"db-.*"}
```

## Network Checklist

- [ ] Central Loki server has port 3100 open (firewall)
- [ ] Remote servers can reach central server on port 3100
- [ ] Promtail on remote servers has access to Docker socket
- [ ] Promtail on remote servers can read container logs

## Troubleshooting

### Test Network Connectivity

From remote server to central server:
```bash
# Test if Loki is reachable
curl http://<LOKI_IP>:3100/ready

# Should return: ready
```

### Check Promtail Status

```bash
# Check if Promtail is running
docker ps | grep promtail

# Check Promtail logs
docker logs promtail-remote

# Check Promtail metrics
curl http://localhost:9080/metrics
```

### Check Loki is Receiving Logs

On central server:
```bash
# Check Loki logs for incoming connections
docker logs loki | grep -i push

# Check Loki metrics
curl http://localhost:3100/metrics | grep loki_distributor_received_lines_total
```

### Verify in Grafana

1. Go to Explore in Grafana
2. Select Loki datasource
3. Query: `{server="<SERVER_NAME>"}`
4. You should see logs from that server

## Security Recommendations

1. **Use Private Network**: Deploy on private/local network, not public internet
2. **Firewall Rules**: Restrict port 3100 to known server IPs
3. **Authentication**: Enable Loki auth for production (see main README)
4. **TLS**: Use HTTPS/TLS for log transmission in production
5. **VPN**: Consider VPN for remote servers outside local network

## Advanced: Custom Log Paths

To collect logs from non-Docker sources, edit `promtail-config-remote.yml` and add:

```yaml
scrape_configs:
  # ... existing docker config ...
  
  - job_name: application-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: application
          server: SERVER_NAME
          __path__: /var/log/app/*.log
```

Then mount the log directory in `docker-compose.promtail-remote.yml`:
```yaml
volumes:
  - /var/log/app:/var/log/app:ro
```
