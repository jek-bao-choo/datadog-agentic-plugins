## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `react-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

Build a React 19.1 + Vite 7.1 sendmoney proof-of-concept app:

- **Sendmoney App** — Mobile-responsive payment flow with mock API integration. React 19.1, Vite 7.1, component-based architecture. Target as a SKILL with the application in `references/`.
- Components: SendMoneyForm, PayeesList, AddPayeeModal, ResultPage, ScamAlertModal
- Mock API service for transaction simulation
- Modern CSS with mobile-responsive design

Tooling:
- Node.js 18+ with npm
- Vite 7.1 as build tool and dev server
- ESLint for code quality
- All code is JSX (React), not TypeScript

## Phase 2: Datadog Instrumentation

Instrument with Datadog RUM SDK and Feature Flags:

- Install `@datadog/browser-rum` and configure RUM initialization
- Configure RUM with these settings:
  - `sessionSampleRate: 100` (capture everything during development)
  - `sessionReplaySampleRate: 100`
  - `defaultPrivacyLevel: 'mask-user-input'`
- Set user information via `datadogRum.setUser()` for session identification
- Guard against duplicate initialization during Vite HMR
- Verify RUM sessions appear in Datadog dashboard

### Feature Flags (6-step OpenFeature process):

1. Install packages: `@datadog/openfeature-browser`, `@openfeature/web-sdk`, `@openfeature/core`
2. Create `src/datadog-feature-flags.js` with DatadogProvider configuration
3. Create `src/hooks/useFeatureFlag.js` custom React hook
4. Initialize Feature Flags before app render in `src/main.jsx` (async IIFE)
5. Use `useFeatureFlag` hook in components for conditional rendering
6. Ensure `targetingKey` matches `datadogRum.setUser({ id })` for proper analytics linking

## Guidelines

- Keep it simple. The app should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to React development should be able to follow along.
- Every app directory gets a `README.md` explaining what it does and how to run it.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Context7 MCP: `/websites/vite_dev` — Vite documentation
- Context7 MCP: `/datadog/browser-sdk` — Datadog Browser SDK source
- Datadog: RUM Browser Monitoring documentation
- Datadog: Feature Flags documentation
- OpenFeature: https://openfeature.dev
