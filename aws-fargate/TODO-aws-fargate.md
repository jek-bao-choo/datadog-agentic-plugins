## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `aws-fargate` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Infrastructure Provisioning

Provision an EKS Fargate cluster on AWS using Terraform.

- Create a Terraform script to deploy an Amazon EKS cluster with **Fargate profiles** in **ap-southeast-1**
- Kubernetes version: **1.33**
- Include: VPC, public/private subnets, NAT gateway, Internet gateway
- Include: IAM roles and policies for EKS cluster and Fargate pod execution
- Create Fargate profiles for:
  - **kube-system** namespace (for CoreDNS — must patch CoreDNS to remove `eks.amazonaws.com/compute-type: ec2` annotation)
  - **default** namespace (for application workloads)
- All resources use **"jek-"** prefix (e.g., `jek-fargate-cluster`, `jek-fargate-profile`)
- Tags: `owner="jek"`, `env="test"`
- No managed node groups — Fargate only
- Output: cluster endpoint, kubeconfig command, Fargate profile status

## Phase 2: Datadog Agent / Operator Setup

Deploy the Datadog Agent as a sidecar on Fargate pods.

- **Important**: Fargate does not support DaemonSets — you cannot use the standard Datadog Agent DaemonSet approach
- Use the **Datadog Agent sidecar injection** pattern for Fargate workloads
- Configure the Datadog Admission Controller to automatically inject the Agent sidecar into Fargate pods
- API key and app key via Kubernetes secret (never hardcoded)
- Enable: log collection, APM, process monitoring
- Verify the sidecar agent container runs alongside application containers in Fargate pods
- Verify data appears in Datadog (Infrastructure > Kubernetes)

## Guidelines

- **Simplicity**: Keep everything Hello World level — less is more
- **Beginner-friendly**: Assume no prior Terraform or Kubernetes knowledge; explain every step
- **README.md**: Each skill folder must have a README.md with setup, deployment, verification, and teardown steps
- **Security**: This is a public GitHub repo — never commit secrets, API keys, or sensitive data
- **Git hygiene**: Create a `.gitignore` to exclude `.terraform/`, `*.tfstate`, `*.tfstate.backup`, `.terraform.lock.hcl`, `*.tfvars` (if containing secrets)
- **Teardown**: Document `terraform destroy` and any manual cleanup in the README
- **Macbook**: Development is on a Macbook running Claude Code in the terminal

## Tools & References

### MCP Libraries (Context7)
- `/hashicorp/terraform`
- `/hashicorp/terraform-provider-aws`

### Datadog References
- Datadog Agent on EKS Fargate: https://docs.datadoghq.com/integrations/eks_fargate/
- Datadog Admission Controller (sidecar injection): https://docs.datadoghq.com/containers/cluster_agent/admission_controller/
- Datadog Kubernetes integration: https://docs.datadoghq.com/integrations/kubernetes/
