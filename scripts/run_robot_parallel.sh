#!/usr/bin/env bash
# =============================================================================
# run_robot_parallel.sh — Run web GUI Robot suites in parallel with pabot,
# inside the qa-platform-robot-web-runner container.
# =============================================================================
# Usage:
#   ./scripts/run_robot_parallel.sh               → all of web/tests/, 4 workers
#   ./scripts/run_robot_parallel.sh smoke          → web/tests/smoke/ only
#   ./scripts/run_robot_parallel.sh smoke 2        → web/tests/smoke/, 2 workers
#
# Note: scoped to web/ (Browser library) suites only. Mobile (Appium)
# suites aren't parallelized here — that needs multiple emulator
# instances, not yet scaffolded (see modules/runner-robot-mobile/README.md).
#
# Also note: this replaces run_parallel.sh, which ran pabot from a local
# .venv. Runs inside the container now instead, for consistency with the
# other scripts (pabot ships in requirements-robot-web.txt).
#
# Prerequisites:
#   Infra stack must be up: cd infrastructure/environments/local && terraform apply
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SUITE=${1:-""}
PROCESSES=${2:-4}
CONTAINER="qa-platform-robot-web-runner"
OUTPUT_DIR="web/results"
ALLURE_DIR="${OUTPUT_DIR}/allure-results"

if [[ -z "$SUITE" || "$SUITE" == "." ]]; then
  TEST_PATH="web/tests"
else
  TEST_PATH="web/tests/${SUITE}"
fi

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: '${CONTAINER}' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

echo "=============================================="
echo "  QA Platform — Parallel Robot Web Runner"
echo "  Suite    : ${TEST_PATH}"
echo "  Workers  : ${PROCESSES}"
echo "=============================================="

docker exec "${CONTAINER}" rm -rf "${OUTPUT_DIR}"
docker exec "${CONTAINER}" rm -f .pabotsuitenames
docker exec "${CONTAINER}" mkdir -p "${OUTPUT_DIR}" "${ALLURE_DIR}"

docker exec "${CONTAINER}" python3 -m pabot.pabot \
  --processes "${PROCESSES}" \
  --testlevelsplit \
  --outputdir "${OUTPUT_DIR}" \
  --listener "allure_robotframework:${ALLURE_DIR}" \
  --loglevel INFO \
  "${TEST_PATH}"

echo ""
echo "Done. Open testings/gui/robot/web/results/report.html for the Robot Framework report."
echo "Run 'allure serve testings/gui/robot/web/results/allure-results' to view the Allure report."
