*** Settings ***
Documentation    Shared keywords for disaster-recovery / resilience suites.
...              Wraps Docker container lifecycle control (via Process) and
...              Loki's HTTP API (via RequestsLibrary) so a test can express
...              "simulate an outage, then verify recovery" as plain keywords.
Library    RequestsLibrary
Library    Process
Library    String
Library    Collections

*** Variables ***
${LOKI_BASE_URL}         http://localhost:3100
${LOKI_CONTAINER}        qa-platform-loki
${RTO_BUDGET}            60s
${RTO_POLL_INTERVAL}     2s

*** Keywords ***
Create Loki Session
    [Documentation]    Creates a persistent requests session for Loki's HTTP API.
    ...                No auth — this stack's loki-config.yaml has auth_enabled: false.
    Create Session    loki    ${LOKI_BASE_URL}

Loki Should Be Ready
    [Documentation]    Fails unless Loki's /ready endpoint returns 200. Used both as a
    ...                one-shot baseline check and, wrapped in Wait Until Keyword
    ...                Succeeds, as the recovery-time-objective gate after an outage.
    ${response}=    GET On Session    loki    /ready    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
    ...    msg=Loki not ready (status ${response.status_code})

Wait Until Loki Recovers
    [Documentation]    Polls /ready until it succeeds or the RTO budget runs out — the
    ...                RTO is enforced by this timeout itself, not a separate assertion.
    Wait Until Keyword Succeeds    ${RTO_BUDGET}    ${RTO_POLL_INTERVAL}    Loki Should Be Ready

Push Log Line
    [Documentation]    Ingests one uniquely-labelled log line. Used as the RPO marker:
    ...                pushed before the simulated outage, queried back after recovery.
    [Arguments]    ${marker}    ${message}
    ${timestamp_ns}=    Evaluate    str(int(__import__('time').time() * 1_000_000_000))
    ${stream}=    Create Dictionary    dr_test=${marker}    job=qa-platform-dr-test
    ${entry}=    Create List    ${timestamp_ns}    ${message}
    ${values}=    Create List    ${entry}
    ${payload_stream}=    Create Dictionary    stream=${stream}    values=${values}
    ${streams}=    Create List    ${payload_stream}
    ${body}=    Create Dictionary    streams=${streams}
    ${response}=    POST On Session    loki    /loki/api/v1/push    json=${body}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    204
    ...    msg=Loki push failed (status ${response.status_code}): ${response.text}

Log Line Should Be Queryable
    [Documentation]    Queries Loki for the given marker and asserts the expected message
    ...                comes back. Used both to confirm ingestion before the outage and,
    ...                after recovery, as the RPO check — proving the data survived the
    ...                restart because /loki is a persistent named volume
    ...                (infrastructure/modules/observability), not container-local storage.
    [Arguments]    ${marker}    ${expected_message}
    ${params}=      Create Dictionary    query={dr_test="${marker}"}
    ${response}=    GET On Session    loki    /loki/api/v1/query    params=${params}    expected_status=any
    Should Be Equal As Integers    ${response.status_code}    200
    ...    msg=Loki query failed (status ${response.status_code}): ${response.text}
    ${result}=      Set Variable    ${response.json()}[data][result]
    Should Not Be Empty    ${result}    msg=No streams found for marker ${marker}
    ${values}=      Set Variable    ${result}[0][values]
    Should Not Be Empty    ${values}    msg=Stream for ${marker} has no log lines
    ${logged_message}=    Set Variable    ${values}[0][1]
    Should Be Equal As Strings    ${logged_message}    ${expected_message}

Stop Container
    [Documentation]    Simulates a dependency outage by stopping the given container.
    [Arguments]    ${container_name}
    ${result}=    Run Process    docker    stop    ${container_name}
    Should Be Equal As Integers    ${result.rc}    0
    ...    msg=docker stop ${container_name} failed: ${result.stderr}

Start Container
    [Documentation]    Recovers the given container after a simulated outage.
    [Arguments]    ${container_name}
    ${result}=    Run Process    docker    start    ${container_name}
    Should Be Equal As Integers    ${result.rc}    0
    ...    msg=docker start ${container_name} failed: ${result.stderr}
