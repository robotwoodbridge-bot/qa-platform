# Disaster Recovery / Resilience Testing

Validates failover, degraded-mode behavior, and recovery-time/recovery-point objectives (RTO/RPO).

Scope: chaos/fault-injection scenarios, region/AZ failover drills, dependency-outage simulation,
backup-restore validation. Feeds results into the shared reporting schema alongside the other
testing engines.

- resources/  — keywords wrapping Docker container lifecycle control (Process library) and
  Loki's HTTP API (RequestsLibrary)
- tests/      — DR suites

## Implemented: Loki outage/recovery, happy path (Robot Framework + Python)

`tests/loki_recovery.robot` — simulates a dependency outage on the observability
stack's log backend and validates a clean recovery:

1. push a uniquely-labelled log line (RPO marker)
2. confirm it's ingested
3. `docker stop qa-platform-loki` (simulated outage)
4. `docker start qa-platform-loki`
5. poll `/ready` until it recovers, bounded by an RTO budget
   (`RTO_BUDGET` in `resources/dr_keywords.robot`, default 60s) — the RTO is
   enforced by this poll's own timeout, not a separate assertion
6. query the marker back — proves data survived the restart because `/loki`
   is a persistent named volume (`infrastructure/modules/observability`),
   not container-local storage

No auth needed — this stack's `loki-config.yaml` has `auth_enabled: false`.

Run via: `./scripts/run_dr.sh`. No dedicated runner container yet (unlike
the other engines) — the suite calls `docker stop`/`start` directly, which
needs to run from the host; runs in a local venv instead (see the script's
header comment for why, and the tradeoff this mirrors from
`testings/security/`).

This is Robot Framework + Python only. Playwright/TypeScript coverage for
GUI-facing DR scenarios (e.g. degraded-mode UI behavior during an outage) is
a deliberate later pass, not an oversight.

Not yet covered: Grafana recovery (same pattern would apply, but its API
needs the admin password — parameterize via env var when adding, don't
hardcode it), region/AZ failover drills, backup/restore of the Pact Broker's
Postgres volume, chaos scenarios beyond a single clean stop/start (e.g.
network partition, resource exhaustion).

## Reporting
`shared/REPORTING_ADAPTER.md` is scaffolded (mirrors the other engines) but
the actual mapping into `platform/reporting/schema` isn't wired up yet —
`platform/reporting/` itself is still scaffolding too (see its README).
