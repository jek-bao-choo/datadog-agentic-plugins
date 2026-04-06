---
name: java-instrumentation
description: >
  Instrument Java applications with Datadog APM. Covers Spring Boot
  applications with the Datadog Java tracer via manual init container
  injection on Kubernetes.
category: instrumentation
requires: [aws-ec2, gcp-gke]
supported_versions:
  java_version: [17]
  springboot_version: [3.5.9]
---

## Overview

The java-instrumentation plugin provides skills for instrumenting Java applications with Datadog APM. Currently covers Spring Boot 3.5.9 on Java 17 with the Datadog Java tracer (`dd-java-agent.jar`) injected via Kubernetes init containers. Includes a sample REST API application with three endpoints, JSON logging, and JVM runtime metrics.

## Prerequisites

- A running Kubernetes cluster with the Datadog Agent deployed (see aws-integration or gcp-integration)
- Java 17 or Docker for building the application
- `kubectl` for deployment
- Datadog API key configured in the cluster

## Skills

### springboot-dd-tracer
Build, deploy, and instrument a Spring Boot 3.5.9 REST API with Datadog APM on Kubernetes. Uses manual init container injection for the Datadog Java tracer. Covers build, deployment, traffic generation, trace verification, and JVM runtime metrics monitoring.

## Recommended Skill Order

1. springboot-dd-tracer

## Compatibility Notes

Tested with Java OpenJDK 17.0.17 and Spring Boot 3.5.9 on GKE. The manual init container approach works on any Kubernetes cluster where the Datadog Agent DaemonSet is running.
