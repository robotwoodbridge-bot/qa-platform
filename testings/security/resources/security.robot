*** Settings ***
Documentation    Security scan keywords — wraps OWASP ZAP and Nmap via Docker
...              (ephemeral docker run containers, needs Docker Desktop running
...              on the host), and Nikto natively via Kali's own apt package
...              (see Dockerfile.security for why Nikto is the odd one out).
...              All scans write structured output to results/security/.
Library          OperatingSystem
Library          Process
Library          String
Library          Collections

*** Variables ***
${SECURITY_OUTPUT_DIR}    results/security
${ZAP_IMAGE}              ghcr.io/zaproxy/zaproxy:stable
${NMAP_IMAGE}             instrumentisto/nmap

# ---------------------------------------------------------------------------
# Phase 2 baseline thresholds — map ZAP risk codes to comparable severities.
# Phase 3: tighten fail_on_severity in settings.yaml to HIGH after clean run.
# ---------------------------------------------------------------------------
${SEVERITY_FAIL_THRESHOLD}    MEDIUM

*** Keywords ***

# =============================================================================
# Orchestration
# =============================================================================

Run Full Security Scan
    [Documentation]    Run ZAP baseline, Nikto, and Nmap scans sequentially.
    ...                Fails the suite if any scan finds issues at or above the
    ...                configured severity threshold.
    [Arguments]    ${target_url}    ${fail_on_severity}=${SEVERITY_FAIL_THRESHOLD}
    Prepare Security Output Dir
    ${zap_findings}=      Run ZAP Baseline Scan    ${target_url}
    ${nikto_findings}=    Run Nikto Scan           ${target_url}
    ${nmap_findings}=     Run Nmap Scan            ${target_url}
    Assert No Critical Findings    ${zap_findings}    ZAP        ${fail_on_severity}
    Assert No Critical Findings    ${nikto_findings}  Nikto      ${fail_on_severity}
    Assert No Critical Findings    ${nmap_findings}   Nmap       ${fail_on_severity}

# =============================================================================
# OWASP ZAP — passive baseline scan
# =============================================================================

Run ZAP Baseline Scan
    [Documentation]    Run the OWASP ZAP baseline (passive) scan against the target.
    ...                Writes zap-report.json to the security output directory.
    ...                Phase 4: change scan type to "full" in settings.yaml for active scanning.
    [Arguments]    ${target_url}
    Log Step    Starting ZAP baseline scan → ${target_url}
    Remove File    ${SECURITY_OUTPUT_DIR}/zap-report.json
    ${result}=    Run Process
    ...    docker    run    --rm
    ...    --user    root
    ...    -v    %{HOST_MOUNT_ROOT}/${SECURITY_OUTPUT_DIR}:/zap/wrk:rw
    ...    ${ZAP_IMAGE}
    ...    zap-baseline.py
    ...    -t    ${target_url}
    ...    -J    zap-report.json
    ...    -I
    ...    timeout=600
    ...    stdout=${SECURITY_OUTPUT_DIR}/zap-stdout.txt
    ...    stderr=${SECURITY_OUTPUT_DIR}/zap-stderr.txt
    Log    ZAP exit code: ${result.rc}    level=INFO    console=True
    Fail If Docker Launch Failed    ${result}    ZAP    ${SECURITY_OUTPUT_DIR}/zap-stderr.txt
    ${findings}=    Parse ZAP Report    ${SECURITY_OUTPUT_DIR}/zap-report.json
    RETURN    ${findings}

Parse ZAP Report
    [Arguments]    ${report_path}
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${report_path}
    IF    not ${exists}
        Log    [WARN] [SECURITY] ZAP report not found at ${report_path}    level=WARN    console=True
        ${empty}=    Create List
        RETURN    ${empty}
    END
    ${raw}=    Get File    ${report_path}
    ${data}=   Evaluate    json.loads($raw)    json
    ${findings}=    Create List
    FOR    ${site}    IN    @{data.get('site', [])}
        FOR    ${alert}    IN    @{site.get('alerts', [])}
            ${severity}=    Map ZAP Risk To Severity    ${alert.get('riskcode', '0')}
            ${entry}=    Create Dictionary
            ...    tool=ZAP
            ...    severity=${severity}
            ...    name=${alert.get('name', 'Unknown')}
            ...    description=${alert.get('desc', '')}
            Append To List    ${findings}    ${entry}
        END
    END
    Log Step    ZAP found ${findings.__len__()} alerts
    RETURN    ${findings}

Map ZAP Risk To Severity
    [Arguments]    ${riskcode}
    ${code}=    Convert To String    ${riskcode}
    IF    '${code}' == '3'    RETURN    CRITICAL
    IF    '${code}' == '2'    RETURN    HIGH
    IF    '${code}' == '1'    RETURN    MEDIUM
    RETURN    LOW

# =============================================================================
# Nikto — web server misconfiguration scan
# =============================================================================

Run Nikto Scan
    [Documentation]    Run Nikto NATIVELY (Kali's own apt package — see
    ...                Dockerfile.security) instead of via `docker run` like
    ...                ZAP/Nmap. frapsoft/nikto's Docker Hub image bundles a
    ...                2017-era Nikto (v2.1.5) whose old SSL handling doesn't
    ...                send SNI, which breaks against this target's Fly.io edge
    ...                (routes by SNI) — every attempt failed with "No web
    ...                server found" regardless of flags. Kali's package is
    ...                current and doesn't have this problem, and running
    ...                natively also sidesteps Docker-outside-of-Docker for
    ...                this one tool entirely (no HOST_MOUNT_ROOT needed here —
    ...                this runs in the same filesystem as the RF process).
    [Arguments]    ${target_url}
    ${host}=    Extract Host From URL    ${target_url}
    Log Step    Starting Nikto scan → ${host}
    Remove File    ${SECURITY_OUTPUT_DIR}/nikto-report.csv
    ${result}=    Run Process
    ...    nikto
    ...    -h    ${host}
    ...    -ssl
    ...    -port    443
    ...    -Format    csv
    ...    -output    ${SECURITY_OUTPUT_DIR}/nikto-report
    ...    -Tuning    1234567890ab
    ...    -Pause    1
    ...    -nointeractive
    ...    timeout=300
    ...    stdout=${SECURITY_OUTPUT_DIR}/nikto-stdout.txt
    ...    stderr=${SECURITY_OUTPUT_DIR}/nikto-stderr.txt
    Log    Nikto exit code: ${result.rc}    level=INFO    console=True
    ${findings}=    Parse Nikto Report    ${SECURITY_OUTPUT_DIR}/nikto-report.csv
    RETURN    ${findings}

Map Nikto Finding To Severity
    [Documentation]    Pragmatic keyword-based heuristic — Nikto's CSV doesn't
    ...                carry a real severity field like ZAP's riskcode does, so
    ...                this infers one from the id column (often a CWE reference)
    ...                and the description text. Not exhaustive; revisit if it
    ...                misclassifies something that matters.
    ...                - credential/CWE-tagged findings (e.g. default admin/admin
    ...                  account) -> HIGH
    ...                - informational lines Nikto emits via the same row format
    ...                  (SSL cert dump, robots.txt entry count) -> LOW, so they
    ...                  stay visible but don't trip a MEDIUM-threshold gate
    ...                - everything else (cookie flags, CORS, headers, etc.) -> MEDIUM
    [Arguments]    ${id}    ${description}
    ${is_credential}=    Evaluate
    ...    'cwe-' in $id.lower() or 'default account' in $description.lower() or 'password' in $description.lower()
    IF    ${is_credential}
        RETURN    HIGH
    END
    ${is_info}=    Evaluate
    ...    'ssl certificate' in $description.lower() or 'ssl ciphers' in $description.lower() or 'robots.txt' in $description.lower() or 'robots.txt' in $id.lower()
    IF    ${is_info}
        RETURN    LOW
    END
    RETURN    MEDIUM

Parse Nikto Report
    [Documentation]    Doesn't assume a fixed column count/order — old Nikto CSV
    ...                layouts vary by version. Takes the last column of each row
    ...                as the description, which has been consistent across
    ...                versions, and skips anything too short to be a real row.
    ...                Column 4 (0-indexed 3) is usually a CWE ID / reference URL
    ...                / plugin ID when present — used for the severity heuristic
    ...                below, but treated as optional since the column layout
    ...                isn't guaranteed.
    [Arguments]    ${report_path}
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${report_path}
    IF    not ${exists}
        Log    [WARN] [SECURITY] Nikto report not found at ${report_path}    level=WARN    console=True
        ${empty}=    Create List
        RETURN    ${empty}
    END
    ${raw}=    Get File    ${report_path}
    ${rows}=    Evaluate    list(csv.reader($raw.splitlines()))    csv
    ${findings}=    Create List
    FOR    ${row}    IN    @{rows}
        ${col_count}=    Get Length    ${row}
        IF    ${col_count} < 2
            CONTINUE
        END
        ${description}=    Set Variable    ${row}[-1]
        # Nikto's own target-summary row has real leading columns but blank
        # trailing ones ("host","ip","port","","","",""") — not a finding.
        # Uses the $description (non-interpolated) form, not '${description}'
        # string-literal substitution — a description containing a quote
        # character (e.g. "Let's Encrypt") breaks the naive form with a
        # Python SyntaxError.
        IF    $description == ''
            CONTINUE
        END
        ${id}=    Set Variable If    ${col_count} >= 4    ${row}[3]    ${EMPTY}
        ${severity}=    Map Nikto Finding To Severity    ${id}    ${description}
        ${entry}=    Create Dictionary
        ...    tool=Nikto
        ...    severity=${severity}
        ...    name=${description[:60]}
        ...    description=${description}
        Append To List    ${findings}    ${entry}
    END
    Log Step    Nikto found ${findings.__len__()} items
    RETURN    ${findings}

# =============================================================================
# Nmap — port and service recon
# =============================================================================

Run Nmap Scan
    [Documentation]    Run Nmap version scan (-sT -sV --open) against the top 100
    ...                ports, writing nmap-report.xml to the security output
    ...                directory.
    ...                -Pn skips ICMP-based host discovery and treats the host as
    ...                online — without it, targets behind a CDN/WAF that block
    ...                ping (common) make nmap conclude the host is down and exit
    ...                immediately without scanning anything.
    ...                -T4 (faster timing) + --top-ports 100 (not the full 1000)
    ...                keep this fast enough for a routine gate — -sV against the
    ...                full port range at default timing was still running past a
    ...                5 minute timeout. A slower, more exhaustive scan can be a
    ...                separate "full" mode later, same as ZAP's baseline vs full.
    [Arguments]    ${target_url}
    ${host}=    Extract Host From URL    ${target_url}
    Log Step    Starting Nmap scan → ${host}
    Remove File    ${SECURITY_OUTPUT_DIR}/nmap-report.xml
    ${result}=    Run Process
    ...    docker    run    --rm
    ...    --user    root
    ...    -v    %{HOST_MOUNT_ROOT}/${SECURITY_OUTPUT_DIR}:/tmp/nmap:rw
    ...    ${NMAP_IMAGE}
    ...    -Pn    -T4    -sT    -sV    --top-ports    100    --open
    ...    -oX    /tmp/nmap/nmap-report.xml
    ...    ${host}
    ...    timeout=600
    ...    stdout=${SECURITY_OUTPUT_DIR}/nmap-stdout.txt
    ...    stderr=${SECURITY_OUTPUT_DIR}/nmap-stderr.txt
    Log    Nmap exit code: ${result.rc}    level=INFO    console=True
    Fail If Docker Launch Failed    ${result}    Nmap    ${SECURITY_OUTPUT_DIR}/nmap-stderr.txt
    ${findings}=    Parse Nmap Report    ${SECURITY_OUTPUT_DIR}/nmap-report.xml
    RETURN    ${findings}

Parse Nmap Report
    [Arguments]    ${report_path}
    ${exists}=    Run Keyword And Return Status    File Should Exist    ${report_path}
    IF    not ${exists}
        Log    [WARN] [SECURITY] Nmap report not found at ${report_path}    level=WARN    console=True
        ${empty}=    Create List
        RETURN    ${empty}
    END
    ${raw}=    Get File    ${report_path}
    ${findings}=    Create List
    ${ports}=    Get Regexp Matches    ${raw}    portid="(\\d+)".*?state="open"    1
    FOR    ${port}    IN    @{ports}
        ${entry}=    Create Dictionary
        ...    tool=Nmap
        ...    severity=LOW
        ...    name=Open port ${port}
        ...    description=Port ${port} is open and accepting connections
        Append To List    ${findings}    ${entry}
    END
    Log Step    Nmap found ${findings.__len__()} open ports
    RETURN    ${findings}

# =============================================================================
# Assertion helpers
# =============================================================================

Assert No Critical Findings
    [Documentation]    Fail if any finding meets or exceeds the severity threshold.
    [Arguments]    ${findings}    ${tool}    ${threshold}=${SEVERITY_FAIL_THRESHOLD}
    ${order}=    Create List    LOW    MEDIUM    HIGH    CRITICAL
    ${threshold_idx}=    Get Index From List    ${order}    ${threshold}
    FOR    ${finding}    IN    @{findings}
        ${sev}=    Set Variable    ${finding['severity']}
        ${sev_idx}=    Get Index From List    ${order}    ${sev}
        IF    ${sev_idx} >= ${threshold_idx}
            Fail    [${tool}] ${sev} finding: ${finding['name']} — ${finding['description']}
        END
    END

# =============================================================================
# Utilities
# =============================================================================

Prepare Security Output Dir
    Create Directory    ${SECURITY_OUTPUT_DIR}

Fail If Docker Launch Failed
    [Documentation]    Exit code 125 is Docker's own reserved code for "the docker
    ...                command itself failed to start the container" — distinct from
    ...                the scanned tool's own exit status (e.g. zap-baseline.py legitimately
    ...                exits non-zero when it finds issues). Without this check, a launch
    ...                failure falls through to Parse Report finding no file, returning an
    ...                empty findings list — which reads as a clean scan, not a scan that
    ...                never ran. That's a false-positive pass on a security gate.
    [Arguments]    ${result}    ${tool}    ${stderr_path}
    IF    ${result.rc} == 125
        Fail    [${tool}] docker failed to launch the scan container (exit 125) — see ${stderr_path}
    END

Extract Host From URL
    [Arguments]    ${url}
    ${host}=    Evaluate    re.sub(r'^https?://', '', '${url}').split('/')[0]    re
    RETURN    ${host}

Log Step
    [Arguments]    ${message}
    Log    [INFO] [SECURITY] ${message}    level=INFO    console=True
