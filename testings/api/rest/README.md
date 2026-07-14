# REST

- tests/       — protocol-specific test suites
- schemas/     — JSON Schema files used for response-shape validation
  (single API's own contract with its consumers — distinct from
  testings/contract/pact, which validates agreement between two specific
  services; see testings/contract/pact/README.md)
- resources/   — keywords for this protocol's suites

ecombasic_contract_test.robot migrated from temp/tests/api/ — validates the
EcomBasic practice API's (rahulshettyacademy.com) login and create-order
endpoints against JSON Schema files, plus basic status-code and field
checks. Uses RequestsLibrary (not a browser) — see
infrastructure/modules/runner-robot-api.

Run via: ./scripts/run_robot_api.sh [rest]
