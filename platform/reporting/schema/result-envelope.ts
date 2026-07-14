// Common result envelope every testing engine adapter maps its native
// report into. Universal fields for aggregation/gating; `metrics` carries
// whatever is engine-specific (k6 p95 latency, ZAP alert counts by
// severity, accessibility violation count, etc.) without forcing it into
// fixed columns.

export type TestStatus = "pass" | "fail" | "skip" | "error";

export interface ResultEnvelope {
  runId: string;            // shared correlation ID for a CI run (platform/orchestration)
  engine: string;           // e.g. "gui-playwright", "security-zap", "performance-k6"
  suite: string;            // suite/test name
  status: TestStatus;
  durationMs: number;
  timestamp: string;        // ISO 8601
  environment: string;      // e.g. "staging", "sandbox"
  buildRef: string;         // commit SHA / build ID
  tags?: string[];          // free-form; reserved namespace e.g. "compliance:pci-dss:6.5.1"
  nativeReportRef?: string; // path/URL to the full native report artifact
  metrics?: Record<string, unknown>; // engine-specific data
}
