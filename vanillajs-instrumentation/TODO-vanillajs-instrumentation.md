## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `vanillajs-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---

## Phase 1: Vanilla JS Meter Reading App

- Scaffold a Vite project with the `vanilla` template
- Build a 3-page flow: Landing -> Enter Meter -> Submitted
- Make the app mobile-responsive (primary users are field workers on phones)
- Apply a utility company color theme (blues/greens, professional palette)
- Implement client-side routing or view transitions
- Ensure the app runs correctly with `npm run dev`

## Phase 2: Datadog RUM SDK

- Install `@datadog/browser-rum` SDK
- Import and initialize `datadogRum` in `main.js`
- Configure application ID, client token, service name, and environment
- Verify RUM events appear in the Datadog dashboard

## Guidelines

- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.

## Tools

- `/websites/vite_dev` - Vite build tool documentation
- `/datadog/browser-sdk` - Datadog Browser SDK for RUM instrumentation
