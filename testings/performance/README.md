# Performance Testing

- k6/  — load/stress/spike/soak testing engine (built out below). Concurrency-
  level testing: many virtual users hitting the login flow at once.

Single-user page-load and transaction-timing budgets (TTFB, DOMContentLoaded,
login SLA) live as a Robot Framework suite instead, alongside the other
Browser-library GUI suites:
testings/gui/robot/web/tests/performance/login_performance.robot — it needs a
real browser to read Navigation Timing metrics, so it rides the same
qa-platform-robot-web-runner container as smoke/, rather than living under
this folder. Run it via: ./scripts/run_robot_web.sh performance

Think of the two as counterparts: the k6 script here measures behavior under
load, the Robot Framework suite measures one user's actual experience.

Note: distributed load generation (k6 running across multiple nodes/pods,
e.g. via k8s) is an infrastructure concern — revisit when building out
infrastructure/, similar to the mobile device farm note under GUI.
