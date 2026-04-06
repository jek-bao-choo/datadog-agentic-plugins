## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `aws-eks` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Infrastructure Provisioning

Provision an EKS cluster on AWS using Terraform.

- Create a Terraform script to deploy an Amazon EKS cluster in **ap-southeast-1**
- Kubernetes version: **1.30**
- Include: VPC, public/private subnets, NAT gateway, Internet gateway
- Include: IAM roles and policies for EKS cluster and node group
- Include: Managed node group (e.g., t3.medium, 2 nodes)
- All resources use **"jek-"** prefix (e.g., `jek-eks-cluster`, `jek-eks-node-group`)
- Tags: `owner="jek"`, `env="test"`
- SSH key name in cloud provider: `jek-macbook-pro-key`
- SSH locally: `~/.ssh/id_ed25519`
- Auto-detect current IP for security group ingress (e.g., `curl` to external service)
- Output: cluster endpoint, kubeconfig command, node group status

## Phase 2: Datadog Agent / Operator Setup

Deploy the Datadog Agent to the EKS cluster using the Datadog Operator.

- Install the **Datadog Operator** via Helm chart
- Deploy a `DatadogAgent` custom resource to roll out the Datadog Agent across nodes
- Configure Helm values for:
  - API key and app key (via Kubernetes secret, never hardcoded)
  - Log collection enabled
  - APM enabled
  - Process monitoring enabled
  - Cluster Agent enabled
- Verify agent pods are running on all nodes (`kubectl get pods -n datadog`)
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
- `/terraform-aws-modules/terraform-aws-ecs`

### Datadog References
- `/datadog/datadog-agent`
- Datadog Operator Helm chart: https://docs.datadoghq.com/containers/kubernetes/installation/?tab=operator
- Datadog Kubernetes integration: https://docs.datadoghq.com/integrations/kubernetes/
