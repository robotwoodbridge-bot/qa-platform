#!/usr/bin/env bash
# =============================================================================
# run_robot_api.sh — Run Robot Framework (RequestsLibrary) API suites inside
# the qa-platform-robot-api-runner container.
# =============================================================================
# Usage:
#   ./scripts/run_robot_api.sh                  → all API suites
#   ./scripts/run_robot_api.sh rest              → rest/tests only
#
# Prerequisites:
#   Infra stack must be up: cd infrastructure/environments/local && terraform apply
#
# No browser involved here — RequestsLibrary talks HTTP directly, so unlike
# run_robot_web.sh there's no headless/headed distinction.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SUITE=${1:-""}
CONTAINER="qa-platform-robot-api-runner"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo ""
  echo "ERROR: '${CONTAINER}' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

# The container's mount root is testings/api/ (not just rest/), so suites
# live under <protocol>/tests/ and can still resolve ../../shared/... .
TEST_PATH="rest/tests/"
if [ -n "${SUITE}" ]; then
  if docker exec "${CONTAINER}" test -d "${SUITE}/tests"; then
    TEST_PATH="${SUITE}/tests/"
  else
    echo "ERROR: no '${SUITE}/tests' directory found under testings/api/."
    exit 1
  fi
fi

echo "============================================================"
echo "  QA Platform — Robot API Runner (RequestsLibrary)"
echo "  Container : ${CONTAINER}"
echo "  Suite     : ${TEST_PATH}"
echo "============================================================"

docker exec "${CONTAINER}" robot \
  --outputdir rest/results \
  --listener allure_robotframework:rest/results/allure-results \
  "${TEST_PATH}"

echo ""
echo "Run complete. Results written to testings/api/rest/results/ on your host."
echo "Open report: open testings/api/rest/results/report.html"
