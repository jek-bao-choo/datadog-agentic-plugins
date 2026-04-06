## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `html-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Static HTML + Nginx

- Create static HTML pages (index.html, CSS, static assets)
- Create an Nginx configuration file for serving static content
- Create a Dockerfile based on the official `nginx` image
- Build and run the Docker container
- Verify the static site is accessible at `http://localhost:8080`

## Phase 2: Datadog RUM Auto-Injection

- Choose instrumentation method: CDN script tag or Nginx auto-injection module
- If CDN: Add the Datadog RUM script tag to the `<head>` of HTML files
- If Nginx auto-injection: Configure the Datadog agent with Nginx integration and enable RUM auto-injection
- Configure application ID, client token, service name, and environment
- Verify RUM events appear in the Datadog dashboard

## Tools

- `/datadog/browser-sdk` - Datadog Browser SDK for RUM instrumentation
