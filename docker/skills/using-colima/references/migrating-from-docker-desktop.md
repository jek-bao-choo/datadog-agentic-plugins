# Migrating from Docker Desktop to Colima (macOS)

One-time migration. Colima uses the real Docker CLI and daemon, so existing scripts, aliases,
Compose files, and Testcontainers setups keep working with minimal changes.

> **Destructive step ahead.** Step 2 removes all local images, containers, volumes, and
> networks. Back up anything you need before starting, and confirm with the user before
> running it.

## 1. Back up what you need

```bash
docker images                        # note images you cannot easily re-pull
docker volume ls                     # note volumes holding data you need
docker save <image> -o ~/backup-<image>.tar
docker run --rm -v <volume>:/data -v "$HOME":/backup alpine \
  tar czf /backup/backup-<volume>.tgz -C /data .
```

## 2. Uninstall Docker Desktop

Preferred: Docker Desktop UI → **Troubleshoot** → **Uninstall**.

If the UI is unreachable (for example a license lockout):

```bash
/Applications/Docker.app/Contents/MacOS/uninstall
```

Then remove the Docker Desktop credential-store entry, or every subsequent `docker` command
fails with `docker-credential-desktop: executable file not found in $PATH`:

```bash
# Removes only the credsStore key; leaves the rest of the config intact.
jq 'del(.credsStore)' ~/.docker/config.json > /tmp/docker-config.json \
  && mv /tmp/docker-config.json ~/.docker/config.json
```

If `jq` is unavailable, edit `~/.docker/config.json` and delete the `"credsStore": "desktop",`
line by hand.

## 3. Install the Docker CLI and plugins

Docker Desktop bundled the CLI, so it must now be installed separately:

```bash
brew install docker docker-compose docker-buildx
brew link docker
```

Point Docker at the Homebrew plugin directory so `docker compose` and `docker buildx` resolve.
Add `cliPluginsExtraDirs` to `~/.docker/config.json`:

```json
{
  "cliPluginsExtraDirs": [
    "/opt/homebrew/lib/docker/cli-plugins"
  ]
}
```

Two things to get right here:

- Use the **actual** Homebrew prefix. `brew --prefix` prints it; it is `/opt/homebrew` on
  Apple Silicon and `/usr/local` on Intel.
- Use a **literal, fully resolved path**. Docker does not expand shell variables in this field,
  so `"$HOMEBREW_PREFIX/lib/docker/cli-plugins"` silently fails to resolve and
  `docker compose` reports `unknown command`.

Verify:

```bash
docker compose version
docker buildx version
```

## 4. Install and start Colima

Colima runs a lightweight Linux VM with the Docker daemon inside it.

```bash
brew install colima
colima start --cpu 4 --memory 16 --vm-type=vz --vz-rosetta
```

- `--vm-type=vz` uses Apple's Virtualization.framework for better performance on Apple Silicon.
- `--vz-rosetta` enables Rosetta 2 so `linux/amd64` images without an `arm64` variant still run.
- Add `--kubernetes` if a local Kubernetes cluster is needed.
- Size `--cpu` and `--memory` to the machine; the VM reserves them from the host.

Verify:

```bash
docker ps
```

## 5. Verify the storage driver

The containerd snapshotter is required for multi-platform builds and attestations.

```bash
docker info | grep -A2 "Storage Driver"
```

Expected:

```
Storage Driver: overlayfs
 driver-type: io.containerd.snapshotter.v1
```

If it still reports the older `overlay2` driver:

```bash
colima start --edit
# Under the `docker:` section, add:
#   features:
#     containerd-snapshotter: true
# Save, then apply:
colima update
```

## 6. Start Colima automatically

```bash
brew services start colima
```

## 7. Point the Docker context at Colima

```bash
docker context ls                # colima should be current (*)
docker context use colima        # if it is not
docker context rm desktop-linux  # remove the stale Docker Desktop context, if present
```

## 8. Configure DOCKER_HOST

Tools that talk to the Docker SDK directly — Testcontainers, some internal CLIs, and AI agents
running test harnesses — need the socket location explicitly.

```bash
export DOCKER_HOST="unix://$HOME/.colima/default/docker.sock"
export TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock
```

Add both lines to `~/.zshrc` (or `~/.bashrc`) **and** to `~/.zshenv`. `~/.zshrc` is only read by
interactive shells; non-interactive tools — scripts, CI, and Claude Code running a test harness —
read `~/.zshenv`. Then reload:

```bash
source ~/.zshrc
```

Setting `DOCKER_HOST` makes the CLI print a warning that it overrides the active context. That is
expected and harmless as long as both point at the Colima socket.

## 9. Bazel (optional)

```bash
echo "test --test_env HOME=$HOME --test_env DOCKER_HOST=unix://$HOME/.colima/default/docker.sock --test_env TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE=/var/run/docker.sock" >> ~/.bazelrc
```

## 10. Restart the IDE

IDEs cache environment variables at launch. Restart so they pick up `DOCKER_HOST`.

## Final check

```bash
bash scripts/colima-preflight.sh
```

Expect `Result: HEALTHY`.
