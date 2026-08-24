---
name: using-colima
description: >-
  Use this skill whenever the user needs to run Docker containers on macOS with Colima
  instead of Docker Desktop. Triggers on mentions of Colima, colima start/stop/restart,
  Docker Desktop replacement or migration, spinning up / starting / stopping / restarting
  Docker containers on a Mac, DOCKER_HOST, Testcontainers not finding Docker, or the errors
  "docker: command not found", "docker: unknown command: docker compose", and
  "docker-credential-desktop: executable file not found in $PATH".
version: 0.1.0
---

# Using Colima for Docker on macOS

Colima runs a lightweight Linux VM with the real Docker daemon inside it. The standard `docker`
and `docker compose` CLIs work unchanged — only the daemon's location differs from Docker
Desktop.

## Prerequisites

- macOS (Apple Silicon or Intel) or Linux
- Homebrew

## Step 1 — Preflight (always run first)

Never assume the machine's state. Run the read-only diagnostic:

```bash
bash scripts/colima-preflight.sh
```

Branch on the exit code:

| Exit | Meaning | Next |
|------|---------|------|
| `0` | Colima running, Docker usable | Skip to Step 3 |
| `1` | Installed but stopped or misconfigured | Step 2b |
| `2` | Colima or the Docker CLI is not installed | Step 2a |

Read the `FAIL` and `WARN` lines — each one names the fix.

## Step 2a — First-time install or migration from Docker Desktop

Follow `references/migrating-from-docker-desktop.md`.

That flow uninstalls Docker Desktop, which **destroys all local images, containers, volumes,
and networks**. Confirm with the user and complete the backup step before running it.

## Step 2b — Repair an existing setup

Apply only the repairs the preflight flagged.

**VM is not running:**

```bash
colima start
```

**Docker context is wrong:**

```bash
docker context use colima
docker context rm desktop-linux   # only if the stale Docker Desktop context exists
```

**`DOCKER_HOST` unset** — needed by Testcontainers, Docker SDK clients, and agents running test
harnesses:

```bash
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
```

Persist to **both** `~/.zshrc` and `~/.zshenv`. `~/.zshrc` is read only by interactive shells;
non-interactive tools (scripts, CI, Claude Code) read `~/.zshenv`. Restart the IDE afterwards.

Re-run the preflight to confirm the repair.

## Step 3 — Colima VM lifecycle

The VM must be running before any `docker` command. A cold start takes roughly 5-10 seconds.

```bash
colima status                 # is it running, and with what resources
colima start                  # start with the saved profile
colima stop                   # stop the VM (containers stop with it)
colima stop && colima start   # restart
brew services start colima    # start automatically at login
colima ssh                    # shell into the VM
```

Resize by stopping first, then starting with new flags:

```bash
colima stop
colima start --cpu 6 --memory 24 --vm-type=vz --vz-rosetta
```

Last resort — recreates the VM. Running containers are lost; pulled images are not:

```bash
colima delete && colima start
```

## Step 4 — Container operations

Standard Docker CLI. Nothing here is Colima-specific.

**Spin up:**

```bash
docker run -d --name <name> -p <host>:<container> <image>
docker compose up -d                     # whole stack
docker compose up -d <service>           # one service
```

**Inspect:**

```bash
docker ps                 # running
docker ps -a              # including stopped
docker logs -f <name>
docker stats
docker exec -it <name> sh
```

**Start / stop / restart:**

```bash
docker start <name>
docker stop <name>
docker restart <name>

docker compose start [service]
docker compose stop [service]
docker compose restart [service]
```

`docker restart` reuses the existing container. To pick up a changed image or changed
environment variables, recreate instead:

```bash
docker compose up -d --force-recreate [service]
```

**Tear down:**

```bash
docker rm -f <name>
docker compose down          # containers and networks
docker compose down -v       # also delete volumes (destroys data — confirm first)
docker system prune -a       # reclaim disk (destroys unused images — confirm first)
```

**Cross-architecture images:** `--vz-rosetta` lets most `linux/amd64` images run on Apple
Silicon. Be explicit when it matters:

```bash
docker run --platform linux/amd64 <image>
docker buildx build --platform linux/amd64,linux/arm64 -t <tag> .
```

## Validation

```bash
colima status                              # colima is running
docker ps                                  # no error
docker context ls                          # colima current, or default overridden by DOCKER_HOST
docker info | grep -A2 "Storage Driver"    # overlayfs + io.containerd.snapshotter.v1
docker run --rm hello-world                # end-to-end pull and run
```

## Troubleshooting

### `docker: command not found`
**Cause:** Docker Desktop bundled the CLI; uninstalling it removed the binary.
**Fix:** `brew install docker docker-compose docker-buildx && brew link docker`

### `docker: unknown command: docker compose`
**Cause:** Docker cannot find the Homebrew CLI plugin directory.
**Fix:** Add `cliPluginsExtraDirs` to `~/.docker/config.json`, pointing at
`<brew --prefix>/lib/docker/cli-plugins` (`/opt/homebrew` on Apple Silicon, `/usr/local` on
Intel). The path must be **literal** — Docker does not expand shell variables in this field, so
`"$HOMEBREW_PREFIX/lib/docker/cli-plugins"` silently fails.

### `docker-credential-desktop: executable file not found in $PATH`
**Cause:** `~/.docker/config.json` still has `"credsStore": "desktop"` from Docker Desktop.
**Fix:** `jq 'del(.credsStore)' ~/.docker/config.json > /tmp/c.json && mv /tmp/c.json ~/.docker/config.json`

### `Warning: DOCKER_HOST environment variable overrides the active context`
**Cause:** Both `DOCKER_HOST` and a Docker context are set.
**Fix:** None needed — harmless as long as both point at
`$HOME/.colima/default/docker.sock`. Verify with `docker context ls`.

### Colima will not start after a macOS reboot
**Cause:** Known issue with the `--vm-type=vz` driver.
**Fix:** `colima stop && colima start`. If it stays stuck, `colima delete && colima start`
recreates the VM cleanly.

### Testcontainers or a Docker SDK client cannot find Docker
**Cause:** The tool ran in a non-interactive shell, which does not read `~/.zshrc`.
**Fix:** Add the `DOCKER_HOST` and `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` exports to
`~/.zshenv` as well (Step 2b), then restart the IDE. For Bazel, add them as `--test_env` flags
in `~/.bazelrc` — see the reference file.

### Storage driver still reports `overlay2`
**Cause:** The containerd snapshotter is not enabled; multi-platform builds and attestations
will fail.
**Fix:** `colima start --edit`, add `features: {containerd-snapshotter: true}` under the
`docker:` section, then `colima update`.

### Port already in use
**Cause:** A container from a previous run still holds the port, or a host process does.
**Fix:** `docker ps -a` to find and remove the container, or `lsof -i :<port>` for a host
process.

## Limitations

- macOS and Linux only. There is no Windows support.
- The VM is not always on. Expect a ~5-10 second cold start versus Docker Desktop.
- VM CPU and memory are reserved from the host and are fixed until the VM restarts.

## References

- `references/migrating-from-docker-desktop.md` — the one-time Docker Desktop migration
- `scripts/colima-preflight.sh` — read-only state diagnostic
- `README.md` — background and command cheatsheet
