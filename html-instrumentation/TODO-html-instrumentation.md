# TODO: html-instrumentation

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
