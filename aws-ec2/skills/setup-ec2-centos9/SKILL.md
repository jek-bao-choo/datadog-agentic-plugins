---
name: setup-ec2-centos9
description: >-
  Provision a CentOS Stream 9 EC2 instance in ap-southeast-1 with Java 17 and Maven.
  Includes Terraform scripts for VPC, subnet, security group, route table, and EC2 with
  user_data. Reuses existing shared VPC and subnet (jek-vpc, jek-public-subnet) if present;
  always creates its own route table (jek-rt-centos9) and security group (jek-sg-centos9)
  to avoid modifying shared resources.
version: 0.1.0
version_matrix:
  ami: [centos-stream-9]
  ssh_user: ec2-user
---

# CentOS Stream 9 EC2 Setup

Provision a CentOS Stream 9 EC2 instance on AWS with Java 17 and Maven pre-installed via user_data. SSH user: `ec2-user`.

## Prerequisites

- AWS account with EC2/VPC permissions in ap-southeast-1
- Terraform >= 1.0 installed
- SSH key `jek_rsa_pem` exists in AWS ap-southeast-1 and locally at `~/.ssh/jek_rsa_pem`

## Instructions

```bash
cd scripts/
terraform init
terraform plan    # Check which AMI is selected and whether VPC is reused
terraform apply
```

## What gets created

- VPC with public subnet (or reuses existing `jek-vpc` / `jek-public-subnet`)
- Route table `jek-rt-centos9` with internet gateway route (always created)
- Security group `jek-sg-centos9` with SSH, app ports, OTel ports (always created)
- CentOS Stream 9 EC2 (t3.large, 30GB gp3) named `jek-ec2-centos9`
- user_data installs: Java 17, Maven, git

## Validation

```bash
ssh-add ~/.ssh/jek_rsa_pem
ssh ec2-user@$(terraform output -raw instance_public_ip)

# Verify software (wait 2-3 min for user_data to finish)
cat /tmp/user_data_done
java --version
mvn --version
```

## Teardown

```bash
cd scripts/
terraform destroy
```
