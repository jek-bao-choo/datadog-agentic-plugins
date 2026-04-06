# TODO — azure-vm

> Combined from datadog-proof/bicep/ CLAUDE.md and TODO files.

---

## CLAUDE.md

# Bicep IaC Script Development

## About
- This folder contains multiple standalone Bicep IaC scripting projects

## Structure
- Shallow directories, avoid deep nesting
- Naming: `<os>__<feature-or-runtime>__<other-info>`
- Example: `ws2016__base`, `ubuntu2204__base`, `ws2022__dotnetfx48__aspdotnet`

## Workflow
1. **Research**: Create `2-RESEARCH.md` implementation plan
2. **Review**: Wait for user approval
3. **Plan**: Create detailed `3-PLAN.md` with atomic steps
4. **Implement**: Execute step-by-step, mark "(COMPLETED)"

## Guidelines
- Keep simple (Hello World level)
- Assume no prior dev knowledge
- Small, atomic steps
- Individual tests only
- Wait for explicit approval between phases
- Focus and independence per app
---

## 1a-TODO.md

## TASK:
- Create a Windows Server 2022, of Standard_D4_v5 (4 vCPUs, 16GB RAM) or similar series, using Bicep in Azure (Asia Pacific) Southeast Asia region
- It should have relevant Resource Group, VPC, Subnet, amd Security Group pointing to My IP.
- After the creation of Windows Server 2022, create a .NET Framework v4.8.1 app running on IIS server in the Windows Server 2022.
- Keep simple (Hello World level)
- Explain the steps to test the .NET Framework v4.8.1 application in the README.md
- Think hard

## USE CONTEXT7
- use library /azure/azure-quickstart-templates
- use library /microsoft/referencesource

## IMPLEMENTATION CONSIDERATION: 
- **Resource naming**: [prefix-resourcename, e.g., "jek-"]
- **Tagging**: [required tags owner="jek", env="test", "criticality"="low"]
- **README.md**: Include setup, start up, deployment, verification, and cleanup steps
- **Git Ignore**: Create a .gitignore to avoid committing common Bicep files or output to Git repo
- **Simplicity**: Keep each Bicep project really simple
- **PII and Sensitive Data**: Do be mindful that I will be committing the Bicep project to a public Github repo so do NOT commit private key or secrets.

## OTHER CONSIDERATIONS:
- My development tools are iTerm and Visual Studio Code
- Explain the steps you would take in clear, beginner-friendly language
- Write the research on performing the task
- Save the research to `2-RESEARCH.md`
