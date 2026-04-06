---
name: setup-vue-rum
description: >-
  Use this skill whenever the user needs to set up a Vue.js application with Datadog RUM.
  Triggers on mentions of Vue RUM, Vue Datadog monitoring, Vue 3 setup with Vite,
  or browser monitoring for Vue apps.
version: 0.1.0
version_matrix:
  vue_version: [3.5]
  vite_version: [7.1]
---

# Vue 3.5 + Vite — Datadog RUM Setup

Build a Vue 3.5 application with Vite 7.1 and configure Datadog Real User Monitoring.

## Prerequisites

- Node.js 18+ installed
- Datadog RUM application ID and client token

## Instructions

The complete application source is in `references/`. To run locally:

```bash
cd references/
npm install
npm run dev
```

### Configure Datadog RUM

Add the Datadog RUM SDK in your Vue app initialization (e.g., `main.js` or `main.ts`):

```javascript
import { datadogRum } from '@datadog/browser-rum';

datadogRum.init({
  applicationId: '<DD_APPLICATION_ID>',
  clientToken: '<DD_CLIENT_TOKEN>',
  site: 'datadoghq.com',
  service: 'vue-tradestocks',
  env: 'sandbox',
  sessionSampleRate: 100,
  trackUserInteractions: true,
});

createApp(App).mount('#app');
```

## Validation

Open the app in a browser, interact with it, then check **RUM > Sessions** in the Datadog UI.

## Troubleshooting

### RUM sessions show but no user interactions
**Cause:** `trackUserInteractions` not set to `true`.
**Fix:** Enable it in the RUM init configuration.
