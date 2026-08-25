# Metrics actually collected

Captured from `agent check ibm_was --json` against WAS traditional **8.5.5.30** with
`statisticSet=all`, integration **v5.5.1**, Agent **7.80.3**. 355 metric samples per run,
**30 unique metric names**. Datadog's docs list ~52 for the integration; the rest need
either `custom_queries` or PMI modules this profile does not exercise.

Sample counts exceed name counts because most metrics are emitted per entity — one series
per thread pool, per web application, per JDBC provider.

## ibm_was.jvm.* (6)

| Metric | Example |
|---|---|
| `heap_size` | 68224 |
| `heap_size_gauge` | 68224 |
| `used_memory_gauge` | 57014 |
| `free_memory_gauge` | 14659 |
| `up_time_gauge` | 558 |
| `process_cpu_usage_gauge` | 0 |

Not tagged per entity — one series each. The non-`_gauge` variants are deprecated upstream
in favour of the `_gauge` ones.

## ibm_was.thread_pools.* (6)

`active_count`, `active_time`, `concurrent_hung_thread_count`, `percent_maxed`,
`percent_used`, `pool_size`

Tagged `thread_pool:<name>`. 11 pools on a default profile:

`WebContainer`, `Default`, `ObjectRequestBroker` (`Object Request Broker`), `Message Listener`,
`SoapConnectorThreadPool`, `HAManager.thread.pool`, `TCPChannel.DCS`, `AriesThreadPool`,
`SIBFAPThreadPool`, `SIBFAPInboundThreadPool`, `WMQJCAResourceAdapter`

`WebContainer` is the one that matters for request-serving capacity.

## ibm_was.servlet_session.* (9)

`active_count`, `live_count`, `life_time`, `session_object_size`,
`time_since_last_activated`, `external_read_size`, `external_read_time`,
`external_write_size`, `external_write_time`

Tagged `web_application:<app>#<module>.war`. Verified live: 12 GETs against a JSP produced
`servlet_session.live_count = 12` on `web_application:sample#sample.war` — JSPs create a
session by default.

## ibm_was.jdbc.* (8)

`pool_size`, `free_pool_size`, `percent_used`, `percent_maxed`, `waiting_thread_count`,
`jdbc_time`, `use_time`, `wait_time`

Tagged `provider:<name>`. A default profile reports `provider:Derby JDBC Provider (XA)` with
all values **0** — the provider exists but nothing uses it. Non-zero values need a real
datasource under load, so do not treat zeros here as a broken check.

## Service check

`ibm_was.can_connect` — `OK` / `CRITICAL` on PerfServlet reachability, tagged with `url:`.

## Not collected by default

No metrics for the transaction manager, EJB containers, JCA connection pools, ORB, dynamic
cache, or web services. PMI exposes them; the integration's defaults do not read them. Add
`custom_queries` in `conf.yaml` if a customer needs them.
