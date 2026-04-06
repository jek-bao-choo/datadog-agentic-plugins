---
name: setup-ec2
description: >-
  Use this skill whenever the user needs to provision an EC2 instance for Datadog monitoring.
  Triggers on mentions of EC2 setup, EC2 provisioning, Terraform EC2, AWS VM setup, or
  preparing an EC2 instance for agent installation. Also applies when the user wants to
  create infrastructure on AWS for a Datadog PoC.
version: 0.1.0
version_matrix:
  ami: [ubuntu-22.04]
---

# EC2 Instance Setup

Provision and configure an EC2 instance on AWS for Datadog monitoring. Includes Terraform scripts for automated infrastructure provisioning.

## Prerequisites

- AWS account with EC2 permissions
- AWS CLI configured or Terraform installed
- SSH key pair for instance access

## Instructions

### Option A: Terraform (recommended)

Use the bundled Terraform scripts in `scripts/` to provision the EC2 instance with all required networking (VPC, subnet, security group, internet gateway).

```bash
cd scripts/
terraform init
terraform plan
terraform apply
```

The Terraform configuration creates:
- VPC with public subnet
- Internet Gateway and route table
- Security group (SSH + HTTP + HTTPS inbound, all outbound)
- EC2 instance with Ubuntu 22.04 AMI
- Key pair for SSH access

See `scripts/variables.tf` for configurable parameters and `scripts/outputs.tf` for the instance's public IP.

### Option B: AWS Console / CLI

1. Launch an EC2 instance with Ubuntu 22.04 AMI
2. Ensure the security group allows:
   - Inbound: SSH (22), HTTP (80), HTTPS (443)
   - Outbound: All traffic (for Datadog agent to reach `*.datadoghq.com`)
3. Note the instance's public IP and SSH key

## Validation

```bash
# Verify SSH access
ssh -i <KEY_PATH> ubuntu@<EC2_PUBLIC_IP> 'echo "SSH connection successful"'

# Verify outbound connectivity to Datadog
ssh -i <KEY_PATH> ubuntu@<EC2_PUBLIC_IP> 'curl -s -o /dev/null -w "%{http_code}" https://api.datadoghq.com'
# Expected: 200 or 403 (reachable)
```

## Troubleshooting

### Cannot SSH into instance
**Cause:** Security group missing SSH inbound rule, or wrong key pair.
**Fix:** Add TCP port 22 inbound rule. Verify the key pair matches.

### Instance cannot reach Datadog endpoints
**Cause:** No internet gateway or outbound rules blocking HTTPS.
**Fix:** Ensure the VPC has an internet gateway and the security group allows all outbound traffic.
