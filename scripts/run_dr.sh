#!/usr/bin/env bash
# =============================================================================
# run_dr.sh — Run the disaster-recovery / resilience suite (Robot Framework)
# against the local observability stack (Loki).
# =============================================================================
# Usage:
#   ./scripts/run_dr.sh              → run all DR suites
#
# Prerequisites:
#   - Infra stack must be up: cd infrastructure/environments/local && terraform apply
#   - Python 3 + host Docker CLI access. This engine has no dedicated runner
#     container yet (unlike the other testing engines) — the suite itself
#     calls `docker stop`/`docker start` on a sibling container, which only
#     makes sense run from the host. Doing this from inside a container would
#     need Docker-outside-of-Docker access, the same tradeoff already accepted
#     for testings/security/ (see modules/runner-security/README.md) — not
#     set up here yet. Runs in a local venv under testings/dr/.venv instead.
#
# What this does: stops and restarts qa-platform-loki mid-test to simulate a
# dependency outage, so expect a brief (~seconds) gap in log ingestion on this
# machine while it runs. Safe against the local dev stack — do not point
# LOKI_CONTAINER (testings/dr/resources/dr_keywords.robot) at a shared or
# production container.
#
# Output:
#   testings/dr/results/  → Robot Framework log/report/output.xml
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

DR_DIR="testings/dr"
VENV_DIR="${DR_DIR}/.venv"

if [ ! -d "${VENV_DIR}" ]; then
  echo "Creating venv at ${VENV_DIR}..."
  python3 -m venv "${VENV_DIR}"
fi

# shellcheck disable=SC1091
source "${VENV_DIR}/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet -r "${DR_DIR}/requirements.txt"

if ! docker ps --format '{{.Names}}' | grep -q '^qa-platform-loki$'; then
  echo "ERROR: 'qa-platform-loki' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

robot \
  --outputdir "${DR_DIR}/results" \
  --loglevel INFO \
  --consolecolors on \
  --name "Disaster Recovery" \
  "${DR_DIR}/tests/"

echo ""
echo "Report: open ${DR_DIR}/results/report.html"
