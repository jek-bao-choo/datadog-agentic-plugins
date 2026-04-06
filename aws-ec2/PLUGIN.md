---
name: aws-ec2
description: >
  Set up and instrument a Datadog-monitored environment on Amazon EC2.
  Covers EC2 instance provisioning via Terraform and Datadog Agent
  installation with syslog collection on Ubuntu.
category: infrastructure
requires: []
supported_versions:
  ami: [ubuntu-22.04]
---

## Overview

The aws-ec2 plugin provides skills for provisioning EC2 instances and setting up Datadog infrastructure monitoring. Covers Terraform-based provisioning (VPC, subnet, security group, EC2 instance) and Datadog Agent installation with log collection on Ubuntu 22.04.

## Prerequisites

- AWS account with EC2 permissions
- SSH key pair for instance access
- Datadog API key and site location
- Terraform (optional, for automated provisioning)

## Skills

### setup-ec2
Provision and configure an EC2 instance on AWS for Datadog monitoring. Includes Terraform scripts for automated infrastructure provisioning (VPC, subnet, security group, instance).

### install-dd-agent
Install the Datadog Agent on an Ubuntu EC2 instance, enable log collection, configure syslog forwarding, and verify telemetry in Datadog. Includes Ubuntu-specific reference instructions and validation scripts.

## Recommended Skill Order

1. setup-ec2
2. install-dd-agent

## Compatibility Notes

Currently supports Ubuntu 22.04 AMIs only. Additional AMI support (Amazon Linux 2, Ubuntu 24.04) can be added as new reference files under `install-dd-agent/references/`.
