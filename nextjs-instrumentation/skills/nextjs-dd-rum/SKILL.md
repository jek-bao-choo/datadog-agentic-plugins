---
name: nextjs-dd-rum
description: Datadog RUM integration for Next.js applications
---

# Datadog RUM for Next.js

Add Datadog Real User Monitoring (RUM) to a Next.js application.

## IMPORTANT

RUM initialization **must** be placed in a `'use client'` component. Next.js uses server components by default, and the Datadog RUM SDK requires browser APIs that are only available on the client side.

## Instructions

1. Install the Datadog Browser SDK:
   ```bash
   npm install @datadog/browser-rum
   ```

2. Create a `DatadogInit` client component (e.g., `app/components/DatadogInit.tsx` or `.jsx`):
   ```tsx
   'use client';

   import { useEffect } from 'react';
   import { datadogRum } from '@datadog/browser-rum';

   export default function DatadogInit() {
     useEffect(() => {
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
     }, []);

     return null;
   }
   ```

3. Include the `DatadogInit` component in your root layout (`app/layout.tsx` or `app/layout.js`):
   ```tsx
   import DatadogInit from './components/DatadogInit';

   export default function RootLayout({ children }) {
     return (
       <html lang="en">
         <body>
           <DatadogInit />
           {children}
         </body>
       </html>
     );
   }
   ```

4. Replace placeholder values with your actual Datadog application ID, client token, service name, and environment.
