# Robot Framework (Python)

Second GUI automation stack, alongside Playwright/TypeScript:
- web/     — Browser library (robotframework-browser, Playwright-based), browser-based regression (e.g. legacy/cross-browser suites)
- mobile/  — AppiumLibrary, native iOS and Android app automation
- shared/  — common resource files (keywords, variables) reused across web/ios/android

Consistent with existing Robot Framework tooling (see dmf-test-generator).
Results should still feed the shared reporting schema alongside Playwright
and the other testing engines.
