# PowerShell script to generate Promtail configuration for remote servers

param(
    [Parameter(Mandatory=$true)]
    [string]$LokiHost,
    
    [Parameter(Mandatory=$true)]
    [string]$ServerName,
    
    [string]$OutputFile = "promtail-config-remote.yml"
)

$TemplateFile = "promtail-config-remote.yml"

if (-not (Test-Path $TemplateFile)) {
    Write-Host "Error: Template file '$TemplateFile' not found" -ForegroundColor Red
    exit 1
}

Write-Host "Generating Promtail configuration..." -ForegroundColor Green
Write-Host "  Loki Host: $LokiHost"
Write-Host "  Server Name: $ServerName"
Write-Host "  Output File: $OutputFile"
Write-Host ""

# Read template and replace placeholders
$content = Get-Content $TemplateFile -Raw
$content = $content -replace 'LOKI_HOST', $LokiHost
$content = $content -replace 'SERVER_NAME', $ServerName

# Write output file
Set-Content -Path $OutputFile -Value $content

Write-Host "Configuration generated successfully: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Review the generated configuration"
Write-Host "  2. Copy it to your remote server"
Write-Host "  3. Start Promtail: docker-compose -f docker-compose.promtail-remote.yml up -d"
