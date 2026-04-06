# TODO — sandbox-setup

> Combined from datadog-proof/shell/ and datadog-proof/dockerfile/ CLAUDE.md and TODO files.

---

## shell/CLAUDE.md

# Shell Script Development

## About
Shell script development project

## Structure
- Shallow directories, avoid deep nesting

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
- Focus and independence per script
---

## shell/1-TODO.md

## TASK:
- Create a folder call "send-test-logs"
- Create a .env to save my Datadog API Key
- Create a simple bash script to send logs to Datadog API:
```
curl -X POST 'https://http-intake.logs.datadoghq.com/v1/input/<api_key> \
--header 'Content-Type: application/json' \
--data-raw '{
    "ddsource": "jek-local-machine",
    "message": "jek-test-log-v1",
    "ddtags":"env:test,team:dd",
    "service": "jek-test-log",
    "hostname": "jek-localhost",
    "level": "info"
}'
```
- The API key should be read from my .env file.
- The .env must NOT be committed to Git.
- Think hard

<!-- ## EXAMPLES:
- [List any example files in the examples folders and explain how they should be used if any] -->

<!-- ## DOCUMENTATION:
- https://docs.datadoghq.com/api/latest/logs/?code-lang=curl -->

<!-- ## USE CONTEXT7
- use library /tiangolo/fastapi -->

## OTHER CONSIDERATIONS:
- My computer is a Macbook
- I'm running Claude Code through the terminal
- Explain the steps you would take in clear, beginner-friendly language
- Write the research on performing the task
- Save the research to `2-RESEARCH.md`
---

## dockerfile/CLAUDE.md

# Dockerfile Development

## About
Dockerfile development for containerizing applications

## Structure
- Shallow directories, avoid deep nesting
- Naming: `<primaryTechStack><techStackVersion>__<secondaryTechStack><techStackVersion>`
- Example: `dogstatsd__datadogagent7dot68dot3`

## Workflow
1. **Research**: Create `2-RESEARCH.md` implementation plan
2. **Review**: Wait for user approval
3. **Plan**: Create detailed `3-PLAN.md` with atomic steps
4. **Implement**: Execute step-by-step, mark "(COMPLETED)"

## Guidelines
- Keep simple (Hello World level)
- Assume no prior Docker knowledge
- Small, atomic steps
- Individual tests only
- Wait for explicit approval between phases
---

## dockerfile/1-TODO.md

## TASK:
- I want to run this command:
```bash
docker run -d --cgroupns host \
              --pid host \
              -v /var/run/docker.sock:/var/run/docker.sock:ro \
              -v /proc/:/host/proc/:ro \
              -v /sys/fs/cgroup/:/host/sys/fs/cgroup:ro \
              -e DD_API_KEY=<DATADOG_API_KEY> \
              -e DD_DOGSTATSD_NON_LOCAL_TRAFFIC="true" \
              -p 8125:8125/udp \
              gcr.io/datadoghq/agent:7.68.3
```
- But I want the <DATADOG_API_KEY> to be read from .env
- The .env must not be committed to Github
- Think hard

## Verification Strategy
1. Start Datadog Agent container
2. Run Python application sending test metrics
3. Verify metrics appear in Datadog dashboard
4. Test teardown and cleanup procedures

## Security Considerations
- `.env` file contains sensitive API key
- Proper `.gitignore` configuration prevents accidental commits
- Docker volumes provide read-only access to system resources
- Network exposure limited to necessary ports only

<!-- ## EXAMPLES:
- [List any example files in the examples folders and explain how they should be used if any] -->

<!-- ## DOCUMENTATION:
- https://docs.datadoghq.com/developers/dogstatsd/?tab=containeragent -->

## USE CONTEXT7
- use library /hashicorp/terraform 
- use library /terraform-docs/terraform-docs /hashicorp/terraform-mcp-server /hashicorp/terraform-provider-aws /petoju/terraform-provider-mysql /terraform-aws-modules/terraform-aws-rds /terraform-aws-modules/terraform-aws-ecs /terraform-provider-datadog /terraform/docs 

## Implementation should consider:
- **README.md**: Include setup, deployment, verification, and teardown steps
- **Git Ignore**: Create a .gitignore to avoid committing sensitive information to Git repo
- **Simplicity**: Keep the Dockerfile really simple
- **Teardown**: Document the steps to clean up the processes or containers in the README.md
- **PII and Sensitive Data**: Do be mindful that I will be committing the Dockerfile folders to a public Github repo

## OTHER CONSIDERATIONS:
- My computer is a Macbook Pro M4 chip
- I'm running Claude Code through the terminal and Visual Studio Code
- Explain the steps you would take in clear, beginner-friendly language
- Write the research on performing the task
- Save the research to `2-RESEARCH.md`



