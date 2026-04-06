---
name: aws-rds-mysql
description: >
  Set up Datadog Database Monitoring for Amazon RDS MySQL.
  Covers RDS MySQL 8.4 provisioning with read replicas
  via Terraform.
category: database-managed
requires: []
supported_versions:
  mysql_version: [8.4]
---

## Overview

The aws-rds-mysql plugin provides skills for provisioning Amazon RDS MySQL instances and configuring Datadog Database Monitoring. Includes Terraform scripts for creating a primary instance with a read replica in a custom VPC.

## Prerequisites

- AWS account with RDS, VPC, and EC2 permissions
- AWS CLI configured
- Terraform >= 1.0
- Datadog API key

## Skills

### setup-rds-mysql
Provision an Amazon RDS MySQL 8.4 primary instance with a read replica using Terraform. Includes VPC, subnets, security groups, and parameter groups.

## Recommended Skill Order

1. setup-rds-mysql

## Compatibility Notes

Tested with MySQL 8.4 LTS in ap-southeast-1. The primary instance deploys in AZ-a and the read replica in AZ-b.
