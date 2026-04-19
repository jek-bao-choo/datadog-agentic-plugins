---
name: validation
description: >
  Validate a prospect's tech stack before a Datadog PoC and generate sequenced
  prework TODO files that replicate the prospect's environment layer-by-layer.
  Scoped to grow — future skills will cover observability coverage, APM
  readiness, and other prework validation checks.
category: prework
requires: []
supported_versions: {}
---

## Overview

The validation plugin is for Sales Engineers doing PoC prework. It currently provides one skill — `generate-tech-stack-validation-todos` — which gathers a prospect's tech stack and transaction flow, then emits a manifest plus sequenced TODO files that replicate the stack bottom-up for hands-on prework validation.

The plugin is scoped to grow: future skills will cover observability coverage checks, APM readiness, and other validation steps that belong in the prework phase (before any live installation or instrumentation work).

## Prerequisites

- Claude Code with plugin support
- Access to the prospect's implementation guide, TMAP, or evaluation plan (or equivalent notes)
- Basic familiarity with the prospect's architecture — transaction flow and tech stack (will be collected interactively if missing)

## Skills

### generate-tech-stack-validation-todos
Gathers PoC requirements, tech stack details, and transaction flow from the user (via implementation guides, TMAPs, evaluation plans, or custom notes), then generates a manifest plus sequenced TODO files that replicate the stack layer-by-layer (bottom-up) for prework validation. Uses dummy prospect names throughout to prevent accidental data leaks into committed artifacts.

## Recommended Order

1. Collect the prospect's implementation guide, TMAP, or evaluation plan (or be ready to describe the tech stack and transaction flow verbally).
2. Trigger the `generate-tech-stack-validation-todos` skill — e.g., "help me do prework for a prospect's PoC", "validate this tech stack", "generate prework TODOs".
3. The skill collects any missing context, then writes the manifest (`{dummy}-manifest.md`) and per-layer TODO files (`{dummy}-TODO-{plugin}.md`) to your working directory.
4. Use the manifest as the run sheet for the actual prework build, following the bottom-up sequence.

## Compatibility Notes

This plugin has no version-specific technology requirements. It handles any language/framework/infrastructure combination — the generated TODO files reference templates from the corresponding Datadog plugins (`aws-ec2`, `java-instrumentation`, `mysql-selfhosted`, etc.) in this repo.

Generated output files should not be committed to public repositories. Add `*-manifest.md` and `*-TODO-*.md` patterns to your project's `.gitignore`, or store the outputs in a location already covered by `.gitignore`.
