---
name: mysql-selfhosted
description: >
  Set up Datadog Database Monitoring for self-hosted MySQL instances.
  Covers MySQL 8.4 LTS master-slave replication on EC2 with
  Terraform provisioning and setup scripts.
category: database-selfhosted
requires: [aws-ec2]
supported_versions:
  mysql_version: [8.4]
---

## Overview

The mysql-selfhosted plugin provides skills for deploying self-hosted MySQL instances and configuring Datadog Database Monitoring. Includes Terraform scripts for EC2 provisioning and bash scripts for MySQL installation, master-slave replication setup, and replication testing.

## Prerequisites

- AWS account with EC2 permissions (see aws-ec2 plugin)
- AWS CLI configured
- Terraform >= 1.0
- SSH key pair in the target AWS region
- Datadog API key

## Skills

### setup-mysql
Provision two EC2 instances and set up MySQL 8.4 LTS master-slave replication using Terraform and shell scripts. Includes automated MySQL installation, replication configuration, and testing.

## Recommended Skill Order

1. setup-mysql

## Compatibility Notes

Tested with MySQL 8.4.6 LTS on Ubuntu 22.04 in ap-southeast-1. Uses public subnets for simplicity (no bastion hosts).
