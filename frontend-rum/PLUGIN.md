---
name: frontend-rum
description: >
  Set up Datadog Real User Monitoring (RUM) for frontend applications.
  Covers React, Vue, Next.js, Vanilla JS, and HTML applications with
  Datadog RUM SDK and auto-injection.
category: instrumentation
requires: [aws-ec2, aws-eks, gcp-gke, gcp-cloudrun]
supported_versions:
  react_version: [19.1]
  vue_version: [3.5]
  nextjs_version: [15.4, 15.5]
  vite_version: [7.1, 7.2]
---

## Overview

The frontend-rum plugin provides skills for setting up Datadog Real User Monitoring (RUM) across frontend frameworks. Covers React, Vue.js, Next.js, Vanilla JS (with Vite), and static HTML applications. RUM captures page loads, user interactions, errors, and resource timing in the browser.

## Prerequisites

- Node.js and npm/yarn installed
- Docker (optional, for containerized deployment)
- Datadog RUM application ID and client token

## Skills

### setup-react-rum
Build a React 19.1 application with Vite and configure Datadog RUM.

### setup-vue-rum
Build a Vue 3.5 application with Vite and configure Datadog RUM.

### setup-nextjs-rum
Build a Next.js 15.x application and configure Datadog RUM for both client and server-side rendering.

### setup-vanilla-rum
Build a Vanilla JS application with Vite and configure Datadog RUM.

### setup-html-rum
Set up Datadog RUM auto-injection for static HTML applications served by Nginx.

## Recommended Skill Order

1. Choose the appropriate setup skill for your framework
2. Configure Datadog RUM client token and application ID

## Compatibility Notes

React and Vue skills use Vite 7.x as the build tool. Next.js covers both 15.4 (TypeScript) and 15.5 (JavaScript) variants.
