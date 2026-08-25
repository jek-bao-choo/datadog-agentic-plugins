---
name: monitor-websphere-with-datadog
description: >-
  Use this skill whenever the user wants to monitor IBM WebSphere Application Server
  traditional with Datadog. Triggers on mentions of the ibm_was integration, the Datadog
  WebSphere integration, PerfServlet, wasPerfTool, PMI or Performance Monitoring
  Infrastructure, statisticSet, ibm_was.can_connect, or ibm_was metrics such as
  ibm_was.jvm, ibm_was.thread_pools, ibm_was.jdbc, ibm_was.servlet_session. Also use it when
  the user asks what telemetry Datadog collects from WebSphere, wants WebSphere SystemOut.log
  or SystemErr.log shipped to Datadog Logs, or reports that WebSphere metrics are not
  appearing in Datadog.
version: 0.1.0
version_matrix:
  was_version: [8.5.5.30]
  agent_version: [7.82.2]
  integration_version: [5.5.1]
---

# Monitoring IBM WebSphere traditional with Datadog

Wire the Datadog `ibm_was` check to a containerised WAS traditional profile, ship its logs,
and confirm data is actually arriving.

Get the server running first with the `setup-ibm-websphere-8-5-5-30` skill in this plugin.

## How the integration works

**Not JMX.** The check scrapes **PerfServlet** — an IBM-supplied servlet that publishes
**PMI** (Performance Monitoring Infrastructure) counters as XML over HTTP. Three things must
line up:

1. **PerfServlet deployed.** `PerfServletApp.ear` ships inside the image at
   `installableApps/`; nothing is downloaded. It serves at `/wasPerfTool/servlet/perfservlet`.
2. **PMI raised to `statisticSet=all`.** The default is `basic`, which starves the check.
   Takes effect only after a server restart.
3. **`servlet_url` pointed at it** in `conf.d/ibm_was.d/conf.yaml`.

Requirements: Agent ≥ 6.10.0, WAS ≥ 8.5.5. See `references/collected-metrics.md` for the
metric list measured on a real profile.

## Verified

End-to-end on macOS 26.6 / Apple Silicon, Colima `vz`, Docker 29.5.2, WAS 8.5.5.30,
containerised Agent 7.82.2 (`gcr.io/datadoghq/agent:7`), integration 5.5.1.

| | |
|---|---|
| PerfServlet payload | HTTP `200`, ~152 KB of PMI XML |
| Check | `[OK]`, 355 metric samples per run, 30 unique names |
| Delivery | `API Key valid`, 22 transaction successes, **0 dropped** |
| Logs | `SystemOut.log` + `SystemErr.log` tailers `Status: OK` |
| Backend | host `was85530-lab` live with `env:local`, `project:websphere-lab`; both containers `UP` |

Backend screenshots: `references/datadog-platform-monitoring-was.png` (host summary) and
`references/datadog-platform-monitoring-was-dd-agent.png` (integrations and containers).

**Application security was not required.** IBM's docs (quoted by Datadog) say to enable it
for PerfServlet; on this image PerfServlet answered `200` with *and without* credentials
while `appEnabled="false"`. So the shipped config carries **no password at all**. Re-test
rather than assuming — if it 401s, add credentials.

## Prerequisites

- A running WAS container (`setup-ibm-websphere-8-5-5-30`), reachable and started.
- A Datadog API key and your site (`datadoghq.com` for US1).
- **Check who owns any Agent already installed on the host** — see the first
  troubleshooting entry. Do not assume an existing Agent is yours to configure.

## Instructions

### 1. Prepare WebSphere

```bash
./scripts/enable-perfservlet.sh
```

Backs up the profile config, deploys PerfServlet, sets `statisticSet=all`, restarts the
container gracefully, waits for `WSVR0001I`, and verifies PerfServlet returns PMI XML. Pass
`--no-restart` to stage the changes without bouncing the server (PMI stays at its old level
until you do).

Override with `WAS_CONTAINER`, `WAS_CELL`, `WAS_NODE`, `WAS_SERVER`, `WAS_USER`,
`WAS_HTTP_PORT`.

### 2. Start the Agent

```bash
DD_API_KEY=<your-key> ./scripts/run-dd-agent.sh
# non-US1:
DD_API_KEY=<your-key> DD_SITE=datadoghq.eu ./scripts/run-dd-agent.sh
```

A **containerised** Agent, for two concrete reasons:

- A host Agent may be corporate/MDM-managed and must not be repurposed.
- Only an Agent on the Docker host can read the WAS log volume. On macOS that volume lives
  inside the Colima VM, invisible to the host filesystem — so a host-installed Agent
  **cannot** tail `SystemOut.log`, no matter how it is configured.

The script creates a user-defined network and attaches the *running* WebSphere container
with `docker network connect` — no recreate, so nothing is lost from its container layer.
That also gives DNS by container name, instead of a bridge IP that moves on restart.

Override with `WAS_LOG_VOLUME`, `DD_HOSTNAME`, `AGENT_CONTAINER`, `DD_NETWORK`,
`DD_CONF_DIR`.

### 3. Confirm data is arriving

```bash
docker exec dd-agent agent check ibm_was          # metrics now, without waiting for a flush
docker exec dd-agent agent status | grep -A6 -E '^ *ibm_was \('
```

Then in Datadog: Metrics Explorer on `ibm_was.*` filtered to `host:was85530-lab`, and Logs
on `source:ibm_was service:websphere`. Allow 2-3 minutes for first indexing.

## Validation

```bash
curl -sS -o /dev/null -w '%{http_code}\n' http://localhost:9080/wasPerfTool/servlet/perfservlet
docker exec dd-agent ls /etc/datadog-agent/conf.d/ibm_was.d/
docker exec dd-agent agent status | grep -E 'API key ending with .*: API Key'
docker exec dd-agent agent status | grep -E '^ *(Dropped|Requeued):'
docker exec dd-agent agent status | grep -A3 'Logs Agent'
```

Expect `200`; `conf.yaml` present; `API Key valid`; `Dropped: 0`; log tailers `Status: OK`.

**A healthy Agent with a valid API key proves nothing about the check running.** Always
confirm `ibm_was` appears in `agent status` and that `conf.d/ibm_was.d/` is non-empty
*inside* the container.

## Troubleshooting

### No metrics in Datadog, and the host Agent looks fine
**Cause:** The host Agent is corporate/MDM-managed and ships to someone else's org. Tells:
`infrastructure_mode: end_user_device`, Jamf tags, an `api_key` left as a placeholder like
`insert_your_dogfood_api`, and real keys under `additional_endpoints`.
**Fix:** Leave it alone — repointing its primary key can disrupt IT's endpoint monitoring,
and MDM will revert the edit. Run a separate containerised Agent (step 2). Check first:
```bash
grep -vE '^\s*#|^\s*$' /opt/datadog-agent/etc/datadog.yaml | grep -E 'api_key|site|infrastructure_mode|additional_endpoints'
```
Redact carefully — `additional_endpoints` holds live API keys, not just `api_key:` lines.

### The check never appears in `agent status`, but the Agent is healthy
**Cause:** The `conf.d` bind mount resolved to an empty directory. On macOS, Colima shares
only `$HOME` by default (`mounts: []`), so a source path under `/var/folders/...` — which is
what `mktemp -d` returns — mounts as empty. The Agent starts fine and reports a valid API
key, so this looks like success.
**Fix:** Render the config under `$HOME`. `run-dd-agent.sh` uses
`$HOME/.websphere-dd-lab/ibm_was.d` and asserts the file is visible inside the container.

### `Empty reply from server` / HTTP `000` right after a restart
**Cause:** `WSVR0001I: Server server1 open for e-business` is logged several seconds *before*
applications finish initialising. On this profile PerfServlet's servlets logged `SRVE0242I`
about 9 s later.
**Fix:** Retry rather than failing. `enable-perfservlet.sh` polls for up to 90 s.

### A bash readiness loop never exits even though the marker is present
**Cause:** `set -o pipefail` plus `grep -q`. `grep -q` exits at the first match, the upstream
writer takes `SIGPIPE`, and pipefail reports the *successful* match as a failed pipeline.
The same trap kills `yes y | ... ` pipelines after a successful deployment.
**Fix:** Never pipe into `grep -q` under pipefail. Use `grep -c` (it consumes all input) and
compare the count, or capture with `$(...)` and test the string. Prefer a finite
`printf 'y\ny\n'` over an infinite `yes`.

### `PKIX path building failed` from `wsadmin`
**Cause:** The SOAP client does not trust the profile's self-signed certificate and prompts
`Add signer to the trust store now? (y/n)` on stdin; plain `docker exec` provides none.
**Fix:** `printf 'y\ny\n' | docker exec -i ...`. Note the `-i`.

### `SyntaxError` from a `wsadmin` Jython script that is valid Python
**Cause:** WAS 8.5.5 embeds **Jython 2.1** — no conditional expressions, no `True`/`False`,
no f-strings.
**Fix:** Plain `if`/`else`, `1`/`0`, `%` formatting.

### PMI reads back as unchanged after `AdminConfig.modify`
**Cause:** `AdminConfig.show(pmi, ['enable','statisticSet'])` omits `statisticSet`, so the
change looks lost when it is not.
**Fix:** Read it explicitly with `AdminConfig.showAttribute(pmi, 'statisticSet')`, or grep
`server.xml` for `statisticSet=`.

### All `ibm_was.jdbc.*` metrics are zero
**Cause:** Not a fault. A default profile has only the unused Derby XA provider.
**Fix:** Nothing. Expect non-zero values only with a real datasource under load.

### `can_connect` is CRITICAL
**Cause:** The Agent cannot reach `servlet_url` — usually the WebSphere container is not on
the Agent's docker network, or the name in `servlet_url` does not resolve.
**Fix:** `docker exec dd-agent getent hosts was85530`, and confirm both containers share the
network with `docker inspect <container> --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}'`.

## Limitations

- Metrics come from PMI, so they are counters and gauges sampled every 15 s — not traces. APM
  needs the Java tracer attached via `JVM_EXTRA_CMD_ARGS`, which this skill does not cover.
- Defaults cover JVM, thread pools, JDBC, and servlet sessions only. Transactions, EJB, JCA,
  ORB, and dynamic cache need `custom_queries`.
- The API key is passed as a container environment variable and is visible in
  `docker inspect`. Acceptable on a personal machine; use a secrets manager elsewhere.

## References

- `scripts/enable-perfservlet.sh` — backup, deploy PerfServlet, set PMI, restart, verify
- `scripts/enable-perfservlet.py` — the Jython the wrapper runs inside the container
- `scripts/ibm_was.d/conf.yaml` — check + logs config template (`@WAS_CONTAINER@` substituted)
- `scripts/run-dd-agent.sh` — network wiring and the containerised Agent
- `references/collected-metrics.md` — the metrics actually measured, with entity tags
- `references/datadog-platform-monitoring-was*.png` — backend proof that data arrived
- `docker/skills/setup-ibm-websphere-8-5-5-30/SKILL.md` — get WebSphere running first
- Datadog docs: https://docs.datadoghq.com/integrations/ibm_was/
