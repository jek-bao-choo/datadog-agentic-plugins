---
name: setup-mssql-win2019
description: >-
  Use this skill to provision an EC2 Windows Server 2019 instance with MS SQL Server
  using Terraform, create a payment gateway database schema, seed with dummy data,
  and configure Datadog Database Monitoring (DBM). Triggers on mentions of MS SQL
  on Windows, SQL Server EC2 setup, or Windows database provisioning.
version: 0.2.0
version_matrix:
  mssql_version: [2022]
  os: [windows-server-2019]
---

# MS SQL Server on EC2 Windows Server 2019

Provision an EC2 instance running Windows Server 2019 with MS SQL Server Express installed (Chocolatey installs the latest available — currently 2022), create a payment gateway database schema, seed test data, and configure Datadog Database Monitoring.

> **Note:** Chocolatey's `sql-server-express` package installs SQL Server 2022 Express (not 2019). This is fine for prework — the DBM integration works identically across 2019 and 2022.

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0 installed
- Datadog API key (DD_API_KEY)
- DD_SITE: datadoghq.com (US1)
- RDP client (Microsoft Remote Desktop on Mac)
- AWS key pair: `jek_rsa_pem` (RSA, may be passphrase-protected)

## Instructions

### Phase 1: Provision Infrastructure

```bash
cd scripts/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: set sql_sa_password, dd_api_key
terraform init
terraform plan
terraform apply
```

### Phase 2: Get Windows Password and RDP In

The Windows admin password takes ~4 minutes after launch to become available.

**If your SSH key is passphrase-protected** (both `aws ec2 get-password-data` and the AWS Console require an unencrypted key):

```bash
openssl rsa -in ~/.ssh/jek_rsa_pem -out /tmp/jek_tmp.pem
aws ec2 get-password-data \
  --instance-id $(terraform output -raw instance_id) \
  --priv-launch-key /tmp/jek_tmp.pem \
  --query 'PasswordData' --output text
rm -f /tmp/jek_tmp.pem
```

Connect via RDP to `<public_ip>:3389` with `Administrator` and the decrypted password.

### Phase 3: Copy Setup Files via RDP Clipboard

**SCP does not work** on Windows Server 2019 out of the box (OpenSSH server not enabled, port 22 not in security group). Use the RDP clipboard method instead:

For each file, on your **Mac**:
```bash
cat ../references/setup-mssql.sql | pbcopy
```
Then in the **RDP session**: open Notepad → Ctrl+V → verify full content → File > Save As → `C:\setup\setup-mssql.sql` (Save as type: All Files, Encoding: UTF-8)

> **Important:** Do NOT use PowerShell `Set-Content -Value (Get-Clipboard)` — it truncates multi-line content. Always use Notepad for multi-line clipboard paste.

Repeat for: `setup-dbm-user.sql`, `install-dd-agent.ps1`.

Verify in PowerShell:
```powershell
Get-ChildItem C:\setup\*.sql, C:\setup\*.yaml, C:\setup\*.ps1 | Format-Table Name, Length
```
Expected: `setup-mssql.sql` ~3000+, `setup-dbm-user.sql` ~900+, `install-dd-agent.ps1` ~1300+

### Phase 4: Enable SA Login and Configure Database

Chocolatey installs SQL Server Express as a **named instance** (`SQLEXPRESS`) in **Windows Authentication only** mode. You must enable Mixed Mode and the SA login manually.

```powershell
# 1. Verify SQL Server is running
Get-Service -Name "MSSQL*"
# Expected: MSSQL$SQLEXPRESS Running

# 2. Connect with Windows auth and enable Mixed Mode
sqlcmd -S localhost\SQLEXPRESS -E -Q "EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'LoginMode', REG_DWORD, 2"

# 3. Enable SA login and set password
sqlcmd -S localhost\SQLEXPRESS -E -Q "ALTER LOGIN sa ENABLE; ALTER LOGIN sa WITH PASSWORD = '<SA_PASSWORD>';"

# 4. Restart SQL Server (quote the $ to avoid PowerShell variable expansion)
Restart-Service 'MSSQL$SQLEXPRESS'

# 5. Test SA login
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -Q "SELECT @@VERSION"
```

Then run the database setup:
```powershell
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -i C:\setup\setup-mssql.sql
```

Verify:
```powershell
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -Q "USE [jek-database-pgw]; SELECT COUNT(*) AS rows_count FROM [jek-table-transactions];"
# Expected: 100
```

### Phase 5: Enable TCP/IP for Datadog Agent

The Datadog Agent connects to SQL Server via TCP. SQL Server Express defaults to Named Pipes only. Enable TCP on port 1433:

```powershell
# Start SQL Server Browser (required for named instances)
Set-Service -Name "SQLBrowser" -StartupType Automatic
Start-Service SQLBrowser

# Enable TCP/IP and set port 1433
$regPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp\IPAll"
Set-ItemProperty -Path $regPath -Name "TcpPort" -Value "1433"
Set-ItemProperty -Path $regPath -Name "TcpDynamicPorts" -Value ""

$tcpPath = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQLServer\SuperSocketNetLib\Tcp"
Set-ItemProperty -Path $tcpPath -Name "Enabled" -Value 1

# Restart SQL Server
Restart-Service 'MSSQL$SQLEXPRESS'

# Verify TCP is listening
netstat -an | Select-String "1433"
# Expected: 0.0.0.0:1433 LISTENING
```

### Phase 6: Install Datadog Agent and Configure DBM

```powershell
# 1. Install Agent
powershell -ExecutionPolicy Bypass -File C:\setup\install-dd-agent.ps1

# 2. Create DBM monitoring user (use a password that meets Windows complexity policy)
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -Q "CREATE LOGIN datadog WITH PASSWORD = '<DD_DBM_PASSWORD>'; GRANT CONNECT ANY DATABASE TO datadog; GRANT VIEW SERVER STATE TO datadog; GRANT VIEW ANY DEFINITION TO datadog;"
sqlcmd -S localhost\SQLEXPRESS -U sa -P '<SA_PASSWORD>' -Q "USE [jek-database-pgw]; CREATE USER datadog FOR LOGIN datadog;"
```

> **Note:** The `setup-dbm-user.sql` script may fail with "Password validation failed" if the password doesn't meet Windows complexity policy. Use the manual commands above with a strong password (uppercase + lowercase + number + special char, 8+ chars).

**3. Create the Agent SQL Server config** — on your Mac:

```bash
cat /tmp/conf.yaml | pbcopy
```

In RDP Notepad → Ctrl+V → Save As `C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml` (All Files, UTF-8).

The config uses the **ODBC connector** (not adodbapi) which handles named instances correctly:

```yaml
init_config:

instances:
  - host: localhost\SQLEXPRESS
    username: datadog
    password: <DD_DBM_PASSWORD>
    connector: odbc
    driver: "{ODBC Driver 17 for SQL Server}"
    database: jek-database-pgw
    dbm: true
    collect_settings:
      enabled: true
    query_samples:
      enabled: true
    query_activity:
      enabled: true
    tags:
      - env:sandbox
      - service:jek-mssql-pgw
      - team:jek
```

> **Important:** If saving from Notepad, the file may include a UTF-8 BOM that the Agent can't parse (`yaml: invalid leading UTF-8 octet`). Fix with:
> ```powershell
> $content = Get-Content "C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml" -Raw
> [System.IO.File]::WriteAllText("C:\ProgramData\Datadog\conf.d\sqlserver.d\conf.yaml", $content, (New-Object System.Text.UTF8Encoding $false))
> ```

**4. Restart and verify:**

```powershell
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" restart-service
& "C:\Program Files\Datadog\Datadog Agent\bin\agent.exe" status | Select-String -Pattern "sqlserver" -Context 5
```

Expected: `sqlserver` check shows `[OK]` with metric samples and DBM metadata.

## Validation

In Datadog UI:
- **Infrastructure > Host Map** — `jek-mssql-win2019` appears
- **Database Monitoring > Query Metrics** — `jek-database-pgw` queries visible

## Troubleshooting

### Chocolatey installs SQL Server 2022 instead of 2019
**Cause:** The `sql-server-express` Chocolatey package installs the latest available version.
**Not a problem:** DBM works identically on 2019 and 2022. Proceed as normal.

### SQL Server installed as named instance (SQLEXPRESS)
**Cause:** Chocolatey's SQL Server Express installs as `SQLEXPRESS` named instance, not the default instance.
**Fix:** Use `localhost\SQLEXPRESS` for all `sqlcmd` commands, not `localhost`.

### SA login fails ("Login failed for user 'sa'")
**Cause:** SQL Server was installed in Windows Authentication only mode. SA is disabled by default.
**Fix:** Connect with Windows auth (`-E`), enable Mixed Mode, enable SA login, set password, restart service. See Phase 4.

### Restart-Service fails ("Cannot find service name 'MSSQL'")
**Cause:** PowerShell interprets `$` in `MSSQL$SQLEXPRESS` as a variable.
**Fix:** Quote the service name: `Restart-Service 'MSSQL$SQLEXPRESS'`

### Password validation failed for DBM user
**Cause:** Windows password complexity policy requires uppercase + lowercase + numbers + special characters.
**Fix:** Use a strong password like `Dd-Dbm-2026!` instead of simple passwords.

### Agent error: "Provider cannot be found" (MSOLEDBSQL19)
**Cause:** The OLEDB driver is not installed, or the config references `MSOLEDBSQL19` which doesn't exist.
**Fix:** Use the ODBC connector instead of adodbapi. Set `connector: odbc` and `driver: "{ODBC Driver 17 for SQL Server}"` in conf.yaml.

### Agent error: "TCP-connection(ERROR: getaddrinfo failed)"
**Cause:** SQL Server Express doesn't listen on TCP by default. It uses Named Pipes only.
**Fix:** Enable TCP/IP, set static port 1433, start SQL Browser service, restart SQL Server. See Phase 5.

### Agent error: "yaml: invalid leading UTF-8 octet"
**Cause:** Notepad saves files with a UTF-8 BOM (Byte Order Mark) that the YAML parser can't handle.
**Fix:** Re-save without BOM: `[System.IO.File]::WriteAllText($path, $content, (New-Object System.Text.UTF8Encoding $false))`

### SCP hangs or fails
**Cause:** Windows Server 2019 doesn't have OpenSSH server enabled by default, and port 22 is not in the security group.
**Fix:** Use the RDP clipboard Notepad method instead of SCP. Copy with `pbcopy` on Mac, paste in Notepad on Windows.

### PowerShell Set-Content truncates clipboard content
**Cause:** `Set-Content -Value (Get-Clipboard)` only captures the last clipboard line.
**Fix:** Always use Notepad (Ctrl+V) for multi-line content, not PowerShell clipboard commands.

## Reference Files

- `scripts/main.tf` — Terraform: EC2 + security groups + user data
- `scripts/userdata.ps1` — PowerShell: install SQL Server via Chocolatey
- `references/setup-mssql.sql` — Create database, tables, seed 100 rows
- `references/setup-dbm-user.sql` — Create Datadog DBM monitoring user
- `references/datadog-sqlserver.yaml` — Agent SQL Server integration config (original template)
- `references/install-dd-agent.ps1` — Install Datadog Agent on Windows

## Teardown

```bash
# 1. Destroy EC2 instance and all AWS resources
cd scripts/
terraform destroy
# Takes ~5 minutes for Windows instances. Confirm with 'yes'.

# 2. Clean up local temp files
rm -f /tmp/jek_tmp.pem
```

Datadog cleanup:
- **Infrastructure > Host Map** → `jek-mssql-win2019` ages out ~2 hours after termination
- **Database Monitoring** → `jek-database-pgw` stops receiving new data automatically
