# AI Operating Rules

These rules apply to Codex, Claude, and any other AI using this repository.

## Default mode: plan and draft only

Until Siddharth provides explicit approval for a named action:

- understand and classify evidence;
- update registers;
- ask prioritized questions;
- produce designs, plans, drafts, synthetic examples, and test cases;
- do not change SAP, Datasphere, CPI, Commerce, files outside the approved workspace, roles, parameters, destinations, or transports.

Approval for one action does not imply approval for later or broader actions.

## Evidence discipline

- Never present a hypothesis as fact.
- Cite source ID and location for material claims.
- Separate observation, interpretation, and implication.
- Prefer current authoritative documents and system evidence over conversation memory.
- Record conflicts instead of choosing the convenient version.
- Treat proposed object and BAPI names as candidates until system-verified.

## Scope discipline

Focus on:

- S/4HANA source and document analysis;
- Datasphere source lineage relevant to interfaces;
- ABAP classes and released APIs/BAPIs;
- SEGW/OData V2;
- CPI-facing contracts;
- errors, logs, correlation, idempotency;
- authorization and tests;
- team boundaries.

Frontend/UI implementation is out of scope.

## Safety and governance

- Never enable SAP GUI scripting or change RZ11/profile parameters.
- Never modify roles or authorizations.
- Never store or reveal credentials, tokens, cookies, certificates, or SSO artifacts.
- Never send client code, documents, screenshots, payloads, or business data to an unapproved external model.
- Never use personal devices/accounts to bypass client controls.
- Never post, cancel, release, activate, transport, mass-update, or delete without specific approval.
- Treat DEV as controlled; it is not disposable.
- QAS and PRD writes require separate, explicit authority.

## Tool design

If system automation is later approved, expose narrow tools:

```text
read_system_status
search_repository
inspect_object
read_gateway_metadata
read_gateway_error
run_named_read_test
prepare_code_draft
prepare_test_plan
```

Write tools must be individually gated, target-scoped, logged, and human-approved. An agent never receives unrestricted GUI or shell authority merely because scripting is enabled.

## Data minimization

- Use synthetic examples in drafts.
- Mask business identifiers where permitted and necessary.
- Collect only fields required for the assigned workflow.
- Store evidence only in approved locations.
- Do not browse sensitive tables without a defined purpose.

## Change rule

Before any approved change, report:

- exact target;
- reason and linked requirement;
- expected effect;
- risk;
- validation;
- rollback/recovery;
- transport.

Afterward, report only verified results and update the registers.

## Stop conditions

Pause and request direction when:

- ownership is disputed;
- business intent is not signed off;
- the source system is unclear;
- a write could create financial/logistical state;
- credentials or sensitive data would cross an unapproved boundary;
- the proposed change expands beyond the assigned interface;
- evidence conflicts materially.

## Master-plan instruction

When this repository and original documents are first provided, do not act. Produce a master plan that:

1. inventories sources and evidence quality;
2. maps systems, teams, capabilities, and boundaries;
3. classifies every candidate interface;
4. identifies source-of-record and ownership gaps;
5. prioritizes questions and first vertical slice;
6. proposes a safe discovery, design, build, and test sequence;
7. identifies what requires human or Basis/functional approval.

