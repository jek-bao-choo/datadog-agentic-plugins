variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "m5.xlarge"
}

variable "key_name" {
  description = "AWS key pair name for RDP access"
  type        = string
  default     = "jek_rsa_pem"
}

variable "sql_sa_password" {
  description = "SQL Server SA password"
  type        = string
  sensitive   = true
}

variable "dd_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}
