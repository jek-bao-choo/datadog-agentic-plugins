## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `azure-vm` plugin. Work proceeds in two phases: first provision infrastructure, then set up Datadog monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place Terraform scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Infrastructure Provisioning
- Create a Windows Server 2022 VM using Bicep in Azure
- VM size: Standard_D4_v5 (4 vCPUs, 16GB RAM) or similar DSv5 series
- Region: Southeast Asia
- Components: Resource Group, VPC (VNet), Subnet, Network Security Group (pointing to My IP)
- After VM creation, install .NET Framework v4.8.1 app running on IIS in the Windows Server 2022
- Directory structure: shallow directories
- Resource naming: all Azure resources use "jek-" prefix
- Tagging: `owner="jek"`, `env="test"`, `criticality="low"`

## Phase 2: Datadog Agent / Operator Setup
- Install Datadog Agent on Windows Server 2022
- Configure IIS monitoring integration in Datadog
- Collect Windows performance counters, IIS metrics, and .NET Framework metrics
- Verify Agent is reporting to Datadog and IIS dashboard is populated
- Document setup and teardown steps in `README.md`

## Guidelines
- Keep it simple (Hello World level)
- Assume no prior Bicep/Azure knowledge
- Provide small, atomic steps with individual tests
- Wait for explicit approval between phases
- Create a `.gitignore` to avoid committing sensitive Bicep output or parameter files with secrets
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Do NOT reveal PII or secrets -- this is a public GitHub repo
- Development tools: iTerm and Visual Studio Code
- Development machine: MacBook M4
- Explain steps in clear, beginner-friendly language

## Tools & References
- Context7 library: `/azure/azure-quickstart-templates`
- Context7 library: `/microsoft/referencesource`
- Datadog docs: [Windows Agent](https://docs.datadoghq.com/agent/basic_agent_usage/windows/)
- Datadog docs: [IIS Integration](https://docs.datadoghq.com/integrations/iis/)
