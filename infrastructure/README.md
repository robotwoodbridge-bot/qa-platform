# Infrastructure

Terraform-managed, local Docker for now (see environments/local). Same
tool (Terraform) is intended to carry forward to a cloud backend later —
only the backend block and provider need to change, not the module shape.

## Layout

    environments/
        local/        — root composition, wires modules together
    modules/
        network/          — net-qa-platform (general) + qa-security-net (isolated)
        observability/    — Loki + Grafana
        runner-playwright/    — Playwright/TypeScript, web GUI
        runner-robot-web/     — Robot Framework + Browser library (Playwright-based), web GUI
        runner-robot-mobile/  — Android emulator + Appium (iOS deferred — see its README)
        runner-k6/             — k6 load testing
        runner-security/         — Kali + ZAP, isolated network by default
        pact-broker/               — Pact Broker + Postgres
    docker/
        Dockerfile.*  — build files for the above
        requirements-robot-web.txt, requirements-robot-mobile.txt
        loki-config.yaml
        grafana/provisioning/

## What changed from the original main.tf

The original combined Playwright + Robot Framework + Kali into one
"robotkali-runner" image on a single network. Split apart so:
- each engine's runner matches the testing/ folder structure already in
  the repo (playwright vs robot vs security are independently testable
  and independently deployable)
- the security/Kali runner is isolated on its own network by default
  (see modules/runner-security/README.md for why)
- k6 and the Pact Broker (both referenced elsewhere in this repo but
  missing from the original file) are now scaffolded

Correction after migrating real tests from temp/: the web Robot suites use
`Library Browser` (robotframework-browser, Playwright-based), not
SeleniumLibrary as originally scaffolded. Dockerfile.robot-web and its
requirements file were updated accordingly — no more chromium/chromedriver
apt install, base image is now the Node-based Playwright image (needed for
the Browser library's Node side-car), plus `rfbrowser init` after pip
install. runner-robot-web and runner-robot-mobile now mount the whole
robot/ folder (not just web/ or mobile/android/) so suites can resolve
../../../shared/resources/*.robot imports.

## Not yet covered (see conversation history / standards docs)

- iOS execution (needs an external macOS runner)
- Distributed/multi-node k6 (this runs a single k6 container)
- Ephemeral per-PR environments
- Object storage, reporting datastore, secrets backend, chaos/DR tooling
- Remote Terraform state (still local backend — fine for now, revisit
  before multiple people share this)
