---
name: java-instrumentation
description: >
  Instrument Java applications with Datadog APM. Covers Spring Boot
  application setup, deployment, and Datadog Java tracer instrumentation
  via manual init container injection on Kubernetes.
category: instrumentation
requires: [aws-ec2, gcp-gke]
supported_versions:
  java_version: [17]
  springboot_version: [3.5.9]
---

## Overview

The java-instrumentation plugin provides skills for setting up and instrumenting Java applications with Datadog APM. Currently covers Spring Boot 3.5.9 on Java 17 with the Datadog Java tracer (`dd-java-agent.jar`) injected via Kubernetes init containers. Includes a sample REST API application with three endpoints, JSON logging, and JVM runtime metrics.

## Prerequisites

- A running Kubernetes cluster with the Datadog Agent deployed (see aws-ec2 or gcp-gke plugins)
- Java 17 or Docker for building the application
- `kubectl` for deployment
- Datadog API key configured in the cluster

## Skills

### setup-springboot
Build and deploy a Spring Boot 3.5.9 REST API application. Covers Maven build, Docker multi-stage build, and Kubernetes deployment. Provides the foundation for APM instrumentation.

### springboot-dd-tracer
Instrument a deployed Spring Boot application with Datadog APM on Kubernetes. Uses manual init container injection for the Datadog Java tracer. Covers tracer setup, traffic generation, trace verification, and JVM runtime metrics monitoring.

## Recommended Skill Order

1. setup-springboot
2. springboot-dd-tracer

## Compatibility Notes

Tested with Java OpenJDK 17.0.17 and Spring Boot 3.5.9 on GKE. The manual init container approach works on any Kubernetes cluster where the Datadog Agent DaemonSet is running.
