*** Settings ***
Documentation    Accessibility happy path (WCAG 2.1 AA via axe-core) for the practice
...              login page — the same public demo target already covered by
...              testings/gui/robot/web's smoke and performance suites.
...
...              Robot Framework + Python only for now — Playwright/TypeScript
...              coverage is a deliberate later pass (see ../README.md).
Resource         ../resources/common.robot
Resource         ../resources/accessibility_keywords.robot

Suite Setup       Start Suite
Suite Teardown    End Suite

*** Test Cases ***
Login Page Has No Blocking Accessibility Violations
    [Documentation]    Happy path: the login page, in its default unauthenticated
    ...                state, has no critical WCAG 2.1 AA violations per axe-core.
    ...                It does have 2 known "serious" findings today
    ...                (avoid-inline-spacing, color-contrast) — logged, not gated
    ...                on; see ../resources/accessibility_keywords.robot.
    [Tags]    accessibility    wcag2aa    login    happy-path
    New Page    ${TARGET_URL}
    Wait For Load State    load
    Page Should Pass Accessibility Scan    context=Login Page
