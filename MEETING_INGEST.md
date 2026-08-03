# Meeting and Source Ingest

## Goal

Convert every meeting or document into updates to one evolving project model. Do not create isolated summaries that are never reconciled.

## Intake procedure

1. Save the source only in an approved client workspace.
2. Assign a source ID: `SRC-YYYYMMDD-NN`. Use `SRC-SID-YYYYMMDD-NN` specifically for a direct statement Siddharth makes in an AI conversation (as opposed to a meeting transcript or document).
3. Record title, date, participants/owners, source type, sensitivity, and location.
4. Extract observations without interpretation.
5. Separate interpretations and implications.
6. Label confidence and cite the source.
7. Update affected registers.
8. Add conflicts and open questions.
9. Record decisions only if an authorized owner made them.
10. Produce a concise next-action list.

## Source index

| Source ID | Date | Type | Title | Owner | Approved location | Sensitivity | Ingested |
|---|---|---|---|---|---|---|---|
| SRC-CONTEXT-001 | 2026-07 | Conversation context | Prior architecture and document summaries | Siddharth | This repository context | Client-sensitive | Partial |
| SRC-BRD-001 | TBD | BRD | C&F Agent Operations Interface BRD | Business | Attach approved original | TBD | Pending original |
| SRC-TECH-001 | TBD | Technical spec | ABAP FM + OData V2 proposal | Technical team | Attach approved original | TBD | Pending original |
| SRC-CPI-001 | TBD | Workbook | CPI interface inventory | Integration team | Attach approved original | TBD | Pending original |
| SRC-MTG-20260728-01 | 2026-07-28 | Transcript/translation | Design walkthrough: DI and invoice creation | Meeting participants | User-supplied local source | Client-sensitive | Ingested |
| SRC-MTG-20260728-02 | 2026-07-28 | Transcript/translation | Invoice management and E-Way Bill | Meeting participants | User-supplied local source | Client-sensitive | Ingested |
| SRC-MTG-20260728-03 | 2026-07-28 | Transcript/translation | Freight and Edit DI discussion | Meeting participants | User-supplied local source | Client-sensitive | Ingested; low audio confidence |
| SRC-MTG-20260728-04 | 2026-07-28 | Transcript/translation | SAP SD knowledge-gap side conversation | Meeting participants | User-supplied local source | Client-sensitive | Ingested |
| SRC-MTG-20260728-SUM | 2026-07-28 | Summary | Meeting summary across four recordings | Derived | User-supplied local source | Client-sensitive | Ingested |
| SRC-TECH-001 | 2026-07 | Technical spec | SAP ABAP & OData Technical Specification v1.0 | SAP Development Team (author/approver unstated) | User-supplied local source | Client-sensitive | Ingested 2026-07-29 |
| SRC-SID-20260729-01 | 2026-07-29 | Direct statement | DI terminology: "DI is just delivery, DI no. means delivery number" | Siddharth | This conversation | Client-sensitive | Ingested |
| SRC-MTG-20260803-01 | 2026-08-03 (inferred from file mtime — confirm) | Recording + transcript/translation | UI/UX design walkthrough: DI quantity edit, transporter/shipping type, invoice generation, Document Flow, reports, dashboard, screen-level source mapping | Meeting participants (4 speakers, roles inferred) | User-supplied local source — `Morecontext.m4a` + `.hi.txt` / `.en.txt` / `.sarvam-raw.json` | Client-sensitive | Ingested 2026-08-03 |
| SRC-SID-20260803-01 | 2026-08-03 | Direct statement | Instruction to use Sarvam AI to transcribe/translate client meeting audio | Siddharth | This conversation | Client-sensitive | Ingested — see D-008 |
| SRC-SID-20260803-02 | 2026-08-03 | Direct statement | Relayed answers from closed-door meetings: sales orgs 1000/1300, KDS = Key Data Structure, business segment 10 = trade, DI predecessor is both SO and STO, storage location immutable at DI creation, available stock = usable stock, transport is SAP standard, FTP/EX are different Incoterms, ODN used at invoice creation, IRN cancel → invoice recreated (24h window then credit memo), sequence is staged with some automation | Siddharth (relaying — he was not present in those meetings) | This conversation | Client-sensitive | Ingested — confidence preserved as stated; several items explicitly hedged by the relayer |
| SRC-DOC-20260803-01 | 2026-08-03 | Mapping document | `CNF_Feature_to_SAP_Mapping_Updated.docx` — feature → SAP table/T-code mapping across Login & Authorisation, Common Masters & KDS, Functionalities (MIGO, DI, Invoice, e-Invoice/e-Way, STO), Visibilities (8 reports), KDS Reference Index | Client SAP/functional team | User-supplied local source (`C:\Users\sidmy\Downloads\`) | Client-sensitive | Ingested 2026-08-03 |
| SRC-DOC-20260803-02 | 2026-08-03 | KDS workbook | `CNF_Feature_to_SAP_Mapping_Updated.xlsx` — 11 sheets of actual code values: SPI↔Sloc (`ZLETSPIMAP`), Plant↔Sloc (T001L), Sales area↔plant (TVKWZ), Sales area↔sales office (TVKBZ), Incoterm↔plant (ZISP condition), Customer group (T151), Vendor/customer master, Material Groups 1–5 (TVM1–TVM5), Nielsen Indicator, Material Freight Group (TMFG) | Client SAP/functional team | User-supplied local source | Client-sensitive | Ingested 2026-08-03 — **this is the KDS artifact V-12/Q-021 was asking for** |
| SRC-ARCH-20260803-01 | 2026-08-03 | Architecture deck | `CNF_Architecture_Optionsv1.2.pptx` — three DSP data-integration options (A: live DSP query + OCC cache; B: Hybris-managed persistent store + scheduled sync; C: direct T1/CRM query + scheduled DSP sync). **Option C selected** | Technology Architecture, Shree Cement | User-supplied local source | Client-sensitive | Ingested 2026-08-03 — see D-014 |

## Evidence object

```text
Claim:
Confidence:
Observation / interpretation / implication:
Source ID and location:
Speaker/owner:
Scope/environment:
Effective date:
Conflicting evidence:
Validation target:
Registers updated:
```

## Meeting output

Every meeting should yield only:

- confirmed requirements;
- decisions;
- changed terminology;
- source/ownership facts;
- process changes;
- risks;
- action items;
- open questions;
- confidence updates.

Use `templates/meeting-notes.md`.
