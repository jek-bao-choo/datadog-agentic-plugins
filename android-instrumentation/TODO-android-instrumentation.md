## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `android-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

Build Android applications in Kotlin:

- **Superapp (API 26)** — Main app matching the provided mockup. Clickable icons linking to WebView-hosted sub-apps. Material Icons, Material 3 design system. Target API 26 (Android 8.0) minimum as a SKILL with the application.
- **WebView + SpringBoot Pattern** — Android WebView frontend backed by a SpringBoot REST service. Demonstrates hybrid native/web architecture as another SKILL with the application

Tooling:
- SDKMAN! for managing JDK versions
- IntelliJ IDEA Community Edition (not Android Studio)
- JAVA_HOME must be set correctly for Gradle builds
- All code is Kotlin, not Java

## Phase 2: Datadog Instrumentation

Instrument with Datadog Android SDK and RUM:

- Add `datadog-sdk-android` dependency and the Datadog Gradle plugin
- Configure RUM with these settings:
  - `trackUserInteractions = true`
  - `trackLongTasks = true`
  - `useViewTrackingStrategy(...)` for automatic view tracking
  - `sessionSampleRate = 100f` (capture everything during development)
- Initialize Datadog in `Application.onCreate()` — not in Activity
- Verify RUM sessions appear in Datadog dashboard

## Guidelines

- Keep it simple. Each app should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to Android development should be able to follow along.
- Every app directory gets a `README.md` explaining what it does and how to run it.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Context7 MCP: `/android/nowinandroid` — Now in Android sample app
- Context7 MCP: `/android/architecture-samples` — Android architecture samples
- Context7 MCP: `/datadog/dd-sdk-android` — Datadog Android SDK source
- Context7 MCP: `/datadog/dd-sdk-android-gradle-plugin` — Datadog Gradle plugin source
- Datadog: Android RUM documentation
- Material Design 3: https://m3.material.io
