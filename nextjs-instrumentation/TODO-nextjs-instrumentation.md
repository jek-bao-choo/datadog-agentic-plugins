## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `nextjs-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---
## Phase 1: App Setup

### TypeScript App (Next.js 15.4)
- Scaffold a Next.js 15.4 TypeScript App Router project
- Build a "PlanHoliday" application with pages for browsing and planning holiday destinations
- Ensure the app runs correctly with `npm run dev`

## Phase 2: Datadog RUM

- Install `@datadog/browser-rum` SDK
- Create a `DatadogInit` client component using the `'use client'` directive (required for App Router since server components cannot run browser-side SDK code)
- Initialize `datadogRum.init()` inside a `useEffect` hook in the client component
- Include the `DatadogInit` component in the root layout (`app/layout.tsx` or `app/layout.js`)
- Configure application ID, client token, service name, and environment
- Verify RUM events appear in the Datadog dashboard

## Tools

- `/vercel/next.js` - Next.js framework documentation and APIs
- `/datadog/browser-sdk` - Datadog Browser SDK for RUM instrumentation
