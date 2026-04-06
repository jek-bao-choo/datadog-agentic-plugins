## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `java-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup
- **React Vite SendMoney App** — React app built with Vite. Includes Feature Flag integration for toggling UI features at runtime.

Each app:
- Own directory with its own `package.json`
- Vite for bundling and dev server
- Clean, minimal styling

## Phase 2: Datadog Instrumentation
- **RUM SDK** — Install and configure `@datadog/browser-rum`. Initialize with applicationId, clientToken, site, service, and sessionSampleRate.
- **Feature Flags** — Integrate via `@datadog/openfeature-browser` and `@openfeature/web-sdk`. Follow the 6-step process from Datadog docs:
  1. Initialize the RUM SDK
  2. Create a feature flag in Datadog
  3. Evaluate the flag in application code
  4. Set targeting rules
  5. Publish the flag
  6. Monitor rollout in Datadog
- Verify RUM sessions and feature flag evaluations appear in Datadog

## Guidelines

- Keep it simple. Each app should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to frontend observability should be able to follow along.
- Every app directory gets a `README.md` explaining what it does and how to run it.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Context7 MCP: `/websites/vite_dev` — Vite documentation
- Context7 MCP: `/websites/vite_dev_guide` — Vite getting started guide
- Context7 MCP: `/datadog/browser-sdk` — Datadog Browser SDK source and docs
- Datadog: RUM documentation, Feature Flags getting started guide
- OpenFeature: `@openfeature/web-sdk` docs
