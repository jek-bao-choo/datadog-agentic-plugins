# TODO: vanillajs-instrumentation

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

## Tools

- `/websites/vite_dev` - Vite build tool documentation
- `/datadog/browser-sdk` - Datadog Browser SDK for RUM instrumentation
