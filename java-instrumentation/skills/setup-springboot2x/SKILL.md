---
name: setup-springboot2x
description: >-
  Use this skill whenever the user needs to build and deploy a Spring Boot 2.x application
  with Java 8. Triggers on mentions of Spring Boot 2 setup, Java 8 Spring Boot, legacy
  Spring Boot deployment, or Corretto 8 application setup.
version: 0.1.0
version_matrix:
  java_version: [8]
  springboot_version: [2.7.5]
---

# Spring Boot 2.7.5 + Java 8 — Build and Deploy

Build and deploy a Spring Boot 2.7.5 REST API application with Java 8 (Amazon Corretto 8u442).

## Prerequisites

- Java 8 (Amazon Corretto 8u442 recommended)
- Maven (wrapper included)

## Instructions

The complete application source is in `references/`. The app provides 3 REST API endpoints (GET, POST, PUT) with comprehensive logging.

```bash
cd references/
./mvnw clean package
java -jar target/*.jar
```

The application starts on `http://localhost:8080`.

See `references/README.md` for full documentation including Docker deployment and testing.

## Validation

```bash
curl http://localhost:8080/api/data
# Expected: JSON response
```

## Troubleshooting

### Build fails with Java version error
**Cause:** Java version is not 8.
**Fix:** Install Amazon Corretto 8: `sdk install java 8.0.442-amzn` or set `JAVA_HOME` to Java 8.
