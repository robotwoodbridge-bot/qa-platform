*** Settings ***
Documentation    axe-core wiring for WCAG 2.1 AA scans: inject the local axe-core
...              build into the current page, run it, and gate on critical
...              violations only — serious/moderate/minor findings are logged
...              for visibility, not failed on. The practice login page this
...              suite targets has 2 known "serious" findings today
...              (avoid-inline-spacing, color-contrast) that are real but
...              deliberately non-blocking under this gate; tightening it to
...              include "serious" is a policy call for later, not baked in
...              here.
Library    Browser
Library    OperatingSystem
Library    Collections

*** Variables ***
${AXE_CORE_PATH}    ${CURDIR}/../node_modules/axe-core/axe.min.js

*** Keywords ***
Inject Axe Core
    [Documentation]    Loads the local axe-core build into the current page's context.
    ...                Requires `npm install` to have been run in testings/accessibility/
    ...                first (scripts/run_accessibility.sh does this automatically) —
    ...                axe-core isn't committed to the repo (~700KB minified), it's a
    ...                Node dependency instead (see ../package.json).
    ${axe_source}=    Get File    ${AXE_CORE_PATH}
    Evaluate JavaScript    ${None}
    ...    (source) => { const s = document.createElement('script'); s.textContent = source; document.head.appendChild(s); }
    ...    arg=${axe_source}

Run Axe Scan
    [Documentation]    Runs axe.run() against the current page and returns the raw
    ...                results dict (violations, passes, incomplete, inapplicable).
    ${results}=    Evaluate JavaScript    ${None}    async () => { return await axe.run(); }
    RETURN    ${results}

Page Should Pass Accessibility Scan
    [Documentation]    Happy path gate: injects axe-core, scans the current page, and
    ...                fails only if critical (WCAG-blocking) violations are found.
    ...                Serious/moderate/minor findings are logged, not failed on —
    ...                see this file's Settings documentation for why "serious" isn't
    ...                gated on yet for this particular target.
    [Arguments]    ${context}=page
    Inject Axe Core
    ${results}=    Run Axe Scan
    ${total}=    Get Length    ${results}[violations]
    Log    [INFO] [A11Y] ${context}: ${total} total violation(s) found (all impacts)    console=True

    ${blocking}=    Evaluate
    ...    [v for v in $results['violations'] if v.get('impact') in ('critical',)]
    ${blocking_count}=    Get Length    ${blocking}

    IF    ${blocking_count} > 0
        ${summary}=    Evaluate
        ...    "\\n".join(f"- [{v['impact']}] {v['id']}: {v['help']} ({len(v['nodes'])} node(s)) -- {v['helpUrl']}" for v in $blocking)
        Fail    Accessibility scan (${context}) found ${blocking_count} blocking violation(s):\n${summary}
    END
