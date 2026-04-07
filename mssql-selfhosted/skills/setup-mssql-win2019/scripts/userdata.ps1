<powershell>
# userdata.ps1 — Install SQL Server 2019 Express on Windows Server 2019
# This runs automatically on first boot via EC2 user data

$logFile = "C:\setup\userdata.log"
New-Item -ItemType Directory -Force -Path "C:\setup" | Out-Null
Start-Transcript -Path $logFile

Write-Host "=== Starting SQL Server 2019 setup ==="

# Install Chocolatey
Write-Host "Installing Chocolatey..."
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install SQL Server 2019 Express
Write-Host "Installing SQL Server 2019 Express..."
choco install sql-server-express -y --params="'/INSTANCENAME=MSSQLSERVER /SECURITYMODE=SQL /SAPWD=${sql_sa_password}'"

# Install SQL Server command-line tools
Write-Host "Installing sqlcmd..."
choco install sqlserver-cmdlineutils -y

# Wait for SQL Server to be ready
Write-Host "Waiting for SQL Server service..."
Start-Sleep -Seconds 30

# Enable TCP/IP
Write-Host "Enabling TCP/IP on port 1433..."
Import-Module SQLPS -DisableNameChecking
$smo = 'Microsoft.SqlServer.Management.Smo.'
$wmi = New-Object ($smo + 'Wmi.ManagedComputer')
$tcp = $wmi.GetSmoObject("ManagedComputer[@Name='$env:COMPUTERNAME']/ServerInstance[@Name='MSSQLSERVER']/ServerProtocol[@Name='Tcp']")
$tcp.IsEnabled = $true
$tcp.Alter()

# Set TCP port to 1433
$ipAll = $tcp.IPAddresses | Where-Object { $_.Name -eq 'IPAll' }
$ipAll.IPAddressProperties['TcpPort'].Value = '1433'
$ipAll.IPAddressProperties['TcpDynamicPorts'].Value = ''
$tcp.Alter()

# Restart SQL Server to apply TCP/IP changes
Restart-Service MSSQLSERVER -Force

# Open firewall for SQL Server
Write-Host "Opening firewall port 1433..."
New-NetFirewallRule -DisplayName "SQL Server 1433" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

# Copy setup SQL scripts (these will be uploaded via RDP or S3)
# Placeholder paths — user will copy files after RDP
Write-Host "Setup scripts should be placed in C:\setup\"
Write-Host "  - setup-mssql.sql (create database + tables + seed data)"
Write-Host "  - setup-dbm-user.sql (create Datadog monitoring user)"
Write-Host "  - install-dd-agent.ps1 (install Datadog Agent)"

# Store DD API key for later use
"DD_API_KEY=${dd_api_key}" | Out-File "C:\setup\.env" -Encoding UTF8

Write-Host "=== SQL Server 2019 setup complete ==="
Write-Host "Connect via: sqlcmd -S localhost -U sa -P <password> -Q 'SELECT @@VERSION'"

Stop-Transcript
</powershell>
