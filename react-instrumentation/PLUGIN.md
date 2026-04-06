---
name: react-instrumentation
description: >
  Instrument React applications with Datadog RUM. Covers React 19.1
  with Vite, including RUM SDK setup and Feature Flags via OpenFeature.
category: instrumentation
requires: [aws-ec2, aws-eks, gcp-gke, gcp-cloudrun]
supported_versions:
  react_version: [19.1]
  vite_version: [7.1]
---

## Overview

The react-instrumentation plugin provides skills for setting up and instrumenting React applications with Datadog. Covers a sendmoney proof-of-concept app built with React 19.1 and Vite 7.1, instrumented with Datadog RUM SDK and Feature Flags via OpenFeature.

## Prerequisites

- Node.js 18+
- npm or yarn
- Datadog client token and application ID

## Skills

### setup-react
Build and run a React 19.1 application with Vite 7.1. Sets up the sendmoney proof-of-concept app with mock API integration.

### react-dd-rum
Instrument the React application with Datadog RUM SDK for session tracking, user monitoring, and Feature Flags via the @datadog/openfeature-browser provider.

## Recommended Skill Order

1. setup-react
2. react-dd-rum

## Compatibility Notes

Tested with React 19.1 and Vite 7.1. Feature Flags require @datadog/openfeature-browser, @openfeature/web-sdk, and @openfeature/core.
