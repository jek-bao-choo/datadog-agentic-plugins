## How to use this file

This file is a prompt for Claude. It describes what to build when working within the `postgres-k8s` plugin. Work proceeds in two phases: first provision the database, then set up Datadog Database Monitoring. Each phase produces skills following the conventions in `MARKETPLACE.md` and `README.md`.

Before starting either phase, check if a matching skill already exists under `skills/`. If it does, use it. If it doesn't, create one using `/skill-creator` and place provisioning scripts, configs, and manifests in the skill's `references/`, `scripts/`, and `assets/` directories.

---


## Phase 1: Database Provisioning

Deploy PostgreSQL on Kubernetes using the Zalando Postgres Operator:

- Install Zalando Postgres Operator via Helm on K8s/OpenShift
- Deploy PostgreSQL 17 cluster with local storage
- Apply ClusterRole patches required for the operator to manage resources
- Validate the PostgreSQL cluster is running and accepting connections
- Document any OpenShift-specific adjustments (SCCs, routes, etc.)

## Phase 2: Datadog Database Monitoring

Research and configure Datadog Database Monitoring (DBM) for PostgreSQL on Kubernetes:

- Research on-prem offline Datadog Operator installation for DBM (same air-gapped/offline context as OpenShift on-prem environments)
- Explain how the Datadog Operator and Agent interact with PostgreSQL to collect query metrics, explain plans, and activity data
- Document the connection flow: Datadog Operator → DaemonSet Agent → PostgreSQL pod → query metrics
- Verify DBM data appears in the Datadog Database Monitoring dashboard

## Guidelines

- Keep it simple. Each manifest should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to K8s database operations should be able to follow along.
- Every sub-directory gets a `README.md` explaining what it does and how to apply it.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Context7 MCP: `/datadog/datadog-operator` — Datadog Operator source and docs
- Datadog: Database Monitoring for PostgreSQL on Kubernetes docs
- Zalando Postgres Operator: https://postgres-operator.readthedocs.io
- Helm: https://helm.sh/docs/
