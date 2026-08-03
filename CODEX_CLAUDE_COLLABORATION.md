# Codex–Claude Collaboration Model

## One shared brain

Codex and Claude must not maintain competing memories. Both read and update the same evidence model, registers, IDs, decisions, and open questions in an approved workspace.

## Suggested division

### Claude

When approved tools/sessions are available:

- assist with interactive reading of meeting material and browser-based Datasphere metadata;
- capture structured evidence with exact object names and source locations;
- compare screens/models against approved requirements;
- propose questions and hand observations to the shared repository.

Claude does not receive raw credentials or unrestricted SAP/Datasphere control.

### Codex

- maintain the repository, schemas, registers, and implementation traceability;
- analyze ABAP source and repository structures through approved access;
- draft ABAP class designs, SEGW models, CPI contracts, tests, and documentation;
- validate consistency across requirements, code, and evidence;
- prepare bounded automation scripts and changes for human review.

### Siddharth

- remains accountable for client policy, SAP semantics, approvals, system actions, and final engineering decisions;
- operates or approves the system interaction;
- confirms what may be provided to each model;
- resolves ownership with functional, CPI, Datasphere, Basis, and management teams.

## Handoff protocol

Every agent task ends with:

```text
Task ID:
Evidence read:
Facts added:
Inferences/hypotheses:
Conflicts:
Files/registers changed:
Questions for owners:
Proposed next action:
Approval needed:
```

The receiving agent verifies source IDs before relying on conclusions.

## Review loop

```text
Meeting/system evidence
  → Claude/Codex extraction
  → shared repository update
  → second-agent consistency review
  → Siddharth/owner validation
  → approved design
  → implementation draft
  → human-approved execution
  → test evidence
  → brain update
```

## Do not do

- Do not let an agent “scrape the whole system” without a business purpose and approved scope.
- Do not paste client secrets or session state between agents.
- Do not allow one agent to convert the other's inference into a verified fact.
- Do not generate implementation from meeting prose without functional confirmation.
- Do not automate SAP writes merely because the GUI path has been learned.

