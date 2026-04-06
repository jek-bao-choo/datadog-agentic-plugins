---
name: running-scality-docker
description: >-
  Use this skill whenever the user needs to run Scality ZenkoCloudServer (S3-compatible
  object storage) locally or on Kubernetes. Triggers on mentions of Scality, ZenkoCloudServer,
  S3-compatible storage, or object storage sandbox setup.
version: 0.1.0
---

# Scality ZenkoCloudServer — S3-Compatible Object Storage

Run Scality ZenkoCloudServer for S3-compatible object storage testing, available as Docker container or Kubernetes deployment.

## Prerequisites

- Docker (for local setup) or Kubernetes cluster (for K8s deployment)

## Instructions

Two deployment options are documented in `references/`:

### Option A: Docker
See `references/README.md` for running ZenkoCloudServer as a Docker container.

### Option B: Kubernetes
See `references/README-k8s.md` for deploying ZenkoCloudServer 9.3.0 on Kubernetes with persistent storage.

## Validation

```bash
# Test S3 compatibility
aws --endpoint-url http://localhost:8000 s3 ls
```

## Troubleshooting

### Container exits immediately
**Cause:** Port conflict or missing volume mount.
**Fix:** Check Docker logs and ensure port 8000 is available.
