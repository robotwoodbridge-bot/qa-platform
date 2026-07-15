# Accessibility Testing (WCAG 2.1 AA)

Automated and manual accessibility testing engine, validated against WCAG 2.1 Level AA.

Scope: axe-core / Playwright accessibility scans, keyboard-nav and screen-reader checks,
color-contrast validation, ARIA audits. Feeds results into the shared reporting schema
alongside the other testing engines.

- resources/  — browser lifecycle (`common.robot`) and axe-core wiring
  (`accessibility_keywords.robot`)
- tests/      — accessibility suites

## Implemented: login page, happy path (Robot Framework + Python)

`tests/login_page_accessibility.robot` — loads the practice login page (the
same public target already covered by `testings/gui/robot/web`'s smoke and
performance suites), injects axe-core, and asserts there are no **critical**
violations. Serious/moderate/minor findings are logged for visibility, not
failed on.

The gate is critical-only rather than serious+critical because the real
page currently has 2 genuine "serious" findings — `avoid-inline-spacing`
and `color-contrast` (see `resources/accessibility_keywords.robot` for
details/links). A serious+critical gate would make this suite fail today,
which isn't a happy path; logging them instead keeps them visible without
blocking. Tightening the gate to include "serious" — after fixing those two
findings, or via an explicit suppression list for known-accepted ones — is
a follow-up, not done here.

Run via: `./scripts/run_accessibility.sh` (add `--headed` to watch it).

### Why this doesn't reuse testings/gui/robot/web/'s page objects

It's tempting to import `../../gui/robot/web/pages/login_page.robot`
directly, but that suite's container (`qa-platform-robot-web-runner`) only
mounts `testings/gui/robot/`, not `testings/accessibility/` alongside it —
so a relative-path `Resource` reference across the two wouldn't resolve at
runtime. Rather than widen that container's mount (which would touch two
already-working scripts and blur the "each engine is independently
testable/deployable" line the rest of `infrastructure/modules/` already
draws), this engine gets a small self-contained target URL + browser
lifecycle instead (~20 lines total) and its own container,
`qa-platform-accessibility-runner` — same underlying image logic
(`infrastructure/modules/runner-robot-web`, Browser library / Playwright)
as the GUI web runner, just mounted at `testings/accessibility/` instead.
A pure accessibility scan doesn't need the login page object's form-filling
keywords anyway — it only needs to load the page.

### axe-core

Not committed to the repo (~700KB minified) — pulled in as a Node
dependency (`package.json`) instead. `scripts/run_accessibility.sh` runs
`npm install` inside the container before each run (fast/no-op once
already installed). The Browser library's underlying image is
Node-based already (same reason `rfbrowser init` works), so no extra
tooling was needed to support this.

Not yet covered: keyboard-nav and screen-reader checks, color-contrast
validation beyond what axe-core's default ruleset already covers, and any
authenticated-state page (axe-core only sees what's rendered — scanning
the secure area after login is a natural next suite, not done here).

This is Robot Framework + Python only. Playwright/TypeScript coverage is a
deliberate later pass, not an oversight.

## Reporting
Not yet scaffolded beyond `shared/REPORTING_ADAPTER.md` (mirrors the other
engines) — the actual mapping into `platform/reporting/schema` isn't wired
up yet; `platform/reporting/` itself is still scaffolding too (see its
README).
