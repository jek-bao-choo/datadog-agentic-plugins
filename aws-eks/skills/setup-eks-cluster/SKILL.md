---
name: setup-eks-cluster
description: >-
  Use this skill whenever the user needs to provision an EKS cluster on AWS using Terraform.
  Triggers on mentions of EKS setup, EKS provisioning, AWS Kubernetes cluster, Terraform EKS,
  or preparing an EKS cluster for Datadog monitoring.
version: 0.1.0
version_matrix:
  k8s_version: [1.30]
---

# EKS Cluster Setup via Terraform

Provision an Amazon EKS cluster with complete VPC infrastructure, IAM roles, security groups, and a managed node group using Terraform.

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0
- kubectl installed
- SSH key pair in the target AWS region

## Instructions

The complete setup is documented in `README.md`. The Terraform scripts in `scripts/` create:

- VPC with 2 public subnets across 2 AZs
- Security groups for cluster communication
- IAM roles for EKS cluster and node group
- EKS cluster with Kubernetes v1.30
- Managed node group (2x t3.medium)

```bash
cd scripts/
terraform init
terraform plan
terraform apply
```

After provisioning, configure kubectl:

```bash
aws eks update-kubeconfig --name <CLUSTER_NAME> --region <REGION>
kubectl get nodes
```

## Validation

```bash
kubectl get nodes
# Expected: 2 nodes in Ready status

kubectl cluster-info
# Expected: Kubernetes control plane URL
```

## Troubleshooting

### Terraform apply fails with IAM permissions error
**Cause:** AWS user lacks required IAM permissions.
**Fix:** Ensure user has EKS, EC2, IAM, and VPC full access policies.

### kubectl cannot connect to cluster
**Cause:** kubeconfig not updated after cluster creation.
**Fix:** Run `aws eks update-kubeconfig --name <CLUSTER_NAME> --region <REGION>`
