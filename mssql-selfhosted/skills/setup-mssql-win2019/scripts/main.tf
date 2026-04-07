# EC2 Windows Server 2019 with MS SQL 2019
# Resources prefixed with jek- for identification

# Auto-detect current IP for security group
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"
}

# Latest Windows Server 2019 AMI
data "aws_ami" "windows_2019" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC (use default)
data "aws_vpc" "default" {
  default = true
}

# Security Group
resource "aws_security_group" "jek_mssql_sg" {
  name        = "jek-mssql-win2019-sg"
  description = "Allow RDP and SQL Server access"
  vpc_id      = data.aws_vpc.default.id

  # RDP
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    description = "RDP from my IP"
  }

  # SQL Server
  ingress {
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
    description = "SQL Server from my IP"
  }

  # Datadog Agent outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound (Datadog, Windows Update, SQL Server install)"
  }

  tags = {
    Name  = "jek-mssql-win2019-sg"
    owner = "jek"
    env   = "test"
  }
}

# EC2 Instance
resource "aws_instance" "jek_mssql_server" {
  ami                    = data.aws_ami.windows_2019.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.jek_mssql_sg.id]

  # 100GB root volume for Windows + SQL Server
  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/userdata.ps1", {
    sql_sa_password = var.sql_sa_password
    dd_api_key      = var.dd_api_key
  })

  tags = {
    Name  = "jek-mssql-win2019"
    owner = "jek"
    env   = "test"
  }
}
