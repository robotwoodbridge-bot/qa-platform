# Pipelines

CI/CD definitions for both platforms this project has used, migrated from
temp/ci/ (Azure) and temp/.github/ (GitHub Actions). Both are kept because
the repo's history includes both, and mirroring them 1:1 makes it obvious
where a new gate needs to be added on each platform.

- azure/    — Azure Pipelines YAML. Location here is a style choice — Azure
  will run a pipeline YAML from anywhere in the repo once you point a
  Pipeline definition at it.
- ../.github/  — GitHub Actions workflows and composite actions. NOT under
  pipelines/ — GitHub only discovers workflows at the fixed repo-root path
  `.github/workflows/`, and composite actions referenced by local path
  (`uses: ./.github/actions/...`) have to live there too. This is a hard
  platform requirement, not a style inconsistency with the azure/ folder
  above.

## Naming convention

Both platforms mirror the same gate names 1:1 so the two are easy to keep
in sync:

| Gate        | Azure                                | GitHub Actions                          |
|-------------|---------------------------------------|------------------------------------------|
| Smoke (IaC) | azure/smoke-pipeline.yml              | .github/workflows/smoke-pipeline.yml     |
| API contract| azure/contract-pipeline.yml           | .github/workflows/contract-pipeline.yml  |
| Performance | azure/performance-pipeline.yml        | .github/workflows/performance-pipeline.yml |
| Load (k6)   | azure/load-pipeline.yml               | .github/workflows/load-pipeline.yml      |
| Security    | azure/security-pipeline.yml           | .github/workflows/security-pipeline.yml  |
| Notify      | azure/templates/notify-on-failure.yml | .github/actions/notify-on-failure/       |

## Migration notes (temp/ci + temp/.github → here)

All path references were rewritten from the old flat repo layout
(tests/, keywords/, pages/, data/, utils/, infra/terraform, requirements.txt)
to the current testings/ + infrastructure/ + scripts/ structure. Container
names updated qa-playwright-runner → qa-platform-robot-web-runner
throughout, matching the container-rename work done during infra migration.

One real rewrite, not just a path swap: **security-pipeline.yml**. The
original design ran Robot Framework natively on the CI agent and shelled
out `docker pull`/`docker run` per scan tool (ZAP, frapsoft/nikto, Nmap).
That design predates the security gate debugging work (see
testings/security/README.md) which found frapsoft/nikto's bundled Nikto
too old to support this target's SNI-based routing, and settled on running
Nikto natively via Kali's own apt package instead — inside the
qa-platform-security-runner container specifically, not a bare Ubuntu CI
agent (which has no `nikto` binary at all). Porting the old pipeline design
forward as-is would have shipped a security gate that fails immediately on
every run. Both pipelines now `terraform apply` the real infra and
`docker exec` into qa-platform-security-runner, the same pattern
smoke-pipeline.yml already used and the same flow that's been verified
working end-to-end against a live target.

## Future: Playwright + TypeScript pipelines

When the Playwright/TypeScript suites (testings/gui/playwright/) get their
own CI gate, follow the same naming convention — e.g.
azure/e2e-playwright-pipeline.yml and
.github/workflows/e2e-playwright-pipeline.yml — and reuse
templates/notify-on-failure.yml / actions/notify-on-failure the same way
the existing gates do, rather than inventing a new notification mechanism.
