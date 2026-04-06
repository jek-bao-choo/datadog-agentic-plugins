## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `ios-instrumentation` plugin. Work proceeds in two phases: first set up the application, then instrument it with Datadog. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place the application source, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Application Setup

**Goal:** For each iOS application pattern, create a `setup-{pattern}` skill that builds and runs the app — independent of any Datadog instrumentation. All code is in Swift.

**What the application produces:**

- Default to UI-driven entry points — screen navigation, tap gestures, and form submissions — as the primary inbound triggers for a mobile app. Depending on the PoC, also consider: deep links via Universal Links or URL Schemes, push notifications via APNs (Apple Push Notification service), or background task triggers (BGTaskScheduler / Background Fetch). Do not implement HTTP server endpoints in an iOS app; it is a client, not a server. If the inbound trigger type is not specified in the PoC requirements, ask before assuming.
- When the app communicates with a backend over HTTP, expect and handle a standardised JSON response: `{ "status": "ok" | "error", "message": "...", "data": {} }`. Parse this structure using `Codable` structs with `JSONDecoder` (URLSession) or Alamofire response decoders. Do NOT apply this schema expectation to non-HTTP backends — use the appropriate message format for that protocol instead. Simulate realistic backend error scenarios in any mock server or stub using a mix of success and error statuses.
- Include at least one outbound network call to a backend service appropriate to the PoC — via `URLSession` (stdlib) or `Alamofire` for HTTP REST, `grpc-swift` stubs for gRPC, or other client libraries for the required protocol. If the backend service or protocol is not explicitly stated in the PoC requirements, ask before assuming.
- Structured logging via `OSLog` (Apple's unified logging framework) with subsystem and category labels so logs are ready for Datadog log collection

**Example patterns to build:**

- **SwiftUI App** — Multi-screen SwiftUI application using the App/Scene/View lifecycle. Navigation stack, state management via `@State` / `@ObservableObject`.
- **UIKit App** — UIViewController-based application with storyboard or programmatic layout. Demonstrates traditional UIKit architecture (MVC or MVVM).

**Tooling:**

- Xcode (latest stable release)
- Swift Package Manager (SPM) for dependency management — preferred over CocoaPods
- `xcodebuild` for headless/CI builds and simulator launches
- All code is Swift, not Objective-C

**Naming convention:** `setup-{pattern}` (e.g., `setup-swiftui`, `setup-uikit`). Include a version suffix only when multiple iOS deployment targets or major SDK versions are in scope.

**Reminder:** Always check if an iOS application is already running in the environment before creating a new one. If the `skills/` folder already has a relevant setup skill, use it instead of creating a new one.

---

## Phase 2: Datadog Instrumentation

**Goal:** For each setup skill, create a matching `{pattern}-datadog-rum` skill that instruments the running application with Datadog RUM — producing sessions, views, actions, errors, and correlated logs.

**What an instrumentation produces:**

- `dd-sdk-ios` added via Swift Package Manager (modules: `DatadogCore`, `DatadogRUM`, `DatadogLogs`, `DatadogCrashReporting`)
- Datadog initialised at app launch — in the `@main` App struct `init()` for SwiftUI, or in `AppDelegate.application(_:didFinishLaunchingWithOptions:)` for UIKit — with client token and application ID
- Unified service tags configured: `service`, `env`, `version` (via `Datadog.Configuration` builder)
- RUM configured with:
  - `sessionSampleRate: 100` (capture everything during development)
  - `sessionReplaySampleRate: 100`
  - View tracking: `.trackRUMView(name:)` SwiftUI modifier, or `UIKitRUMViewsPredicate` for UIKit automatic view tracking
  - `trackUserInteractions: true` for tap action tracking
  - `trackBackgroundEvents: true`
- Log shipping configured via `DatadogLogs` to forward `OSLog`-based logs to Datadog using a `Logger` instance
- Network call tracing via `URLSessionInstrumentation` (from `DatadogTrace`) applied to the app's `URLSession` instances for distributed trace propagation to backend services
- Crash reporting enabled via `DatadogCrashReporting`
- Verification steps: launch the app in a simulator, navigate between screens, trigger errors; then confirm RUM sessions appear in Datadog dashboard
- Validation in the Datadog UI: RUM > Sessions shows user sessions, RUM > Views shows screen views, RUM > Errors shows crashes and errors

**Naming convention:** `{pattern}-datadog-rum` (e.g., `swiftui-datadog-rum`, `uikit-datadog-rum`).

**Prerequisite:** The corresponding `setup-{pattern}` skill must be completed first. State this explicitly in the SKILL.md prerequisites section.

**Reminder:** Always check if Datadog RUM is already configured in the environment before instrumenting. If the `skills/` folder already has a relevant RUM skill, use it instead of creating a new one.

---

## Guidelines

- **Simplicity:** Keep applications at Hello World level. A few screens with basic interactions and logging is sufficient.
- **Atomic steps:** Small, individually testable steps. Wait for explicit approval between phases.
- **Package management:** Use Swift Package Manager (SPM). Define dependencies in `Package.swift` or via Xcode's package resolver. Avoid CocoaPods unless explicitly required by the PoC.
- **Version compatibility:** Ensure all versions across the tech stack are compatible (iOS deployment target, Xcode version, Swift version, SPM package versions).
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- **Security:** This plugin will be committed to a public GitHub repo. Never commit API keys, private keys, passwords, certificates, or provisioning profiles. Use environment variables and `.env.example` templates.
- **Git hygiene:** Create a `.gitignore` to exclude `build/`, `DerivedData/`, `*.xcuserstate`, `.DS_Store`, and other Xcode-generated artifacts.

---

## Tools & References

### MCP Libraries (Context7)

- `/apple/swift-foundation` — Swift Foundation documentation
- `/Alamofire/Alamofire` — Alamofire networking library

### Datadog MCP Libraries (Context7)

- `/datadog/dd-sdk-ios` — Datadog iOS SDK source
- `/datadog/datadog-agent` — Datadog Agent setup and configuration

### Datadog Documentation

- [iOS RUM setup](https://docs.datadoghq.com/real_user_monitoring/ios/)
- [iOS log collection](https://docs.datadoghq.com/logs/log_collection/ios/)
- [iOS crash reporting](https://docs.datadoghq.com/real_user_monitoring/error_tracking/ios/)
- [iOS network tracing](https://docs.datadoghq.com/real_user_monitoring/ios/advanced_configuration/#automatically-track-network-requests)
- [Datadog MCP server](https://docs.datadoghq.com/bits_ai/mcp_server.md) — use to validate RUM sessions are received

### External References

- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines
