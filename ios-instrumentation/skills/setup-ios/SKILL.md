---
name: setup-ios
description: >-
  Use this skill whenever the user needs to build and run an iOS/Swift application for
  Datadog instrumentation. Triggers on mentions of iOS app setup, Swift project, Xcode
  project, or iOS mobile app development for Datadog testing.
version: 0.1.0
version_matrix:
  swift_version: [6.2]
  xcode_version: [26]
---

# iOS/Swift Application Setup

Build and run a Swift 6.2 iOS application in Xcode 26.

## Prerequisites

- macOS with Xcode 26 installed
- iOS Simulator or physical device

## Instructions

The application source is in `references/`. Open the project in Xcode:

1. Open the `.xcodeproj` file in Xcode
2. Select the target device (Simulator or connected device)
3. Build and run (Cmd+R)

## Validation

The app should launch on the simulator or device. Verify it displays the hello world interface.

## Troubleshooting

### Build fails with Swift version error
**Cause:** Xcode version doesn't support Swift 6.2.
**Fix:** Update to Xcode 26 or later.

### Simulator not available
**Cause:** iOS simulator runtime not installed.
**Fix:** Open Xcode > Settings > Platforms > Download the required iOS runtime.
