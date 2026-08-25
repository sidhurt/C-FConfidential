# Meeting Notes — MIGO and Order-Fulfilment Alignment

- **Source ID:** `SRC-MTG-20260810-02`
- **Date/time:** 2026-08-10; 28m 17s of diarized speech
- **Participants and roles:** Five diarized speakers (`S0`–`S4`). Several people are addressed or mentioned, but identities are not mapped to speaker IDs.
- **Decision owner(s):** Not established from the recording
- **Topic/workflow:** MIGO and order-fulfilment business context, field lineage, T1/T2/DSP/CPI/SAP flow, and immediate SAP API scope
- **Recording/transcript location:** `New Recording 20.m4a` outside the repository; `../sources/SRC-MTG-20260810-02_transcript.hi.txt`, `.en.txt`, `.raw.json`, and `.raw.en.json`
- **Transcription method:** Sarvam AI batch STT, `saaras:v3`, independent `transcribe` (`hi-IN`) and `translate` passes, both diarized and timestamped
- **Sensitivity:** Client-sensitive

## Reading guidance

This is Tier-4 meeting evidence. Timestamps use the source-language diarized pass where the two passes differ. No statement is attributed to a named person unless the name is explicitly spoken; a spoken name is not a speaker-ID mapping.

Frequent ASR artifacts: `MeeGo` / `Bego` / `ego` → MIGO; `MRM` / `MRI` / `MRL` → MRN, but its expansion is genuinely disputed; `Highbrisk` / `high brace` → Hybris; `SCPI` / `SEPI` / `SIPI` → CPI; `Titu` → T2; `D1` in the invoice-return passage → T1; `BRT` / `BID` → BRD; `Sigma` → Figma; `STU` → STO; `plan/store/soaring location` → plant-to-storage-location.

## Purpose

Test whether the delivery team can connect screen behavior and every request attribute to the business process and owning system before development starts.

## Observed statements

| Observation | Speaker/source | Affected item |
|---|---|---|
| The team is expected to explain when each API is called and the source/meaning of every mapped request attribute, not only expose endpoints. | `S0`, `00:32–01:23` | Field lineage; acceptance criteria |
| Plant-to-storage-location mapping is used during MIGO to allocate inward quantity across storage locations; treating it only as an MRN report filter is rejected. | `S0`/`S3`/`S4`, `01:32–03:19` | API-02 payload; Q-004 |
| Figma and BRD review are mandatory. The immediate working focus is two end-to-end processes: MIGO and order fulfilment, at attribute-level detail. | `S0`, `05:11–06:24` | Q-006; delivery sequence |
| Participants report that the BRD exists, was shared with team members, and has been studied. CPI is said to be configured; two Cloud Connector instances are relayed but not system-verified. | `S2`/`S3`, `06:27–07:50`, `25:11` | `SRC-BRD-001`; landscape validation |
| The CNF user’s two primary operational jobs are receiving inbound goods and fulfilling customer orders. | `S0`, `10:03–10:22` | Project model |
| The receipt flow is described as an STO/plant-to-depot movement. Users see only records assigned to their depot/plant, with movement, delivery, vehicle, material, and quantity details. | `S0`, `10:32–12:20` | Q-004; authorization |
| The dominant speaker calls MRN/MRM “Movement Reference Number,” conflates it with MIGO, and later expects an MRN number immediately from Submit MIGO. | `S0`, `10:52–11:11`, `27:30–27:43` | C-14; API-02 response |
| Receipt work items have Pending, Completed, and Partial states. A receipt can be split over time and allocated to storage locations including usable, damaged/cut-and-torn, and shortage buckets. | `S0`, `12:20–13:30` | API-02 request/status model |
| Intended read/write loop: Pending MRN data reaches Hybris from DSP; the frontend queries Hybris; Initiate MIGO retrieves plant storage locations; Submit MIGO posts to SAP; SAP data later syncs through DSP and the portal shows Completed. | `S0`, `13:30–14:32` | D-014; C-12; Q-053 |
| Three order categories are named: trade, non-trade, and STO. T1/DMS holds trade and non-trade orders but not STO. Trade is dealer-channel business; non-trade is direct institutional business. | `S0`/`S3`/`S4`, `15:09–18:31` | Glossary; Q-031 |
| Trade/non-trade orders are fetched T1→T2, not from DSP or SAP. T1 supplies order ID, material, quantity, and plant. | `S0`, `18:33–19:13` | D-014; SoR matrix |
| One order may produce multiple DIs. A new, unverified rule is asserted that each order has exactly one product/line item across trade, non-trade, and STO. | `S0`, `19:31–20:18` | D-011; Q-048 |
| An existing SAP→CPI→T1 trigger/push is described for DI creation, invoice creation, and order changes. T1 creates or updates the delivery record against the original order. | `S0`, `20:45–21:18`, `23:20–23:26` | Q-037 |
| Orders, deliveries, and invoices are displayed from T1. Shipment input includes vehicle, driver/mobile, and LR/GR; invoice data is created in SAP and sent back to T1. | `S0`, `21:35–22:20` | D-014; shipment contract |
| Troubleshooting “DI created but absent in T1” should trace SAP creation, the outbound record into CPI, endpoint health/status, and the T1 projection. | `S0`/`S2`, `22:24–22:51` | Observability; Q-012/Q-037 |
| In the current dealer flow, the dealer creates the order in T1; CNF/T2 creates the delivery and invoice through SAP APIs, not the order. This is scoped to the present dealer flow and does not settle T2's future OMS/order-creation role. | `S0`, `23:20–24:02` | T2 role; C-11 context |
| The working directive is to focus on MIGO and order fulfilment and defer STO because the speaker still has STO uncertainty. | `S0`, `24:19–24:57` | Q-006; Q-031 |
| Create DI must return the SAP delivery number synchronously so the UI can show it immediately without waiting for T1 replication. Submit MIGO is also treated as requiring an immediate identifier. | `S0`/`S3`, `25:41–27:43` | API-02/API-03 response contract |

## Interpretations

| Interpretation | Confidence | Supporting observations | Validation |
|---|---|---|---|
| Create DI has two response paths: an immediate authoritative number from S/4 and a later T1 projection used by list/read screens. | Strong inference | `20:45–21:18`, `25:41–26:08` | Identify the outbound interface and propagation SLA under Q-037 |
| The claimed SAP→CPI→T1 push may coexist with the pull-shaped `ZCRM_STAGEGATE_SRV`: one may project full documents while the other serves progression. | Hypothesis | `20:45–21:18`; D-032 system evidence | Verify interface names, direction, payloads, triggers, and consumers |
| The meeting’s “all calls are synchronous” language is safely scoped only to Submit MIGO/Create DI immediate identifiers. It does not close the multi-stage invoice questions. | Strong inference | `25:41–27:50`; `SRC-MTG-20260810-01 @01:43–02:09` | Q-008, Q-032, Q-035 remain open |
| If multi-storage-location receipt allocation is correct, an API-02 payload with one scalar storage location is insufficient. | Strong inference | `01:32–03:19`, `12:20–13:30` | Confirm payload and partial/damage/shortage rules with MM |
| The DSP round-trip corroborates the intended Option C path, not its implementation. QS4 still has no Pending-MRN extraction queue. | Verified distinction | `13:30–14:32`; D-038 | Q-053 remains open |

## Decisions

No statement is promoted to `DECISION_LOG.md`: speaker identity and decision authority are not established. “MIGO and order fulfilment first; STO later” and immediate MIGO/DI identifiers are recorded as working directions pending owner confirmation.

## Requirements changed or sharpened

- API-02 needs a collection of storage-location quantity allocations if partial, damaged, and shortage splits are in scope.
- API-02 and API-03 need explicit authoritative response identifiers and read-after-write behavior.
- The T1 projection needs a named interface, propagation SLA, correlation key, retry/error behavior, and a support trace across SAP → CPI → T1.
- The one-product/one-line rule must be confirmed before it shapes the DI contract.
- Current CNF scope and future OMS/order-creation scope must be separated when describing T2.

## Terminology

| Term | Client meaning | Confidence |
|---|---|---|
| Trade order | Dealer/channel order held in T1 | Meeting-supported; SAP representation remains per KDS/SD |
| Non-trade order | Direct order for an institutional customer rather than a dealer purchase | Meeting-supported; SAP representation remains per KDS/SD |
| STO | Stock Transport Order used for plant/depot or warehouse transfer; absent from the current T1 trade/non-trade order set | Supported by meeting and D-021; exact portal scope open |
| MIGO | SAP goods-receipt transaction/process used to post inbound quantities to storage locations | Supported; exact reference and output identifier remain open |
| MRN | Disputed in speech: “Movement Reference Number” here versus the source-verified Material Receipt Note/derived Pending-MRN model | Conflicted (C-14); preserve D-021 pending owner validation |

## Open questions and actions

| Priority | Question/action | Owner |
|---|---|---|
| Critical | Identify and observe the existing SAP→CPI→T1 projection: object/trigger, direction, payload, correlation, retry, owner, and latency; reconcile it with `ZCRM_STAGEGATE_SRV`. | SAP / CPI / T1 owners |
| Critical | Resolve MRN terminology and the authoritative identifier returned by Submit MIGO; confirm receipt reference and multi-storage-location/partial allocation contract. | MM / SD / ABAP / DSP |
| High | Confirm whether T2 ever creates/lands orders in S/4 or only creates DI/invoice for T1 orders in the current CNF scope. | Architect / Commerce / SD |
| High | Confirm whether one order truly has one material line, and at which document/view grain. | SD / T1 / Product |
| High | Obtain and version the approved BRD and Figma evidence, then build field lineage for every MIGO and order-fulfilment attribute. | BA / Product / interface owners |
| Medium | Define read-after-write UX and propagation SLA when SAP returns a DI number before it appears in T1. | Product / CPI / T1 |

## Registers updated

`MEETING_INGEST.md` · `sources/README.md` · `PROJECT_BRAIN.md` · `OPEN_QUESTIONS.md` · `DOMAIN_GLOSSARY.md` · `SYSTEM_OF_RECORD_MATRIX.md` · `HANDOVER_AI.md`
