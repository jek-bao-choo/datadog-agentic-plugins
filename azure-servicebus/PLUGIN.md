---
name: azure-servicebus
description: >
  Set up Datadog monitoring for Azure Service Bus. Covers namespace
  provisioning via Bicep or Terraform, queue/topic configuration,
  producer/consumer validation, and Datadog Azure integration for
  metrics, logs, and monitors.
category: queue-managed
requires: []
supported_versions:
  servicebus_tier: [Standard, Premium]
---

## Overview

The azure-servicebus plugin provides skills for provisioning Azure Service Bus namespaces and configuring Datadog monitoring. Azure Service Bus is a fully managed enterprise message broker with queues and publish-subscribe topics. Datadog collects metrics via the Azure integration and logs via Diagnostic Settings.

## Prerequisites

- Azure subscription with Service Bus permissions
- Azure CLI (`az`) installed and authenticated
- Datadog API key and Azure integration configured
- Bicep or Terraform (depending on PoC IaC preference)

## Skills

Skills are created based on the PoC requirement using the TODO file as a prompt. Typical skills include:

- `setup-servicebus/` — Provision namespace, queues, topics, and Shared Access Policies
- `install-dd-integration/` — Configure Datadog Azure integration for Service Bus metrics and logs

## Recommended Skill Order

1. setup-servicebus (provision the namespace and messaging entities)
2. install-dd-integration (configure Datadog monitoring)

## Compatibility Notes

Azure Service Bus Standard tier supports queues and topics. Premium tier adds features like geo-disaster recovery, Virtual Network integration, and larger message sizes. The Datadog Azure integration collects metrics from both tiers.
