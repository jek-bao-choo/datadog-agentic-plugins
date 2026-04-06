---
name: setup-lambda-dotnet
description: >-
  Use this skill whenever the user needs to deploy .NET Lambda functions on AWS with
  Datadog monitoring. Triggers on mentions of C# Lambda, .NET Lambda, AWS Lambda .NET,
  native AOT Lambda, SAM deploy Lambda, or serverless .NET on AWS.
version: 0.1.0
version_matrix:
  dotnet_version: [8.0, 10.0]
---

# AWS Lambda .NET Setup

Deploy .NET Lambda functions on AWS with Datadog tracing. Covers multiple patterns: native AOT, global CLI tool, and web API.

## Prerequisites

- AWS CLI and SAM CLI configured
- .NET SDK (8.0 or 10.0)
- Datadog API key

## Instructions

Three Lambda patterns are available in `references/`:

### Pattern 1: Native AOT (.NET 10, AL2023)
See `references/dotnet10__al2023__lambda__native__aot/`. Uses ahead-of-time compilation for minimal cold starts.

### Pattern 2: Global CLI Tool (.NET 8.0)
See `references/lambda__globalcli__net8dot0__processmeterreading/`. Standard Lambda handler with model classes.

### Pattern 3: Web API (.NET 8.0)
See `references/net8dot0__web__processmeterreading/`. ASP.NET Core Web API running on Lambda with SAM template.

Full setup documentation: `README.md`

## Validation

```bash
# Invoke the Lambda function
aws lambda invoke --function-name <FUNCTION_NAME> --payload '{}' response.json
cat response.json
```

In the Datadog UI: **Serverless > Functions** — verify the Lambda function appears.

## Troubleshooting

### Cold start timeout
**Cause:** Lambda memory too low for .NET runtime initialization.
**Fix:** Increase memory allocation. Native AOT (.NET 10) significantly reduces cold starts.

### No traces in Datadog
**Cause:** Datadog Lambda extension not installed or API key not configured.
**Fix:** Verify the Datadog Lambda layer is attached and `DD_API_KEY` environment variable is set.
