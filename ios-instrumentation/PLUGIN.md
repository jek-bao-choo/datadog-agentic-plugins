---
name: ios-instrumentation
description: >
  Instrument iOS/Swift applications with Datadog RUM and APM.
  Covers Swift 6.2 with Xcode 26 and the Datadog iOS SDK.
category: instrumentation
requires: []
supported_versions:
  swift_version: [6.2]
  xcode_version: [26]
---

## Overview

The ios-instrumentation plugin provides skills for setting up and instrumenting iOS applications with Datadog. Currently covers a Swift 6.2 hello world application as a foundation for Datadog iOS SDK integration.

## Prerequisites

- macOS with Xcode 26 installed
- Apple Developer account (for device deployment)
- Datadog client token and RUM application ID

## Skills

### setup-ios
Build and run a Swift 6.2 iOS application in Xcode. Provides the foundation for Datadog SDK instrumentation.

## Recommended Skill Order

1. setup-ios

## Compatibility Notes

Tested with Swift 6.2 and Xcode 26. Datadog iOS SDK integration to be expanded.
