# Security Testing

- tests/kali_scan.robot     — ZAP baseline + Nikto + Nmap, orchestrated via Robot Framework
- resources/security.robot  — keywords wrapping each tool. ZAP and Nmap run as ephemeral
  `docker run --rm` sibling containers, so qa-platform-security-runner needs
  /var/run/docker.sock — see infrastructure/modules/runner-security/README.md for that
  tradeoff. Nikto runs NATIVELY instead (Kali's own apt package, not docker run) — the
  frapsoft/nikto Docker Hub image is a 2017-era Nikto whose SSL handling doesn't send
  SNI, which breaks against this target's Fly.io edge (routes by SNI).
- zap/  — placeholder for a future native/ZAP-only engine (scans/tests/reports/rules/shared),
  separate from the combined Kali suite above. Currently empty.

Run via: ./scripts/run_security.sh [environment]

## Docker-outside-of-Docker path gotcha

resources/security.robot's `docker run -v ...` calls go through
qa-platform-security-runner's mounted /var/run/docker.sock, which means
they're executed by the HOST's Docker daemon, not the calling container. A
`-v` source path only makes sense to that host daemon if it's a real path
on the HOST filesystem — a container-internal path like /qa-platform/...
(this container's own bind-mount target) means nothing to it, and fails
with "mounts denied ... not shared from the host."

Fix: infrastructure/modules/runner-security/main.tf sets
`HOST_MOUNT_ROOT=${var.mount_path}` (the real host absolute path) as an
env var on the container, and security.robot uses
`%{HOST_MOUNT_ROOT}/${SECURITY_OUTPUT_DIR}` as the -v source instead of a
container-relative path. If mount_path ever changes, this env var updates
automatically since it's wired from the same Terraform variable.

## Launch-failure vs. clean-scan gate integrity

A docker run that fails to even start the scan container (exit code 125)
used to fall through to "report file not found → empty findings → pass."
`Fail If Docker Launch Failed` now checks specifically for rc == 125 and
fails the test loudly instead, without misreading a tool's own non-zero
exit status (e.g. zap-baseline.py legitimately exits non-zero when it
finds issues) as an infrastructure failure.

## Stale-report gate integrity

Each `Run X Scan` keyword now `Remove File`s its own report before invoking
the tool. Without this, a scan that fails to (re)write its report (e.g.
Nikto getting cut off early by a WAF's error-limit/rate-limiting) would
silently parse a leftover report from a previous run instead of getting a
"report not found" warning — same false-negative risk as the exit-125
case above, just via a stale file instead of a missing one.

Also: this target sits behind Fly.io's edge, which appears to fingerprint
and rate-limit scanning traffic — Nikto's scan got cut short after ~2%
complete ("Error limit (20) reached ... ssl connect failed"). Added
`-Pause 1` to slow Nikto's request rate, which may or may not be enough to
avoid triggering it — a fully passing Nikto run against this particular
target isn't guaranteed regardless of tooling.

## Nikto severity mapping

Nikto's CSV output has no severity field (unlike ZAP's riskcode). Everything
was flat MEDIUM initially, which meant informational rows Nikto happens to
emit through the same row format (SSL certificate dump, robots.txt entry
count) could trip the gate exactly like a real finding. `Map Nikto Finding
To Severity` now infers a severity from the id/reference column and
description text: CWE-tagged or credential-related findings -> HIGH,
SSL-cert-dump/robots.txt informational lines -> LOW, everything else
(cookie flags, CORS, headers) -> MEDIUM. It's a keyword heuristic, not an
authoritative mapping — revisit if it misclassifies something that matters.

Deferred for later (placeholders, not yet scoped): SAST, dependency/SCA
scanning, secrets scanning, pen-test evidence tracking. Some of these may
tie into compliance/ for audit evidence rather than living purely here.
