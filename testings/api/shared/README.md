# API Shared

Cross-protocol layer used by rest/, graphql/, grpc/, websocket/, soap/:
auth handling, base request/client builders, shared fixtures, models, utils,
and config. Protocol folders should hold protocol-specific tests and
schema/contract validation only — not their own copies of these concerns.
