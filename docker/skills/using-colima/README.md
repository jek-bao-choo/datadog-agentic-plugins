# using-colima

Background and cheatsheet for the `using-colima` skill. The executable workflow lives in
`SKILL.md`.

## What Colima is

Colima ("Containers on Lima") runs a lightweight Linux VM on macOS with the Docker daemon
inside it. The `docker` CLI on the host talks to that daemon over a Unix socket at
`$HOME/.colima/default/docker.sock`.

Because the daemon is the real Docker Engine, everything downstream is unchanged: `docker`,
`docker compose`, `docker buildx`, Testcontainers, Dockerfiles, Compose files, registries, and
BuildKit all behave as they did under Docker Desktop.

## Why it replaces Docker Desktop

- Docker Desktop requires a paid subscription for larger organisations; Colima is MIT-licensed.
- Colima is the most transparent drop-in replacement — same CLI, same daemon, same images.
- Resource usage is explicit: the VM only holds the CPU and memory allocated to it, and stops
  entirely when not needed.

Trade-off: Docker Desktop kept an always-on daemon and a GUI. With Colima the VM must be
running, which costs roughly 5-10 seconds on a cold start, and there is no GUI —
`docker ps` / `docker stats` / `colima status` are the equivalents.

## Sizing the VM

```bash
colima start --cpu 4 --memory 16 --vm-type=vz --vz-rosetta
```

| Flag | Guidance |
|------|----------|
| `--cpu` | 2 for light use, 4 for a typical Compose stack, 6-8 for heavy builds or Kubernetes. Leave cores for the host. |
| `--memory` | GB. 8 for light use, 16 for a multi-service stack, 24+ for Kubernetes or JVM-heavy work. |
| `--disk` | GB, default 60. Raise it up front — growing it later requires recreating the VM. |
| `--vm-type=vz` | Apple's Virtualization.framework. Faster than QEMU on Apple Silicon. |
| `--vz-rosetta` | Runs `linux/amd64` images that have no `arm64` variant. Requires `vz`. |
| `--kubernetes` | Bundles a local Kubernetes cluster. |

Settings persist across `colima stop` / `colima start`. To change them, stop the VM and start it
again with the new flags, or edit the profile with `colima start --edit`.

## Cheatsheet

**VM**

```bash
colima status                 # state, arch, runtime, socket paths
colima start                  # start with the saved profile
colima stop                   # stop the VM
colima stop && colima start   # restart
colima start --edit           # edit the VM profile, then: colima update
colima ssh                    # shell into the VM
colima delete && colima start # recreate from scratch (loses containers, keeps images)
brew services start colima    # start at login
```

**Containers**

```bash
docker run -d --name web -p 8080:80 nginx
docker ps -a
docker logs -f web
docker exec -it web sh
docker start|stop|restart web
docker rm -f web
```

**Compose**

```bash
docker compose up -d
docker compose ps
docker compose logs -f [service]
docker compose start|stop|restart [service]
docker compose up -d --force-recreate [service]   # pick up image/env changes
docker compose down [-v]
```

**Health**

```bash
bash scripts/colima-preflight.sh
docker context ls
docker info | grep -A2 "Storage Driver"
docker system df
```

## Environment variables

| Variable | Value | Why |
|----------|-------|-----|
| `DOCKER_HOST` | `unix://$HOME/.colima/default/docker.sock` | Docker SDK clients and Testcontainers do not read Docker contexts |
| `TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE` | `/var/run/docker.sock` | The path Testcontainers should advertise to containers, from inside the VM |

Set both in `~/.zshrc` **and** `~/.zshenv`. Only `~/.zshenv` is read by non-interactive shells,
which is what scripts, CI, and coding agents use.

## See also

- `references/migrating-from-docker-desktop.md` — one-time migration off Docker Desktop
- Colima: https://github.com/abiosoft/colima
- Lima: https://lima-vm.io/
