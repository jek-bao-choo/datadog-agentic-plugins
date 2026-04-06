---
name: setup-android
description: >-
  Use this skill whenever the user needs to build and run an Android application for Datadog
  instrumentation. Triggers on mentions of Android app setup, Kotlin Android project,
  Android Studio project, or mobile app development for Datadog testing.
version: 0.1.0
version_matrix:
  android_api: [24, 26]
---

# Android Application Setup

Build and run Kotlin Android applications across different API levels and patterns.

## Prerequisites

- Android Studio installed with SDK for target API level
- Kotlin plugin configured
- Physical device or emulator

## Instructions

Three application patterns are available in `references/`:

### Pattern 1: Hello World (API 24)
`references/android7__api24__helloworld/` — Minimal Android app for basic Datadog SDK integration testing.

### Pattern 2: Super App (API 26)
`references/android8__api26__superapp/` — Feature-rich app demonstrating multiple Datadog RUM use cases.

### Pattern 3: WebView + Spring Boot (API 26)
`references/android8__api26__webview__springboot/` — Android WebView that loads a Spring Boot backend, demonstrating cross-platform trace propagation.

Open any project in Android Studio, sync Gradle, and run on an emulator or device.

## Validation

```bash
# Verify the app builds
./gradlew assembleDebug

# Run on connected device
./gradlew installDebug
```

## Troubleshooting

### Gradle sync fails
**Cause:** SDK version mismatch or missing build tools.
**Fix:** Open SDK Manager in Android Studio and install the required API level and build tools.
