---
name: java-instrumentation
description: >
  Instrument Java applications with Datadog APM. Covers Spring Boot
  2.7.5 (Java 8), 3.5.9 (Java 17), and 4.0.2 (Java 21) with the
  Datadog Java tracer via javaagent and Kubernetes init containers.
category: instrumentation
requires: [aws-ec2, aws-eks, gcp-gke]
supported_versions:
  java_version: [8, 17, 21]
  springboot_version: [2.7.5, 3.5.9, 4.0.2]
---

## Overview

The java-instrumentation plugin provides skills for setting up and instrumenting Java applications with Datadog APM. Covers three Spring Boot generations: 2.7.5 on Java 8 (Corretto), 3.5.9 on Java 17, and 4.0.2 on Java 21. Includes javaagent attachment, Kubernetes init container injection, and JVM runtime metrics.

## Prerequisites

- Java 8, 17, or 21 (depending on Spring Boot version)
- Maven (wrapper included in each project)
- Docker and kubectl (for Kubernetes deployment)
- Datadog API key

## Skills

### setup-springboot2x
Build and deploy a Spring Boot 2.7.5 REST API with Java 8 (Amazon Corretto 8u442).

### springboot2x-dd-tracer
Instrument a Spring Boot 2.7.5 application with Datadog APM via javaagent.

### setup-springboot
Build and deploy a Spring Boot 3.5.9 REST API with Java 17 on Kubernetes.

### springboot-dd-tracer
Instrument a Spring Boot 3.5.9 application with Datadog APM via Kubernetes init container injection.

### setup-springboot4x
Build and deploy a Spring Boot 4.0.2 REST API with Java 21 (OpenJDK), featuring payload-to-custom-tags.

### springboot4x-dd-tracer
Instrument a Spring Boot 4.0.2 application with Datadog APM via javaagent with custom tag extraction.

## Recommended Skill Order

Pick the version matching your stack:
1. setup-springboot2x → springboot2x-dd-tracer (Java 8)
2. setup-springboot → springboot-dd-tracer (Java 17)
3. setup-springboot4x → springboot4x-dd-tracer (Java 21)

## Compatibility Notes

Spring Boot 2.7.5 requires Java 8. Spring Boot 3.5.9 requires Java 17+. Spring Boot 4.0.2 requires Java 21+. The Kubernetes init container approach (Spring Boot 3.x) works on any cluster with the Datadog Agent DaemonSet.
