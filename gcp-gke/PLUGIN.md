---
name: gcp-gke
description: >
  Set up and instrument a Datadog-monitored environment on Google
  Kubernetes Engine. Covers GKE cluster configuration and Datadog
  Operator installation via Helm.
category: infrastructure
requires: []
supported_versions:
  gke_version: [1.34]
---

## Overview

The gcp-gke plugin provides skills for setting up Datadog monitoring on GKE Standard clusters. Covers cluster configuration for Datadog compatibility (Cloud NAT for egress) and Datadog Operator deployment via Helm.

## Prerequisites

- GCP project with GKE cluster running
- `gcloud`, `kubectl`, and `helm` CLI tools
- Datadog API key

## Skills

### setup-gke-cluster
Configure a GKE Standard cluster for Datadog monitoring. Covers Cloud NAT setup for private clusters and cluster name configuration.

### install-dd-operator
Deploy the Datadog Agent on a GKE cluster using the Datadog Operator via Helm. Covers Helm repo setup, API key secret creation, operator installation, and agent deployment.

## Recommended Skill Order

1. setup-gke-cluster
2. install-dd-operator

## Compatibility Notes

Tested on GKE Standard 1.34. Private clusters require Cloud NAT for agent egress to Datadog endpoints.
