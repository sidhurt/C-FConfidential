# SAP GUI Discovery and Automation Plan

## Objective

Build an evidence-backed model of Shree Cement's SAP processes and objects. GUI scripting is an optional collection adapter, not the project brain and not authorization to change SAP.

## Gate 0 — permission

Before any scripting:

- Basis/security confirms scripting policy and environment.
- Per-user and read-only constraints are preferred.
- Data may be stored only in an approved client workspace.
- No SAP credentials or session tokens are given to an AI model.
- Allowed transactions, data classes, rate limits, logging, and retention are documented.
- Write, activation, transport, configuration, and posting actions remain excluded unless separately approved.

## Prefer cleaner access first

Use, in order:

1. Standard/released APIs and metadata.
2. ADT/repository search for source and object relationships.
3. Approved exports or reports.
4. Deterministic SAP GUI scripting only where the information is GUI-bound.

## Manual discovery before automation

Trace one approved successful example for each relevant variant:

- trade and non-trade order;
- credit-free and credit-blocked;
- FTP and EX-works;
- delivery/DI;
- one-location/multiple-batch invoice;
- PGI/shipment/shipment cost/billing;
- E-Invoice/E-Way Bill success and error;
- STO/warehouse transfer;
- partial MIGO.

For every chain, record:

- transaction/display path;
- document type and keys;
- predecessor/successor;
- plant, storage location, batch;
- order/DI/open quantity;
- Incoterm, route, transporter;
- status and rejection messages;
- output/document identifiers;
- relevant custom fields;
- created/changed timestamps.

## Read-only discovery tasks suitable for scripting

- Capture System Status and component versions.
- Search repository/package/object inventory.
- Read SEGW runtime artifacts and registered service metadata.
- Open known DDIC/CDS/class/function objects.
- Read Gateway error/application log entries by correlation ID.
- Open named business documents and capture approved fields/status.
- Execute saved read-only reports/variants.
- Compare the same field across a controlled list of test documents.
- Produce a structured evidence record.

## Prohibited default tasks

- RZ11/profile/role changes.
- Object creation, save, activation, or transport release.
- BAPI write tests or business-document posting.
- Table maintenance or direct updates.
- Mass extraction of unrelated business data.
- Unattended scanning of the entire client.
- Sending screenshots or values to an unapproved external service.

## Proposed bounded tool surface

```text
sap.read_system_status()
sap.search_repository(query, object_types, package_scope)
sap.inspect_segw_project(project)
sap.read_service_metadata(service)
sap.read_gateway_error(correlation_id)
sap.display_document(document_type, key, approved_fields)
sap.run_saved_read_variant(report, variant)
sap.capture_evidence(test_id)
```

Each call records user, timestamp, environment, purpose, parameters, and result location.

## Extraction schema

```yaml
evidence_id:
purpose:
environment:
transaction_or_object:
business_key_masked:
fields:
  - name:
    value:
    meaning:
source_screen:
captured_at:
operator:
confidence:
related_requirement:
```

## First SAP discovery mission

Once formal scope exists:

1. Identify the real SAP object behind DI.
2. Trace one DI to PGI, shipment, shipment cost, billing, accounting, and e-document status.
3. Record the KDS/master fields that determine the path.
4. Validate which standard API can reproduce the approved step.
5. Do not automate beyond this vertical slice until the evidence model is correct.

