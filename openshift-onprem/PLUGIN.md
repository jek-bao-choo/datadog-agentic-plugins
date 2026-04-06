---
name: openshift-onprem
description: >
  Set up Datadog monitoring on Red Hat OpenShift Container Platform.
  Covers Azure Red Hat OpenShift (ARO) cluster provisioning and
  Datadog Operator with DDOT Collector deployment.
category: infrastructure
requires: []
supported_versions:
  openshift_version: [4.19.20]
  k8s_version: [1.32.9]
---

## Overview

The openshift-onprem plugin provides skills for setting up Datadog monitoring on OpenShift clusters. Currently covers Azure Red Hat OpenShift (ARO) with Datadog Operator and DDOT (Datadog OpenTelemetry) Collector via Kubernetes DaemonSet.

## Prerequisites

- Azure subscription with ARO permissions
- Azure CLI (`az`) installed and authenticated
- `oc` (OpenShift CLI) or kubectl
- Datadog API key

## Skills

### setup-openshift
Provision an Azure Red Hat OpenShift (ARO) 4 cluster using the Azure CLI. Covers VPC, subnets, and cluster creation.

### install-dd-operator
Deploy the Datadog Operator and DDOT Collector on an OpenShift cluster. Includes operator subscription and agent configuration with OpenShift-specific SecurityContextConstraints.

## Recommended Skill Order

1. setup-openshift
2. install-dd-operator

## Compatibility Notes

Tested with ARO 4.19.20 (Kubernetes 1.32.9) in southeastasia region. Datadog Operator v1.22.0.
