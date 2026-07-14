# CLAUDE.md

Guidance for Claude Code (and other AI agents) working in this repository.
See [README.md](README.md) for the project overview and repo layout first.

## What this is

An enterprise QE platform monorepo, not a single test framework. Platform-first,
modular: shared services (`platform/`), Infrastructure as Code
(`infrastructure/`), one folder per testing domain (`testings/`), mirrored
CI/CD (`pipelines/azure/` + `.github/workflows/`), and an AI agent/skill layer
(`ai/`). Read a domain's own `README.md` before adding to it — most define
scope boundaries deliberately, and duplicating a concern that already has a
home (e.g. adding request-builder helpers inside `testings/api/rest/` instead
of `testings/api/shared/`) is the main way this repo would rot.

## Ground truth over assumptions

Several top-level folders (`architecture/`, `dashboards/`, `shared/`,
`tools/`) are reserved but empty — don't assume there's missing content to
find. Several `testings/` domains (Playwright GUI, Pact contract testing,
accessibility, DR) and most of `platform/` are scaffolding: a `README.md`
describing intended scope with no implementation yet. Always check a
directory's own README for its actual status before building on it or
reporting on "existing" functionality that may not exist.

`temp/` is gitignored, migration-source scratch space (the original flat
repo layout this platform was restructured from) — not part of the platform.
Several `README.md` files reference it for migration context; don't treat it
as live source to build from.

## Naming conventions

- **Containers:** `qa-platform-<engine>-runner` (e.g.
  `qa-platform-robot-web-runner`, `qa-platform-k6-runner`,
  `qa-platform-security-runner`). Match this when adding a new runner module.
- **Terraform modules:** `infrastructure/modules/runner-<engine>/` — each has
  `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`. Follow this exact
  file split for new modules.
- **Pipelines:** `<gate>-pipeline.yml`, mirrored 1:1 between
  `pipelines/azure/` and `.github/workflows/` — see the table in
  `pipelines/README.md`. When adding a new CI gate, add both, using the same
  gate name, and reuse `templates/notify-on-failure.yml` /
  `.github/actions/notify-on-failure/` for failure notification rather than
  inventing a new mechanism.
- **Scripts:** `scripts/run_<engine>.sh`, each execs into that engine's
  container rather than requiring host-installed tooling. Header comments
  document usage/options — read before modifying.

## Adding a new testing engine

1. Create `testings/<domain>/` with its own `README.md` stating scope and
   status (scaffolded vs. implemented) — follow the existing domains' style.
2. If it needs its own runner container, add
   `infrastructure/modules/runner-<engine>/` plus a `Dockerfile.<engine>` (and
   `requirements-*.txt` if Python) under `infrastructure/docker/`, and wire it
   into `infrastructure/environments/local/main.tf`.
3. Add a `shared/` subfolder with a reporting adapter that maps the engine's
   native report format into `platform/reporting/schema`'s result envelope
   and calls `submit()` — this is how every engine feeds the common
   dashboards/release-readiness layer. `platform/reporting/` itself must
   never depend on a specific engine.
4. Add `scripts/run_<engine>.sh` following the existing scripts' pattern
   (docker exec into the container, not local execution).
5. Add mirrored pipeline YAML in both `pipelines/azure/` and
   `.github/workflows/` per the naming convention above.

## Known gotchas (don't re-debug these)

- **k6 container entrypoint:** `grafana/k6`'s image ships
  `ENTRYPOINT ["k6"]`. Don't try to clear it via Terraform's `entrypoint = []`
  — the docker provider appends `command` after the image entrypoint instead
  of replacing it, so `command = ["tail", "-f", "/dev/null"]` becomes
  `k6 tail -f /dev/null` and crash-loops. Fix is `entrypoint = ["tail"]` +
  `command = ["-f", "/dev/null"]` (already applied in `runner-k6/main.tf`).
- **k6 relative script paths:** the stock image's `WORKDIR` is `/home/k6`, not
  the repo mount point — `runner-k6` sets `working_dir = "/qa-platform"`
  explicitly so `k6 run scripts/<file>.js` resolves.
- **Security runner Docker-outside-of-Docker:** `testings/security/`'s
  keywords launch ZAP/Nmap as sibling containers via the host's Docker socket
  (mounted into `qa-platform-security-runner`). Any `-v` bind-mount source in
  those `docker run` calls must be a real **host** path, not a path relative
  to this container's own mount — use the `HOST_MOUNT_ROOT` env var
  (`infrastructure/modules/runner-security/main.tf`) rather than a
  container-local path.
- **Nikto vs. frapsoft/nikto:** the Docker Hub `frapsoft/nikto` image is a
  2017-era build that doesn't send SNI and breaks against SNI-routed targets
  (e.g. Fly.io edges). Nikto runs natively via Kali's own apt package instead
  — don't revert to the Docker image.
- **Security gate false negatives:** a scan container that fails to launch
  (docker exit 125) or leaves a stale report file must not be read as "no
  findings" — `Fail If Docker Launch Failed` and the per-scan `Remove File`
  before each run exist specifically to prevent that. Preserve both patterns
  if you touch `testings/security/resources/security.robot`.
- **`practice.expandtesting.com` / public demo targets:** these have
  request-volume/cadence-based anti-automation defenses (not tied to VU
  count, executor type, or any k6 flag). A single isolated `smoke` run passes
  reliably; back-to-back runs (including re-running the same script, or
  running it soon after a security scan against the same target) can fail
  with instant connection-refused. Not a regression — space runs out, or
  point `BASE_URL` at a target you control for real load/stress runs.
- **Robot web runner uses `Library Browser`, not SeleniumLibrary** —
  `robotframework-browser` (Playwright-based). If you see Selenium/webdriver
  patterns proposed for `testings/gui/robot/web/`, that's stale; the
  Dockerfile and requirements were migrated off Selenium already.
- **iOS is not scaffolded.** Xcode/Simulator needs macOS; the mobile runner
  module only covers Android (emulator + Appium via `budtmo/docker-android`).
  Needs `/dev/kvm` for acceleration — unreliable/slow on Apple Silicon hosts
  under Docker Desktop. Don't propose iOS automation without first flagging
  that it needs an external macOS runner.
- **Terraform state is local** (`infrastructure/environments/local/`) — no
  remote backend yet. Fine for single-developer use; flag it if asked about
  multi-person or CI-shared state.

## AI agents (`ai/`)

Specialist subagents exist for both Claude Code (`ai/.claude/agents/`,
`ai/.claude/skills/`) and Codex (`ai/.codex/agents/`) — kept in sync as pairs,
same names/scopes. Current specialists: `qe-lead` (planning/strategy,
coordinates the others), `automation-specialist`, `api-specialist`,
`contract-testing-specialist`, `performance-specialist`,
`security-specialist`, `pen-test-specialist` (authorized scanning only),
`compliance-specialist`, `SRE-specialist`, `chaos-engineering-specialist`,
`observability-specialist`, `ai-testing-specialist`,
`quality-engineer-specialist`, `daily_standup_specialist`. When adding a new
one, add both the Claude Code and Codex versions together.

## Working conventions

- Don't add code to `platform/utilities/` unless it's a genuinely
  domain-less helper (retry/wait, common assertions) — anything with a clear
  home (data, storage, notifications, reporting) belongs in its own module;
  see `platform/utilities/README.md`.
- `testings/api/rest/schemas/` (single API's own response-shape contract) and
  `testings/contract/pact/` (agreement between two specific services) are
  deliberately separate concerns — don't merge them.
- Results from every engine should ultimately feed
  `platform/reporting/schema`'s common result envelope, even for scaffolded
  domains being built out — check `platform/reporting/README.md` before
  designing a new engine's output format.
