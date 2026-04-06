---
name: android-dd-sdk
description: >-
  Use this skill whenever the user wants to instrument an Android app with the Datadog SDK.
  Triggers on mentions of Datadog Android SDK, Android RUM, mobile app monitoring with
  Datadog, Android crash reporting, or WebView trace propagation.
version: 0.1.0
---

# Android — Datadog SDK Instrumentation

Instrument Android applications with the Datadog Android SDK for RUM, crash reporting, and trace propagation.

## Prerequisites

- Skill `setup-android` has been completed successfully
- Datadog client token and RUM application ID

## Instructions

### 1. Add Datadog SDK dependencies

In `app/build.gradle.kts`:

```kotlin
dependencies {
    implementation("com.datadoghq:dd-sdk-android-rum:2.x.x")
    implementation("com.datadoghq:dd-sdk-android-logs:2.x.x")
    implementation("com.datadoghq:dd-sdk-android-trace:2.x.x")
}
```

### 2. Initialize the SDK

In your `Application` class:

```kotlin
val config = Configuration.Builder(
    clientToken = "<DD_CLIENT_TOKEN>",
    env = "sandbox",
    variant = ""
).useSite(DatadogSite.US1)
 .build()

Datadog.initialize(this, config, TrackingConsent.GRANTED)

val rumConfig = RumConfiguration.Builder("<DD_APPLICATION_ID>")
    .trackUserInteractions()
    .trackLongTasks()
    .useViewTrackingStrategy(ActivityViewTrackingStrategy(true))
    .build()

Rum.enable(rumConfig)
```

### 3. (Optional) WebView bridge

For WebView apps, enable trace propagation between native and web:

```kotlin
DatadogEventBridge.setup(webView)
```

## Validation

Use the app for 1-2 minutes, then check **RUM > Sessions** in the Datadog UI. Verify session, views, actions, and errors appear.

## Troubleshooting

### No RUM data appearing
**Cause:** Client token or application ID incorrect.
**Fix:** Verify at **UX Monitoring > RUM Applications** in Datadog UI.

### Crashes not reported
**Cause:** SDK not initialized before the crash occurs.
**Fix:** Initialize Datadog in `Application.onCreate()`, not in an Activity.
