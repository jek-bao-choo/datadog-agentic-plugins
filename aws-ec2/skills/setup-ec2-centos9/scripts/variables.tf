variable "region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "ap-southeast-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "Existing AWS key pair name for SSH access"
  type        = string
  default     = "jek_rsa_pem"
}

variable "storage_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "jek"
}

variable "owner_tag" {
  description = "Owner tag for resources"
  type        = string
  default     = "jek"
}

variable "env_tag" {
  description = "Environment tag for resources"
  type        = string
  default     = "test"
}

variable "ssh_user" {
  description = "SSH username for the CentOS Stream 9 AMI (owner 125523088429). Confirmed: ec2-user."
  type        = string
  default     = "ec2-user"
}
