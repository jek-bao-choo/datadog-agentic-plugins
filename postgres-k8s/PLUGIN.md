---
name: postgres-k8s
description: >
  Set up Datadog Database Monitoring for PostgreSQL running as a
  Kubernetes workload. Covers Zalando Postgres Operator with
  PostgreSQL 17 on OpenShift and Kubernetes clusters.
category: database-k8s
requires: [aws-eks, gcp-gke, openshift-onprem]
supported_versions:
  postgres_version: [17]
  operator: [zalando-1.15.1]
---

## Overview

The postgres-k8s plugin provides skills for deploying PostgreSQL on Kubernetes using the Zalando Postgres Operator and configuring Datadog Database Monitoring. Includes Helm values, cluster manifests, local storage configuration, and operator patches for OpenShift compatibility.

## Prerequisites

- A running Kubernetes or OpenShift cluster (see aws-eks, gcp-gke, or openshift-onprem plugins)
- `kubectl` or `oc` CLI configured
- `helm` v3 installed
- Datadog API key

## Skills

### setup-postgres-k8s
Deploy PostgreSQL 17 on Kubernetes using the Zalando Postgres Operator via Helm. Covers operator installation, cluster manifest deployment, local storage provisioning, and OpenShift-specific patches.

## Recommended Skill Order

1. setup-postgres-k8s

## Compatibility Notes

Tested with Zalando Postgres Operator 1.15.1, PostgreSQL 17.5, Spilo 4.0-p3, and Patroni 4.0.4 on OpenShift. Includes OpenShift-specific Helm values and ClusterRole patches.
