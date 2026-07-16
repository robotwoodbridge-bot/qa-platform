# QA Platform

An enterprise Quality Engineering (QE) platform — a monorepo of shared, reusable
testing infrastructure and services, not a single test framework. It exists to
give every testing engine (GUI, API, contract, performance, security,
accessibility, DR, ...) a common home: shared platform services, Infrastructure
as Code, CI/CD, dashboards, and an AI layer, instead of each discipline
reinventing its own scaffolding.

## Status

Active build-out. Some pieces are real and working end-to-end; most of the
platform is scaffolding (a `README.md` describing intended scope, no code yet).
Where something is scaffolded rather than implemented, its own `README.md`
says so explicitly — check there before assuming a folder is empty by mistake.

Working today:
- **Local infra via Terraform** (`infrastructure/`) — Docker-based runners for
  Playwright, Robot Framework (web + mobile + API), k6, security (Kali/ZAP),
  a Pact Broker, and an observability stack (Loki + Grafana).
- **Security scanning** — ZAP baseline + Nikto + Nmap orchestrated via Robot
  Framework (`testings/security/`), plus hand-crafted exploit-attempt
  regression tests (SQLi-style bypass, reflected XSS) against the login form
  (`testings/security/pentest/`).
- **Load testing** — a k6 login load test with smoke/load/stress profiles
  (`testings/performance/k6/`).
- **API testing** — a Robot Framework + RequestsLibrary suite validating a
  practice API against JSON Schema (`testings/api/rest/`).
- **Contract testing** — a pact-python consumer suite covering the same
  login + create-order happy path as the API suite above, publishable to
  the Pact Broker (`testings/contract/pact/consumer/`). Provider-side
  verification isn't scaffolded — see that domain's README for why.
- **Disaster recovery** — a Robot Framework suite that simulates a Loki
  outage, verifies recovery within an RTO budget, and confirms no data loss
  (RPO) (`testings/dr/`). Robot Framework + Python only for now; Playwright/
  TypeScript coverage is a deliberate later pass.
- **Accessibility (WCAG 2.1 AA)** — a Robot Framework + axe-core suite
  scanning the practice login page, gated on critical violations
  (`testings/accessibility/`). Robot Framework + Python only for now;
  Playwright/TypeScript coverage is a deliberate later pass.
- **CI/CD** — mirrored Azure Pipelines and GitHub Actions definitions for the
  gates above (`pipelines/azure/`, `.github/workflows/`).
- **AI layer** — a set of specialist subagents (QE lead, API, automation,
  performance, security, pen-test, compliance, SRE, chaos, contract, AI
  testing, observability) plus matching skills, defined for both Claude Code
  and Codex (`ai/`).

Scaffolded (README only, no implementation yet): GUI automation with
Playwright/TypeScript, contract testing's provider side (Pact), most of
`platform/` (orchestration, reporting, test-data, utilities), and all of
`compliance/`.

## Repository layout

```
qa-platform/
├── testings/            # Testing engines, one subfolder per domain
│   ├── gui/             #   Playwright/TS (primary) + Robot Framework (secondary/legacy + native mobile)
│   ├── api/              #   rest/graphql/grpc/websocket/soap, plus a cross-protocol shared/ layer
│   ├── contract/pact/    #   consumer-driven contract testing
│   ├── performance/k6/   #   load/stress/spike/soak
│   ├── security/, security/zap/  # ZAP/Nikto/Nmap scans
│   ├── accessibility/    #   WCAG 2.1 AA
│   └── dr/               #   disaster recovery / resilience
├── platform/             # Shared services consumed by every testing engine
│   ├── reporting/        #   common result envelope + ingest/aggregate
│   ├── orchestration/    #   shared run IDs, tagging, cross-engine traceability
│   ├── observability/    #   telemetry/monitoring/alerting
│   ├── test-data/        #   test data generation & lifecycle
│   └── utilities/        #   small shared helpers only
├── infrastructure/       # Terraform, one module per runner/service
│   ├── environments/local/   # root composition wiring modules together
│   └── modules/          #   network, observability, pact-broker, runner-*
├── pipelines/azure/      # Azure Pipelines YAML (mirrors .github/workflows/ 1:1)
├── .github/              # GitHub Actions workflows + composite actions
├── ai/                   # Claude Code + Codex agents, skills
├── standards/            # Tech-stack decisions
├── compliance/           # Regulatory/governance scope (placeholder)
├── architecture/         # (reserved, empty)
├── dashboards/           # (reserved, empty)
├── shared/               # (reserved, empty)
├── tools/                # (reserved, empty)
├── scripts/              # ./run_*.sh entry points, one per engine
└── temp/                 # Tracked scratch space — NOT platform architecture; see below
```

`temp/` is tracked in git (kept in sync across machines/team, not gitignored)
but isn't part of the platform's structure — don't assume something living
there is platform code just because it's in this repo. It can hold anything
from migration leftovers to unrelated personal projects (currently
`temp/TypeScript/`, a personal TypeScript practice repo with no relation to
this platform). Check a subfolder's own contents/README before building on
anything found there.

## Prerequisites

- Docker
- Terraform
- `gh` / Azure CLI only if you're wiring up pipeline runs manually

## Getting started

Bring up the local stack (network, observability, and all runner containers):

```bash
cd infrastructure/environments/local
terraform init
terraform apply
```

Then run a testing engine via its script in `scripts/` (all of them exec into
the relevant container — nothing needs to be installed on the host):

```bash
./scripts/run_security.sh                          # ZAP + Nikto + Nmap
./scripts/run_k6.sh smoke                           # k6 load test, smoke profile
./scripts/run_robot_api.sh rest                     # API suite (RequestsLibrary)
./scripts/run_robot_web.sh smoke                    # web GUI suite (Browser library)
./scripts/run_robot_parallel.sh smoke 4             # web GUI suites in parallel (pabot)
```

Each script's header comment documents its own options and env var overrides
in more detail — read it before running.

## Tech stack

See [standards/tech-stack.md](standards/tech-stack.md) for the authoritative,
up-to-date list. Summary:

- **GUI (primary):** TypeScript + Playwright
- **GUI (secondary/legacy) + native mobile:** Python + Robot Framework
  (`robotframework-browser` for web, `AppiumLibrary` for iOS/Android)
- **API protocol tooling:** TBD per-protocol (base stack is TypeScript)
- **Infrastructure:** Terraform, Docker

## Testing domains

GUI, API (REST/GraphQL/gRPC/WebSocket/SOAP), Contract, Performance/Load,
Security/Pen Tests, Accessibility, Disaster Recovery, Integration, Smoke,
Regression, End-to-End.

## AI layer

`ai/` defines specialist subagents (QE lead, automation, API, performance,
security, pen-test, compliance, SRE, chaos engineering, contract testing, AI
testing, observability, daily standup) for both Claude Code
(`ai/.claude/agents/`, `ai/.claude/skills/`) and Codex
(`ai/.codex/agents/`). Use the QE lead agent for planning-level strategy and
release-confidence reviews; use a specialist agent when the work is scoped to
its domain.

## Contributing

Read the relevant domain's `README.md` before adding to it — most describe
scope boundaries deliberately (e.g. what belongs in `platform/utilities/` vs.
its own domain module) so functionality doesn't end up duplicated across
folders. See also [CLAUDE.md](CLAUDE.md) for repo-specific conventions and
known gotchas when working in this codebase with an AI coding agent.
