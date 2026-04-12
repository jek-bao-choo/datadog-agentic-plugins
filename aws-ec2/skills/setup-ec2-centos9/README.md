# setup-ec2-centos9

CentOS Stream 9 EC2 instance with Java 17 and Maven for PoC environments.

## Prerequisites

- AWS CLI configured with ap-southeast-1 access
- Terraform >= 1.0
- SSH key `jek_rsa_pem` in AWS (key name: `jek_rsa_pem`) and locally at `~/.ssh/jek_rsa_pem`

## Tech Stack

| Component | Version |
|---|---|
| OS | CentOS Stream 9 (AMI owner: 125523088429) |
| SSH user | `ec2-user` |
| Instance | t3.large (2 vCPU, 8GB RAM) |
| Storage | 30GB gp3 (encrypted) |
| Region | ap-southeast-1 |
| Java | OpenJDK 17 (via user_data) |
| Maven | 3.6.3+ (via user_data) |

## Quick Start

```bash
cd scripts/
terraform init
terraform plan
terraform apply
terraform output ssh_connection_command
```

## SSH Access

The key `jek_rsa_pem` is passphrase-protected. Use `ssh-agent`:

```bash
ssh-add ~/.ssh/jek_rsa_pem
ssh ec2-user@$(cd scripts && terraform output -raw instance_public_ip)
```

## What user_data Installs

On first boot, the instance runs:
1. **Java 17** — `dnf install java-17-openjdk java-17-openjdk-devel`
2. **Maven** — `dnf install maven` (fallback: manual install of 3.9.9)
3. **Git** — `dnf install git`

Completion marker: `/tmp/user_data_done`. If this file doesn't exist, user_data is still running.

## Resource Reuse

The Terraform automatically detects existing shared resources:

| Resource | If `jek-vpc` exists | If not |
|---|---|---|
| VPC | Reuses `jek-vpc` | Creates `jek-vpc-centos9` |
| Subnet | Reuses `jek-public-subnet` | Creates `jek-subnet-centos9` |
| Internet Gateway | Looks up existing IGW on VPC | Creates `jek-igw-centos9` |
| Route Table | Always creates `jek-rt-centos9` | Always creates `jek-rt-centos9` |
| Security Group | Always creates `jek-sg-centos9` (shared SG also attached to EC2) | Always creates `jek-sg-centos9` |
| EC2 | Always creates `jek-ec2-centos9` | Always creates `jek-ec2-centos9` |

**Why route table and SG are always created**: Shared resources may have been partially destroyed by other skills' `terraform destroy`. By always owning these, this skill guarantees internet connectivity and correct firewall rules regardless of shared resource state.

On `terraform destroy`: removes EC2, route table, and SG. Shared VPC/subnet/IGW are left intact.

## Security Group Rules

| Direction | Port(s) | Protocol | Source | Purpose |
|---|---|---|---|---|
| Inbound | 22 | TCP | Your IP | SSH access |
| Inbound | 8081-8084 | TCP | Your IP | Application ports |
| Inbound | 4317-4318 | TCP | Your IP | OTel Collector OTLP |
| Outbound | All | All | 0.0.0.0/0 | Internet access |

## Teardown

```bash
cd scripts/
terraform destroy
```
