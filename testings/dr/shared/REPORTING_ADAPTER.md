# Reporting Adapter

Maps this engine's native report output into the shared ResultEnvelope
(see platform/reporting/schema/result-envelope.ts) and calls
platform/reporting's submit(). This engine owns the mapping logic since
it knows its own native format; platform/reporting does not.
