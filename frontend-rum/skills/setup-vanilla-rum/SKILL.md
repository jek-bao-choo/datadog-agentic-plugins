---
name: setup-vanilla-rum
description: >-
  Use this skill whenever the user needs to set up a Vanilla JavaScript application with
  Datadog RUM. Triggers on mentions of Vanilla JS RUM, plain JavaScript Datadog monitoring,
  Vite vanilla app, or browser monitoring without a framework.
version: 0.1.0
version_matrix:
  vite_version: [7.2]
---

# Vanilla JS + Vite — Datadog RUM Setup

Build a Vanilla JavaScript application with Vite and configure Datadog Real User Monitoring.

## Prerequisites

- Node.js 18+ installed
- Datadog RUM application ID and client token

## Instructions

The complete application source is in `references/`.

```bash
cd references/
npm install
npm run dev
```

### Configure Datadog RUM

Add the RUM SDK to your main JavaScript entry point:

```javascript
import { datadogRum } from '@datadog/browser-rum';

datadogRum.init({
  applicationId: '<DD_APPLICATION_ID>',
  clientToken: '<DD_CLIENT_TOKEN>',
  site: 'datadoghq.com',
  service: 'vanilla-app',
  env: 'sandbox',
  sessionSampleRate: 100,
  trackUserInteractions: true,
});
```

## Validation

Open the app in a browser, submit some forms or click buttons, then check **RUM > Sessions** in the Datadog UI.

## Troubleshooting

### RUM SDK not loading
**Cause:** `@datadog/browser-rum` not in package.json.
**Fix:** `npm install @datadog/browser-rum`
