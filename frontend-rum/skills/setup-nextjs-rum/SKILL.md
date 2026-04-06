---
name: setup-nextjs-rum
description: >-
  Use this skill whenever the user needs to set up a Next.js application with Datadog RUM.
  Triggers on mentions of Next.js RUM, Next.js Datadog monitoring, Next.js 15 setup,
  or browser monitoring for server-rendered React apps. Covers both JavaScript and TypeScript.
version: 0.1.0
version_matrix:
  nextjs_version: [15.4, 15.5]
---

# Next.js 15 — Datadog RUM Setup

Build a Next.js 15 application and configure Datadog Real User Monitoring for both client and server-side rendered pages.

## Prerequisites

- Node.js 18+ installed
- Datadog RUM application ID and client token

## Instructions

The application source is in `references/` with both JavaScript (Next.js 15.5) and TypeScript (Next.js 15.4) variants.

```bash
cd references/
npm install
npm run dev
```

### Configure Datadog RUM

Create a client component for RUM initialization:

```tsx
'use client';
import { datadogRum } from '@datadog/browser-rum';

datadogRum.init({
  applicationId: '<DD_APPLICATION_ID>',
  clientToken: '<DD_CLIENT_TOKEN>',
  site: 'datadoghq.com',
  service: 'nextjs-app',
  env: 'sandbox',
  sessionSampleRate: 100,
  trackUserInteractions: true,
  trackResources: true,
});

export default function DatadogRum() { return null; }
```

Include this component in your root layout.

## Validation

Open the app, navigate between pages, then check **RUM > Sessions** in the Datadog UI. Both client-side navigations and server-rendered page loads should appear.

## Troubleshooting

### RUM not initializing in Next.js App Router
**Cause:** RUM SDK called in a server component.
**Fix:** Ensure the RUM init is in a `'use client'` component.
