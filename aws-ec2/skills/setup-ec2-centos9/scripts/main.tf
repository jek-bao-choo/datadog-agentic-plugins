terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

# =============================================================================
# AMI: CentOS Stream 9 (official)
# Default SSH user: ec2-user
# If no CentOS Stream 9 AMI is found, change the filter to
# "CentOS Stream 8 x86_64 *" as a fallback.
# =============================================================================
data "aws_ami" "centos9" {
  most_recent = true
  owners      = ["125523088429"] # CentOS official

  filter {
    name   = "name"
    values = ["CentOS Stream 9 x86_64 *"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Auto-detect current IP for security group rules
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# =============================================================================
# Detect existing shared resources (created by setup-ec2 or other skills).
# VPC and subnet are reused if found. IGW is looked up from the reused VPC.
# Route table and security group are ALWAYS created by this skill to avoid
# dependency on shared resources that may have been partially destroyed.
# =============================================================================

data "aws_vpcs" "existing" {
  tags = {
    Name = "${var.name_prefix}-vpc"
  }
}

locals {
  vpc_exists = length(data.aws_vpcs.existing.ids) > 0
  vpc_id     = local.vpc_exists ? data.aws_vpcs.existing.ids[0] : aws_vpc.main[0].id
}

# Look up subnet within existing VPC
data "aws_subnets" "existing" {
  count = local.vpc_exists ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.existing.ids[0]]
  }

  tags = {
    Name = "${var.name_prefix}-public-subnet"
  }
}

# Look up IGW attached to existing VPC (needed for route table)
data "aws_internet_gateway" "existing" {
  count = local.vpc_exists ? 1 : 0

  filter {
    name   = "attachment.vpc-id"
    values = [data.aws_vpcs.existing.ids[0]]
  }
}

# Look up shared SG within existing VPC
data "aws_security_groups" "existing" {
  count = local.vpc_exists ? 1 : 0

  filter {
    name   = "vpc-id"
    values = [data.aws_vpcs.existing.ids[0]]
  }

  tags = {
    Name = "${var.name_prefix}-ec2-sg"
  }
}

locals {
  subnet_exists = local.vpc_exists && length(try(data.aws_subnets.existing[0].ids, [])) > 0
  subnet_id     = local.subnet_exists ? data.aws_subnets.existing[0].ids[0] : aws_subnet.public[0].id

  igw_id = local.vpc_exists ? data.aws_internet_gateway.existing[0].id : aws_internet_gateway.main[0].id

  sg_exists    = local.vpc_exists && length(try(data.aws_security_groups.existing[0].ids, [])) > 0
  shared_sg_id = local.sg_exists ? data.aws_security_groups.existing[0].ids[0] : null
}

# =============================================================================
# VPC + Networking (VPC, IGW, subnet only created if no existing shared VPC)
# =============================================================================

resource "aws_vpc" "main" {
  count = local.vpc_exists ? 0 : 1

  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name  = "${var.name_prefix}-vpc-centos9"
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

resource "aws_internet_gateway" "main" {
  count = local.vpc_exists ? 0 : 1

  vpc_id = aws_vpc.main[0].id

  tags = {
    Name  = "${var.name_prefix}-igw-centos9"
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

resource "aws_subnet" "public" {
  count = local.subnet_exists ? 0 : 1

  vpc_id                  = local.vpc_id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name  = "${var.name_prefix}-subnet-centos9"
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

# =============================================================================
# Route Table — always created and owned by this skill.
# Uses the IGW from the existing VPC or the newly created one.
# This ensures internet connectivity even if the shared route table was deleted.
# On terraform destroy: this route table is removed, subnet reverts to the
# VPC's main route table.
# =============================================================================
resource "aws_route_table" "centos9" {
  vpc_id = local.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = local.igw_id
  }

  tags = {
    Name  = "${var.name_prefix}-rt-centos9"
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

resource "aws_route_table_association" "centos9" {
  subnet_id      = local.subnet_id
  route_table_id = aws_route_table.centos9.id
}

# =============================================================================
# Security Group — always created, owned by this skill.
# If a shared SG (jek-ec2-sg) exists, BOTH are attached to the EC2 instance.
# terraform destroy removes only this SG — the shared SG is never touched.
# =============================================================================
resource "aws_security_group" "centos9" {
  name_prefix = "${var.name_prefix}-sg-centos9"
  vpc_id      = local.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "App ports 8081-8084"
    from_port   = 8081
    to_port     = 8084
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  ingress {
    description = "OTel OTLP gRPC and HTTP (4317-4318)"
    from_port   = 4317
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myip.response_body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "${var.name_prefix}-sg-centos9"
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}

# =============================================================================
# Key Pair (must already exist in AWS)
# =============================================================================
data "aws_key_pair" "main" {
  key_name = var.key_name
}

# =============================================================================
# EC2 Instance (always created)
# =============================================================================
resource "aws_instance" "main" {
  ami                    = data.aws_ami.centos9.id
  instance_type          = var.instance_type
  key_name               = data.aws_key_pair.main.key_name
  vpc_security_group_ids = local.sg_exists ? [local.shared_sg_id, aws_security_group.centos9.id] : [aws_security_group.centos9.id]
  subnet_id              = local.subnet_id

  root_block_device {
    volume_type = "gp3"
    volume_size = var.storage_size
    encrypted   = true

    tags = {
      Name  = "${var.name_prefix}-root-volume-centos9"
      Owner = var.owner_tag
      Env   = var.env_tag
    }
  }

  user_data = <<-USERDATA
    #!/bin/bash
    set -euxo pipefail

    # Java 17
    dnf install -y java-17-openjdk java-17-openjdk-devel

    # Maven (try repo first, manual fallback)
    dnf install -y maven || {
      curl -sL https://dlcdn.apache.org/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz | tar xz -C /opt
      ln -sf /opt/apache-maven-3.9.9/bin/mvn /usr/local/bin/mvn
    }

    # Git
    dnf install -y git

    echo "user_data setup complete" > /tmp/user_data_done
  USERDATA

  tags = {
    Name  = "${var.name_prefix}-ec2-centos9"
    Owner = var.owner_tag
    Env   = var.env_tag
  }
}
