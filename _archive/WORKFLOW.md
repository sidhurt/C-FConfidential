# Co-work Workflow

## Phase 0 — Understand

AI reads the repository and newly supplied evidence. It produces:

- what changed;
- verified facts;
- strong inferences;
- hypotheses;
- contradictions;
- prioritized questions;
- affected registers.

No implementation action occurs.

## Phase 1 — Classify the assignment

For a formal request, establish:

1. Business intent and acceptance criteria.
2. Operational command, operational read, or analytical read.
3. Source/target systems.
4. System of record for every important field.
5. Primary owner and collaborators.
6. Real-time/latency need.
7. Existing standard API or object.

Output: completed interface-discovery record.

## Phase 2 — Discover SAP and Datasphere evidence

Using approved, primarily read-only access:

- trace one successful business document flow;
- inspect relevant standard APIs, CDS entities, DDIC, enhancements, authorizations, and logs;
- inspect Datasphere lineage, grain, latency, and exposure;
- capture contradictions against the requirement.

Output: evidence-backed source model and validation questions.

## Phase 3 — Design

Prepare:

- API design;
- internal class boundaries;
- BAPI/released API validation;
- CPI contract;
- errors;
- logging/correlation;
- idempotency and retry;
- authorization;
- test matrix;
- transport/deployment dependencies.

AI may draft. Humans approve.

## Phase 4 — Implement in DEV

Only after explicit authorization:

- create/change approved objects;
- keep Gateway methods thin;
- implement reusable classes;
- run syntax/unit checks;
- record all changes and transports.

AI does not activate, register, release, or post unless that exact bounded action is separately authorized and policy permits it.

## Phase 5 — Verify

Layered test order:

1. Standard API/BAPI in a safe test.
2. Application class.
3. SEGW/Gateway request.
4. Authorization and negative cases.
5. Retry/idempotency and concurrency.
6. CPI end-to-end message.
7. Resulting SAP document.
8. Datasphere reconciliation when relevant.

Store evidence using `templates/test-evidence.md`.

## Phase 6 — Handoff and preserve memory

Update:

- requirements matrix;
- interface register;
- decision log;
- open questions;
- BAPI record;
- API contract;
- operational support route.

Explain what was verified, what remains uncertain, and who owns follow-up.

## Interaction pattern with AI assistants

Use requests such as:

> Ingest these approved meeting notes. Update project memory, separate facts from interpretations, show conflicts, and propose questions. Do not propose code yet.

> For IF-002, create a design dossier using verified evidence only. Mark missing information and produce a draft contract. Do not modify SAP.

> Analyze this synthetic BAPI test result against the approved acceptance criteria. Produce likely causes and the next read-only checks.

Avoid:

> Build everything.

> Click around SAP until you understand it.

> Use whatever data you can find.
