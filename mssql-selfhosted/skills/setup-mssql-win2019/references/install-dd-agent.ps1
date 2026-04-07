# install-dd-agent.ps1 — Install Datadog Agent on Windows Server
# Run as Administrator in PowerShell
# Reference: https://docs.datadoghq.com/agent/basic_agent_usage/windows/

# Read DD_API_KEY from .env
$envFile = "C:\setup\.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match "^DD_API_KEY=(.+)$") {
            $env:DD_API_KEY = $matches[1]
        }
    }
}

if (-not $env:DD_API_KEY) {
    Write-Host "ERROR: DD_API_KEY not found. Set it in C:\setup\.env or as environment variable."
    exit 1
}

Write-Host "Installing Datadog Agent with DD_SITE=datadoghq.com..."

# Download and install Datadog Agent MSI
$msiUrl = "https://s3.amazonaws.com/ddagent-windows-stable/datadog-agent-7-latest.amd64.msi"
$msiPath = "C:\setup\datadog-agent.msi"

Write-Host "Downloading Datadog Agent..."
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath

Write-Host "Installing..."
Start-Process msiexec.exe -Wait -ArgumentList @(
    "/qn",
    "/i", $msiPath,
    "APIKEY=$env:DD_API_KEY",
    "SITE=datadoghq.com",
    "HOSTNAME=jek-mssql-win2019",
    "TAGS=env:sandbox,service:jek-mssql-pgw,team:jek"
)

Write-Host "Datadog Agent installed."
Write-Host "Verify with: & 'C:\Program Files\Datadog\Datadog Agent\bin\agent.exe' status"
