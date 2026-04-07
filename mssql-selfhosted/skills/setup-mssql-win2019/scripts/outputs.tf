output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.jek_mssql_server.id
}

output "public_ip" {
  description = "Public IP for RDP and SQL Server access"
  value       = aws_instance.jek_mssql_server.public_ip
}

output "rdp_command" {
  description = "RDP connection info"
  value       = "Connect via RDP to ${aws_instance.jek_mssql_server.public_ip}:3389 (Administrator / get password from AWS Console using key pair)"
}

output "sql_connection" {
  description = "SQL Server connection string"
  value       = "Server=${aws_instance.jek_mssql_server.public_ip},1433;Database=jek-database-pgw;User Id=sa;Password=<from_tfvars>"
  sensitive   = true
}
