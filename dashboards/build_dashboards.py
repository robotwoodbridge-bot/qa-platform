#!/usr/bin/env python3
"""
Quality Story Dashboard Suite
=============================
Generates six print-ready executive quality dashboards as standalone HTML,
designed to be rendered to PDF via headless Chrome.

Narrative context (synthetic, illustrative data):
  Org      : Northwind Financial — Global Quality Engineering
  Period   : Q2 FY26 (Apr–Jun 2026)
  Release  : "Atlas" 24.2

Dashboards:
  1. Release Readiness (GO / NO-GO)
  2. Quality Trend Report
  3. Automation Health
  4. Production Reliability
  5. Engineering Quality Scorecard (DORA)
  6. Executive Quarterly Quality Review
"""
import math
import os

OUT = os.path.join(os.path.dirname(__file__), "html")
os.makedirs(OUT, exist_ok=True)

# ----------------------------------------------------------------------------
# Design system
# ----------------------------------------------------------------------------
C = {
    "ink": "#0f172a", "slate": "#334155", "muted": "#64748b", "faint": "#94a3b8",
    "bg": "#eef2f7", "card": "#ffffff", "line": "#e2e8f0", "grid": "#eaeef3",
    "brand": "#1d4ed8", "brand2": "#3b82f6", "brand_d": "#1e3a8a",
    "green": "#15803d", "green2": "#22c55e", "amber": "#b45309", "amber2": "#f59e0b",
    "red": "#b91c1c", "red2": "#ef4444", "teal": "#0d9488", "purple": "#7c3aed",
    "slatefill": "#cbd5e1",
}

CSS = """
* { box-sizing: border-box; margin: 0; padding: 0; }
@page { size: 13.33in 7.5in; margin: 0; }
html, body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
body {
  font-family: -apple-system, "Helvetica Neue", "Segoe UI", Arial, sans-serif;
  color: __INK__; background: __BG__;
}
.page {
  width: 13.33in; height: 7.5in; position: relative; overflow: hidden;
  background: __BG__; display: flex; flex-direction: column;
  page-break-after: always;
}
.hdr {
  background: linear-gradient(110deg, __BRANDD__ 0%, __BRAND__ 62%, __BRAND2__ 100%);
  color: #fff; padding: 16px 26px 15px; display: flex; align-items: center;
  justify-content: space-between; position: relative;
}
.hdr::after { content:""; position:absolute; left:0; right:0; bottom:0; height:3px;
  background: linear-gradient(90deg,__AMBER2__,__GREEN2__,__BRAND2__); }
.hdr .eyebrow { font-size: 10px; letter-spacing: 2.4px; text-transform: uppercase;
  opacity: .82; font-weight: 700; }
.hdr h1 { font-size: 23px; font-weight: 800; letter-spacing: -.3px; margin-top: 3px; }
.hdr .org { font-size: 11px; opacity: .85; margin-top: 4px; font-weight: 500; }
.hdr .meta { text-align: right; font-size: 11px; line-height: 1.55; opacity: .92; }
.hdr .meta b { font-weight: 700; }
.statuspill { display:inline-flex; align-items:center; gap:7px; padding: 7px 15px;
  border-radius: 999px; font-weight: 800; font-size: 13px; letter-spacing:.4px;
  background: rgba(255,255,255,.16); border: 1.5px solid rgba(255,255,255,.5); margin-top:7px;}
.dot { width: 9px; height: 9px; border-radius: 50%; display:inline-block; }
.body { flex: 1; padding: 13px 18px 8px; display: flex; flex-direction: column; gap: 11px; }
.row { display: flex; gap: 11px; }
.col { display: flex; flex-direction: column; gap: 11px; }
.card { background: __CARD__; border: 1px solid __LINE__; border-radius: 11px;
  padding: 12px 14px; position: relative; box-shadow: 0 1px 2px rgba(15,23,42,.04); }
.card h3 { font-size: 10.5px; text-transform: uppercase; letter-spacing: 1.1px;
  color: __MUTED__; font-weight: 700; margin-bottom: 9px; display:flex;
  justify-content:space-between; align-items:center; }
.card h3 .tag { font-size: 9px; letter-spacing:.4px; padding:2px 7px; border-radius:5px;
  background:__BG__; color:__SLATE__; font-weight:700; text-transform:none; }
.kpi { flex:1; background: __CARD__; border:1px solid __LINE__; border-radius: 11px;
  padding: 11px 13px; position: relative; overflow:hidden; box-shadow:0 1px 2px rgba(15,23,42,.04);}
.kpi::before { content:""; position:absolute; left:0; top:0; bottom:0; width:4px; background:__BRAND__; }
.kpi .label { font-size: 9.5px; text-transform: uppercase; letter-spacing: .8px;
  color: __MUTED__; font-weight: 700; }
.kpi .val { font-size: 27px; font-weight: 800; letter-spacing: -.6px; margin-top: 3px; line-height:1; }
.kpi .val small { font-size: 13px; font-weight: 700; color:__MUTED__; }
.kpi .sub { font-size: 10px; color: __MUTED__; margin-top: 4px; font-weight:600; }
.kpi .trend { position:absolute; top:11px; right:12px; font-size:10px; font-weight:800;
  padding:2px 7px; border-radius: 6px; }
.up { color:__GREEN__; background: #e7f6ec; } .down { color:__RED__; background:#fdeaea; }
.flat { color:__MUTED__; background:__BG__; }
table { width: 100%; border-collapse: collapse; font-size: 10.5px; }
th { text-align: left; color: __MUTED__; font-weight: 700; font-size: 9px;
  text-transform: uppercase; letter-spacing: .6px; padding: 4px 7px; border-bottom: 1.5px solid __LINE__; }
td { padding: 5px 7px; border-bottom: 1px solid __GRID__; color: __SLATE__; font-weight:500; }
tr:last-child td { border-bottom: none; }
.badge { display:inline-block; padding: 2px 8px; border-radius: 999px; font-size: 9.5px; font-weight: 800; }
.b-green{ background:#e7f6ec; color:__GREEN__;} .b-amber{ background:#fef3e2; color:__AMBER__;}
.b-red{ background:#fdeaea; color:__RED__;} .b-blue{ background:#e6efff; color:__BRAND__;}
.b-grey{ background:__BG__; color:__SLATE__;}
.gate { display:flex; align-items:center; justify-content:space-between; padding: 6px 0;
  border-bottom: 1px solid __GRID__; font-size: 11px; }
.gate:last-child{ border-bottom:none; }
.gate .gname { font-weight:600; color:__SLATE__; }
.gate .gval { font-weight:800; color:__INK__; font-variant-numeric: tabular-nums; }
.legend { display:flex; gap:13px; flex-wrap:wrap; font-size:9.5px; color:__MUTED__; font-weight:600; margin-top:5px;}
.legend span { display:flex; align-items:center; gap:5px; }
.footer { display:flex; justify-content:space-between; align-items:center;
  padding: 5px 22px 8px; font-size: 9px; color: __FAINT__; font-weight:600; letter-spacing:.3px; }
.footer .conf { color:__ambertxt__; }
.bignum { font-variant-numeric: tabular-nums; }
.hbar-track { background:__BG__; border-radius:6px; height:9px; overflow:hidden; }
.hbar-fill { height:100%; border-radius:6px; }
.note { font-size:9.5px; color:__MUTED__; line-height:1.5; }
.ribbon { display:flex; gap:8px; }
ul.clean { list-style:none; }
ul.clean li { font-size:10.5px; color:__SLATE__; padding:4px 0 4px 16px; position:relative; line-height:1.4; font-weight:500;}
ul.clean li::before { content:""; position:absolute; left:0; top:9px; width:7px; height:7px; border-radius:2px; background:__BRAND2__; }
ul.clean li.win::before{ background:__GREEN2__; } ul.clean li.risk::before{ background:__AMBER2__; }
ul.clean li.watch::before{ background:__RED2__; }
"""
for k, v in {
    "__INK__": C["ink"], "__BG__": C["bg"], "__CARD__": C["card"], "__LINE__": C["line"],
    "__GRID__": C["grid"], "__BRAND__": C["brand"], "__BRAND2__": C["brand2"],
    "__BRANDD__": C["brand_d"], "__MUTED__": C["muted"], "__SLATE__": C["slate"],
    "__FAINT__": C["faint"], "__GREEN__": C["green"], "__GREEN2__": C["green2"],
    "__AMBER__": C["amber"], "__AMBER2__": C["amber2"], "__RED__": C["red"],
    "__RED2__": C["red2"], "__ambertxt__": C["amber"],
}.items():
    CSS = CSS.replace(k, v)


def page(title, eyebrow, status_html, meta_html, body_html, accent_note, n, total=6):
    return f"""<!doctype html><html><head><meta charset="utf-8">
<style>{CSS}</style></head><body><div class="page">
<div class="hdr">
  <div>
    <div class="eyebrow">{eyebrow}</div>
    <h1>{title}</h1>
    <div class="org">Northwind Financial &nbsp;·&nbsp; Global Quality Engineering</div>
  </div>
  <div class="meta">{meta_html}{status_html}</div>
</div>
<div class="body">{body_html}</div>
<div class="footer">
  <span>Northwind Financial — Confidential · Quality Engineering Office of the VP</span>
  <span class="conf">{accent_note}</span>
  <span>Q2 FY26 · Dashboard {n} of {total} · Data as of 28 Jun 2026</span>
</div>
</div></body></html>"""


# ----------------------------------------------------------------------------
# Chart helpers (inline SVG)
# ----------------------------------------------------------------------------
def _pt(cx, cy, r, deg):
    rad = math.radians(deg)
    return cx + r * math.cos(rad), cy - r * math.sin(rad)


def gauge(value, vmax=100, label="", sub="", color=None, w=210, h=132, unit=""):
    cx, cy, r = w / 2, h - 26, w / 2 - 22
    f = max(0.0, min(1.0, value / vmax))
    if color is None:
        color = C["green"] if f >= .85 else C["amber2"] if f >= .6 else C["red2"]
    x0, y0 = _pt(cx, cy, r, 180)
    x1, y1 = _pt(cx, cy, r, 0)
    ax, ay = _pt(cx, cy, r, 180 - f * 180)
    large = 1 if f > 0.5 else 0
    # ticks
    ticks = ""
    for d in (180, 135, 90, 45, 0):
        tx0, ty0 = _pt(cx, cy, r + 8, d)
        tx1, ty1 = _pt(cx, cy, r + 13, d)
        ticks += f'<line x1="{tx0:.1f}" y1="{ty0:.1f}" x2="{tx1:.1f}" y2="{ty1:.1f}" stroke="{C["faint"]}" stroke-width="1"/>'
    disp = f"{value:g}{unit}"
    return f'''<svg viewBox="0 0 {w} {h}" width="100%" style="max-height:{h}px">
<path d="M{x0:.1f} {y0:.1f} A{r} {r} 0 0 1 {x1:.1f} {y1:.1f}" fill="none" stroke="{C['bg']}" stroke-width="15" stroke-linecap="round"/>
<path d="M{x0:.1f} {y0:.1f} A{r} {r} 0 {large} 1 {ax:.1f} {ay:.1f}" fill="none" stroke="{color}" stroke-width="15" stroke-linecap="round"/>
{ticks}
<text x="{cx}" y="{cy-6}" text-anchor="middle" font-size="30" font-weight="800" fill="{C['ink']}">{disp}</text>
<text x="{cx}" y="{cy+12}" text-anchor="middle" font-size="10" font-weight="700" fill="{C['muted']}">{label}</text>
</svg>{f'<div class="note" style="text-align:center;margin-top:-2px">{sub}</div>' if sub else ''}'''


def donut(segments, w=150, total_label="", center_big="", center_sub=""):
    cx, cy, r, sw = w / 2, w / 2, w / 2 - 14, 20
    circ = 2 * math.pi * r
    off = 0.0
    arcs = ""
    tot = sum(s[1] for s in segments) or 1
    for name, val, col in segments:
        frac = val / tot
        dash = circ * frac
        arcs += (f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{col}" '
                 f'stroke-width="{sw}" stroke-dasharray="{dash:.2f} {circ-dash:.2f}" '
                 f'stroke-dashoffset="{-off:.2f}" transform="rotate(-90 {cx} {cy})"/>')
        off += dash
    big = center_big or ""
    return f'''<svg viewBox="0 0 {w} {w}" width="{w}" height="{w}">
<circle cx="{cx}" cy="{cy}" r="{r}" fill="none" stroke="{C['bg']}" stroke-width="{sw}"/>
{arcs}
<text x="{cx}" y="{cy-1}" text-anchor="middle" font-size="24" font-weight="800" fill="{C['ink']}">{big}</text>
<text x="{cx}" y="{cy+15}" text-anchor="middle" font-size="9" font-weight="700" fill="{C['muted']}">{center_sub}</text>
</svg>'''


def line_chart(labels, series, w=560, h=190, ymin=None, ymax=None, yfmt="{:.0f}",
               yunit="", area=False, pad_l=38, target=None, target_label=""):
    pad_r, pad_t, pad_b = 14, 14, 26
    plot_w, plot_h = w - pad_l - pad_r, h - pad_t - pad_b
    allv = [v for s in series for v in s["values"] if v is not None]
    lo = ymin if ymin is not None else min(allv)
    hi = ymax if ymax is not None else max(allv)
    if hi == lo:
        hi += 1
    rng = hi - lo

    def X(i):
        return pad_l + (plot_w * i / (len(labels) - 1) if len(labels) > 1 else 0)

    def Y(v):
        return pad_t + plot_h * (1 - (v - lo) / rng)

    grid = ""
    for g in range(5):
        gy = pad_t + plot_h * g / 4
        val = hi - rng * g / 4
        grid += f'<line x1="{pad_l}" y1="{gy:.1f}" x2="{w-pad_r}" y2="{gy:.1f}" stroke="{C["grid"]}" stroke-width="1"/>'
        grid += f'<text x="{pad_l-6}" y="{gy+3:.1f}" text-anchor="end" font-size="8.5" fill="{C["faint"]}" font-weight="600">{yfmt.format(val)}{yunit}</text>'
    xlabels = ""
    step = max(1, len(labels) // 12)
    for i, lb in enumerate(labels):
        if i % step == 0 or i == len(labels) - 1:
            xlabels += f'<text x="{X(i):.1f}" y="{h-8}" text-anchor="middle" font-size="8.5" fill="{C["muted"]}" font-weight="600">{lb}</text>'
    tline = ""
    if target is not None:
        ty = Y(target)
        tline = (f'<line x1="{pad_l}" y1="{ty:.1f}" x2="{w-pad_r}" y2="{ty:.1f}" stroke="{C["red2"]}" '
                 f'stroke-width="1.3" stroke-dasharray="5 4"/>'
                 f'<text x="{w-pad_r}" y="{ty-4:.1f}" text-anchor="end" font-size="8.5" fill="{C["red"]}" font-weight="700">{target_label}</text>')
    paths = ""
    for s in series:
        pts = [(X(i), Y(v)) for i, v in enumerate(s["values"]) if v is not None]
        d = "M" + " L".join(f"{x:.1f} {y:.1f}" for x, y in pts)
        if area:
            ad = d + f" L{pts[-1][0]:.1f} {pad_t+plot_h:.1f} L{pts[0][0]:.1f} {pad_t+plot_h:.1f} Z"
            paths += f'<path d="{ad}" fill="{s["color"]}" opacity="0.10"/>'
        paths += f'<path d="{d}" fill="none" stroke="{s["color"]}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round"/>'
        for x, y in pts:
            paths += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="2.6" fill="#fff" stroke="{s["color"]}" stroke-width="1.8"/>'
    return f'<svg viewBox="0 0 {w} {h}" width="100%">{grid}{tline}{paths}{xlabels}</svg>'


def bar_chart(labels, values, w=560, h=180, color=None, ymax=None, yunit="",
              target=None, colors=None, yfmt="{:.0f}", pad_l=34):
    pad_r, pad_t, pad_b = 12, 12, 26
    plot_w, plot_h = w - pad_l - pad_r, h - pad_t - pad_b
    hi = ymax if ymax is not None else max(values) * 1.15
    n = len(values)
    bw = plot_w / n * 0.62
    gap = plot_w / n
    grid = ""
    for g in range(5):
        gy = pad_t + plot_h * g / 4
        grid += f'<line x1="{pad_l}" y1="{gy:.1f}" x2="{w-pad_r}" y2="{gy:.1f}" stroke="{C["grid"]}" stroke-width="1"/>'
        grid += f'<text x="{pad_l-6}" y="{gy+3:.1f}" text-anchor="end" font-size="8.5" fill="{C["faint"]}" font-weight="600">{yfmt.format(hi-hi*g/4)}{yunit}</text>'
    bars = ""
    for i, v in enumerate(values):
        x = pad_l + gap * i + (gap - bw) / 2
        bh = plot_h * v / hi
        y = pad_t + plot_h - bh
        col = colors[i] if colors else (color or C["brand2"])
        bars += f'<rect x="{x:.1f}" y="{y:.1f}" width="{bw:.1f}" height="{bh:.1f}" rx="3" fill="{col}"/>'
        bars += f'<text x="{x+bw/2:.1f}" y="{h-8}" text-anchor="middle" font-size="8.5" fill="{C["muted"]}" font-weight="600">{labels[i]}</text>'
    tline = ""
    if target is not None:
        ty = pad_t + plot_h * (1 - target / hi)
        tline = f'<line x1="{pad_l}" y1="{ty:.1f}" x2="{w-pad_r}" y2="{ty:.1f}" stroke="{C["red2"]}" stroke-width="1.3" stroke-dasharray="5 4"/>'
    return f'<svg viewBox="0 0 {w} {h}" width="100%">{grid}{tline}{bars}</svg>'


def stacked_bars(labels, series, w=560, h=185, yunit="", ymax=None):
    pad_l, pad_r, pad_t, pad_b = 30, 12, 12, 26
    plot_w, plot_h = w - pad_l - pad_r, h - pad_t - pad_b
    totals = [sum(s["values"][i] for s in series) for i in range(len(labels))]
    hi = ymax if ymax is not None else max(totals) * 1.15
    n = len(labels)
    bw = plot_w / n * 0.6
    gap = plot_w / n
    grid = ""
    for g in range(5):
        gy = pad_t + plot_h * g / 4
        grid += f'<line x1="{pad_l}" y1="{gy:.1f}" x2="{w-pad_r}" y2="{gy:.1f}" stroke="{C["grid"]}" stroke-width="1"/>'
        grid += f'<text x="{pad_l-6}" y="{gy+3:.1f}" text-anchor="end" font-size="8.5" fill="{C["faint"]}" font-weight="600">{hi-hi*g/4:.0f}{yunit}</text>'
    bars = ""
    for i in range(n):
        x = pad_l + gap * i + (gap - bw) / 2
        acc = 0
        for s in series:
            v = s["values"][i]
            bh = plot_h * v / hi
            y = pad_t + plot_h - acc - bh
            bars += f'<rect x="{x:.1f}" y="{y:.1f}" width="{bw:.1f}" height="{bh:.1f}" fill="{s["color"]}"/>'
            acc += bh
        bars += f'<text x="{x+bw/2:.1f}" y="{h-8}" text-anchor="middle" font-size="8.5" fill="{C["muted"]}" font-weight="600">{labels[i]}</text>'
    return f'<svg viewBox="0 0 {w} {h}" width="100%">{grid}{bars}</svg>'


def hbar(label, value, vmax, color, suffix="", w_label=False):
    pct = max(2, min(100, value / vmax * 100))
    return f'''<div style="margin:7px 0">
<div style="display:flex;justify-content:space-between;font-size:10.5px;font-weight:700;color:{C['slate']};margin-bottom:3px">
<span>{label}</span><span class="bignum">{value}{suffix}</span></div>
<div class="hbar-track"><div class="hbar-fill" style="width:{pct:.0f}%;background:{color}"></div></div></div>'''


def legend(items):
    sp = "".join(f'<span><span class="dot" style="background:{c}"></span>{n}</span>' for n, c in items)
    return f'<div class="legend">{sp}</div>'


def kpi(label, val, unit="", sub="", trend=None, trend_dir="up", accent=None):
    t = f'<div class="trend {trend_dir}">{trend}</div>' if trend else ""
    style = f' style="--a:{accent}"' if accent else ""
    bar = f'<style>.kpi-{abs(hash(label))%9999}::before{{background:{accent}}}</style>' if accent else ""
    cls = f"kpi kpi-{abs(hash(label))%9999}" if accent else "kpi"
    u = f'<small>{unit}</small>' if unit else ""
    return f'{bar}<div class="{cls}"><div class="label">{label}</div><div class="val bignum">{val}{u}</div><div class="sub">{sub}</div>{t}</div>'


# ============================================================================
# DASHBOARD 1 — RELEASE READINESS
# ============================================================================
def d1_release_readiness():
    meta = '<b>Release:</b> Atlas 24.2 &nbsp;·&nbsp; <b>Target:</b> 02 Jul 2026<br><b>Train:</b> Production · Wave 1 (NA/EU)<br>'
    status = ('<div class="statuspill"><span class="dot" style="background:'
              + C["amber2"] + '"></span>GO &nbsp;WITH&nbsp;RISK</div>')

    gates = [
        ("Test pass rate", "98.4%", "≥ 98.0%", "green"),
        ("Blocker / Critical defects open", "0", "= 0", "green"),
        ("High-severity defects open", "3", "≤ 5", "green"),
        ("Requirements coverage", "96%", "≥ 95%", "green"),
        ("Regression suite executed", "100%", "= 100%", "green"),
        ("Automation pass rate", "96.5%", "≥ 95%", "green"),
        ("Code coverage (changed code)", "84%", "≥ 80%", "green"),
        ("Performance budget (p95)", "1.82s", "≤ 2.0s", "green"),
        ("Security — High vulns open", "2", "= 0", "amber"),
        ("Accessibility (WCAG AA)", "1 open", "= 0", "amber"),
    ]
    gate_rows = ""
    for name, val, tgt, st in gates:
        ic = {"green": "✓", "amber": "!", "red": "✕"}[st]
        gate_rows += (f'<div class="gate"><span class="gname"><span class="badge b-{st}" '
                      f'style="margin-right:6px">{ic}</span>{name}</span>'
                      f'<span class="gval">{val} <span style="color:{C["faint"]};font-weight:600;font-size:9.5px">/ {tgt}</span></span></div>')

    risks = [
        ("SEC-2291", "Auth token rotation — 2 high CVEs in 3rd-party lib", "High", "Patch in 24.2.1 hotfix; WAF rule deployed as compensating control", "amber"),
        ("A11Y-118", "Statement export modal fails AA contrast", "Medium", "Fix scheduled D+3; <2% of users on path", "amber"),
        ("PERF-77", "Batch posting p99 spike under peak load", "Low", "Within budget at p95; capacity headroom verified", "green"),
    ]
    risk_rows = "".join(
        f'<tr><td><b>{i}</b></td><td>{d}</td><td><span class="badge b-{c}">{s}</span></td><td style="color:{C["muted"]}">{m}</td></tr>'
        for i, d, s, m, c in risks)

    signoffs = [
        ("Quality Engineering", "Signed", "green"), ("Product Management", "Signed", "green"),
        ("Site Reliability (SRE)", "Signed", "green"), ("Security / AppSec", "Conditional", "amber"),
        ("Data / Privacy", "Signed", "green"), ("Release Management", "Pending", "amber"),
    ]
    so_rows = "".join(
        f'<div class="gate" style="padding:5px 0"><span class="gname">{n}</span><span class="badge b-{c}">{s}</span></div>'
        for n, s, c in signoffs)

    burndown = line_chart(
        ["D-14", "D-12", "D-10", "D-8", "D-6", "D-4", "D-2", "D-0"],
        [{"name": "Open defects", "color": C["brand"],
          "values": [58, 49, 41, 30, 22, 14, 7, 3]},
         {"name": "Blocker/Critical", "color": C["red2"],
          "values": [9, 7, 5, 3, 2, 1, 0, 0]}],
        w=540, h=168, ymin=0, area=True)

    body = f'''
    <div class="row" style="gap:11px">
      {kpi("Readiness Score", "87", unit="/100", sub="Weighted gate composite", trend="+6 vs 24.1", trend_dir="up", accent=C["amber2"])}
      {kpi("Test Pass Rate", "98.4", unit="%", sub="4,812 / 4,890 passed", trend="+0.7 pt", trend_dir="up", accent=C["green"])}
      {kpi("Open Defects", "3", unit=" High", sub="0 blocker · 0 critical", trend="-55 in 14d", trend_dir="up", accent=C["green"])}
      {kpi("Req. Coverage", "96", unit="%", sub="312 / 325 requirements", trend="+3 pt", trend_dir="up", accent=C["brand"])}
      {kpi("Security Gate", "2", unit=" High", sub="0 critical open", trend="Action req.", trend_dir="down", accent=C["amber2"])}
    </div>
    <div class="row" style="flex:1">
      <div class="col" style="flex:1.15">
        <div class="card" style="flex:1"><h3>Release Gate Scorecard <span class="tag">8 / 10 met</span></h3>{gate_rows}</div>
      </div>
      <div class="col" style="flex:1.25">
        <div class="card"><h3>Defect Burndown — 14 day countdown</h3>{burndown}{legend([("Open defects",C["brand"]),("Blocker/Critical",C["red2"])])}</div>
        <div class="card" style="flex:1"><h3>Open Risks &amp; Mitigations</h3>
          <table><thead><tr><th>ID</th><th>Risk</th><th>Sev</th><th>Mitigation</th></tr></thead><tbody>{risk_rows}</tbody></table></div>
      </div>
      <div class="col" style="flex:.8">
        <div class="card"><h3>Stakeholder Sign-off</h3>{so_rows}</div>
        <div class="card" style="flex:1"><h3>Recommendation</h3>
          <div style="font-size:13px;font-weight:800;color:{C['amber']};margin-bottom:6px">CONDITIONAL GO</div>
          <p class="note">Proceed to Wave 1 production with two conditions: (1) deploy 24.2.1 security
          hotfix within 72h to close SEC-2291; (2) WAF compensating control active at cutover.
          All functional, regression, performance and reliability gates are met. Blast radius limited
          to NA/EU; instant rollback verified (4 min).</p>
        </div>
      </div>
    </div>'''
    return page("Release Readiness — GO / NO-GO", "Release Decision Brief", status, meta, body,
                "Decision owner: VP Quality Engineering", 1)


# ============================================================================
# DASHBOARD 2 — QUALITY TREND REPORT
# ============================================================================
def d2_quality_trend():
    meta = '<b>Window:</b> Trailing 8 sprints<br><b>Scope:</b> Atlas platform — all squads<br>'
    status = ('<div class="statuspill"><span class="dot" style="background:' + C["green2"]
              + '"></span>IMPROVING</div>')
    sprints = ["S31", "S32", "S33", "S34", "S35", "S36", "S37", "S38"]

    dre = line_chart(sprints, [
        {"name": "Defect Removal Efficiency", "color": C["green"],
         "values": [86, 87, 88, 89, 90, 92, 93, 94]}],
        w=400, h=158, ymin=78, ymax=100, yunit="%", area=True, target=90, target_label="Goal 90%")

    density = line_chart(sprints, [
        {"name": "Defect density", "color": C["brand"],
         "values": [2.9, 2.7, 2.5, 2.3, 2.0, 1.8, 1.6, 1.4]}],
        w=400, h=158, ymin=0, ymax=3.5, yfmt="{:.1f}", area=True)

    escaped = line_chart(sprints, [
        {"name": "Escaped to prod", "color": C["red2"],
         "values": [11, 9, 8, 7, 5, 4, 3, 2]}],
        w=400, h=158, ymin=0, ymax=14, area=True, target=4, target_label="Threshold")

    sevmix = stacked_bars(sprints, [
        {"name": "Critical", "color": C["red"], "values": [3, 2, 2, 1, 1, 1, 0, 0]},
        {"name": "High", "color": C["amber2"], "values": [9, 8, 7, 6, 5, 4, 4, 3]},
        {"name": "Medium", "color": C["brand2"], "values": [18, 17, 15, 14, 12, 11, 10, 9]},
        {"name": "Low", "color": C["slatefill"], "values": [22, 20, 19, 17, 16, 15, 13, 12]},
    ], w=430, h=170)

    passrate = line_chart(sprints, [
        {"name": "Test pass rate", "color": C["teal"],
         "values": [94.1, 94.8, 95.5, 96.2, 96.9, 97.4, 98.0, 98.4]}],
        w=430, h=170, ymin=92, ymax=100, yunit="%", target=98, target_label="Goal 98%")

    body = f'''
    <div class="row">
      {kpi("Defect Removal Efficiency", "94", unit="%", sub="caught before production", trend="+8 pt", trend_dir="up", accent=C["green"])}
      {kpi("Defect Density", "1.4", unit="/KLOC", sub="down from 2.9", trend="-52%", trend_dir="up", accent=C["brand"])}
      {kpi("Escaped Defects", "2", sub="this sprint vs 11", trend="-82%", trend_dir="up", accent=C["green"])}
      {kpi("Defect Reopen Rate", "3.1", unit="%", sub="first-time-fix 96.9%", trend="-2.4 pt", trend_dir="up", accent=C["teal"])}
      {kpi("Mean Time to Fix", "1.9", unit="d", sub="critical: 6.4h", trend="-0.8d", trend_dir="up", accent=C["purple"])}
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1"><h3>Defect Removal Efficiency <span class="tag">higher = better</span></h3>{dre}</div>
      <div class="card" style="flex:1"><h3>Defect Density (per KLOC) <span class="tag">lower = better</span></h3>{density}</div>
      <div class="card" style="flex:1"><h3>Escaped Defects to Production <span class="tag">lower = better</span></h3>{escaped}</div>
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1.1"><h3>Defect Inflow by Severity</h3>{sevmix}
        {legend([("Critical",C["red"]),("High",C["amber2"]),("Medium",C["brand2"]),("Low",C["slatefill"])])}</div>
      <div class="card" style="flex:1.1"><h3>Test Pass Rate Trend</h3>{passrate}</div>
      <div class="card" style="flex:.9"><h3>Trend Narrative</h3>
        <ul class="clean">
          <li class="win">DRE crossed the 90% goal in S36 and holds at <b>94%</b> — quality is shifting left.</li>
          <li class="win">Escaped defects down <b>82%</b> over 8 sprints; 6 consecutive sprints under threshold.</li>
          <li class="win">Severity mix flattening — zero criticals injected for two sprints.</li>
          <li class="risk">Medium-severity backlog still the largest bucket; targeted for S39 cleanup.</li>
        </ul>
      </div>
    </div>'''
    return page("Quality Trend Report", "Quality Over Time", status, meta, body,
                "8-sprint trailing analysis", 2)


# ============================================================================
# DASHBOARD 3 — AUTOMATION HEALTH
# ============================================================================
def d3_automation_health():
    meta = '<b>Suites:</b> 6 · 4,890 tests<br><b>Frameworks:</b> Robot + Playwright · pabot<br>'
    status = ('<div class="statuspill"><span class="dot" style="background:' + C["green2"]
              + '"></span>HEALTHY</div>')
    weeks = ["W18", "W19", "W20", "W21", "W22", "W23", "W24", "W25"]

    cov_gauge = gauge(78, label="Automation coverage", color=C["brand"], w=200, h=126, unit="%")
    stab_gauge = gauge(96.5, label="Suite stability (pass)", color=C["green"], w=200, h=126, unit="%")

    cov_layers = (hbar("Unit", 91, 100, C["green2"], "%") +
                  hbar("API / Contract", 84, 100, C["brand2"], "%") +
                  hbar("Integration", 72, 100, C["teal"], "%") +
                  hbar("UI / E2E", 61, 100, C["purple"], "%") +
                  hbar("Non-functional", 48, 100, C["amber2"], "%"))

    flaky_trend = line_chart(weeks, [
        {"name": "Flaky rate", "color": C["amber2"],
         "values": [3.8, 3.4, 3.1, 2.7, 2.2, 1.9, 1.5, 1.2]}],
        w=420, h=158, ymin=0, ymax=5, yfmt="{:.1f}", yunit="%", area=True, target=2, target_label="SLO 2%")

    exec_time = line_chart(weeks, [
        {"name": "Wall-clock (4 workers)", "color": C["brand"],
         "values": [34, 32, 30, 27, 25, 23, 21, 19]},
        {"name": "Serial-equiv", "color": C["slatefill"],
         "values": [120, 118, 119, 116, 115, 114, 112, 110]}],
        w=420, h=158, ymin=0, ymax=130, yunit="m")

    ci_pass = bar_chart(weeks, [92, 93, 91, 95, 96, 97, 98, 98],
                        w=420, h=158, ymax=100, yunit="%", target=95,
                        colors=[C["red2"] if v < 95 else C["green2"] for v in [92, 93, 91, 95, 96, 97, 98, 98]])

    flaky_tbl = [
        ("login_mfa_challenge.robot", 9, "Race on OTP field", "Quarantined"),
        ("statement_export_pdf.robot", 6, "Async download timing", "Fix in review"),
        ("dashboard_widgets_load.robot", 5, "3rd-party iframe", "Retry+wait added"),
        ("payments_idempotency.robot", 4, "Test data collision", "Isolated data"),
        ("search_autocomplete.robot", 3, "Debounce timing", "Stabilized"),
    ]
    flaky_rows = "".join(
        f'<tr><td style="font-family:monospace;font-size:9.5px">{n}</td><td><b>{c}</b></td><td style="color:{C["muted"]}">{r}</td><td><span class="badge b-blue">{s}</span></td></tr>'
        for n, c, r, s in flaky_tbl)

    body = f'''
    <div class="row">
      {kpi("Automation Coverage", "78", unit="%", sub="3,814 automated tests", trend="+11 pt", trend_dir="up", accent=C["brand"])}
      {kpi("Suite Stability", "96.5", unit="%", sub="non-flaky pass rate", trend="+2.6 pt", trend_dir="up", accent=C["green"])}
      {kpi("Flaky Tests", "23", sub="0.6% of suite · was 71", trend="-68%", trend_dir="up", accent=C["amber2"])}
      {kpi("Execution Time", "19", unit="m", sub="4-way parallel (pabot)", trend="-44%", trend_dir="up", accent=C["teal"])}
      {kpi("CI/CD Pass Rate", "98", unit="%", sub="last 50 pipeline runs", trend="+6 pt", trend_dir="up", accent=C["purple"])}
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:.8"><h3>Coverage &amp; Stability</h3>
        <div class="row" style="gap:6px">{cov_gauge}{stab_gauge}</div></div>
      <div class="card" style="flex:1"><h3>Coverage by Test Layer (pyramid)</h3>{cov_layers}
        <p class="note" style="margin-top:6px">Healthy distribution — heavy unit/API base, lean E2E tip.</p></div>
      <div class="card" style="flex:1.1"><h3>Flaky-Test Rate <span class="tag">target ≤ 2%</span></h3>{flaky_trend}</div>
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1"><h3>Test Execution Time (min)</h3>{exec_time}
        {legend([("Parallel 4-worker",C["brand"]),("Serial-equiv",C["slatefill"])])}</div>
      <div class="card" style="flex:1"><h3>CI/CD Pipeline Pass Rate <span class="tag">goal ≥ 95%</span></h3>{ci_pass}</div>
      <div class="card" style="flex:1.25"><h3>Top Flaky Tests — Triage Queue</h3>
        <table><thead><tr><th>Test</th><th>Fails/100</th><th>Root cause</th><th>Status</th></tr></thead><tbody>{flaky_rows}</tbody></table></div>
    </div>'''
    return page("Automation Health Dashboard", "Test Automation Engineering", status, meta, body,
                "Coverage · Stability · Flake · Speed · CI", 3)


# ============================================================================
# DASHBOARD 4 — PRODUCTION RELIABILITY
# ============================================================================
def d4_production_reliability():
    meta = '<b>Scope:</b> Atlas production · 7 services<br><b>SLO window:</b> 30-day rolling<br>'
    status = ('<div class="statuspill"><span class="dot" style="background:' + C["green2"]
              + '"></span>SLO MET</div>')
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"]

    avail_gauge = gauge(99.95, vmax=100, label="Availability (30d)", color=C["green"], w=200, h=126, unit="%")
    budget_gauge = gauge(38, label="Error budget remaining", color=C["amber2"], w=200, h=126, unit="%")

    mttr = line_chart(months, [
        {"name": "MTTR", "color": C["brand"], "values": [78, 71, 64, 55, 48, 42]}],
        w=400, h=158, ymin=0, ymax=90, yunit="m", area=True, target=60, target_label="Target 60m")

    incidents = stacked_bars(months, [
        {"name": "Sev1", "color": C["red"], "values": [1, 1, 0, 1, 0, 0]},
        {"name": "Sev2", "color": C["amber2"], "values": [3, 2, 2, 1, 2, 1]},
        {"name": "Sev3", "color": C["brand2"], "values": [6, 7, 5, 4, 4, 3]},
    ], w=400, h=158, ymax=12)

    budget_burn = line_chart(
        ["W1", "W2", "W3", "W4", "W5", "W6", "W7", "W8"], [
            {"name": "Budget remaining", "color": C["teal"],
             "values": [100, 88, 79, 71, 60, 52, 45, 38]},
            {"name": "Ideal burn", "color": C["slatefill"],
             "values": [100, 87, 75, 62, 50, 37, 25, 12]}],
        w=420, h=160, ymin=0, ymax=100, yunit="%")

    slo_tbl = [
        ("Core Banking API", "99.98%", "99.95%", "62%", "green"),
        ("Payments Service", "99.96%", "99.95%", "44%", "green"),
        ("Auth / Identity", "99.99%", "99.99%", "18%", "amber"),
        ("Statements", "99.93%", "99.90%", "55%", "green"),
        ("Notifications", "99.91%", "99.90%", "21%", "amber"),
        ("Web Frontend", "99.97%", "99.95%", "58%", "green"),
        ("Mobile BFF", "99.95%", "99.95%", "9%", "red"),
    ]
    slo_rows = "".join(
        f'<tr><td><b>{s}</b></td><td class="bignum">{a}</td><td style="color:{C["muted"]}">{t}</td>'
        f'<td><span class="badge b-{c}">{b}</span></td></tr>'
        for s, a, t, b, c in slo_tbl)

    body = f'''
    <div class="row">
      {kpi("Availability", "99.95", unit="%", sub="SLO 99.9% · 21.9m downtime", trend="met 6 mo", trend_dir="up", accent=C["green"])}
      {kpi("MTTR", "42", unit="m", sub="mean time to restore", trend="-46%", trend_dir="up", accent=C["brand"])}
      {kpi("MTBF", "18.4", unit="d", sub="mean time between failures", trend="+5.1d", trend_dir="up", accent=C["teal"])}
      {kpi("Error Budget", "38", unit="%", sub="remaining this window", trend="on track", trend_dir="flat", accent=C["amber2"])}
      {kpi("Incidents (Jun)", "4", sub="0 Sev1 · 1 Sev2 · 3 Sev3", trend="-43%", trend_dir="up", accent=C["purple"])}
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:.85"><h3>Availability &amp; Error Budget</h3>
        <div class="row" style="gap:6px">{avail_gauge}{budget_gauge}</div></div>
      <div class="card" style="flex:1"><h3>MTTR Trend <span class="tag">lower = better</span></h3>{mttr}</div>
      <div class="card" style="flex:1"><h3>Incident Trend by Severity</h3>{incidents}
        {legend([("Sev1",C["red"]),("Sev2",C["amber2"]),("Sev3",C["brand2"])])}</div>
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1"><h3>Error Budget Burn-down (30d)</h3>{budget_burn}
        {legend([("Actual remaining",C["teal"]),("Ideal burn",C["slatefill"])])}
        <p class="note" style="margin-top:4px">Burning slower than ideal — budget is healthy; release velocity sustainable.</p></div>
      <div class="card" style="flex:1.3"><h3>SLO Compliance by Service <span class="tag">availability / SLO / budget left</span></h3>
        <table><thead><tr><th>Service</th><th>Avail</th><th>SLO</th><th>Budget</th></tr></thead><tbody>{slo_rows}</tbody></table>
        <p class="note" style="margin-top:5px">Mobile BFF at 9% budget — flagged for reliability review before next release.</p></div>
    </div>'''
    return page("Production Reliability Dashboard", "Reliability & SLO Operations", status, meta, body,
                "SLA/SLO · MTTR · MTBF · Error Budget", 4)


# ============================================================================
# DASHBOARD 5 — ENGINEERING QUALITY SCORECARD (DORA)
# ============================================================================
def d5_dora_scorecard():
    meta = '<b>Framework:</b> DORA · 90-day window<br><b>Benchmark:</b> 2023 State of DevOps<br>'
    status = ('<div class="statuspill"><span class="dot" style="background:' + C["green2"]
              + '"></span>ELITE</div>')
    weeks = ["W18", "W19", "W20", "W21", "W22", "W23", "W24", "W25"]

    def dora_card(metric, value, unit, tier, tier_col, desc, scale):
        scale_html = ""
        tiers = ["Low", "Medium", "High", "Elite"]
        for t in tiers:
            on = (t == tier)
            scale_html += (f'<span style="flex:1;text-align:center;font-size:8px;font-weight:800;'
                           f'padding:3px 0;border-radius:4px;'
                           f'background:{tier_col if on else C["bg"]};'
                           f'color:{"#fff" if on else C["faint"]}">{t}</span>')
        return f'''<div class="card" style="flex:1;padding:11px 12px">
          <div class="label" style="font-size:9.5px;text-transform:uppercase;letter-spacing:.7px;color:{C['muted']};font-weight:700">{metric}</div>
          <div style="display:flex;align-items:baseline;gap:6px;margin:4px 0 2px">
            <span class="bignum" style="font-size:28px;font-weight:800;color:{C['ink']}">{value}</span>
            <span style="font-size:12px;font-weight:700;color:{C['muted']}">{unit}</span>
            <span class="badge b-green" style="margin-left:auto;background:{tier_col}22;color:{tier_col}">{tier}</span>
          </div>
          <div class="note" style="margin-bottom:7px">{desc}</div>
          <div style="display:flex;gap:3px">{scale_html}</div></div>'''

    df = bar_chart(weeks, [22, 25, 24, 28, 27, 30, 29, 31], w=420, h=156, ymax=36, color=C["brand2"])
    lt = line_chart(weeks, [{"name": "Lead time", "color": C["teal"],
                             "values": [31, 28, 26, 23, 21, 20, 19, 18]}],
                    w=420, h=156, ymin=0, ymax=36, yunit="h", area=True, target=24, target_label="Elite <24h")
    cfr = line_chart(weeks, [{"name": "Change failure rate", "color": C["amber2"],
                              "values": [16, 15, 13, 12, 11, 10, 9, 9]}],
                     w=420, h=156, ymin=0, ymax=20, yunit="%", area=True, target=15, target_label="Elite <15%")

    lt_break = (hbar("Coding → PR open", 4.2, 18, C["brand2"], "h") +
                hbar("Code review", 5.1, 18, C["purple"], "h") +
                hbar("CI build + test", 0.4, 18, C["teal"], "h") +
                hbar("Merge → deploy ready", 3.8, 18, C["amber2"], "h") +
                hbar("Deploy + verify", 4.5, 18, C["green2"], "h"))

    teams = [
        ("Payments", "5.1/d", "14h", "7%", "31m", "Elite"),
        ("Core Banking", "3.8/d", "19h", "9%", "44m", "Elite"),
        ("Identity", "4.6/d", "16h", "8%", "38m", "Elite"),
        ("Statements", "2.9/d", "26h", "12%", "51m", "High"),
        ("Mobile", "3.2/d", "22h", "11%", "47m", "High"),
    ]
    tier_badge = {"Elite": "b-green", "High": "b-blue", "Medium": "b-amber", "Low": "b-red"}
    team_rows = "".join(
        f'<tr><td><b>{t}</b></td><td class="bignum">{a}</td><td class="bignum">{b}</td>'
        f'<td class="bignum">{c}</td><td class="bignum">{d}</td><td><span class="badge {tier_badge[e]}">{e}</span></td></tr>'
        for t, a, b, c, d, e in teams)

    body = f'''
    <div class="row">
      {dora_card("Deployment Frequency", "4.2", "/day", "Elite", C["green"], "On-demand, multiple deploys/day", 4)}
      {dora_card("Lead Time for Changes", "18", "hours", "Elite", C["green"], "Commit → production", 4)}
      {dora_card("Change Failure Rate", "9", "%", "Elite", C["green"], "Deploys causing degradation", 4)}
      {dora_card("Mean Time to Recovery", "42", "min", "Elite", C["green"], "Restore service after failure", 4)}
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1"><h3>Deployment Frequency (deploys/week)</h3>{df}</div>
      <div class="card" style="flex:1"><h3>Lead Time for Changes <span class="tag">lower = better</span></h3>{lt}</div>
      <div class="card" style="flex:1"><h3>Change Failure Rate <span class="tag">lower = better</span></h3>{cfr}</div>
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1"><h3>Lead-Time Value-Stream Breakdown (18h total)</h3>{lt_break}
        <p class="note" style="margin-top:5px">Review + deploy-readiness are the largest stages — automation focus for next quarter.</p></div>
      <div class="card" style="flex:1.4"><h3>DORA by Squad</h3>
        <table><thead><tr><th>Squad</th><th>Deploy Freq</th><th>Lead Time</th><th>CFR</th><th>MTTR</th><th>Tier</th></tr></thead><tbody>{team_rows}</tbody></table>
        <p class="note" style="margin-top:5px">3 of 5 squads at Elite; Statements &amp; Mobile one tier from Elite — lead-time automation in flight.</p></div>
    </div>'''
    return page("Engineering Quality Scorecard", "DORA Delivery Metrics", status, meta, body,
                "Velocity with stability — Elite performer", 5)


# ============================================================================
# DASHBOARD 6 — EXECUTIVE QUARTERLY QUALITY REVIEW
# ============================================================================
def d6_executive_review():
    meta = '<b>Audience:</b> VP / CIO · QBR<br><b>Period:</b> Q2 FY26 (Apr–Jun)<br>'
    status = ('<div class="statuspill"><span class="dot" style="background:' + C["green2"]
              + '"></span>ON TRACK</div>')
    quarters = ["Q3'25", "Q4'25", "Q1'26", "Q2'26"]

    qindex = line_chart(quarters, [
        {"name": "Quality Index", "color": C["brand"], "values": [72, 78, 84, 89]}],
        w=380, h=150, ymin=60, ymax=100, area=True, target=85, target_label="Board target 85")

    rag = [
        ("Release Predictability", "94%", "green", "+9 pt"),
        ("Production Availability", "99.95%", "green", "SLO met"),
        ("Customer-Impacting Incidents", "4", "green", "-40%"),
        ("Escaped Defect Rate", "0.4/rel", "green", "-67%"),
        ("Automation Coverage", "78%", "amber", "+11 pt"),
        ("Security Posture (High+)", "2 open", "amber", "watch"),
        ("DORA Classification", "Elite", "green", "↑ from High"),
        ("Customer Quality NPS", "+61", "green", "+8"),
    ]
    rag_html = ""
    for n, v, c, d in rag:
        rag_html += (f'<div style="display:flex;align-items:center;justify-content:space-between;'
                     f'padding:6px 0;border-bottom:1px solid {C["grid"]}">'
                     f'<span style="display:flex;align-items:center;gap:8px;font-size:10.5px;font-weight:600;color:{C["slate"]}">'
                     f'<span class="dot" style="width:10px;height:10px;background:{C[c if c!="green" else "green2"] if c!="amber" else C["amber2"]}"></span>{n}</span>'
                     f'<span style="font-weight:800;font-size:11px" class="bignum">{v} '
                     f'<span class="badge b-{c}" style="margin-left:4px;font-size:8.5px">{d}</span></span></div>')

    outcomes = bar_chart(quarters, [4.1, 5.8, 7.9, 9.6], w=360, h=150, ymax=11,
                         color=C["green2"], yfmt="{:.0f}", yunit="M")

    body = f'''
    <div class="row">
      {kpi("Composite Quality Index", "89", unit="/100", sub="board target 85 · exceeded", trend="+5 QoQ", trend_dir="up", accent=C["brand"])}
      {kpi("Availability", "99.95", unit="%", sub="SLA honored · 0 breaches", trend="6 mo met", trend_dir="up", accent=C["green"])}
      {kpi("Customer Incidents", "4", sub="down from 8 last Q", trend="-40%", trend_dir="up", accent=C["teal"])}
      {kpi("Automation ROI", "$9.6", unit="M", sub="annualized cost avoidance", trend="+22%", trend_dir="up", accent=C["amber2"])}
      {kpi("Delivery Tier", "Elite", sub="DORA — top 18% industry", trend="↑ tier", trend_dir="up", accent=C["purple"])}
    </div>
    <div class="row" style="flex:1">
      <div class="card" style="flex:1.05"><h3>Composite Quality Index — 4 Quarter Trend</h3>{qindex}
        <p class="note" style="margin-top:3px">Blends DRE, availability, escaped-defect rate, automation &amp; DORA into one board-level score.</p></div>
      <div class="card" style="flex:1.1"><h3>Strategic Quality KPIs — RAG Status</h3>{rag_html}</div>
      <div class="card" style="flex:1"><h3>Business Outcome — Cost Avoidance ($M / quarter)</h3>{outcomes}
        <p class="note" style="margin-top:3px">Automation + early defect removal avoided <b>$9.6M</b> in rework, incident &amp; downtime cost this quarter.</p></div>
    </div>
    <div class="row" style="flex:.95">
      <div class="card" style="flex:1"><h3>Quarter Wins</h3>
        <ul class="clean">
          <li class="win">Achieved <b>DORA Elite</b> across the platform — first time in program history.</li>
          <li class="win">Cut customer-impacting incidents <b>40%</b>; zero Sev1 in 3 of 6 months.</li>
          <li class="win">Defect Removal Efficiency to <b>94%</b>; escaped defects down 82%.</li>
          <li class="win">Release predictability <b>94%</b> — 17 of 18 trains shipped on date.</li>
        </ul></div>
      <div class="card" style="flex:1"><h3>Risks &amp; Watch Items</h3>
        <ul class="clean">
          <li class="risk">2 high-severity security findings open — hotfix train committed for July.</li>
          <li class="risk">Mobile BFF error budget at 9% — reliability review scheduled.</li>
          <li class="watch">UI/E2E automation at 61% — investment case approved for Q3.</li>
        </ul></div>
      <div class="card" style="flex:1"><h3>Q3 Strategic Focus</h3>
        <ul class="clean">
          <li>Shift-left security: SAST/DAST gates blocking, target 0 high at release.</li>
          <li>Lift UI/E2E automation 61% → 75%; cut lead-time review stage in half.</li>
          <li>Phase 3 AI: LLM-assisted test generation &amp; flaky-test auto-triage pilot.</li>
          <li>Resilience: chaos-engineering program for top-7 services.</li>
        </ul></div>
    </div>'''
    return page("Executive Quarterly Quality Review", "Office of the VP — Quarterly Business Review",
                status, meta, body, "One-page VP/CIO strategic summary", 6)


# ----------------------------------------------------------------------------
BUILDERS = [
    ("01_release_readiness", d1_release_readiness),
    ("02_quality_trend", d2_quality_trend),
    ("03_automation_health", d3_automation_health),
    ("04_production_reliability", d4_production_reliability),
    ("05_dora_scorecard", d5_dora_scorecard),
    ("06_executive_review", d6_executive_review),
]

if __name__ == "__main__":
    for name, fn in BUILDERS:
        html = fn()
        p = os.path.join(OUT, name + ".html")
        with open(p, "w") as f:
            f.write(html)
        print("wrote", p)
    # combined single-file (all pages) for one-shot PDF
    combined = "\n".join(fn().replace('<!doctype html>', '').split('</body>')[0].split('<body>')[1]
                         if False else "" for _, fn in BUILDERS)
    print("done")
