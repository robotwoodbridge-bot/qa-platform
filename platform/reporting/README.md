# Reporting (Phase 6)

Owns the common result envelope and the ingestion/aggregation logic that
feeds dashboards and release readiness. Does NOT know about individual
testing engines (Playwright, Robot, ZAP, k6, Pact, etc.) — each engine
owns its own adapter (in its shared/ or utils/ folder) that maps its
native report into the envelope and calls submit().

- schema/     — the ResultEnvelope type/contract
- ingest/     — submit() API, writes envelopes to storage
- aggregate/  — query/rollup logic consumed by dashboards
