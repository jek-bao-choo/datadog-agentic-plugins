---
name: aws-lambda
description: >
  Set up Datadog-monitored serverless functions on AWS Lambda.
  Covers .NET Lambda functions with native AOT and standard
  runtimes, with Datadog and OpenTelemetry tracing.
category: infrastructure
requires: []
supported_versions:
  dotnet_version: [8.0, 10.0]
  runtime: [al2023]
---

## Overview

The aws-lambda plugin provides skills for deploying and monitoring AWS Lambda functions with Datadog. Currently covers C#/.NET Lambda functions with native AOT compilation and standard runtimes.

## Prerequisites

- AWS account with Lambda permissions
- AWS CLI and SAM CLI configured
- .NET SDK (8.0 or 10.0)
- Datadog API key

## Skills

### setup-lambda-dotnet
Deploy .NET Lambda functions on AWS with Datadog tracing. Covers native AOT (.NET 10), global CLI tool (.NET 8.0), and web API patterns. Includes SAM templates and deployment guides.

## Recommended Skill Order

1. setup-lambda-dotnet

## Compatibility Notes

Tested with .NET 8.0 and 10.0 on Amazon Linux 2023 runtime. Native AOT requires .NET 10+.
