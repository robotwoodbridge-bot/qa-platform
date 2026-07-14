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

## Implemented: EcomBasic consumer, happy path

`consumer/` has a working pact-python suite (`test_ecombasic_consumer.py`)
covering the same two happy-path scenarios as
`testings/api/rest/tests/ecombasic_contract_test.robot` — login and create
order — expressed as Pact interactions instead of JSON Schema validation.
Consumer name is `qa-platform-ecombasic-client` (there's no real "consumer
app" here — the platform itself is standing in as the consumer of a public
practice API); provider is `ecombasic-api`.

Run via: `./scripts/run_pact_consumer.sh` (add `--publish` to also push the
generated pact to the Pact Broker). Generates
`pacts/qa-platform-ecombasic-client-ecombasic-api.json`.

No dedicated runner container yet (unlike the other testing engines) — runs
in a local Python venv under `consumer/.venv`. If this grows beyond one
suite, containerize it the same way as the other engines
(`infrastructure/modules/runner-<engine>/`).

`provider/` is still empty on purpose: `rahulshettyacademy.com` is a public
demo site with no provider-state test hooks, so there's nothing to verify
the pact against yet. If a real service under this platform's control ever
consumes/provides against a Pact contract, provider verification belongs
there.
