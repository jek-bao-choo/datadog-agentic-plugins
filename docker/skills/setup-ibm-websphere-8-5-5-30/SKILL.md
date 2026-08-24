---
name: setup-ibm-websphere-8-5-5-30
description: >-
  Use this skill whenever the user needs to stand up IBM WebSphere Application Server
  traditional 8.5.5.30 in a Docker container — on Colima, Docker Desktop, or any Docker
  host. Triggers on mentions of WebSphere, WAS 8.5.5, WAS 8.5.5.30, WebSphere ND, a
  WebSphere image or container, IBM Installation Manager, imcl, a WAS fixpack or interim
  fix, wsadmin, the WebSphere integrated solutions console on port 9043, a deployment
  manager or node agent, or deploying an EAR/WAR to WebSphere. Also use it when the user
  is running WebSphere on Apple Silicon and hits `linux/amd64` platform or emulation
  problems — even if they only say "WAS 8.5.5" or "WebSphere in Docker".
version: 0.1.0
version_matrix:
  was_version: [8.5.5.30]
---

# Setting up IBM WebSphere Application Server 8.5.5.30 in Docker

Stand up a containerised WAS traditional 8.5.5.30 profile, reach the admin console, and
deploy an application — on a Docker host managed by the `using-colima` skill.

## Status

**This skill is a scaffold. The setup procedure has not been written yet.**

The owner of this skill is supplying the steps separately. Until `## Instructions` below
is filled in, do not synthesise a WebSphere install — ask the user for their procedure
instead.

That restraint matters here more than in most skills. WAS traditional has no public
ready-to-run 8.5.5.30 image: a real build needs IBM Passport Advantage entitlement, an
Installation Manager repository, a silent-install response file, and the 8.5.5.30 fixpack
applied on top of an 8.5.5.0 base. Every one of those is site-specific. A plausible-looking
guess would waste hours and fail against the user's actual entitlement.

If the user asks you to proceed anyway, say what is missing, then work from whatever
installers and licence details they can point you at.

Delete this section once the real steps land.

## Prerequisites

<!-- TODO: confirm with the skill owner. Known-safe items below; the rest depends on the procedure. -->

- A working Docker host. On macOS, set this up first with the `using-colima` skill in this
  plugin.
- WAS traditional images are `linux/amd64` only. On Apple Silicon, start Colima with
  `--vm-type=vz --vz-rosetta` and pass `--platform linux/amd64` to `docker build` and
  `docker run`, or the container will not start.
- Budget generous VM resources. WAS is heavy — expect several GB of RAM and disk for the
  profile alone, well above Colima's defaults.
- IBM entitlement and installation media — details TBD with the skill owner.

## Instructions

<!-- TODO: the actual procedure. Pending from the skill owner. -->

Not written yet. See `## Status`.

When these steps are authored, put the Dockerfile, Compose file, Installation Manager
response file, and any `wsadmin` Jython in `scripts/`, and move anything specific to a
particular WAS version or topology into `references/` so this file stays under 500 lines.

## Validation

<!-- TODO: replace with real checks once the procedure exists. -->

Not written yet. At minimum the finished skill should verify that the container is up, the
server process has started, and the admin console answers on its port. The ports WAS uses
by default:

| Port | Purpose |
|------|---------|
| 9043 | Integrated solutions console (HTTPS) |
| 9060 | Integrated solutions console (HTTP) |
| 9080 | Application HTTP transport |
| 9443 | Application HTTPS transport |
| 8880 | SOAP connector (`wsadmin`) |

Confirm these against the profile the procedure actually creates — they are defaults, and
`portsFile` or a second profile will shift them.

## Troubleshooting

<!-- TODO: add an H3 per symptom with **Cause:** / **Fix:**, matching using-colima. -->

Not written yet.

## References

- `scripts/` — empty. Dockerfile, Compose file, response file, and `wsadmin` scripts go here.
- `references/` — empty. Version- and topology-specific detail goes here.
- `assets/` — empty. Proof screenshots of the admin console go here.
- `docker/skills/using-colima/SKILL.md` — get the Docker host working first on macOS.
