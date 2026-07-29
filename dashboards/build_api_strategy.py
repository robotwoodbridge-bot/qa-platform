#!/usr/bin/env python3
"""
API vs Serverless Test Strategy — one-page slide in the dashboard-deck style.
Reuses the shared design system (CSS, page template, helpers) from build_dashboards.
"""
import os
import importlib.util

HERE = os.path.dirname(__file__)
spec = importlib.util.spec_from_file_location("bd", os.path.join(HERE, "build_dashboards.py"))
bd = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bd)
C, page, hbar, legend = bd.C, bd.page, bd.hbar, bd.legend


def pills(items):
    return '<div style="display:flex;flex-wrap:wrap;gap:5px;margin-top:7px">' + "".join(
        f'<span class="badge b-grey" style="font-weight:600;font-size:9px">{t}</span>' for t in items
    ) + '</div>'


def coltitle(text, color):
    return (f'<div style="border-left:4px solid {color};padding-left:9px;margin-bottom:8px">'
            f'<div style="font-size:13px;font-weight:800;color:{C["ink"]}">{text}</div></div>')


def api_strategy_slide():
    meta = '<b>Layer:</b> Service / API tier<br><b>Applies to:</b> REST · GraphQL · event-driven<br>'
    status = ('<div class="statuspill"><span class="dot" style="background:' + C["brand2"]
              + '"></span>STRATEGY</div>')

    api_types = [
        "Functional / happy-path — endpoints return correct data",
        "Schema &amp; contract — OpenAPI / Pact, no breaking changes",
        "Negative &amp; boundary — bad input &rarr; correct 4xx",
        "Auth &amp; authz — token, scope, <b>tenant isolation</b>",
        "Idempotency, pagination, filtering",
        "Performance — latency, throughput, rate limits",
        "Security — OWASP API Top 10 (BOLA, mass assignment)",
    ]
    api_tools = ["Robot Framework · RequestsLibrary", "Postman / Newman", "REST Assured",
                 "Pact", "Schemathesis", "k6", "OWASP ZAP"]

    sl_types = [
        "Trigger / event-shape — HTTP, queue, storage, timer, stream",
        "Handler unit — mock event object + mocked cloud SDK",
        "Local integration — emulate the cloud services",
        "<b>Idempotency &amp; retries</b> — DLQ + partial-batch failures",
        "Cold-start &amp; concurrency — perf under scale-from-zero",
        "IAM least-privilege — function permissions are correctness",
        "Eventual consistency — async assertions on side effects",
    ]
    sl_tools = ["LocalStack", "AWS SAM CLI", "Serverless Framework", "moto",
                "Azurite", "EventBridge schema registry", "AWS Powertools"]

    # coverage matrix rows: concern, api, serverless-adds
    matrix = [
        ("Correctness", "status · schema · data", "+ event shape per trigger"),
        ("Reliability", "retries · timeouts", "+ idempotency · DLQ · partial batch"),
        ("Auth &amp; access", "token · scope · tenant", "+ IAM least-privilege"),
        ("Performance", "latency · throughput · limits", "+ cold start · concurrency caps"),
        ("State", "DB side-effects", "+ eventual consistency · ephemeral"),
        ("Security", "OWASP API Top 10", "+ function perms · secrets · cost guardrails"),
        ("Where it runs", "shared live test env", "+ local emulation &rarr; ephemeral cloud stack"),
    ]
    mrows = "".join(
        f'<tr><td><b style="color:{C["ink"]}">{c}</b></td>'
        f'<td><span class="badge b-blue" style="font-weight:600">{a}</span></td>'
        f'<td><span class="badge b-grey" style="font-weight:600;background:#d9f2ee;color:{C["teal"]}">{s}</span></td></tr>'
        for c, a, s in matrix)

    # test layers (pyramid, broad base -> narrow tip)
    layers = [
        ("Unit — handler logic", 95, C["green2"], "fast · mocked"),
        ("Component / contract", 80, C["brand2"], "Pact · schema"),
        ("Integration — emulated cloud", 60, C["teal"], "LocalStack · SAM"),
        ("End-to-end — ephemeral stack", 35, C["purple"], "real triggers"),
        ("Non-functional — perf / sec / chaos", 22, C["amber2"], "k6 · ZAP"),
    ]
    layer_html = ""
    for name, w, col, tag in layers:
        layer_html += (
            f'<div style="margin:6px 0">'
            f'<div style="display:flex;justify-content:space-between;font-size:10.5px;font-weight:700;color:{C["slate"]};margin-bottom:3px">'
            f'<span>{name}</span><span style="color:{C["faint"]};font-weight:600;font-size:9.5px">{tag}</span></div>'
            f'<div class="hbar-track" style="height:11px"><div class="hbar-fill" style="width:{w}%;background:{col}"></div></div></div>')

    body = f'''
    <div class="row" style="flex:0">
      <div class="card" style="flex:1;border-top:3px solid {C['brand']}">
        {coltitle("API Testing &mdash; verify the interface contract", C['brand'])}
        <div class="note" style="margin:-2px 0 6px"><b>Under test:</b> an always-on service endpoint (REST / GraphQL / gRPC).</div>
        <ul class="clean" style="margin-top:-2px">{"".join(f'<li>{x}</li>' for x in api_types)}</ul>
        {pills(api_tools)}
      </div>
      <div class="card" style="flex:1;border-top:3px solid {C['teal']}">
        {coltitle("Serverless Testing &mdash; everything above, plus the runtime", C['teal'])}
        <div class="note" style="margin:-2px 0 6px"><b>Under test:</b> event-driven functions + managed services (Lambda / Azure Functions).</div>
        <ul class="clean" style="margin-top:-2px">{"".join(f'<li class="win">{x}</li>' for x in sl_types)}</ul>
        {pills(sl_tools)}
      </div>
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1.5"><h3>Coverage Matrix &mdash; same concern, what each layer adds
        <span class="tag">blue = API testing &nbsp;·&nbsp; teal = serverless adds</span></h3>
        <table><thead><tr><th style="width:18%">Quality concern</th><th style="width:34%">API testing checks</th><th>Serverless testing adds</th></tr></thead>
        <tbody>{mrows}</tbody></table></div>
      <div class="card" style="flex:1"><h3>Where the tests run &mdash; the pyramid</h3>{layer_html}
        <p class="note" style="margin-top:6px">Heavy fast base (handler units), thin slow tip (E2E on a real stack).
        Serverless pushes <b>integration</b> left via local cloud emulation.</p></div>
    </div>
    <div class="card" style="flex:0;background:linear-gradient(110deg,#eef4ff,#e6f6f3);border:1px solid {C['line']}">
      <div style="display:flex;align-items:center;gap:16px">
        <div style="font-size:14px;font-weight:800;color:{C['brand_d']};white-space:nowrap">Serverless = API testing&nbsp;+&nbsp;runtime</div>
        <div class="note" style="flex:1">A serverless API needs <b>both</b> layers: the contract tests prove the interface is right;
        the runtime tests prove events, retries, cold starts and IAM behave. They catch different defect classes &mdash; neither replaces the other.</div>
        <div class="note" style="flex:1;border-left:1px solid {C['line']};padding-left:14px">
        <b>In this lab:</b> <code>api-contract</code> (Pact/schema), <code>performance</code> (k6) and
        <code>security</code> (ZAP) pipelines already cover the API tier &mdash; serverless adds an
        emulated-integration + idempotency suite to the same CI.</div>
      </div>
    </div>'''
    return page("API &amp; Serverless Test Strategy", "Service-Layer Quality — Reference",
                status, meta, body, "Test types · tooling · CI mapping", 7, total=7)


if __name__ == "__main__":
    html = api_strategy_slide()
    out_html = os.path.join(HERE, "html", "07_api_serverless_strategy.html")
    open(out_html, "w").write(html)
    print("wrote", out_html)
