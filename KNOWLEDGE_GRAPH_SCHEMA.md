# Knowledge Graph Schema

The first implementation may be Markdown/CSV/JSON rather than a graph database. The schema defines how evidence is related regardless of storage technology.

## Core entity

```yaml
id: stable-id
type: Requirement|Term|Rule|Process|System|Owner|Code|Document|Field|SourceObject|Interface|Implementation|Decision|Question|Test|Incident|Evidence
name: human-readable name
description: concise meaning
confidence: Verified|StrongInference|Hypothesis|Contradicted|Unknown
owner: team/person
environment: Global|DEV|QAS|PRD|Datasphere-space
effective_date: YYYY-MM-DD
source_ids: []
last_validated: YYYY-MM-DD
status: candidate|approved|implemented|retired
```

## Relationship

```yaml
from: entity-id
relation: REQUIRES|CREATES|READS|REPRESENTED_BY|SOURCED_FROM|DERIVED_FROM|CALLS|CONSUMES|OWNS|DECIDES|SUPPORTS|CONTRADICTS|VERIFIES
to: entity-id
confidence: Verified|StrongInference|Hypothesis|Contradicted|Unknown
source_ids: []
notes: ""
```

## Required views

### Workflow view

Business trigger → process steps → SAP documents → statuses → downstream consumers.

### Field lineage view

Portal field → CPI mapping → OData property → ABAP/internal field → SAP source/API → Datasphere representation.

### Ownership view

Requirement or object → decision owner → implementation owner → support owner.

### Evidence view

Claim → source → speaker/system → confidence → conflicts → validation target.

### Implementation view

Requirement → interface → SEGW method → service class → SAP API/query → test evidence.

## Ingestion rule

AI may propose graph updates. It must not merge two terms or codes solely because their labels look similar. Ambiguous acronyms such as SPI, GD/GDF, DTP, ODN, and KDS remain separate unknowns until verified.

