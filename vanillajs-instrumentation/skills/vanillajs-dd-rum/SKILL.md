---
name: vanillajs-dd-rum
description: Datadog RUM integration for vanilla JavaScript applications
---

# Datadog RUM for Vanilla JS

Add Datadog Real User Monitoring (RUM) to a vanilla JavaScript application using the `@datadog/browser-rum` npm package.

## Instructions

1. Install the Datadog Browser RUM SDK:
   ```bash
   npm install @datadog/browser-rum
   ```

2. Import and initialize RUM in `main.js`:
   ```js
   import { datadogRum } from '@datadog/browser-rum';

   datadogRum.init({
     applicationId: '<YOUR_APPLICATION_ID>',
     clientToken: '<YOUR_CLIENT_TOKEN>',
     site: 'datadoghq.com',
     service: '<YOUR_SERVICE_NAME>',
     env: '<YOUR_ENV>',
     sessionSampleRate: 100,
     sessionReplaySampleRate: 20,
     trackUserInteractions: true,
     trackResources: true,
     trackLongTasks: true,
     defaultPrivacyLevel: 'mask-user-input',
   });
   ```

3. Replace placeholder values with your actual Datadog application ID, client token, service name, and environment.

4. Verify RUM events appear in the Datadog dashboard after running the app.
