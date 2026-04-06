---
name: setup-rds-mysql
description: >-
  Use this skill whenever the user needs to provision an Amazon RDS MySQL instance.
  Triggers on mentions of RDS MySQL setup, Amazon RDS provisioning, Terraform RDS,
  MySQL read replica on AWS, or managed MySQL on AWS. Also applies when the user wants
  to create a database for Datadog DBM testing.
version: 0.1.0
version_matrix:
  mysql_version: [8.4]
---

# Amazon RDS MySQL 8.4 Setup via Terraform

Provision an Amazon RDS MySQL 8.4 primary instance with a read replica using Terraform.

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0
- AWS permissions for RDS, VPC, and EC2

## Instructions

The complete setup is documented in `README.md`. The Terraform scripts in `scripts/` create:

- Custom VPC with public subnets across 2 AZs
- Security group allowing MySQL access (port 3306)
- RDS MySQL 8.4 LTS primary instance in AZ-a
- Read replica in AZ-b

```bash
cd scripts/
terraform init
terraform plan
terraform apply
```

## Validation

```bash
# Get the RDS endpoint from Terraform output
terraform output rds_endpoint

# Connect to MySQL
mysql -h <RDS_ENDPOINT> -u <USERNAME> -p

# Verify replication status on read replica
mysql -h <REPLICA_ENDPOINT> -u <USERNAME> -p -e "SHOW REPLICA STATUS\G"
```

## Troubleshooting

### Cannot connect to RDS instance
**Cause:** Security group not allowing inbound MySQL (3306) from your IP.
**Fix:** Update the security group to allow your IP or CIDR range on port 3306.

### Read replica lag is high
**Cause:** Primary instance under heavy write load or network latency.
**Fix:** Monitor `ReplicaLag` CloudWatch metric. Consider upgrading instance class.
