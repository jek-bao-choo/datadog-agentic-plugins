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

## Phase 2: Datadog RUM Instrumentation

**Default approach: CDN script tag** (simpler, works everywhere)

Add the Datadog RUM CDN script to the `<head>` of every HTML file:

```html
<script src="https://www.datadoghq-browser-agent.com/us1/v5/datadog-rum.js" type="text/javascript"></script>
<script>
  window.DD_RUM && window.DD_RUM.init({
    clientToken: '<DD_CLIENT_TOKEN>',
    applicationId: '<DD_APPLICATION_ID>',
    site: 'datadoghq.com',
    service: 'html-webapp',
    env: 'sandbox',
    sessionSampleRate: 100,
    sessionReplaySampleRate: 100,
    trackUserInteractions: true,
    trackResources: true,
    trackLongTasks: true,
  });
</script>
```

**Advanced option: Nginx auto-injection module** — automatically injects the RUM script into all HTML responses without modifying source files. Use when you cannot edit the HTML source.

**Validation:**
- Open the HTML page in a browser, click around, then check **RUM > Sessions** in the Datadog UI
- Verify page views, user interactions, and resource timing appear
- Check browser console for any CSP errors (add `https://www.datadoghq-browser-agent.com` to `script-src` if needed)

## Guidelines

- Keep it simple. The static site should be the smallest thing that demonstrates the RUM pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to frontend observability should be able to follow along.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files. Use placeholders like `<DD_CLIENT_TOKEN>`.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools

- `/datadog/browser-sdk` - Datadog Browser SDK for RUM instrumentation
