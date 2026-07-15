*** Settings ***
Documentation    Browser lifecycle for accessibility suites (Browser library /
...              Playwright — same stack as testings/gui/robot/web, kept in a
...              separate container/mount here so this engine stays
...              independently testable/deployable; see ../README.md).
Library    Browser

*** Variables ***
${TARGET_URL}          https://practice.expandtesting.com/login
${BROWSER_TYPE}        Chromium
${HEADLESS_MODE}       True
${BROWSER_TIMEOUT}     30s

*** Keywords ***
Start Suite
    New Browser    ${BROWSER_TYPE}    headless=${HEADLESS_MODE}
    Set Browser Timeout    ${BROWSER_TIMEOUT}

End Suite
    Close Browser
