# Accessibility Testing (WCAG 2.1 AA)

Automated and manual accessibility testing engine, validated against WCAG 2.1 Level AA.

Scope: axe-core / Playwright accessibility scans, keyboard-nav and screen-reader checks,
color-contrast validation, ARIA audits. Feeds results into the shared reporting schema
alongside the other testing engines.

## Reporting
Not yet scaffolded (engine has no subfolders yet). When built out, add a
shared/ folder with a reporting adapter mapping into
platform/reporting/schema/result-envelope.ts, same as the other engines.
