---
name: docker
description: >
  Run Docker containers on macOS with Colima instead of Docker Desktop.
  Covers migration from Docker Desktop, Colima VM lifecycle, day-to-day
  container operations, and containerised middleware setups.
category: infrastructure
requires: []
supported_versions:
  was_version: [8.5.5.30]
  agent_version: [7.80.3]
---

## Overview

The docker plugin provides skills for running containers on macOS without Docker Desktop.
Colima runs a lightweight Linux VM with the real Docker daemon inside it, so the standard
`docker` and `docker compose` CLIs, existing scripts, aliases, Compose files, and
Testcontainers setups all keep working.

## Prerequisites

- macOS (Apple Silicon or Intel) or Linux
- Homebrew
- Administrator access (only for the one-time Docker Desktop uninstall)

## Skills

### using-colima
Detect the current Docker/Colima state of the machine, install or repair the Colima setup when
needed, and drive container operations — spin up, start, stop, restart, and tear down.

### setup-ibm-websphere-8-5-5-30
Stand up IBM WebSphere Application Server traditional 8.5.5.30 in a container, reach the admin
console, and deploy a WAR. Verified end-to-end against `icr.io/appcafe/websphere-traditional`,
which pulls anonymously — no Passport Advantage entitlement or Installation Manager needed.

### monitor-websphere-with-datadog
Wire the Datadog `ibm_was` check to a running WebSphere container: deploy IBM's PerfServlet,
raise PMI to `statisticSet=all`, run a containerised Agent, and ship `SystemOut.log` /
`SystemErr.log`. Includes the metrics actually measured on a real profile.

## Recommended Skill Order

1. using-colima — get a working Docker host first
2. setup-ibm-websphere-8-5-5-30 — get the server running and an app deployed
3. monitor-websphere-with-datadog — instrument it

## Compatibility Notes

- macOS and Linux only. There is no Windows support.
- Colima runs a VM, so a cold start costs roughly 5-10 seconds versus Docker Desktop's
  always-on daemon. Container commands fail until the VM is running.
- On Apple Silicon, `--vm-type=vz --vz-rosetta` is recommended so `linux/amd64` images that
  have no `arm64` variant still run.
