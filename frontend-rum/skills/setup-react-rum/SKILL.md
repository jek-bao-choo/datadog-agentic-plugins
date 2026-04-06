---
name: setup-react-rum
description: >-
  Use this skill whenever the user needs to set up a React application with Datadog RUM.
  Triggers on mentions of React RUM, React Datadog monitoring, React 19 setup with Vite,
  or browser monitoring for React apps. Also applies for Vite + React development setup.
version: 0.1.0
version_matrix:
  react_version: [19.1]
  vite_version: [7.1]
---

# React 19.1 + Vite — Datadog RUM Setup

Build a React 19.1 application with Vite 7.1 and configure Datadog Real User Monitoring.

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

Add the Datadog RUM SDK to your application entry point:

```javascript
import { datadogRum } from '@datadog/browser-rum';

datadogRum.init({
  applicationId: '<DD_APPLICATION_ID>',
  clientToken: '<DD_CLIENT_TOKEN>',
  site: 'datadoghq.com',
  service: 'react-sendmoney',
  env: 'sandbox',
  sessionSampleRate: 100,
  trackUserInteractions: true,
  trackResources: true,
  trackLongTasks: true,
});
```

## Validation

Open the app in a browser, perform some interactions, then check **RUM > Sessions** in the Datadog UI.

## Troubleshooting

### No RUM data appearing
**Cause:** Application ID or client token incorrect.
**Fix:** Verify values at **UX Monitoring > RUM Applications** in Datadog UI.
