# Meeting Notes — UI and Process Walkthrough

- **Source ID:** `SRC-MTG-20260810-01`
- **Date/time:** 2026-08-10; 29m 19s
- **Participants and roles:** Four diarized speakers (`S0`–`S3`). Names and roles are not mapped to speaker IDs.
- **Decision owner(s):** Not established from the recording
- **Topic/workflow:** Shipment and invoice screens, MIGO/MRN, E-Way correction and extension, STO, physical inventory reconciliation, visibility, and dashboard behavior
- **Recording/transcript location:** `Chaayos 11.m4a` outside the repository; `../sources/SRC-MTG-20260810-01_transcript.hi.txt`, `.en.txt`, `.raw.json`, and `.raw.en.json`
- **Transcription method:** Sarvam AI batch STT, `saaras:v3`, independent `transcribe` (`hi-IN`) and `translate` passes, both diarized and timestamped
- **Sensitivity:** Client-sensitive

## Reading guidance

This is Tier-4 meeting evidence. It proves what anonymous participants said, not that the business approved it. The two Sarvam passes were cross-read; timestamps below use the English diarized pass. Do not map speaker IDs to the names mentioned in conversation.

Frequent ASR artifacts: `STP` → FTP; `voice management` → Invoice Management; `MeeGo` → MIGO; `MRM` / `MRI` / `MRL` → MRN; `BID` / `BRT` → BRD; `EPO` / `EP` → ePOD; `built quantity` → Billed Quantity. The phrase equating FTB with stock transfer at `22:40` is not normalized: it conflicts with the documented FTB meaning and may be a speaker slip rather than ASR.

## Purpose

Walk through the current portal design and give the delivery, integration, and data teams enough process context to map screens and fields to their interfaces.

## Observed statements

| Observation | Speaker/source | Affected item |
|---|---|---|
| Transporter search is by code or name. The user validates the selection before a freight estimate/amount and Proceed to Shipment. | `S3`, `00:00–00:24` | Transporter master; API-05 |
| Shipping term/Incoterm is set upstream when the dealer places the order, shown prefilled across screens, and is not editable in the portal even though SAP permits a change. | `S1`/`S3`, `00:25–00:50` | Q-022, Q-034; shipment payload |
| After LR/GR, vehicle, driver name, and driver mobile are entered, one user action starts PGI, invoice, and E-Way processing. Document Flow can show completed document numbers, failure, or Processing because some backend steps run asynchronously. | `S1`/`S3`, `00:51–02:09` | Q-008, Q-026, Q-035 |
| Generated Invoices contains only zero-error/happy-path records; the second Invoice Management tab is Details Correction. | `S1`/`S3`, `03:36–04:05` | Q-035 failure/retry surface |
| The MRN discussion contradicted itself. One explanation placed MRN before MIGO; the later correction described MIGO as the inward-receipt process and said Pending MRN is not a separate number—the report uses PO, DI, and invoice references. | `S3`/`S1`, `04:10–06:04` | C-14; Q-004; D-021 remains authoritative |
| Invoice-detail correction was described as available for 24 hours after invoice creation, principally for a wrong vehicle number. The earlier user-facing invoice-cancellation feature has been removed from the design. | `S1`, `06:10–07:47` | Q-042/Q-055; invoice/e-document scope |
| Part A/B correction exposes vehicle and distance; transporter ID/name is prefilled from the transporter master. Participants said the flow and editable fields exist in SAP but also requested full verification. | `S1`/`S2`/`S3`, `08:40–09:57` | API-08; Q-055 |
| An updated invoice/e-invoice is intended to reach the driver by SMS, but the trigger is described both as Continue and as Update. | `S1`/`S3`, `10:01–11:10` | Notification contract, retry, audit, PII |
| E-Way extension is searched by DI or invoice and captures current/from location, state, PIN, reason code, remarks, and—when needed—a replacement vehicle. The meeting described repeatable 24-hour increments. | `S1`/`S3`, `11:15–13:55` | API-09; D-003/D-035; Q-055 |
| The portal is intended to move existing SAP operations behind APIs and simpler screens. | `S2`/`S3`, `14:07–14:22` | SAP/portal boundary |
| STO/intra-warehouse movement was both deferred as “later/not needed right now” and then walked through as PO/STO → DI → batch/transporter → the normal fulfillment flow. | `S1`/`S3`, `14:38–16:43` | Q-006; Q-031 |
| Physical Inventory Reconciliation is not performed in SAP today. SAP supplies system stock; the portal captures warehouse, reconciler, product/storage-location bag counts, calculates variance, requires a reason, and retains audit history. Whether Post adjusts SAP was not stated. | `S1`/`S2`/`S3`, `16:49–19:34` | Q-017; inventory SoR |
| Visibility remains in progress. Reports are filterable and exportable to Excel; data visualization is described as separate command-center work. | `S1`/`S2`/`S3`, `20:20–21:55` | Reporting scope; frontend boundary |
| Dashboard definitions include STO in transit (count and MT), credit-free pending orders (not credit-blocked), In Process (DI exists, invoice does not), Billed Quantity, stock ageing, and ePOD. ePOD is code/OTP-like proof of delivery, is not active at many warehouses, and has no agreed validation design. | `S1`/`S3`, `22:02–24:17` | Q-036; Q-056; glossary |
| Stock-ageing freshness is corrected within the discussion from “real time” to D-1/day-wise. | `S1`/`S2`/`S3`, `24:20–24:48` | D-014; SoR matrix |
| Dashboard stock can be stale and is display-only. At fulfillment, live system stock and batch determination block progress if stock is unavailable. | `S1`/`S3`, `25:09–26:02` | Q-014; Q-038 |
| A CNF user can have multiple assigned warehouses and select several for the working view. Notifications cover new pending orders, STOs, and Pending MRNs; display retention is configurable but backend retention is unspecified. | `S1`/`S2`/`S3`, `26:15–27:03` | Q-007; authorization; audit |
| Per-screen validations and return messages are said to exist in the BRD, which the team is mapping to Figma. The prototype is incomplete. | `S1`/`S3`, `27:44–29:09` | `SRC-BRD-001`; acceptance criteria |

## Interpretations

| Interpretation | Confidence | Supporting observations | Validation |
|---|---|---|---|
| Display stock and transactional availability are different products: DSP/portal data may inform a user, but SAP-side batch validation must govern allocation. | Strong inference | `25:09–26:02`; consistent with D-014 and Q-038 | Confirm exact stock semantics and API-04 read path with MM/SD/architect |
| The invoice journey is not proven atomic or wholly synchronous. The UI explicitly supports Processing and failure, while Generated Invoices contains only successes. | Strong inference | `01:43–02:09`, `03:36–04:05` | Measure Q-032; define Q-035 retry surface |
| The current verified MRN model should not change. The meeting’s conflicting expansions and timing descriptions are lower-tier than the report source code behind D-021. | Verified evidence precedence | `04:10–06:04`; D-021 | Resolve the API response identifier under Q-004/C-14 |
| Physical reconciliation is portal-led, but the authoritative posting/approval outcome is still unknown. | Strong inference | `16:49–19:34` | MM/business to answer Q-017 |
| `1 bag = 0.05 MT` is a screen assumption, not a safe universal conversion rule. | Hypothesis/risk | `18:08–18:41`; pack type varies in KDS | Validate material UoM conversion with MM/material owner |

## Decisions

No statement is promoted to `DECISION_LOG.md`: speaker identity, authority, and business sign-off are not established. The removal of the invoice-cancellation screen and deferral of STO are recorded as design/scope positions requiring owner confirmation.

## Requirements changed or sharpened

- Shipping term is upstream and read-only in the portal.
- Document Flow needs success, failure, and processing states with document-number/PDF access.
- Generated Invoices is a success-only surface; a failed-invoice recovery surface remains unspecified.
- Invoice/E-Way correction, SMS delivery, and cancellation/regeneration need one explicit trigger and audit contract.
- Physical reconciliation needs material-UoM conversion, reason capture, approval/posting ownership, and an audit system of record.
- ePOD needs an owner, source, code-generation/validation mechanism, and warehouse rollout decision.
- Multi-warehouse assignment is an authorization input, not merely a UI filter.

## Terminology

| Term | Client meaning | Confidence |
|---|---|---|
| ePOD | Electronic Proof of Delivery; code/OTP-like completion validation for a receiving party | Meeting-supported; design and rollout unresolved |
| In Process order | DI created, invoice not yet created | Meeting-supported design meaning |
| Pending MRN | A pending receipt position, not a separate “pending MRN number” | Later meeting correction; D-021/source code remains authoritative |

## Open questions and actions

| Priority | Question/action | Owner |
|---|---|---|
| Critical | Obtain the approved, versioned BRD and ingest it as `SRC-BRD-001`; it is reported to exist and contain validations/return messages. | BA / Product / Siddharth |
| High | Confirm whether removing invoice cancellation removes only a screen or also API-08/backend cancel-regenerate scope. | Product / Tax / SD / Architect |
| High | Confirm whether STO is deferred from the MVP or only from the current onboarding/build sequence. | Business / Product / Architect |
| High | Define the failed-invoice retry/recovery surface and measure the invoice chain. | SD / Architect / CPI |
| Medium | Define ePOD source, code validation, persistence, and warehouse activation. | Business / Product / Commerce |
| Medium | Define correction-SMS trigger, content, retry, audit, and PII handling. | Product / CPI / Security |
| Medium | Validate statutory distance authority and the material-specific bag-to-MT conversion. | Tax / MM |

## Registers updated

`MEETING_INGEST.md` · `sources/README.md` · `PROJECT_BRAIN.md` · `OPEN_QUESTIONS.md` · `DOMAIN_GLOSSARY.md` · `SYSTEM_OF_RECORD_MATRIX.md` · `HANDOVER_AI.md`
