*** Settings ***
Documentation    Disaster-recovery / resilience happy path for the observability
...              stack's log backend (Loki): simulate a dependency outage, verify
...              recovery lands inside the recovery-time objective (RTO), and verify
...              data ingested before the outage is still there afterward (RPO).
...
...              Robot Framework + Python only for now — Playwright/TypeScript
...              coverage for GUI-facing DR scenarios is a later pass (see
...              testings/dr/README.md).
Resource         ../resources/dr_keywords.robot

Suite Setup      Create Loki Session
Suite Teardown   Delete All Sessions

*** Test Cases ***
Loki Recovers From A Simulated Outage Within RTO And Retains Data
    [Documentation]    Happy path: outage -> recovery -> no data loss. Pushes a uniquely
    ...                labelled log line, confirms it's ingested, stops the Loki container
    ...                (simulated dependency outage), starts it again, waits for /ready to
    ...                come back within the RTO budget, then confirms the log line pushed
    ...                before the outage still queries back correctly (RPO) — proving the
    ...                persistent volume, not the container, is what actually held the data.
    [Tags]    dr    resilience    loki    happy-path

    ${marker}=    Generate Random String    8    [LETTERS][NUMBERS]
    ${message}=    Set Variable    dr-happy-path-${marker}

    Loki Should Be Ready
    Push Log Line    ${marker}    ${message}
    Wait Until Keyword Succeeds    10s    1s
    ...    Log Line Should Be Queryable    ${marker}    ${message}

    Stop Container    ${LOKI_CONTAINER}
    Start Container    ${LOKI_CONTAINER}
    Wait Until Loki Recovers

    Log Line Should Be Queryable    ${marker}    ${message}
