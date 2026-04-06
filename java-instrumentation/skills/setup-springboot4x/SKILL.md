---
name: setup-springboot4x
description: >-
  Use this skill whenever the user needs to build and deploy a Spring Boot 4.x application
  with Java 21. Triggers on mentions of Spring Boot 4 setup, Java 21 Spring Boot,
  latest Spring Boot deployment, or Spring Boot 4.0.2 application setup.
version: 0.1.0
version_matrix:
  java_version: [21]
  springboot_version: [4.0.2]
---

# Spring Boot 4.0.2 + Java 21 — Build and Deploy

Build and deploy a Spring Boot 4.0.2 REST API application with Java 21 (OpenJDK), featuring payload-to-custom-tags functionality.

## Prerequisites

- Java 21 (OpenJDK)
- Maven (wrapper included)

## Instructions

The complete application source is in `references/`.

```bash
cd references/
./mvnw clean package
./mvnw spring-boot:run
```

The application starts on `http://localhost:8080`.

See `README.md` for full documentation.

## Validation

```bash
curl http://localhost:8080/api/data
# Expected: JSON response
```

## Troubleshooting

### Build fails with unsupported class version
**Cause:** Java version is not 21.
**Fix:** Install Java 21: `sdk install java 21-open` or set `JAVA_HOME` to Java 21.
