# k6

- scripts/     — load, stress, spike, and soak test scripts.
  scripts/login_load_test.js migrated from temp/tests/performance/k6/ —
  login transaction under concurrency (smoke/load/stress profiles via
  -e PROFILE=). Run via: ./scripts/run_k6.sh [smoke|load|stress]
- thresholds/  — SLA / pass-fail criteria definitions (response time, error rate, etc.).
  Currently inline in each script's `options.thresholds` (see login_load_test.js) —
  empty for now, revisit if/when thresholds need to be shared across scripts
  instead of duplicated per-file.
- reports/     — generated scan/run output (artifacts, not source-controlled long-term)
- shared/      — data generators, request builders, utils shared across scripts

Runs inside the qa-platform-k6-runner container (official grafana/k6 image,
provisioned by infrastructure/modules/runner-k6). That module sets
`working_dir = "/qa-platform"` on the container explicitly — the stock
grafana/k6 image's own WORKDIR is /home/k6, not our mount point, so without
it `docker exec ... k6 run scripts/<file>.js` (a relative path) would fail
to find the script.

## grafana/k6's baked-in ENTRYPOINT

The image ships with `ENTRYPOINT ["k6"]`. Setting `entrypoint = []` in
Terraform to clear it doesn't reliably work with the docker provider — the
container's `command` (`tail -f /dev/null`, meant to keep it idle) ends up
appended AFTER the image's entrypoint instead of replacing it, so it
actually tries to run `k6 tail -f /dev/null`, which k6 rejects as an
unknown subcommand and crash-loops forever (exit 255,
`unknown command "tail" for "k6"` in `docker logs`).
Fixed in runner-k6/main.tf by overriding entrypoint to `["tail"]` directly
and moving the args into `command = ["-f", "/dev/null"]`, instead of trying
to blank the entrypoint out. `docker exec ... k6 run ...` (how tests are
actually launched) invokes `k6` directly regardless of the container's own
PID 1, so this doesn't affect test runs.

## practice.expandtesting.com's anti-bot defenses are time-window based, not tied to any script/executor detail

This took several rounds of debugging, and it's worth recording what was
actually ruled out so nobody re-chases the same dead ends. Definitively
NOT the cause: proxy env vars (none present), the Docker network being
`internal` (it isn't — plain bridge, other containers on the same network
reach the internet fine), DNS/IPv6 issues (a plain `curl` from the host
and a k6 run against httpbin.org both worked normally, real bytes
transferred), VU concurrency (a 1-VU `stages` run failed 100% just like a
2-VU one), the `ramping-vus` vs `shared-iterations` executor choice, and
the `--summary-export` flag — every one of these was tested head-to-head
with an otherwise-identical run, and every one of them showed the SAME
scenario config passing cleanly at one moment and failing 100% (instant
`dial: connection refused`, 0 bytes, every request refused from the very
first one) minutes earlier or later.

The actual pattern: this target has anti-automation defenses that appear
to key off recent request volume/cadence from the source IP within some
rolling time window, not any structural detail of how the traffic is
generated. During active debugging we hit this endpoint dozens of times in
rapid succession (on top of the ZAP/Nikto/Nmap scans against the same
target earlier in the security gate work — see
testings/security/README.md, which already documented this site cutting
off Nikto's scan early for the same reason). That's very likely what kept
the window "hot." A single isolated run, spaced out from other traffic,
consistently passes.

Consequence: there's no code fix for this — `smoke` (1 VU, 3 fixed
iterations via `shared-iterations`, no time-based ramp) is a reasonable,
minimal-footprint sanity check, but expect it to occasionally fail against
this specific public demo target if run back-to-back with other traffic
against the same site (including re-runs of this same script). If it
fails, wait a few minutes before retrying rather than treating it as a
regression. `load` and `stress` stay on `ramping-vus` at their originally
intended VU counts (5 and 15) — they were never expected to survive
against a shared public demo site; point `BASE_URL` at an environment you
control before running those for real.
