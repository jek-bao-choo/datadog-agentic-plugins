## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `android-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each Android application pattern, create a `setup-{pattern}` skill that builds and runs the app — independent of any Datadog instrumentation. All code is in Kotlin.

**What the application produces:**

- Default to UI-driven entry points — screen navigation, button interactions, and form submissions — as the primary inbound triggers for a mobile app. Depending on the PoC, also consider: deep links for external navigation, push notifications via Firebase Cloud Messaging (FCM), or background job triggers (WorkManager). Do not implement HTTP server endpoints in an Android app; it is a client, not a server. If the inbound trigger type is not specified in the PoC requirements, ask before assuming.
- When the app communicates with a backend over HTTP, expect and handle a standardised JSON response: `{ "status": "ok" | "error", "message": "...", "data": {} }`. Parse this structure in your API client (Retrofit model classes or manual JSON parsing). Do NOT apply this schema expectation to non-HTTP backends — use the appropriate message format for that protocol instead. Simulate realistic backend error scenarios in any mock server or stub using a mix of success and error statuses.
- Include at least one outbound network call to a backend service appropriate to the PoC — via Retrofit/OkHttp for HTTP REST, gRPC-Android stubs for gRPC, or other client libraries for the required protocol. If the backend service or protocol is not explicitly stated in the PoC requirements, ask before assuming.
- Structured logging via `Timber` (wrapping Android `Log`) for logcat output, with structured log tags and messages so logs are ready for Datadog log collection

**Example patterns built so far:**

- **App (API 26)** — Main app matching the provided mockup. Clickable icons linking to WebView-hosted sub-apps. Material Icons, Material 3 design system. Target API 26 (Android 8.0) minimum.
- **WebView + SpringBoot Pattern** — Android WebView frontend backed by a SpringBoot REST service. Demonstrates hybrid native/web architecture.

**Tooling:**

- SDKMAN! for managing JDK versions
- IntelliJ IDEA Community Edition (not Android Studio)
- JAVA_HOME must be set correctly for Gradle builds
- All code is Kotlin, not Java

**Naming convention:** `setup-{pattern}` (e.g., `setup-superapp`, `setup-webview`). Include a version suffix only when multiple Android API levels or major SDK versions are in scope.

**Reminder:** Always check if an Android application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{pattern}-datadog-rum` skill that instruments the running application with Datadog RUM — producing sessions, views, actions, errors, and correlated logs.

**What an instrumentation produces:**

- `datadog-sdk-android` dependency and Datadog Gradle plugin added to the project
- Datadog initialised in `Application.onCreate()` (not in Activity) with client token and application ID
- Unified service tags configured: `DD_SERVICE`, `DD_ENV`, `DD_VERSION` (via `Datadog.initialize` configuration)
- RUM configured with:
  - `trackUserInteractions = true`
  - `trackLongTasks = true`
  - `useViewTrackingStrategy(...)` for automatic view tracking
  - `sessionSampleRate = 100f` (capture everything during development)
- Log shipping configured via `dd-sdk-android-logs` to forward Timber/logcat logs to Datadog
- Network call tracing via `dd-sdk-android-okhttp` plugin on the OkHttp client for distributed trace propagation to backend services
- Verification steps: launch the app, navigate between screens, trigger errors; then confirm RUM sessions appear in Datadog dashboard
- Validation in the Datadog UI: RUM > Sessions shows user sessions, RUM > Views shows screen views, RUM > Errors shows crashes and errors

**Naming convention:** `{pattern}-datadog-rum` (e.g., `superapp-datadog-rum`, `webview-datadog-rum`).

**Prerequisite:** The corresponding `setup-{pattern}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if Datadog RUM is already configured in the environment before instrumenting. If the `skills/` folder already has a relevant RUM skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. A few screens with basic interactions and logging is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (Android API level, Kotlin version, Gradle version, Android Gradle Plugin version).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, or secrets. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `build/`, `.gradle/`, `*.keystore`, local properties files, and other build artifacts.

---



## Datadog Credentials

Before sending any telemetry to Datadog, confirm these with the user:

- **Datadog Site (DD_SITE):** Ask which Datadog site the prospect uses. Do NOT assume `datadoghq.com`. Options: `datadoghq.com` (US1), `us3.datadoghq.com` (US3), `us5.datadoghq.com` (US5), `datadoghq.eu` (EU1), `ap1.datadoghq.com` (AP1), `ap2.datadoghq.com` (AP2), `ddog-gov.com` (US1-FED). Reference: https://docs.datadoghq.com/getting_started/site/
- **API Key (DD_API_KEY):** Required for all telemetry submission (metrics, traces, logs). Ask if not already provided. Store in `.env` file, never hardcode.
- **Application Key (DD_APP_KEY):** Required only if connecting to Datadog MCP server or using the Datadog API for read operations (e.g., querying metrics, listing monitors). Not needed for basic telemetry submission.

## Resource Naming Convention

All resources created in this plugin use the **"jek-"** prefix for easy identification in shared environments.

| Resource Type | Convention | Examples |
|---|---|---|
| HTTP endpoints | `jek-endpoint-{method}` | `jek-endpoint-get`, `jek-endpoint-post`, `jek-endpoint-put` |
| Message queues | `jek-queue` | `jek-queue`, `jek-queue-orders` |
| Database name | `jek-database` | `jek-database`, `jek-database-master`, `jek-database-slave` |
| Database tables | `jek-table` | `jek-table`, `jek-table-users` |
| Infra resources | `jek-{resource}` | `jek-vpc`, `jek-eks-cluster`, `jek-ec2-master` |
| Services (DD_SERVICE) | `jek-{app-name}` | `jek-springboot-app`, `jek-fastapi-gateway` |
| Cloud tags | `owner="jek"`, `env="test"` | — |
| gRPC services | `jek-grpc-{service}` | `jek-grpc-orders`, `jek-grpc-payments` |
| WebSocket endpoints | `jek-ws-{purpose}` | `jek-ws-chat`, `jek-ws-notifications` |
| GraphQL endpoints | `jek-graphql` | `jek-graphql` (single endpoint by convention) |
| Event streams | `jek-stream-{name}` | `jek-stream-orders`, `jek-stream-events` |
| Other protocols | `jek-{protocol}-{name}` | `jek-rpc-auth`, `jek-mqtt-sensor` |

## Tools & References

### MCP Libraries (Context7)

- `/android/nowinandroid` — Now in Android sample app
- `/android/architecture-samples` — Android architecture samples

### Datadog MCP Libraries (Context7)

- `/datadog/dd-sdk-android` — Datadog Android SDK source
- `/datadog/dd-sdk-android-gradle-plugin` — Datadog Gradle plugin source

### Datadog Documentation

- [Android RUM setup](https://docs.datadoghq.com/real_user_monitoring/android/)
- [Android log collection](https://docs.datadoghq.com/logs/log_collection/android/)
- [Android crash reporting](https://docs.datadoghq.com/real_user_monitoring/error_tracking/android/)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate RUM sessions are received

### External References

- Material Design 3: https://m3.material.io
