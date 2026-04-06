## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `vue-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

Build a Vue 3.5 + Vite 7.1 tradestocks proof-of-concept app:

- **Tradestocks App** — Mobile-responsive stock trading flow with mock API integration. Vue 3.5, Vite 7.1, Composition API. Target as a SKILL with the application in `references/`.
- Components: TradingForm, StockDropdown, QuantityInput, BuyButton, BackButton, ResultPage
- Composables: useStockData, useTradingAPI
- Modern CSS with mobile-responsive design

Tooling:
- Node.js 18+ with npm
- Vite 7.1 as build tool and dev server
- All code is Vue SFC (.vue) with Composition API

## Phase 2: Datadog Instrumentation

Instrument with Datadog RUM SDK:

- Install `@datadog/browser-rum` and configure RUM initialization in `src/main.js`
- Configure RUM with these settings:
  - `sessionSampleRate: 100` (capture everything during development)
  - `sessionReplaySampleRate: 100`
  - `defaultPrivacyLevel: 'mask-user-input'`
- Set user information via `datadogRum.setUser()` for session identification
- Initialize RUM before `createApp(App).mount('#app')`
- Verify RUM sessions appear in Datadog dashboard

## Guidelines

- Keep it simple. The app should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to Vue development should be able to follow along.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Context7 MCP: `/websites/vite_dev` — Vite documentation
- Context7 MCP: `/websites/vuejs_guide` — Vue.js guide
- Context7 MCP: `/datadog/browser-sdk` — Datadog Browser SDK source
- Datadog: RUM Browser Monitoring documentation
