# Build and run script for the monitoring stack (PowerShell)

param(
    [string]$ImageTag = "latest"
)

$ImageName = "qortex-loki-grafana"
$FullImageName = "${ImageName}:${ImageTag}"

Write-Host "Building Docker image: $FullImageName" -ForegroundColor Green

# Build the image
docker build -t $FullImageName .

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Image built successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "To run the container, use:" -ForegroundColor Yellow
    Write-Host "  docker run -d \"
    Write-Host "    --name monitoring-stack \"
    Write-Host "    -p 3000:3000 \"
    Write-Host "    -p 3100:3100 \"
    Write-Host "    -p 9080:9080 \"
    Write-Host "    -v /var/run/docker.sock:/var/run/docker.sock:ro \"
    Write-Host "    -v /var/lib/docker/containers:/var/lib/docker/containers:ro \"
    Write-Host "    -v loki-data:/loki \"
    Write-Host "    -v grafana-data:/var/lib/grafana \"
    Write-Host "    $FullImageName"
    Write-Host ""
    Write-Host "Or use docker-compose:" -ForegroundColor Yellow
    Write-Host "  docker-compose -f docker-compose.deploy.yml up -d"
} else {
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
