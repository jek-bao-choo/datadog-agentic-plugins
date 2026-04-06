---
name: aws-eks
description: >
  Set up and instrument a Datadog-monitored environment on Amazon Elastic
  Kubernetes Service. Covers EKS cluster provisioning via Terraform,
  Datadog Operator installation, and Helm-based agent deployment.
category: infrastructure
requires: []
supported_versions:
  k8s_version: [1.30]
---

## Overview

The aws-eks plugin provides skills for provisioning EKS clusters on AWS and deploying Datadog monitoring via the Datadog Operator. Includes Terraform scripts for complete VPC, IAM, and EKS cluster setup with managed node groups.

## Prerequisites

- AWS account with EKS, EC2, IAM, and VPC permissions
- AWS CLI configured
- Terraform >= 1.0
- kubectl and helm CLI tools
- Datadog API key

## Skills

### setup-eks-cluster
Provision an EKS cluster with Terraform including VPC, subnets, security groups, IAM roles, and managed node group (2x t3.medium). Outputs kubeconfig for kubectl access.

### install-dd-operator
Deploy the Datadog Agent on an EKS cluster using the Datadog Operator via Helm. Includes agent operator YAML and Helm values configuration.

## Recommended Skill Order

1. setup-eks-cluster
2. install-dd-operator

## Compatibility Notes

Tested with EKS Kubernetes v1.30 in ap-southeast-1 region. Requires SSH key pair in the target AWS region.
