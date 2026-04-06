---
name: setup-html-rum
description: >-
  Use this skill whenever the user needs to set up Datadog RUM for static HTML pages
  served by Nginx. Triggers on mentions of HTML RUM, RUM auto-injection, Nginx RUM,
  or browser monitoring for static websites without a build tool.
version: 0.1.0
---

# Static HTML + Nginx — Datadog RUM Auto-Injection

Set up Datadog RUM auto-injection for static HTML applications served by Nginx.

## Prerequisites

- Docker (for Nginx container)
- Datadog RUM application ID and client token

## Instructions

The reference files in `references/` contain the HTML, Nginx config, and Docker setup.

### Option A: Nginx with RUM script tag

Add the Datadog RUM CDN script to your HTML `<head>`:

```html
<script
  src="https://www.datadoghq-browser-agent.com/us1/v5/datadog-rum.js"
  type="text/javascript">
</script>
<script>
  window.DD_RUM && window.DD_RUM.init({
    clientToken: '<DD_CLIENT_TOKEN>',
    applicationId: '<DD_APPLICATION_ID>',
    site: 'datadoghq.com',
    service: 'html-webapp',
    env: 'sandbox',
    sessionSampleRate: 100,
  });
</script>
```

### Option B: Auto-injection via Nginx

Use the Datadog Nginx module to automatically inject the RUM script into all HTML responses without modifying source files.

## Validation

Open any page in a browser, then check **RUM > Sessions** in the Datadog UI.

## Troubleshooting

### RUM script blocked by CSP
**Cause:** Content Security Policy doesn't allow the Datadog CDN.
**Fix:** Add `https://www.datadoghq-browser-agent.com` to `script-src` in your CSP header.
