---
name: quickstart
description: >
  Interactive onboarding plugin that guides prospects and customers through
  Datadog PoC setup. Presents a menu of 26 use cases, connects to Datadog
  MCP server when needed, and fetches live documentation.
category: onboarding
requires: []
supported_versions: {}
---

## Overview

The quickstart plugin is the recommended entry point for any Datadog proof of concept. It provides an interactive menu covering agent setup, APM instrumentation, frontend monitoring, log management, cloud integrations, and troubleshooting — all accessible via a single `/quickstart:menu` command.

On session start, it displays a welcome message guiding the user to the menu or to describe their needs directly. It can connect to the Datadog MCP server for account-specific guidance, search the web for current setup guides, or fall back to Datadog's `llms.txt` documentation index.

## Prerequisites

- Claude Code with plugin support
- Internet access (for documentation lookup and web search)
- (Optional) Datadog API and APP keys for MCP server integration

## Skills

### fetching-datadog-docs
Looks up Datadog product documentation, API references, feature configuration steps, and integration setup guides using Datadog's `llms.txt` index. Used as a fallback when MCP and web search are unavailable.

## Commands

### menu
Presents 26 grouped use cases (Agent Setup, APM Backend, Frontend Monitoring, Log Management, Cloud Integrations, Troubleshooting) and guides the user through their selection step by step.

## Hooks

### SessionStart
Displays a welcome message on every new session with guidance to use `/quickstart:menu` or describe their needs.

## Recommended Order

1. Run `/quickstart:menu` to select a use case
2. The menu command handles the full flow: gather context, look up docs, present plan, execute, verify

## Compatibility Notes

This plugin has no version-specific requirements. It works with any Datadog site region and any technology stack — the menu routes to the appropriate documentation and setup guides.
