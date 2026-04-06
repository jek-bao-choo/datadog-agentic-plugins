# TODO: nextjs-instrumentation

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
