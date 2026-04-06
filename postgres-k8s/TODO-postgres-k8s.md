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

Configure Datadog Database Monitoring (DBM) for PostgreSQL on Kubernetes:

**Implementation steps:**
- Create a PostgreSQL monitoring user with the required permissions (`pg_monitor` role, `pg_stat_statements` extension enabled)
- Configure the Datadog Agent's PostgreSQL integration at `conf.d/postgres.d/conf.yaml` with: host, port, username, password (from K8s secret), `dbm: true`
- Enable query metrics collection (`collect_activity_samples: true`, `collect_plans: true`)
- Enable explain plan collection for slow queries
- Set unified service tags on the Agent (`DD_ENV`, `DD_SERVICE`, `DD_VERSION`)

**Research tasks (document findings in README.md):**
- Research on-prem offline Datadog Operator installation for DBM (same air-gapped/offline context as OpenShift on-prem environments)
- Explain how the Datadog Operator and Agent interact with PostgreSQL to collect query metrics, explain plans, and activity data
- Document the connection flow: Datadog Operator → DaemonSet Agent → PostgreSQL pod → query metrics

**Validation:**
- Verify DBM data appears in **Database Monitoring > Query Metrics** in the Datadog UI
- Confirm query samples are being collected (Database Monitoring > Query Samples)
- Check explain plans are available for slow queries
- Run `kubectl exec <agent-pod> -c agent -- agent status` and verify the PostgreSQL check is running without errors

## Guidelines

- Keep it simple. Each manifest should be the smallest thing that demonstrates the pattern.
- Atomic steps: one change, one test, one commit.
- Beginner-friendly: someone new to K8s database operations should be able to follow along.
- Every skill directory includes a `README.md` for the app, infra, database, or other component built: prerequisites, tech stack (framework + version), step-by-step reproduction guide, run instructions, and teardown steps.
- Security: this is a public repo. No API keys, no secrets, no credentials in code or committed files.
- Git hygiene: meaningful commit messages, small commits, `.gitignore` up to date.
- Check existing skills before creating new ones. Use `/skill-creator` to create new skills.

## Tools & References

- Context7 MCP: `/datadog/datadog-operator` — Datadog Operator source and docs
- Datadog: Database Monitoring for PostgreSQL on Kubernetes docs
- Zalando Postgres Operator: https://postgres-operator.readthedocs.io
- Helm: https://helm.sh/docs/
