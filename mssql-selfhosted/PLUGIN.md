---
name: mssql-selfhosted
description: >
  Set up Datadog Database Monitoring for self-hosted Microsoft SQL
  Server. Covers SQL Server on Windows Server (Azure VM) or Linux
  (EC2/Azure VM) with Datadog DBM for query metrics, explain plans,
  and activity monitoring.
category: database-selfhosted
requires: [aws-ec2, azure-vm]
supported_versions:
  mssql_version: [2019, 2022]
---

## Overview

The mssql-selfhosted plugin provides skills for deploying self-hosted Microsoft SQL Server instances and configuring Datadog Database Monitoring. Supports two deployment paths: Windows Server (provisioned via Azure VM with Bicep) and Linux (provisioned via EC2 with Terraform or Azure VM). The PoC requirement determines which OS path to follow.

## Prerequisites

- For Windows Server: Azure subscription (see azure-vm plugin)
- For Linux: AWS account with EC2 permissions (see aws-ec2 plugin) or Azure subscription
- Datadog API key

## Skills

Skills are created based on the PoC requirement using the TODO file as a prompt. Typical skills include:

- `setup-mssql-windows/` — Provision Windows Server VM + install SQL Server
- `setup-mssql-linux/` — Provision Linux VM + install SQL Server from Microsoft repos
- `install-dd-dbm/` — Configure Datadog Agent with SQL Server DBM integration

## Recommended Skill Order

1. setup-mssql-{os} (provision the VM and install SQL Server)
2. install-dd-dbm (configure Datadog Database Monitoring)

## Compatibility Notes

SQL Server 2019 and 2022 are supported. Windows Server deployment uses Bicep (azure-vm prerequisite). Linux deployment uses Terraform (aws-ec2 prerequisite). The Datadog Agent SQL Server integration works on both platforms.
