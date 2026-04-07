# MS SQL Server on EC2 Windows Server 2019

## Prerequisites

- AWS CLI configured (`aws configure`)
- Terraform >= 1.0
- RDP client (Microsoft Remote Desktop on Mac)
- Datadog API key
- AWS key pair: `jek_rsa_pem` (RSA, may be passphrase-protected)

## Tech Stack

| Component | Version | Notes |
|---|---|---|
| Windows Server | 2019 | EC2 AMI |
| SQL Server | 2022 Express | Chocolatey installs latest (2022) — DBM works the same |
| EC2 Instance | m5.xlarge | |
| Region | ap-southeast-1 | |
| Datadog Agent | 7 (latest) | |
| SQL Instance | Named: `SQLEXPRESS` | Use `localhost\SQLEXPRESS` everywhere |

## Step-by-Step

### 1. Provision EC2 Instance

```bash
cd scripts/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set sql_sa_password, dd_api_key
terraform init
terraform plan
terraform apply
```

### 2. Get Windows Admin Password

Passphrase-protected key workaround (both AWS CLI and Console require unencrypted key):

```bash
openssl rsa -in ~/.ssh/jek_rsa_pem -out /tmp/jek_tmp.pem
aws ec2 get-password-data \
  --instance-id $(terraform output -raw instance_id) \
  --priv-launch-key /tmp/jek_tmp.pem \
  --query 'PasswordData' --output text
rm -f /tmp/jek_tmp.pem
```

### 3. Connect via RDP

Connect to `<public_ip>:3389` with `Administrator` and the decrypted password.

### 4. Copy Setup Files via RDP Clipboard

SCP does not work on Windows Server 2019 out of the box. Use Notepad copy-paste:

For each file: Mac `cat file | pbcopy` → RDP Notepad → Ctrl+V → Save As (All Files, UTF-8).

Files to copy: `setup-mssql.sql`, `setup-dbm-user.sql`, `install-dd-agent.ps1`.

### 5. Enable SA Login

SQL Express installs in Windows Auth only mode:

```powershell
sqlcmd -S localhost\SQLEXPRESS -E -Q "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2"
sqlcmd -S localhost\SQLEXPRESS -E -Q "ALTER LOGIN sa ENABLE; ALTER LOGIN sa WITH PASSWORD = '<SA_PASSWORD>';"
Restart-Service 'MSSQL$SQLEXPRESS'
```

### 6. Run Database Setup

```powershell
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -i C:\setup\setup-mssql.sql
```

### 7. Enable TCP/IP for Datadog Agent

```powershell
Set-Service -Name "SQLBrowser" -StartupType Automatic
Start-Service SQLBrowser
$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
Set-ItemProperty -Path $regPath -Name "TcpPort" -Value "1433"
Set-ItemProperty -Path $regPath -Name "TcpDynamicPorts" -Value ""
$tcpPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"
Set-ItemProperty -Path $tcpPath -Name "Enabled" -Value 1
Restart-Service 'MSSQL$SQLEXPRESS'
```

### 8. Install Datadog Agent

```powershell
powershell -ExecutionPolicy Bypass -File C:\setup\install-dd-agent.ps1
```

### 9. Create DBM User (use strong password for Windows policy)

```powershell
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -Q "CREATE LOGIN datadog WITH PASSWORD = '<DD_DBM_PASSWORD>'; GRANT CONNECT ANY DATABASE TO datadog; GRANT VIEW SERVER STATE TO datadog; GRANT VIEW ANY DEFINITION TO datadog;"
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -Q "USE [jek-database-pgw]; CREATE USER datadog FOR LOGIN datadog;"
```

### 10. Configure DBM Integration

Copy config via Notepad to `C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml`. Key: use `connector: odbc` with `driver: "{ODBC Driver 17 for SQL Server}"`, not adodbapi.

If BOM error, fix with:
```powershell
$c = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" -Raw
[System.IO.File]::WriteAllText("C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml", $c, (New-Object System.Text.UTF8Encoding $false))
```

### 11. Verify

```powershell
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" restart-service
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status | Select-String -Pattern "sqlserver" -Context 5
```

Expected: `sqlserver [OK]` with metrics and DBM metadata.

## Teardown

```bash
cd scripts/
terraform destroy
```
