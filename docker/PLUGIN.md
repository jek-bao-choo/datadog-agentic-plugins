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
console, and deploy an application. **Scaffold only** — the setup procedure is still pending
from the skill owner, so the skill currently asks for the steps rather than improvising them.

## Recommended Skill Order

1. using-colima — get a working Docker host first
2. setup-ibm-websphere-8-5-5-30

## Compatibility Notes

- macOS and Linux only. There is no Windows support.
- Colima runs a VM, so a cold start costs roughly 5-10 seconds versus Docker Desktop's
  always-on daemon. Container commands fail until the VM is running.
- On Apple Silicon, `--vm-type=vz --vz-rosetta` is recommended so `linux/amd64` images that
  have no `arm64` variant still run.
