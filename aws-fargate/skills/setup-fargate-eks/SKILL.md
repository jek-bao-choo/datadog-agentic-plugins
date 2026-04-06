---
name: setup-fargate-eks
description: >-
  Use this skill whenever the user needs to provision an EKS Fargate cluster on AWS.
  Triggers on mentions of Fargate setup, serverless Kubernetes on AWS, EKS Fargate,
  or Terraform Fargate EKS. Also applies when the user wants serverless compute for
  Kubernetes workloads on AWS.
version: 0.1.0
version_matrix:
  k8s_version: [1.33]
---

# EKS Fargate Cluster Setup via Terraform

Provision an AWS EKS cluster with Fargate compute profiles using Terraform. Pods run serverlessly without EC2 instances.

## Prerequisites

- AWS CLI configured with valid credentials
- Terraform >= 1.0
- kubectl installed
- Required IAM permissions (EKS, EC2/VPC, IAM)

## Instructions

The complete setup is documented in `README.md`. The Terraform scripts in `scripts/` create:

- Custom VPC with public and private subnets across 2 AZs
- EKS cluster with Kubernetes v1.33
- Fargate profiles for CoreDNS (kube-system) and default namespace
- IAM roles for EKS and Fargate

```bash
cd scripts/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```

## Validation

```bash
aws eks update-kubeconfig --name <CLUSTER_NAME> --region <REGION>
kubectl get nodes
# Expected: Fargate nodes (fargate-ip-*) in Ready status

kubectl get pods -n kube-system
# Expected: CoreDNS pods running on Fargate
```

## Troubleshooting

### CoreDNS pods stuck in Pending
**Cause:** Fargate profile for kube-system not created or subnets not tagged correctly.
**Fix:** Verify Fargate profile exists and private subnets have the `kubernetes.io/role/internal-elb: 1` tag.

### Cannot schedule pods in default namespace
**Cause:** No Fargate profile matches the default namespace.
**Fix:** Ensure a Fargate profile with `namespace: default` selector exists.
