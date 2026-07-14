#!/usr/bin/env bash
# =============================================================================
# run_k6.sh — Run the k6 login load test inside the qa-platform-k6-runner container.
# =============================================================================
# Usage:
#   ./scripts/run_k6.sh                 → smoke profile (2 VUs, 30s sanity check)
#   ./scripts/run_k6.sh load            → load profile (5 VUs sustained 2m)
#   ./scripts/run_k6.sh stress          → stress profile (ramp to 15 VUs)
#
# Optional env overrides:
#   BASE_URL=https://staging.example.com ./scripts/run_k6.sh load
#   LOGIN_USERNAME / LOGIN_PASSWORD to override credentials
#
# Prerequisites:
#   Infra stack must be up: cd infrastructure/environments/local && terraform apply
#
# Note: this replaces run_k6.sh, which assumed a locally installed k6
# binary (brew install k6). Runs inside the qa-platform-k6-runner container now, for
# consistency with the rest of the stack — no local k6 install needed.
#
# Expects testings/performance/k6/scripts/login_load_test.js. If it's not
# there yet, migrate it from temp/tests/performance/k6/login_load_test.js
# first.
#
# Results land in testings/performance/k6/reports/ (git-ignored) as a JSON
# summary per run.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

PROFILE=${1:-smoke}
CONTAINER="qa-platform-k6-runner"
SCRIPT="scripts/login_load_test.js"
OUTPUT_DIR="testings/performance/k6/reports"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
SUMMARY_HOST="${OUTPUT_DIR}/login-${PROFILE}-${TIMESTAMP}.json"
SUMMARY_CONTAINER="reports/login-${PROFILE}-${TIMESTAMP}.json"

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: '${CONTAINER}' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"

echo "=============================================="
echo "  QA Platform — k6 Load Test Runner"
echo "  Script   : ${SCRIPT}"
echo "  Profile  : ${PROFILE}"
echo "  Summary  : ${SUMMARY_HOST}"
echo "=============================================="

docker exec \
  -e PROFILE="${PROFILE}" \
  ${BASE_URL:+-e BASE_URL="${BASE_URL}"} \
  ${LOGIN_USERNAME:+-e LOGIN_USERNAME="${LOGIN_USERNAME}"} \
  ${LOGIN_PASSWORD:+-e LOGIN_PASSWORD="${LOGIN_PASSWORD}"} \
  "${CONTAINER}" \
  k6 run --summary-export "${SUMMARY_CONTAINER}" "${SCRIPT}"

echo ""
echo "Done. JSON summary saved to ${SUMMARY_HOST}"
