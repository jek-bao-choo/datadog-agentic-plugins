# TODO — gcp-apigee

> Combined from datadog-proof/hcl-gcp/ CLAUDE.md and TODO files.

---

## CLAUDE.md

# IaC Terraform .hcl Script Development

## About
IaC Terraform .hcl script developments for Google Cloud Platform

## Structure
- Shallow directories, avoid deep nesting
- Naming: `<technology><version if exists>__<variant><version if exists>`
- Example: `gke1dot32__standard`, `gce__ubuntu22`, `gke1dot32__autopilot`, `gce-rhel9`, `cloudsql-postgres15`

## Workflow
1. **Research**: Create `2-RESEARCH.md` implementation plan
2. **Review**: Wait for user approval
3. **Plan**: Create detailed `3-PLAN.md` with atomic steps
4. **Implement**: Execute step-by-step, mark "(COMPLETED)"

## DO
- Keep it simple like Hello World level
- Keep the code short and concise
- Assume no prior Terraform knowledge
- Provide small, atomic steps
- Provide individual tests
- Wait for explicit approval between phases
---

## 1-TODO.md

## TASK:
- Create a terraform project in the folder cloudrun__java to setup a Java spring boot app
- Set it up in Asia Southeast region
- Recommend a sample Java sample app for testing an API endpoint
- Keep it simple
- Think hard


<!-- ### Access & Authentication:
- **SSH Key**: key name in cloud provider, it is called jek-macbook-pro-key in cloud provider
- **SSH Locally**: when ssh use ~/.ssh/id_ed25519
- **IP Addresses**: [current IP of the EC2 for SSH access, do auto-detection such as curl to an address to get it] -->

<!-- ## EXAMPLES:
- [List any example files in the examples folders and explain how they should be used if any] -->

<!-- ## DOCUMENTATION: -->

## USE CONTEXT7
- use library id /googlecloudplatform/terraform-google-cloud-run
- use library id /googlecloudplatform/cloud-run-samples
- use library id /hashicorp/terraform 
- use library id /hashicorp/hcl
<!-- - use library id /googlecloudplatform/terraformer
- use library id /terraform-docs/terraform-docs   -->


## DO NOT
- Reveal PII information because I am committing everything to a public Github repo.

## DO
- Create a .gitignore to avoid committing sensitive terraform files or output to Git repo
- Keep the terraform script really simple
- Document the steps to run the terraform script to README.md including tear down steps
- Consider that my terminal is Macbook M4
- Explain the steps you would take in clear, beginner-friendly language
- Create all GCP resources with "jek-" prefix and tags owner:jek,env=test
- Save the research to `2-RESEARCH.md`



---

## 1-TODO-DATADOG-GCP-MONITORING-INTEGRATION-VIA-TERRAFORM.md.md

## Task
- Research how do I use this Terraform module in this github repo https://github.com/GoogleCloudPlatform/terraform-gcp-datadog-integration for Log Collection Integration of Google Cloud Platform to Datadog
<!-- - Research how to NOT create a new NAT Gateway (instead provides an option to re-use an existing NAT Gateway that is already in the GCP environment) to collect logs from GCP and send logs from GCP via Dataflow to Datadog. 
    - This Github repo that will contain more information is here https://github.com/GoogleCloudPlatform/terraform-gcp-datadog-integration
    - The architecture diagram of the terraform creation is here https://raw.githubusercontent.com/GoogleCloudPlatform/terraform-gcp-datadog-integration/refs/heads/main/gcp-to-datadog-diagram.png
    - Once the research is done, add your thoughts to the below steps on how to NOT create a new NAT Gateway instead it will re-use and existing NAT Gateway. -->


## USE CONTEXT7
- use library id /websites/cloud_google_terraform
- use library id /terraform-google-modules/terraform-google-network
<!-- - use library id /googlecloudplatform/terraform-google-cloud-run
- use library id /googlecloudplatform/cloud-run-samples -->
<!-- - use library id /hashicorp/terraform  -->
<!-- - use library id /hashicorp/hcl -->
<!-- - use library id /googlecloudplatform/terraformer
- use library id /terraform-docs/terraform-docs   -->

## DO NOT
- Reveal PII information because I am committing everything to a public Github repo.

## DO
- Explain the steps you would take in clear, beginner-friendly language
- Explain how to tear down or remove whatever that is created in the research.
- Save the research to `2-RESEARCH.md`

