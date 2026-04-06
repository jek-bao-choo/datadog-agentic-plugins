---
name: php-instrumentation
description: >
  Instrument PHP Laravel applications with Datadog APM. Covers
  Laravel 8 with PHP 7.4 on Apache2 and Laravel 12 with PHP 8.3
  on Nginx, both on Ubuntu EC2 instances.
category: instrumentation
requires: [aws-ec2]
supported_versions:
  php_version: [7.4, 8.3]
  laravel_version: [8, 12]
---

## Overview

The php-instrumentation plugin provides skills for setting up and instrumenting PHP Laravel applications with Datadog APM. Covers two stack variants: Laravel 12 on PHP 8.3 with Nginx/PHP-FPM, and Laravel 8 on PHP 7.4 with Apache2. Each variant has a setup skill (Docker + EC2 native install) and an instrumentation skill (dd-trace-php).

## Prerequisites

- An EC2 instance running Ubuntu 24.04 (see aws-ec2 plugin)
- SSH access to the target instance
- Datadog API key and site location

## Skills

### setup-laravel12-nginx
Set up a Laravel 12 application with PHP 8.3 and Nginx on Ubuntu 24.04. Covers local Docker setup and EC2 native installation.

### laravel12-dd-tracer
Instrument a Laravel 12 + PHP 8.3 + Nginx application with Datadog APM. Covers Single Step and manual tracer installation, unified service tagging, and verification.

### setup-laravel8-apache2
Set up a Laravel 8 application with PHP 7.4 and Apache2 on Ubuntu 24.04. Covers local Docker setup and EC2 native installation.

### laravel8-dd-tracer
Instrument a Laravel 8 + PHP 7.4 + Apache2 application with Datadog APM. Covers manual tracer installation, unified service tagging, and verification.

## Recommended Skill Order

1. setup-laravel12-nginx (or setup-laravel8-apache2)
2. laravel12-dd-tracer (or laravel8-dd-tracer)

## Compatibility Notes

Both stacks require an EC2 instance running Ubuntu 24.04. The setup skills are independent of the tracer skills — complete setup first, then instrument.
