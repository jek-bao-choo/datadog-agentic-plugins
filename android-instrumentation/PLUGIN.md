---
name: android-instrumentation
description: >
  Instrument Android applications with Datadog RUM and APM. Covers
  Kotlin Android apps across API levels with the Datadog Android SDK,
  including WebView bridge integration.
category: instrumentation
requires: []
supported_versions:
  android_api: [24, 26]
  kotlin_version: [latest]
---

## Overview

The android-instrumentation plugin provides skills for setting up and instrumenting Android applications with Datadog. Covers hello world, super app, and WebView + Spring Boot backend patterns across Android API levels 24-26.

## Prerequisites

- Android Studio installed
- Kotlin support configured
- Datadog client token and application ID

## Skills

### setup-android
Build and run Android applications across different API levels and patterns. Includes hello world (API 24), super app (API 26), and WebView with Spring Boot backend (API 26).

### android-dd-sdk
Instrument Android applications with the Datadog Android SDK for RUM, crash reporting, and trace propagation through WebViews.

## Recommended Skill Order

1. setup-android
2. android-dd-sdk

## Compatibility Notes

Tested with Android API 24-26. The WebView pattern requires a running Spring Boot backend (see java-instrumentation plugin).
