---
name: nextjs-instrumentation
category: instrumentation
requires:
  - aws-ec2
  - aws-eks
  - gcp-gke
  - gcp-cloudrun
supported_versions:
  nextjs_version: [15.4, 15.5]
---

# Next.js Instrumentation Plugin

Instrument Next.js applications with Datadog RUM. Covers Next.js 15.4 (TypeScript) and 15.5 (JavaScript).

## Skills

| Skill | Description |
|-------|-------------|
| `setup-nextjs-ts` | Next.js 15.4 App Router project setup (TypeScript) |
| `setup-nextjs-js` | Next.js 15.5 App Router project setup (JavaScript) |
| `nextjs-dd-rum` | Datadog RUM integration for Next.js |

## Recommended Workflow

1. Pick **one** of the setup skills based on your language preference:
   - `setup-nextjs-ts` for TypeScript (Next.js 15.4)
   - `setup-nextjs-js` for JavaScript (Next.js 15.5)
2. Run `nextjs-dd-rum` to add Datadog Real User Monitoring.
