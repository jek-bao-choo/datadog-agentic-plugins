---
name: html-instrumentation
category: instrumentation
requires:
  - aws-ec2
---

# HTML Instrumentation Plugin

Instrument static HTML applications with Datadog RUM via auto-injection on Nginx.

**Note:** No build tool is needed. Datadog RUM can be added via a CDN script tag or Nginx auto-injection.

## Skills

| Skill | Description |
|-------|-------------|
| `setup-html-nginx` | Static HTML app served by Nginx (Docker) |
| `html-dd-rum` | Datadog RUM via CDN script tag or Nginx auto-injection |

## Recommended Workflow

1. Run `setup-html-nginx` to set up the static HTML app with Nginx.
2. Run `html-dd-rum` to add Datadog RUM instrumentation.
