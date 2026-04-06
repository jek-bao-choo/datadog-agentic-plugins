---
name: setup-mysql
description: >-
  Use this skill whenever the user needs to set up self-hosted MySQL with replication on
  EC2 instances. Triggers on mentions of MySQL master-slave, MySQL replication setup,
  self-hosted MySQL on EC2, Terraform MySQL, or MySQL 8.4 installation. Also applies
  when the user wants to create a MySQL environment for Datadog DBM testing.
version: 0.1.0
version_matrix:
  mysql_version: [8.4]
---

# MySQL 8.4 Master-Slave Replication on EC2

Provision two EC2 instances and set up MySQL 8.4 LTS master-slave replication using Terraform and shell scripts.

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0
- SSH key pair in the target AWS region

## Instructions

The complete setup is documented in `README.md`. Two phases:

### Phase 1: Provision infrastructure

The Terraform scripts in `scripts/` create 2 EC2 instances (master and slave) with public IPs:

```bash
cd scripts/
terraform init
terraform plan
terraform apply
```

### Phase 2: Install and configure MySQL

Use the bundled shell scripts:

```bash
# Install MySQL 8.4 on both instances
bash scripts/install-mysql.sh

# Configure the master
bash scripts/setup-master.sh

# Configure the slave
bash scripts/setup-slave.sh

# Test replication
bash scripts/test-replication.sh
```

## Validation

```bash
# On the master: verify replication is active
mysql -u root -p -e "SHOW MASTER STATUS\G"

# On the slave: verify replication is running
mysql -u root -p -e "SHOW REPLICA STATUS\G"
# Check: Replica_IO_Running = Yes, Replica_SQL_Running = Yes

# Test: create a table on master, verify it appears on slave
```

## Troubleshooting

### Replication not starting on slave
**Cause:** Incorrect master host, port, or credentials in replication config.
**Fix:** Run `SHOW REPLICA STATUS\G` on the slave and check `Last_Error`. Reconfigure with correct master details.

### MySQL installation fails
**Cause:** apt repository not configured for MySQL 8.4.
**Fix:** Run `scripts/install-mysql.sh` which adds the MySQL APT repository automatically.
