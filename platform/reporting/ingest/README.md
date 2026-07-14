# Ingest

submit(envelope: ResultEnvelope) — called by each engine's adapter.
Writes envelopes to storage (backing store TBD). No engine-specific logic
belongs here.
