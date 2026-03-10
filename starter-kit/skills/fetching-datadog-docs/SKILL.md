---
name: fetching-datadog-docs
description: >-
  This skill should be used when the user needs to look up Datadog product documentation,
  find API references, check feature configuration steps, or locate integration setup guides.
  Use this skill whenever the user asks "how do I configure X in Datadog", "what are the
  Datadog API endpoints for Y", "show me the docs for Z", "find the Datadog documentation
  on monitors/logs/APM/RUM/synthetics", or "what are the rate limits for the Datadog API".
  Also use it when the user mentions Datadog docs, llms.txt, Datadog documentation lookup,
  or Datadog integration references — even if they don't explicitly say "look up documentation".
  It also applies when the user asks "how do I troubleshoot the Datadog Agent" or needs
  help diagnosing Agent connectivity, log collection, or metric submission issues.
version: "1.1.0"
author: datadog-labs
tags: datadog,docs,llms.txt,fetching-datadog-docs
---

# Datadog Documentation Lookup

Use this skill to locate and retrieve Datadog documentation pages on any product, feature, API, or integration. Datadog publishes an LLM-optimized documentation index at `https://docs.datadoghq.com/llms.txt` which lists every product page with a short description and a direct URL. This index is the single best starting point for any documentation lookup — it is always up to date and covers the full breadth of Datadog's documentation site.

Follow the four-step workflow below: fetch the index, search it for the relevant topic, retrieve the full Markdown content of matching pages, and cross-reference related pages to build a complete answer.

## Common Use Cases

- **Configuration lookups** — find step-by-step instructions for configuring monitors, dashboards, SLOs, alerting rules, or notification channels within Datadog.
- **API endpoint references** — locate Datadog REST API endpoints, request/response schemas, authentication methods, pagination patterns, and SDK usage examples.
- **Product feature documentation** — look up capabilities and configuration of APM, Logs, Metrics, RUM, Synthetics, Profiling, or any other Datadog product area.
- **Agent installation and troubleshooting** — find Datadog Agent installation steps, configuration file references, proxy setup, and troubleshooting guides for Linux, macOS, Windows, Docker, and Kubernetes environments.
- **Integration setup guides** — locate documentation for 800+ integrations including AWS, GCP, Azure, Kubernetes, PostgreSQL, MySQL, Redis, Nginx, Apache, and many more. Each integration page includes setup instructions, collected metrics, and configuration options.
- **Limits, quotas, and rate limits** — find official limits on API rate limits, metric submission rates, log ingestion quotas, retention policies, and custom metric cardinality limits. Always fetch the latest page rather than relying on memorised values.
- **Security and compliance documentation** — look up Datadog's security features including Cloud Security Management, Application Security Monitoring, Cloud Workload Security, audit logging, and data privacy controls.

## How to Look Up Documentation

### Step 1 — Fetch the index

Datadog's `llms.txt` file is a plain-text index containing 500+ documentation page links, each with a short description. This file is lightweight and fast to fetch. Start every documentation lookup by fetching this index to understand what pages are available:

```bash
curl -s https://docs.datadoghq.com/llms.txt | head -200
```

The file is organised by product area (Infrastructure, APM, Logs, Security, etc.). Each entry contains a URL and a brief description of that page's content. The full file is typically under 100 KB, so it can be fetched and searched quickly. Do not skip this step — it prevents guessing at URLs and ensures you find the most relevant page.

### Step 2 — Search the index for your topic

Use `grep` to filter the index for relevant pages. Search terms should be broad enough to capture related pages but specific enough to avoid hundreds of results. Use case-insensitive matching (`-i`) and combine terms with `\|` for OR logic:

```bash
# Find all pages related to monitors
curl -s https://docs.datadoghq.com/llms.txt | grep -i "monitors"

# Find APM and tracing pages
curl -s https://docs.datadoghq.com/llms.txt | grep -i "apm\|tracing"

# Find integration docs for PostgreSQL
curl -s https://docs.datadoghq.com/llms.txt | grep -i "postgres"

# Find Datadog Agent pages
curl -s https://docs.datadoghq.com/llms.txt | grep -i "agent"

# Find API reference pages
curl -s https://docs.datadoghq.com/llms.txt | grep -i "api"
```

If the first search returns no results, try synonyms or broader terms. For example, search for "trace" instead of "distributed tracing", or "rum" instead of "real user monitoring".

### Step 3 — Fetch the full page content

Append `.md` to most Datadog documentation URLs to retrieve the raw Markdown content instead of HTML. This is the preferred format for reading documentation programmatically because it strips navigation chrome, sidebars, and JavaScript, leaving only the content. The Markdown version follows the same path structure as the HTML page:

```bash
# Fetch the monitors overview page
curl -s https://docs.datadoghq.com/monitors.md

# Fetch the APM/tracing overview
curl -s https://docs.datadoghq.com/tracing.md

# Fetch a sub-page (metric monitors)
curl -s https://docs.datadoghq.com/monitors/types/metric.md
```

For long pages, pipe through `head` to read the first section before fetching the full content:

```bash
curl -s https://docs.datadoghq.com/logs.md | head -200
```

### Step 4 — Cross-reference related pages

Datadog documentation is structured hierarchically. An overview page (e.g., `/monitors/`) links to type-specific sub-pages (e.g., `/monitors/types/metric/`, `/monitors/types/anomaly/`). After reading the overview, follow links to the specific sub-page that matches the user's question. This is especially important for broad topics like monitors, integrations, or security, where the overview page provides context but the detailed configuration steps live on sub-pages. Also cross-reference with the API reference when the user needs to perform operations programmatically:

```bash
# Read the monitors overview first
curl -s https://docs.datadoghq.com/monitors.md | head -100

# Then fetch the specific monitor type
curl -s https://docs.datadoghq.com/monitors/types/metric.md

# And the API reference for creating monitors
curl -s https://docs.datadoghq.com/api/latest/monitors.md
```

## Key Documentation Sections

| Topic | URL |
|-------|-----|
| APM / Tracing | https://docs.datadoghq.com/tracing/ |
| Logs | https://docs.datadoghq.com/logs/ |
| Metrics | https://docs.datadoghq.com/metrics/ |
| Monitors | https://docs.datadoghq.com/monitors/ |
| Dashboards | https://docs.datadoghq.com/dashboards/ |
| Security | https://docs.datadoghq.com/security/ |
| Synthetics | https://docs.datadoghq.com/synthetics/ |
| RUM | https://docs.datadoghq.com/real_user_monitoring/ |
| Incidents | https://docs.datadoghq.com/service_management/incident_management/ |
| API Reference | https://docs.datadoghq.com/api/ |
| Datadog Agent | https://docs.datadoghq.com/agent/ |
| Integrations | https://docs.datadoghq.com/integrations/ |
| CI/CD Visibility | https://docs.datadoghq.com/continuous_integration/ |
| Cloud Security | https://docs.datadoghq.com/security/cloud_security_management/ |
| SLOs | https://docs.datadoghq.com/service_management/service_level_objectives/ |
| Database Monitoring | https://docs.datadoghq.com/database_monitoring/ |
| Network Monitoring | https://docs.datadoghq.com/network_monitoring/ |
| Serverless | https://docs.datadoghq.com/serverless/ |

## Datadog Documentation by Region

Datadog operates in multiple regions worldwide. The documentation site (`docs.datadoghq.com`) is shared across all regions and always contains the same content. However, API endpoints and in-app application URLs differ by region. When constructing API calls or linking to the Datadog application, use the correct site for the user's environment:

| Region | Documentation Site | API Site |
|--------|--------------------|----------|
| US1 (default) | https://docs.datadoghq.com | https://api.datadoghq.com |
| US3 | https://docs.datadoghq.com | https://api.us3.datadoghq.com |
| US5 | https://docs.datadoghq.com | https://api.us5.datadoghq.com |
| EU | https://docs.datadoghq.com | https://api.datadoghq.eu |
| AP1 | https://docs.datadoghq.com | https://api.ap1.datadoghq.com |
| US1-FED | https://docs.datadoghq.com | https://api.ddog-gov.com |

## Scope Guardrails

- Always use `llms.txt` as the entry point for documentation lookups rather than guessing URLs. The index is the authoritative source for available pages.
- Verify information against the fetched documentation before citing it. Do not paraphrase from memory when the actual page content is available.
- Do not guess rate limits, quotas, or numeric thresholds. These values change over time — always fetch the current documentation page to confirm.
- This skill is lookup-only. It retrieves and reads documentation. It does not modify Datadog configurations, call the Datadog API, or interact with a Datadog account.
- When the user asks about a specific integration, check the integrations documentation at `https://docs.datadoghq.com/integrations/` first, as integration-specific configuration is documented there rather than in the general product pages.

## Failure Handling

- If `https://docs.datadoghq.com/llms.txt` is unreachable, try fetching a known documentation page directly (e.g., `https://docs.datadoghq.com/getting_started.md`) to confirm whether the site is down or only the index is unavailable.
- If a URL returns HTML instead of Markdown, ensure the `.md` extension is appended to the path. Not all pages support the `.md` suffix — if the Markdown version is unavailable, fall back to reading the HTML content.
- If a page returns a 404 error, go back to `llms.txt` and search for the correct URL. Documentation paths change when pages are reorganised — the index always reflects the current structure.
- If a page is too large to process in a single fetch, use `head` to read the first 200-300 lines and identify the specific section headings, then use `grep` or `sed` to extract the relevant section.
- For region-specific documentation (e.g., EU or government cloud), note that all regions share the same documentation site (`docs.datadoghq.com`). Only API endpoints and in-app URLs differ by region — refer to the region table above.

## Bundled Resources

This skill does not currently bundle any local files — all documentation is fetched live from `docs.datadoghq.com` at the time of the lookup. This ensures the information is always current, as Datadog updates their documentation frequently.

Future versions of this skill may include:
- A `references/` directory with cached snapshots of commonly referenced pages (e.g., rate limits, API authentication) for offline or faster access.
- A `scripts/` directory with helper utilities for bulk documentation retrieval, index caching, or structured search across multiple pages.
