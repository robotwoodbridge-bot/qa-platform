#!/usr/bin/env bash
# =============================================================================
# run_security.sh — Run the security scan suite (ZAP / Nikto / Nmap) inside
# the qa-platform-security-runner container.
# =============================================================================
# Usage:
#   ./scripts/run_security.sh                                    → scan the suite's default target
#   ./scripts/run_security.sh https://staging.example.com         → explicit target URL
#   ./scripts/run_security.sh https://staging.example.com HIGH    → target + severity threshold
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
# Nikto pull removed: it runs natively via Kali's own apt package now, not
# a docker-pulled image — see testings/security/README.md for why
# (frapsoft/nikto's bundled Nikto doesn't support this target's SNI-based
# routing).
#
# Output:
#   testings/security/results/security/  → raw JSON/CSV/XML reports from ZAP, Nikto, Nmap
#   testings/security/results/           → Robot Framework execution log
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

CONTAINER="qa-platform-security-runner"
OUTPUT_DIR="results"
VARIABLE_ARGS=()
[ -n "${1:-}" ] && VARIABLE_ARGS+=(--variable "TARGET_URL:${1}")
[ -n "${2:-}" ] && VARIABLE_ARGS+=(--variable "FAIL_ON_SEVERITY:${2}")

echo "=============================================="
echo "  QA Platform — Security Scan Runner"
echo "  Target      : ${1:-<suite default>}"
echo "  Fail on     : ${2:-<suite default>}"
echo "=============================================="

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "ERROR: '${CONTAINER}' is not running."
  echo "Start the infra stack first:"
  echo "  cd infrastructure/environments/local && terraform apply"
  exit 1
fi

echo "Pulling scan tool images (ZAP, Nmap — Nikto runs natively, no pull needed)..."
docker pull ghcr.io/zaproxy/zaproxy:stable --quiet
docker pull instrumentisto/nmap             --quiet

docker exec "${CONTAINER}" robot \
  --outputdir "${OUTPUT_DIR}" \
  ${VARIABLE_ARGS[@]+"${VARIABLE_ARGS[@]}"} \
  --loglevel INFO \
  --consolecolors on \
  --name "Security Scan" \
  tests/

echo ""
echo "Scan complete."
echo "  RF report    : open testings/security/results/report.html"
echo "  Raw findings : ls testings/security/results/security/"
