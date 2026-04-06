---
name: azure-vm
description: >
  Set up Datadog-monitored environments on Azure Virtual Machines.
  Covers Windows Server provisioning with .NET Framework and ASP.NET
  using Azure Bicep templates.
category: infrastructure
requires: []
supported_versions:
  os: [windows-server-2022]
  dotnet: [fx-4.8]
---

## Overview

The azure-vm plugin provides skills for provisioning Azure VMs and configuring them for Datadog monitoring. Currently covers Windows Server 2022 with .NET Framework 4.8 and ASP.NET using Bicep infrastructure-as-code.

## Prerequisites

- Azure subscription with VM permissions
- Azure CLI (`az`) installed and authenticated
- Datadog API key

## Skills

### setup-azure-vm
Provision a Windows Server 2022 VM on Azure using Bicep templates with .NET Framework 4.8 and ASP.NET pre-configured.

## Recommended Skill Order

1. setup-azure-vm

## Compatibility Notes

Tested with Windows Server 2022 and .NET Framework 4.8. Bicep templates deploy to the Azure region specified in parameters.
