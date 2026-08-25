# IBM WebSphere traditional, and how Datadog monitors it

Background for the `monitor-websphere-with-datadog` skill. `SKILL.md` is the procedure; this
file explains what the thing is and how the telemetry actually gets out of it.

## What is IBM WebSphere Application Server (tWAS)?

A Java EE / Jakarta EE **application server**: a long-running managed container that you
deploy applications *into*, as WAR or EAR archives, rather than a library your application
embeds. It supplies the servlet/JSP engine, EJB container, JTA transaction manager, JNDI
resource registry, JDBC connection pooling, JMS messaging, and a security realm — plus an
admin console, the `wsadmin` scripting client, and PMI instrumentation.

"WebSphere" is a brand covering several products, and the distinction matters when reading
IBM's docs:

| Product | What it is |
|---|---|
| **WebSphere Application Server traditional** (tWAS) | The heavyweight lineage. Profiles, cells, nodes, deployment manager. This is what the skill targets. |
| **WebSphere Liberty** | IBM's modern, lightweight, feature-composable server. Different runtime, shared brand. |
| **Open Liberty** | The open-source upstream of Liberty. |

The version this skill was verified against is tWAS **8.5.5.30** — the `8.5.5` line, fix
pack 30.

## What problem does it solve?

It comes from an era when the **runtime**, not the application, owned infrastructure
concerns. Instead of every application solving connection pooling, distributed transactions,
clustering, failover, and session replication for itself, the container provides them and
applications declare what they need through standard APIs and deployment descriptors.

What that buys:

- **Portability** — build against Java EE APIs, deploy on any compliant server.
- **Operational uniformity** — one console, one security realm, one clustering model across
  many applications from many teams.
- **Distributed transactions** — a JDBC datasource and a JMS queue committed atomically in
  one two-phase transaction. Genuinely hard without a container-managed transaction manager,
  and the capability most often cited for staying on tWAS.
- **Separation of duties** — developers ship an EAR; operators bind it to real datasources,
  hostnames, and credentials at deploy time. The artifact carries no environment secrets.

## Why is it used?

Almost never chosen for new work. It persists because of circumstance:

- **Existing applications** built against Java EE and, usually, WebSphere-specific
  behaviour — IBM JNDI naming, the IBM J9 JVM, IBM MQ integration, proprietary bindings.
- **Support and compliance** — regulated industries want a vendor contract behind the
  runtime, on a version they have already certified.
- **Migration cost** — a large EAR estate with EJBs and container-managed transactions is
  expensive to re-platform, and the migration ships no user-visible feature.
- **The surrounding IBM stack** — MQ, DB2, DataPower and IBM tooling all assume it.

Put plainly: it is required by inertia and support obligations far more often than by
capability.

## Alternatives

**Peers — full Java EE servers.** Same architectural model, so a migration is a port rather
than a rewrite.

- **Oracle WebLogic** — the closest commercial equivalent; similar clustering and JTA story.
- **JBoss EAP** (and its free upstream **WildFly**) — the usual choice when leaving tWAS but
  keeping Java EE. Red Hat support contract available.
- **Payara** / **GlassFish** — the Jakarta EE reference lineage.

**Lighter — servlet containers.** Enough for the large share of "enterprise" applications
that were only ever web applications.

- **Tomcat** — servlet/JSP only: no EJB, no JTA, no JMS. If an app uses none of those, this
  is often the honest answer, and the operational simplification is large.
- **Jetty** — similar scope, embeddable, common inside other products.
- **TomEE** — Tomcat plus the Java EE pieces, for apps that need a few of them.

**Modern — framework-first.** Inverts the model: the application embeds the server and ships
as a single artifact, while the container platform supplies clustering and failover.

- **Spring Boot** — embedded Tomcat/Jetty/Undertow, fat JAR, Kubernetes handles the rest.
- **Quarkus**, **Micronaut**, **Helidon** — same inversion, tuned for fast startup and low
  memory.

The industry moved to that last group: the app server's responsibilities were absorbed by
the framework and the orchestrator.

## How the Datadog Agent monitors it

### Is it using JMX? No.

Worth stating clearly, because it is the natural assumption for a Java server, and because
tWAS *does* expose JMX. On a default profile the server log even advertises it:

```
ADMC0058I: The JMX JSR160RMI connector is available at port 2809
```

You could point Datadog's generic `jmx` check (JMXFetch) at that connector and write your own
bean queries. But the **`ibm_was` integration does not.** It never opens a JMX connection.

### It uses PerfServlet, which exposes PMI counters as XML over HTTP. Yes.

Exactly that. The mechanism has three parts:

1. **PMI — Performance Monitoring Infrastructure.** WebSphere's built-in instrumentation.
   The server maintains counters for thread pools, JDBC pools, sessions, the JVM, and more.
   PMI has a **statistic set** controlling how much is recorded; the default is `basic`,
   which is too sparse for the integration. It must be raised to `all`, and that only takes
   effect after a server restart.

2. **PerfServlet — the HTTP front door to PMI.** An IBM-supplied servlet, shipped inside the
   image as `installableApps/PerfServletApp.ear`. Once deployed it serves at
   `/wasPerfTool/servlet/perfservlet` and renders the current PMI tree as XML.

3. **The Agent's `ibm_was` check** performs a plain HTTP GET against that URL on each
   collection interval, parses the XML, and emits Datadog metrics.

So the data path is `PMI counters → PerfServlet → XML over HTTP → Agent check → Datadog`.
Nothing more exotic. A useful consequence: you can verify the entire server-side half with
`curl` before involving the Agent at all.

The payload is a `<PerformanceMonitor>` document — roughly **152 KB** on a default profile
with `statisticSet=all`:

```xml
<PerformanceMonitor responseStatus="success" version="8.5.5.30">
<Node name="DefaultNode01">
<Server name="server1">
<Stat name="server">
  <CountStatistic ID="1" count="74" name="RequestCount" unit="None"/>
  <DoubleStatistic ID="3" double="78.378" name="HitRate" .../>
```

### Architecture

How it fits together on a macOS/Colima laptop. On a Linux host the Colima boundary
disappears; everything else is identical.

```
  macOS host
 ┌────────────────────────────────────────────────────────────────────────┐
 │  Colima VM  —  Linux kernel + Docker daemon                            │
 │                                                                        │
 │  docker network: dd-was   (containers resolve each other by name)      │
 │                                                                        │
 │   ┌────────────────────────────┐      ┌────────────────────────────┐   │
 │   │ container: was85530        │      │ container: dd-agent        │   │
 │   │                            │      │                            │   │
 │   │  IBM J9 JVM                │      │  ibm_was check             │   │
 │   │  └─ server1 (tWAS)         │      │   runs every 15s           │   │
 │   │     ├─ PMI counters        │      │                            │   │
 │   │     │    thread pools      │      │                            │   │
 │   │     │    JDBC pools        │      │                            │   │
 │   │     │    sessions          │      │                            │   │
 │   │     │    JVM memory        │      │                            │   │
 │   │     │         │            │      │                            │   │
 │   │     │         ▼            │      │                            │   │
 │   │     ├─ PerfServlet         │◄─────┤  GET /wasPerfTool/         │   │
 │   │     │    :9080             │      │      servlet/perfservlet   │   │
 │   │     │                      ├─────►│  PMI tree as XML, ~152 KB  │   │
 │   │     └─ deployed apps       │      │                            │   │
 │   │                            │      │                            │   │
 │   │  /logs                     │      │  logs tailer               │   │
 │   │   ├─ SystemOut.log         ├─────►│   /was-logs  (read-only)   │   │
 │   │   └─ SystemErr.log         │      │                            │   │
 │   │        via volume was85530-logs   │                            │   │
 │   └────────────────────────────┘      └─────────────┬──────────────┘   │
 │                                                     │                  │
 └─────────────────────────────────────────────────────┼──────────────────┘
                                                       │ HTTPS + API key
                                                       ▼
                                            ┌──────────────────────────┐
                                            │  Datadog  (US1)          │
                                            │   metrics                │
                                            │   logs                   │
                                            │   service checks         │
                                            └──────────────────────────┘
```

Two things the diagram is making explicit, both of which shaped the skill:

- **The Agent runs in a container, not on the host.** The WAS log volume lives *inside* the
  Colima VM. A host-installed Agent cannot see `/var/lib/docker/volumes/...` at all, so it
  can never tail `SystemOut.log`, however it is configured. An Agent on the Docker host can
  mount the volume directly.
- **Both containers share a user-defined network.** That gives DNS by container name
  (`http://was85530:9080/...`) instead of a bridge IP that changes on restart. The running
  WAS container is attached with `docker network connect`, so it is never recreated — which
  matters, because a tWAS profile's configuration lives in the container layer.

## What telemetry is collected

Measured on a real 8.5.5.30 profile with `statisticSet=all`, integration v5.5.1:
**355 metric samples per collection, 30 unique metric names.** Sample count exceeds name
count because most metrics are emitted once per entity — per thread pool, per web
application, per JDBC provider.

| Family | Names | What it tells you | Entity tag |
|---|---|---|---|
| `ibm_was.thread_pools.*` | 6 | Request-serving capacity: active threads, pool size, `percent_used`, `percent_maxed`, hung-thread count | `thread_pool:` (11 pools; `WebContainer` is the one that matters) |
| `ibm_was.servlet_session.*` | 9 | Live and active sessions, session object size, external read/write timings | `web_application:<app>#<module>.war` |
| `ibm_was.jdbc.*` | 8 | Connection pool size, free pool, `percent_used`, wait time, use time | `provider:` |
| `ibm_was.jvm.*` | 6 | Heap size, used and free memory, CPU usage, uptime | none — one series each |
| `ibm_was.can_connect` | service check | `OK`/`CRITICAL` on PerfServlet reachability | `url:` |

Plus, from the containerised Agent independently of the `ibm_was` check:

- **Logs** — `SystemOut.log` and `SystemErr.log`, tagged `source:ibm_was service:websphere`,
  with a multi-line rule so Java stack traces stay in one event.
- **Container metrics** — `container.cpu.*`, `container.memory.*` for both containers, via the
  mounted Docker socket.

**What is *not* collected by default:** transaction manager, EJB containers, JCA pools, ORB,
dynamic cache, web services. PMI exposes these; the integration's defaults do not read them.
Add `custom_queries` to `conf.yaml` if a customer needs them.

**Expect zeros in `ibm_was.jdbc.*` on a bare profile.** A default install has only an unused
Derby XA provider. Zeros there are correct, not a broken check.

Full measured list with example values: `references/collected-metrics.md`.

## Two prerequisites worth knowing before you start

- **PMI defaults to `basic`.** Skip raising it to `all` and the check connects, reports
  healthy, and returns almost nothing. The absence looks like a broken integration.
- **IBM's application-security prerequisite did not apply here.** IBM's docs, quoted by
  Datadog, say application security must be enabled for PerfServlet. On the
  `icr.io/appcafe/websphere-traditional:8.5.5.30` image PerfServlet answered `200` both with
  and without credentials while `appEnabled="false"` — so the shipped config carries no
  password. Re-test on your own build rather than assuming either way.

## References

- `SKILL.md` — the procedure, validation, and troubleshooting
- `references/collected-metrics.md` — every metric measured, with entity tags
- `docker/skills/setup-ibm-websphere-8-5-5-30/` — standing the server up in the first place
- Datadog integration docs: https://docs.datadoghq.com/integrations/ibm_was/
- IBM's container repository: https://github.com/WASdev/ci.docker.websphere-traditional
