---
name: vue-instrumentation
description: >
  Instrument Vue.js applications with Datadog RUM. Covers Vue 3.5
  with Vite, including RUM SDK setup for session tracking and
  user monitoring.
category: instrumentation
requires: [aws-ec2, aws-eks, gcp-gke, gcp-cloudrun]
supported_versions:
  vue_version: [3.5]
  vite_version: [7.1]
---

## Overview

The vue-instrumentation plugin provides skills for setting up and instrumenting Vue.js applications with Datadog. Covers a tradestocks proof-of-concept app built with Vue 3.5 and Vite 7.1, instrumented with Datadog RUM SDK.

## Prerequisites

- Node.js 18+
- npm or yarn
- Datadog client token and application ID

## Skills

### setup-vue
Build and run a Vue 3.5 application with Vite 7.1. Sets up the tradestocks proof-of-concept app with Composition API and reactive state management.

### vue-dd-rum
Instrument the Vue application with Datadog RUM SDK for session tracking, user monitoring, and frontend observability.

## Recommended Skill Order

1. setup-vue
2. vue-dd-rum

## Compatibility Notes

Tested with Vue 3.5 and Vite 7.1. Uses the Composition API and modern Vue.js patterns.
