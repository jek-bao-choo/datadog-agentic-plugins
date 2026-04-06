---
name: html-dd-rum
description: Datadog RUM for static HTML via CDN script tag or Nginx auto-injection module
---

# Datadog RUM for Static HTML

Add Datadog Real User Monitoring (RUM) to a static HTML application using either a CDN script tag or the Nginx auto-injection module.

## Option 1: CDN Script Tag

Add the following script tag to the `<head>` of your HTML files:

```html
<script
  src="https://www.datadoghq-browser-agent.com/us1/v5/datadog-rum.js"
  type="text/javascript">
</script>
<script>
  window.DD_RUM && window.DD_RUM.init({
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
</script>
```

## Option 2: Nginx Auto-Injection

Use the Datadog Nginx auto-injection module to automatically inject the RUM SDK into all HTML responses served by Nginx, without modifying any HTML files.

1. Configure the Datadog agent with Nginx integration.
2. Enable RUM auto-injection in the Datadog agent configuration.
3. The agent will automatically inject the RUM script into HTML responses.

## Instructions

1. Choose one of the two options above.
2. Replace placeholder values with your actual Datadog application ID, client token, service name, and environment.
3. Verify RUM events appear in the Datadog dashboard.
