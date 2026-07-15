#!/usr/bin/env bash
# =============================================================================
# run_accessibility.sh — Run the WCAG 2.1 AA accessibility suite (Robot
# Framework + Browser library + axe-core) inside qa-platform-accessibility-runner.
# =============================================================================
# Usage:
#   ./scripts/run_accessibility.sh              → all suites, headless
#   ./scripts/run_accessibility.sh --headed      → headed (xvfb)
#
# Prerequisites:
#   Infra stack must be up: cd infrastructure/environments/local && terraform apply
#
# Runs in its own container (qa-platform-accessibility-runner), built from
# the same image as qa-platform-robot-web-runner (Dockerfile.robot-web —
# Browser library / Playwright) but mounted at testings/accessibility/
# instead of testings/gui/robot/ — kept separate so this engine stays
# independently testable/deployable, same reasoning as every other runner
# in infrastructure/modules/. See testings/accessibility/README.md for why
# it doesn't reuse testings/gui/robot/web/'s page objects directly.
#
# axe-core isn't committed to the repo (~700KB minified) — installed as a
# Node dependency (package.json) each run (fast/no-op once already installed).
#
# Output:
#   testings/accessibility/results/  → Robot Framework log/report/output.xml
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CONTAINER="qa-platform-accessibility-runner"
HEADLESS="True"
for arg in "$@"; do
  if [ "$arg" = "--headed" ]; then
    HEADLESS="False"
  fi
done

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: '${CONTAINER}' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

echo "=============================================="
echo "  QA Platform — Accessibility Runner (axe-core)"
echo "  Headless : ${HEADLESS}"
echo "=============================================="

docker exec "${CONTAINER}" npm install --no-save --no-fund --no-audit

if [ "${HEADLESS}" = "False" ]; then
  docker exec "${CONTAINER}" xvfb-run --auto-servernum \
    robot --outputdir results --variable HEADLESS_MODE:False --variable BROWSER_TIMEOUT:30s tests/
else
  docker exec "${CONTAINER}" robot --outputdir results --variable HEADLESS_MODE:True tests/
fi

echo ""
echo "Report: open testings/accessibility/results/report.html"
