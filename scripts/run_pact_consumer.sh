#!/usr/bin/env bash
# =============================================================================
# run_pact_consumer.sh — Run the EcomBasic consumer-side Pact contract tests
# and (optionally) publish the resulting pact file to the Pact Broker.
# =============================================================================
# Usage:
#   ./scripts/run_pact_consumer.sh              → run consumer tests only
#   ./scripts/run_pact_consumer.sh --publish     → run tests, then publish the
#                                                   generated pact to the broker
#
# Optional env overrides:
#   PACT_BROKER_URL=http://localhost:9292   (default; matches
#     infrastructure/modules/pact-broker's default pact_broker_port)
#   CONSUMER_VERSION=<version string>       (default: current short git SHA)
#
# Prerequisites:
#   - Python 3 on the host. This engine has no dedicated runner container yet
#     (unlike the other testing engines) — see testings/contract/pact/README.md.
#     Runs in a local venv under testings/contract/pact/consumer/.venv instead.
#   - For --publish: the Pact Broker must be up —
#     cd infrastructure/environments/local && terraform apply
#
# What this generates:
#   testings/contract/pact/pacts/qa-platform-ecombasic-client-ecombasic-api.json
#
# Scope: happy-path consumer side only (login + create order), mirroring
# testings/api/rest/tests/ecombasic_contract_test.robot. No provider
# verification — rahulshettyacademy.com is a public demo site with no
# provider-state test hooks to drive; provider/ stays empty for now.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PACT_DIR="testings/contract/pact"
CONSUMER_DIR="${PACT_DIR}/consumer"
VENV_DIR="${CONSUMER_DIR}/.venv"
CONSUMER_NAME="qa-platform-ecombasic-client"
PROVIDER_NAME="ecombasic-api"
PACT_FILE="${PACT_DIR}/pacts/${CONSUMER_NAME}-${PROVIDER_NAME}.json"

echo "=============================================="
echo "  QA Platform — Pact Consumer Runner"
echo "  Consumer    : ${CONSUMER_NAME}"
echo "  Provider    : ${PROVIDER_NAME}"
echo "=============================================="

if [ ! -d "${VENV_DIR}" ]; then
  echo "Creating venv at ${VENV_DIR}..."
  python3 -m venv "${VENV_DIR}"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet -r "${CONSUMER_DIR}/requirements.txt"

pytest "${CONSUMER_DIR}" -v

echo ""
echo "Pact file written: ${PACT_FILE}"

if [ "${1:-}" = "--publish" ]; then
  PACT_BROKER_URL="${PACT_BROKER_URL:-http://localhost:9292}"
  CONSUMER_VERSION="${CONSUMER_VERSION:-$(git rev-parse --short HEAD 2>/dev/null || date +%Y%m%d%H%M%S)}"

  echo ""
  echo "Publishing to ${PACT_BROKER_URL} as consumer version ${CONSUMER_VERSION}..."
  curl --fail -sS -X PUT \
    -H "Content-Type: application/json" \
    --data-binary "@${PACT_FILE}" \
    "${PACT_BROKER_URL}/pacts/provider/${PROVIDER_NAME}/consumer/${CONSUMER_NAME}/version/${CONSUMER_VERSION}"
  echo ""
  echo "Published."
fi
