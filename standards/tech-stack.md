# Tech Stack Standards

- Testing engines / tools: TypeScript 7.0.2 (native/tsgo compiler) + Playwright
- Infrastructure: Terraform (IaC)

Update this file as stack decisions are made for other layers (CI/CD, dashboards, AI layer).

Every TypeScript project in this repo extends the root `tsconfig.base.json`
and shares the root `.vscode/settings.json` (enables tsgo) — see the
"TypeScript" section of the root `README.md` and `CLAUDE.md`.

## API Protocol Tooling (TBD)

Base stack is TypeScript. Per-protocol libraries still to be decided:
- REST: TBD (e.g. supertest / axios)
- GraphQL: TBD (e.g. graphql-request / Apollo)
- gRPC: TBD (e.g. @grpc/grpc-js)
- WebSocket: TBD (e.g. ws)
- SOAP: TBD (e.g. soap / strong-soap)

Playwright is not used for protocol-level API testing — reserved for GUI/visual.

## GUI Automation (two stacks)

- Web GUI (primary): TypeScript + Playwright (testing/gui/playwright)
  - Mobile web (responsive, emulated): Playwright device emulation (testing/gui/playwright/mobile-web)
- Web GUI (secondary/legacy) + native mobile: Python + Robot Framework (testing/gui/robot)
  - Web: robotframework-browser (Playwright-based, NOT SeleniumLibrary)
  - Native iOS/Android: AppiumLibrary
