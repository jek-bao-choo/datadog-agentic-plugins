---
name: aws-fargate
description: >
  Set up a Datadog-monitored serverless Kubernetes environment on
  AWS EKS with Fargate compute. Covers VPC, EKS cluster, and Fargate
  profile provisioning via Terraform.
category: infrastructure
requires: []
supported_versions:
  k8s_version: [1.33]
---

## Overview

The aws-fargate plugin provides skills for provisioning serverless EKS clusters using AWS Fargate. Pods run without EC2 instances — AWS manages the underlying compute. Includes Terraform scripts for VPC, EKS cluster, and Fargate profiles.

## Prerequisites

- AWS account with EKS and Fargate permissions
- AWS CLI configured
- Terraform >= 1.0
- kubectl

## Skills

### setup-fargate-eks
Provision an EKS Fargate cluster with Terraform including VPC, subnets, EKS cluster, and Fargate profiles for CoreDNS and default namespace.

## Recommended Skill Order

1. setup-fargate-eks

## Compatibility Notes

Tested with EKS Kubernetes v1.33 in ap-southeast-1. Fargate does not support DaemonSets — Datadog monitoring requires the Datadog Agent sidecar injection approach.
