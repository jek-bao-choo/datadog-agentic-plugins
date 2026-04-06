---
name: react-dd-rum
description: >-
  Use this skill whenever the user wants to instrument a React app with Datadog RUM and
  Feature Flags. Triggers on mentions of Datadog RUM for React, browser monitoring,
  session replay, React feature flags, OpenFeature with Datadog, or frontend observability.
version: 0.1.0
---

# React — Datadog RUM + Feature Flags Instrumentation

Instrument React applications with Datadog RUM SDK for session tracking, user monitoring, session replay, and Feature Flags via the OpenFeature standard.

## Prerequisites

- Skill `setup-react` has been completed successfully
- Datadog client token and RUM application ID
- App running on `http://localhost:5173`

## Instructions

### 1. Install Datadog RUM SDK

```bash
npm install @datadog/browser-rum
```

### 2. Initialize Datadog RUM

Create `src/datadog-rum.js`:

```javascript
import { datadogRum } from '@datadog/browser-rum'

if (typeof window !== 'undefined' && !window.__DATADOG_RUM_INSTALLED__) {
  datadogRum.init({
    applicationId: '<DD_APPLICATION_ID>',
    clientToken: '<DD_CLIENT_TOKEN>',
    site: 'datadoghq.com',
    service: 'my-react-app',
    env: 'test',
    version: '1.0.0',
    sessionSampleRate: 100,
    sessionReplaySampleRate: 100,
    defaultPrivacyLevel: 'mask-user-input',
  })

  datadogRum.setUser({
    id: 'user-12345',
    name: 'John Doe',
    email: 'user-12345@example.com',
  })

  window.__DATADOG_RUM_INSTALLED__ = true
}

export { datadogRum }
```

### 3. Import RUM in your entry point

In `src/main.jsx`, add:

```javascript
import './datadog-rum'
```

### 4. Add Feature Flags (6-step process)

Feature Flags use the OpenFeature standard with Datadog as the provider.

#### Step 1: Install Feature Flag packages

```bash
npm install @datadog/openfeature-browser @openfeature/web-sdk @openfeature/core
```

#### Step 2: Create Feature Flag configuration (`src/datadog-feature-flags.js`)

```javascript
import { DatadogProvider } from '@datadog/openfeature-browser'
import { OpenFeature } from '@openfeature/web-sdk'

const provider = new DatadogProvider({
  clientToken: '<DD_CLIENT_TOKEN>',
  applicationId: '<DD_APPLICATION_ID>',
  enableExposureLogging: true,
  site: 'datadoghq.com',
  env: 'dev',
  service: 'my-react-app',
  version: '1.0.0'
})

export async function initializeFeatureFlags() {
  const evaluationContext = {
    targetingKey: 'user-12345',  // MUST match datadogRum.setUser({ id })
    userId: 'user-12345',
    userRole: 'beta-tester',
  }
  await OpenFeature.setProviderAndWait(provider, evaluationContext)
}

export function getFeatureFlagClient() {
  return OpenFeature.getClient()
}
```

#### Step 3: Create a custom React hook (`src/hooks/useFeatureFlag.js`)

```javascript
import { useState, useEffect } from 'react'
import { getFeatureFlagClient } from '../datadog-feature-flags'

export function useFeatureFlag(flagKey, defaultValue = false) {
  const [isEnabled, setIsEnabled] = useState(defaultValue)
  const [isLoading, setIsLoading] = useState(true)

  useEffect(() => {
    const client = getFeatureFlagClient()
    client.getBooleanValue(flagKey, defaultValue)
      .then(setIsEnabled)
      .catch(() => setIsEnabled(defaultValue))
      .finally(() => setIsLoading(false))
  }, [flagKey, defaultValue])

  return { isEnabled, isLoading }
}
```

#### Step 4: Initialize Feature Flags before app render (`src/main.jsx`)

```javascript
import { initializeFeatureFlags } from './datadog-feature-flags'

;(async () => {
  await initializeFeatureFlags()
  createRoot(document.getElementById('root')).render(
    <StrictMode><App /></StrictMode>
  )
})()
```

#### Step 5: Use feature flags in components

```javascript
const { isEnabled, isLoading } = useFeatureFlag('enable-payee-feature', false)

{isEnabled && <PayeesList ... />}
```

#### Step 6: Ensure user IDs match

The `targetingKey` in `datadog-feature-flags.js` MUST match `datadogRum.setUser({ id })` in `datadog-rum.js`. This links feature flag evaluations to RUM sessions for proper analytics.

## Validation

1. Use the app for 1-2 minutes (navigate pages, submit forms, trigger actions)
2. Check **UX Monitoring > RUM > Sessions** in the Datadog UI
3. Verify sessions, views, actions, and errors appear
4. For Feature Flags: check **Software Delivery > Feature Flags** for flag evaluations

## Troubleshooting

### No RUM data appearing
**Cause:** Client token or application ID incorrect.
**Fix:** Verify credentials at **UX Monitoring > RUM Applications** in Datadog UI.

### Feature flags always return default value
**Cause:** Provider not initialized or flag not created in Datadog.
**Fix:** Ensure `initializeFeatureFlags()` completes before app render. Create the flag in Datadog Feature Flags dashboard first.

### RUM events not linked to feature flag evaluations
**Cause:** User ID mismatch between RUM and Feature Flags.
**Fix:** Ensure `datadogRum.setUser({ id })` matches `targetingKey` in the evaluation context.

### HMR causes duplicate RUM initialization
**Cause:** Vite hot module replacement re-runs initialization.
**Fix:** Use the `window.__DATADOG_RUM_INSTALLED__` guard as shown above.
