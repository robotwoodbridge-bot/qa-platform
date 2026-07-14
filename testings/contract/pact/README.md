# Contract Testing (Pact)

- consumer/  — consumer-side tests, generate pact files against mocked providers
- provider/  — provider-side verification tests, replay pacts against the real provider
- pacts/     — generated contract files, typically synced to/from a Pact Broker
- broker/    — Pact Broker config, publish / can-i-deploy scripts
- shared/    — fixtures, models, utils shared between consumer/provider tests

Multiple consumer/provider service pairs (e.g. web-app <-> payments-service)
nest as subfolders under consumer/ and provider/ rather than new top-level folders.

Note: distinct from testing/api/rest/schemas (OpenAPI schema validation of a
single API's own responses). Contract testing here validates agreement
between two specific services.
