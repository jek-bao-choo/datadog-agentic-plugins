output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "vpc_id" {
  description = "ID of the VPC (existing or newly created)"
  value       = local.vpc_id
}

output "vpc_reused" {
  description = "Whether an existing VPC was reused"
  value       = local.vpc_exists
}

output "subnet_id" {
  description = "ID of the public subnet (existing or newly created)"
  value       = local.subnet_id
}

output "security_group_id" {
  description = "ID of the skill-specific security group (jek-sg-centos9)"
  value       = aws_security_group.centos9.id
}

output "shared_sg_reused" {
  description = "Whether the existing shared SG (jek-ec2-sg) was also attached to the instance"
  value       = local.sg_exists
}

output "ssh_connection_command" {
  description = "Command to connect to the instance via SSH"
  value       = "ssh -i ~/.ssh/jek_rsa_pem ${var.ssh_user}@${aws_instance.main.public_ip}"
}

output "instance_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "ami_id" {
  description = "AMI ID used — verify this is CentOS Stream 9"
  value       = data.aws_ami.centos9.id
}

output "ami_name" {
  description = "AMI name used — verify this is CentOS Stream 9"
  value       = data.aws_ami.centos9.name
}
