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
version: 0.3.0
version_matrix:
  was_version: [8.5.5.30]
---

# IBM WebSphere Application Server 8.5.5.30 in Docker

Stand up a containerised WAS traditional 8.5.5.30 profile, reach the admin console, and
deploy an application.

IBM publishes a ready-to-run image at `icr.io/appcafe/websphere-traditional:8.5.5.30`. It
pulls anonymously — no Passport Advantage entitlement, no Installation Manager, and no
fixpack step. The image is `linux/amd64` only.

`README.md` holds the full step-by-step runbook, including WAR/EAR deployment through the
console and configuration backup. Use this file to drive the setup; drop into the README
when the user needs the long form.

## Verified

End-to-end run on macOS 26.6 / Apple Silicon, Colima `vz` + Rosetta, Docker 29.5.2,
4 CPU / 16 GB VM — console reachable and `server1` started.

| | |
|---|---|
| Image digest | `sha256:24e73173afb52203bfa28fa992e878c2a71a0f85de951242556b35275ebbf4d6` |
| Compressed / on-disk | 1.19 GB / 2.91 GB (1.1 GB as a `docker save` tar) |
| Product | `8.5.5.30`, build `cf302626.03`, package `...v85_8.5.5030.20260701_1755` |
| JVM | IBM J9 `1.8.0_491` (SR8 FP65), amd64 |
| Time to `WSVR0001I` | ~40 s |
| Console | `302` from `https://localhost:9043/ibm/console` |

The profile also listens on `WC_adminhost=9060` (console over HTTP) and
`SOAP_CONNECTOR_ADDRESS=8880` (`wsadmin`). Neither is published by the `docker run` below —
add `-p 127.0.0.1:8880:8880` if the user needs remote `wsadmin`.

## Prerequisites

- **A working Docker host.** On macOS, set this up first with the `using-colima` skill in
  this plugin.
- **Resources.** WAS is heavy. Give the VM at least 4 CPUs, 8 GB RAM, and 60 GB disk —
  well above Colima's defaults:
  ```bash
  colima stop
  colima start --cpu 4 --memory 8 --disk 60 --vm-type=vz --vz-rosetta
  ```
- **Apple Silicon.** The image is `linux/amd64` only. `--vz-rosetta` (above) plus
  `--platform linux/amd64` on every `docker pull` / `run` / `save` is required, or the
  container will not start. Expect slower startup under translation.

Set this once so the rest of the commands stay short:

```bash
export WAS_IMAGE=icr.io/appcafe/websphere-traditional:8.5.5.30
export WAS_PLATFORM=--platform=linux/amd64   # Apple Silicon; leave empty on Intel/AMD
```

## Instructions

### 1. Check ports and name collisions

```bash
docker ps -a --filter name=was85530          # must return no container
lsof -nP -iTCP:9043 -sTCP:LISTEN             # admin console
lsof -nP -iTCP:9443 -sTCP:LISTEN             # app HTTPS
lsof -nP -iTCP:9080 -sTCP:LISTEN             # app HTTP
```

No output from the `lsof` calls means the ports are free. On Linux without `lsof`, use
`ss -ltnp`.

### 2. Pull and verify the image

```bash
docker pull $WAS_PLATFORM "$WAS_IMAGE"
docker image inspect --format '{{index .RepoDigests 0}}' "$WAS_IMAGE"
```

Record that digest — IBM retains only the latest three 8.5.5 tags.

Confirm the version before starting anything:

```bash
docker run --rm $WAS_PLATFORM \
  --entrypoint /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh \
  "$WAS_IMAGE" | grep -A4 "Installed Product"
```

Expect `Version  8.5.5.30`. Stop if it reports anything else.

### 3. Archive the image

IBM rotates tags, so keep a local copy:

```bash
docker save $WAS_PLATFORM -o websphere-traditional-8.5.5.30.tar "$WAS_IMAGE"
shasum -a 256 websphere-traditional-8.5.5.30.tar   # sha256sum on Linux
```

Restore later with `docker load -i websphere-traditional-8.5.5.30.tar`. The archive is
several GB — do not commit it.

### 4. Create the log volume and run the container

```bash
docker volume create was85530-logs

docker run -d $WAS_PLATFORM \
  --name was85530 \
  --hostname was85530 \
  -e ENABLE_BASIC_LOGGING=true \
  -p 127.0.0.1:9043:9043 \
  -p 127.0.0.1:9443:9443 \
  -p 127.0.0.1:9080:9080 \
  -v was85530-logs:/logs \
  "$WAS_IMAGE"
```

Binding to `127.0.0.1` keeps the console off the local network — WAS ships with a known
default admin user, so do not publish these ports broadly.
`ENABLE_BASIC_LOGGING=true` gives readable `SystemOut.log` instead of the HPEL JSON stream.

Do **not** add `-e UPDATE_HOSTNAME=true`. The 8.5.5.30 UBI image has no `hostname` binary
on its `PATH`, so the image's `updateHostName.py` runs with no argument and dies with
`IndexError: index out of range: 1`. Startup survives it, but the variable accomplishes
nothing — the node keeps `hostName="localhost"` in `serverindex.xml`, which is what
port-forwarded local access wants anyway. Setting it only adds a traceback to the log.

The volume persists **logs only**, not the WebSphere configuration. See step 8.

`/logs` in the image is a symlink to
`/opt/IBM/WebSphere/AppServer/profiles/AppSrv01/logs`, so Docker resolves the mount onto
the real profile log directory. `SystemOut.log`, `SystemErr.log`, and `ffdc/` all land in
the volume as intended.

### 5. Wait for startup

```bash
docker logs -f was85530
```

Wait for `WSVR0001I: Server server1 open for e-business`, then `Ctrl+C` — that stops
log-following only, not the server. On Apple Silicon under Rosetta this took about 40
seconds on a 4-CPU / 16 GB VM; allow a few minutes on slower hosts before suspecting a
problem.

Non-interactive equivalent:

```bash
for i in $(seq 1 120); do
  docker logs was85530 2>&1 | grep -q "open for e-business" && { echo READY; break; }
  docker ps --filter name=was85530 --format '{{.Names}}' | grep -q was85530 \
    || { echo "EXITED before ready"; docker logs was85530 2>&1 | tail -40; break; }
  sleep 10
done
```

The container-exit guard matters: a bare `until ... grep` loop spins forever if the JVM
aborts, and a hung wait looks identical to a slow start.

### 6. Retrieve credentials

```bash
docker exec was85530 cat /tmp/PASSWORD
```

The admin user is `wsadmin`. That is the only credential — this image creates no
`/tmp/KEYSTORE_PASSWORD`. `/tmp` holds just `PASSWORD` and `passwordupdated`, and the
image's `start_server.sh` references no keystore file, so do not go hunting for a second
password. Tell the user to store it in a password manager; never write it into the repo
or a Compose file.

### 7. Open the console

```bash
curl -k -I https://localhost:9043/ibm/console    # 200/302 confirms connectivity
```

Then browse to `https://localhost:9043/ibm/console`, accept the development certificate,
and log in as `wsadmin`. Confirm **Servers → Server Types → WebSphere application
servers** lists `server1` as started.

Image defaults: profile `AppSrv01`, cell `DefaultCell01`, node `DefaultNode01`, server
`server1`.

### 8. Deploy a WAR or EAR, and back up

Console deployment and `backupConfig.sh` are step-by-step in `README.md` sections L and N.
The important part: **configuration lives in the container, not the volume.** Removing the
container discards console changes unless they were backed up:

```bash
docker exec was85530 /opt/IBM/WebSphere/AppServer/bin/backupConfig.sh \
  /tmp/AppSrv01-backup.zip -profileName AppSrv01 -nostop
docker cp was85530:/tmp/AppSrv01-backup.zip ./AppSrv01-backup.zip
```

Keep the original `.war`/`.ear` alongside it — the config backup is not an application
binary backup.

## Validation

```bash
docker ps --filter name=was85530             # Up
docker port was85530                         # 9043, 9443, 9080 bound to 127.0.0.1
docker exec was85530 /opt/IBM/WebSphere/AppServer/bin/versionInfo.sh | grep -A4 "Installed Product"
curl -k -sS -o /dev/null -w '%{http_code}\n' https://localhost:9043/ibm/console
```

Expect the container `Up`, `Version 8.5.5.30`, and an HTTP `200` or `302` from the console.

## Day-to-day

```bash
docker stop -t 60 was85530     # graceful; WAS needs the longer timeout
docker start was85530
```

Note `-t`, not Podman's `--time`. On macOS, `colima start` must come first after a reboot.

Console and application changes survive `stop`/`start`. They are lost on `docker rm`.

## Troubleshooting

### `exec format error`, or the container exits immediately on Apple Silicon
**Cause:** The image is `linux/amd64` only and Rosetta translation is not active.
**Fix:** Start Colima with `--vm-type=vz --vz-rosetta` and pass `--platform linux/amd64`
to every `docker pull` / `run` / `save`.

### Container is killed during startup, or the JVM aborts
**Cause:** Not enough memory in the VM. WAS needs several GB before the profile is usable.
**Fix:** `colima stop && colima start --cpu 4 --memory 8 --disk 60 --vm-type=vz --vz-rosetta`.

### Port already allocated
**Cause:** A previous `was85530` container, or a host process on 9043/9443/9080.
**Fix:** `docker ps -a --filter name=was85530` and remove it, or find the host process with
`lsof -nP -iTCP:9043 -sTCP:LISTEN`.

### `/tmp/PASSWORD` is missing
**Cause:** The server has not finished its first start, or the profile was recreated.
**Fix:** Wait for `WSVR0001I: Server server1 open for e-business` in `docker logs`, then
re-read the file.

### Console changes disappeared after recreating the container
**Cause:** The named volume covers `/logs` only; configuration lives in the container layer.
**Fix:** Restore from `backupConfig.sh` output. Take a backup before any `docker rm`.

### Manifest or tag not found on pull
**Cause:** IBM retains only the latest three 8.5.5 fixpack tags; 8.5.5.30 may have rotated out.
**Fix:** Load the archived tar from step 3, or check IBM's current tag list at
https://github.com/WASdev/ci.docker.websphere-traditional/blob/main/docs/images.md

## References

- `README.md` — the full runbook, including console WAR/EAR deployment and backup
- `docker/skills/using-colima/SKILL.md` — get the Docker host working first on macOS
- IBM's image repository: https://github.com/WASdev/ci.docker.websphere-traditional
