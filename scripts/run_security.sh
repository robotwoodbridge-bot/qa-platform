#!/usr/bin/env bash
# =============================================================================
# run_security.sh — Run the security scan suite (ZAP / Nikto / Nmap) inside
# the qa-platform-security-runner container.
# =============================================================================
# Usage:
#   ./scripts/run_security.sh               → scan staging (default)
#   ./scripts/run_security.sh staging       → explicit environment target
#   ./scripts/run_security.sh production    → scan production environment
#
# Prerequisites:
#   Infra stack must be up: cd infrastructure/environments/local && terraform apply
#
# Note: this replaces run_security.sh, which ran locally via a .venv (the
# suite's keywords launch `docker run --rm` scan containers directly, so it
# needed host Docker access). Now runs inside qa-platform-security-runner instead,
# which has /var/run/docker.sock mounted in for the same reason — see
# modules/runner-security/README.md for the isolation tradeoff that
# accepts.
#
# Expects testings/security/kali_scan.robot + testings/security/... keywords
# to exist. If they're not there yet, migrate them from
# temp/tests/security/kali_scan.robot and temp/keywords/security.robot first.
#
# Output:
#   testings/security/zap/reports/  → raw JSON/XML reports from ZAP, Nikto, Nmap
#   testings/security/results/      → Robot Framework execution log
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

ENVIRONMENT=${1:-"staging"}
CONTAINER="qa-platform-security-runner"
OUTPUT_DIR="results"

echo "=============================================="
echo "  QA Platform — Security Scan Runner"
echo "  Environment : ${ENVIRONMENT}"
echo "=============================================="

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: '${CONTAINER}' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

echo "Pulling scan tool images..."
docker pull ghcr.io/zaproxy/zaproxy:stable --quiet
docker pull frapsoft/nikto                  --quiet
docker pull instrumentisto/nmap             --quiet

docker exec "${CONTAINER}" robot \
  --outputdir "${OUTPUT_DIR}" \
  --variable ENVIRONMENT:"${ENVIRONMENT}" \
  --loglevel INFO \
  --consolecolors on \
  --name "Security Scan — ${ENVIRONMENT}" \
  tests/

echo ""
echo "Scan complete."
echo "  RF report    : open testings/security/results/report.html"
echo "  Raw findings : ls testings/security/results/security/"
