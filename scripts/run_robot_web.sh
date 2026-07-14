#!/usr/bin/env bash
# =============================================================================
# run_robot_web.sh — Run Robot Framework (Browser library) web GUI suites
# inside the qa-platform-robot-web-runner container.
# =============================================================================
# Usage:
#   ./scripts/run_robot_web.sh                  → all web suites, headless
#   ./scripts/run_robot_web.sh smoke             → web/tests/smoke only
#   ./scripts/run_robot_web.sh smoke --headed    → headed (xvfb)
#
# Prerequisites:
#   Infra stack must be up: cd infrastructure/environments/local && terraform apply
#
# Note: this replaces run_iac.sh. That script ran `python -m robot` inside
# a combined "qa-platform-playwright-runner" container that mixed Playwright, Robot
# Framework, and Kali. That's split apart now — this targets
# qa-platform-robot-web-runner specifically, and the suite uses `Library Browser`
# (Playwright-based), not SeleniumLibrary.
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

SUITE=${1:-""}
HEADLESS="True"
CONTAINER="qa-platform-robot-web-runner"

for arg in "$@"; do
  if [ "$arg" = "--headed" ]; then
    HEADLESS="False"
  fi
done

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo ""
  echo "ERROR: '${CONTAINER}' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

# The container's mount root is testings/gui/robot/ (not just web/), so
# suites live under web/tests/ and can still resolve ../../../shared/... .
TEST_PATH="web/tests/"
INCLUDE_ARGS=()
if [ -n "${SUITE}" ]; then
  if docker exec "${CONTAINER}" test -d "web/tests/${SUITE}"; then
    TEST_PATH="web/tests/${SUITE}/"
  else
    INCLUDE_ARGS=(--include "${SUITE}")
  fi
fi

echo "============================================================"
echo "  QA Platform — Robot Web Runner (Browser library)"
echo "  Container : ${CONTAINER}"
echo "  Suite     : ${TEST_PATH}"
[ ${#INCLUDE_ARGS[@]} -gt 0 ] && echo "  Tag       : ${SUITE}"
echo "  Headless  : ${HEADLESS}"
echo "============================================================"

if [ "${HEADLESS}" = "False" ]; then
  docker exec "${CONTAINER}" xvfb-run --auto-servernum \
    robot \
    --outputdir web/results \
    --variable HEADLESS_MODE:False \
    --variable BROWSER_TIMEOUT:30s \
    --listener allure_robotframework:web/results/allure-results \
    ${INCLUDE_ARGS[@]+"${INCLUDE_ARGS[@]}"} \
    "${TEST_PATH}"
else
  docker exec "${CONTAINER}" robot \
    --outputdir web/results \
    --variable HEADLESS_MODE:True \
    --listener allure_robotframework:web/results/allure-results \
    ${INCLUDE_ARGS[@]+"${INCLUDE_ARGS[@]}"} \
    "${TEST_PATH}"
fi

echo ""
echo "Run complete. Results written to testings/gui/robot/web/results/ on your host."
echo "Open report: open testings/gui/robot/web/results/report.html"
