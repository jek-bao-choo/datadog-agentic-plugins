---
name: vue-dd-rum
description: >-
  Use this skill whenever the user wants to instrument a Vue.js app with Datadog RUM.
  Triggers on mentions of Datadog RUM for Vue, Vue browser monitoring, Vue session replay,
  Vue frontend observability, or Datadog Vue integration.
version: 0.1.0
---

# Vue — Datadog RUM Instrumentation

Instrument Vue.js applications with Datadog RUM SDK for session tracking, user monitoring, and session replay.

## Prerequisites

- Skill `setup-vue` has been completed successfully
- Datadog client token and RUM application ID
- App running on `http://localhost:5173`

## Instructions

### 1. Install Datadog RUM SDK

```bash
npm install @datadog/browser-rum
```

### 2. Initialize Datadog RUM in main.js

In `src/main.js`, add RUM initialization before mounting the app:

```javascript
import { createApp } from 'vue'
import { datadogRum } from '@datadog/browser-rum'
import './style.css'
import App from './App.vue'

// Initialize Datadog RUM
datadogRum.init({
  applicationId: '<DD_APPLICATION_ID>',
  clientToken: '<DD_CLIENT_TOKEN>',
  site: 'datadoghq.com',
  service: 'my-vue-app',
  env: 'test',
  version: '1.0.0',
  sessionSampleRate: 100,
  sessionReplaySampleRate: 100,
  defaultPrivacyLevel: 'mask-user-input',
})

// Set user information for session identification
datadogRum.setUser({
  id: 'user-12345',
  name: 'John Doe',
  email: 'user-12345@example.com',
})

createApp(App).mount('#app')
```

### 3. Verify RUM is loaded

Open browser DevTools Network tab and look for requests to `datadoghq.com`. RUM events should be sent as the user interacts with the app.

## Validation

1. Use the app for 1-2 minutes (select stocks, submit buy orders, navigate)
2. Check **UX Monitoring > RUM > Sessions** in the Datadog UI
3. Verify sessions, views, actions, and errors appear
4. Check Session Replay recordings are captured

## Troubleshooting

### No RUM data appearing
**Cause:** Client token or application ID incorrect.
**Fix:** Verify credentials at **UX Monitoring > RUM Applications** in Datadog UI.

### Session Replay not recording
**Cause:** `sessionReplaySampleRate` set to 0 or privacy level too restrictive.
**Fix:** Ensure `sessionReplaySampleRate: 100` during development.

### RUM events not sending
**Cause:** Ad blocker or network issue blocking Datadog endpoints.
**Fix:** Disable ad blockers for localhost. Check browser console for blocked requests.

### Duplicate sessions on page reload
**Cause:** RUM initialized multiple times during Vite HMR.
**Fix:** Add a guard: `if (!window.__DATADOG_RUM_INSTALLED__) { ... window.__DATADOG_RUM_INSTALLED__ = true }`.
