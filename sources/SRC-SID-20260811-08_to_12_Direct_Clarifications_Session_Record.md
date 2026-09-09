# Direct Clarifications — 11 August 2026

**Source type:** direct statements from Siddharth in the Codex working session  
**Evidence tier:** Tier 3 under `AGENTS.md`
**Purpose:** preserve the business clarifications that accompanied the Figma and workbook work until they are promoted into `MEETING_INGEST.md`, `DECISION_LOG.md`, `OPEN_QUESTIONS.md`, and `DOMAIN_GLOSSARY.md`  
**Transcription note:** this is a structured paraphrase, not a verbatim chat transcript.

## SRC-SID-20260811-08 — Trade, non-trade and STO relationship

- The project has three business flows: Trade, Non-trade and STO.
- STO is the project's intra-warehouse movement between two Shree Cement warehouses/plants.
- Trade and Non-trade start from a sales-order context. STO starts from a stock-transport purchase-order context.
- After that predecessor difference, the Delivery Instruction and downstream fulfilment journey are functionally the same. Differences are primarily naming and how the predecessor is maintained in SAP.
- In this project, Delivery Instruction/DI and SAP outbound delivery are interchangeable terms, consistent with `SRC-SID-20260811-02`.

**Boundary:** this clarification validates the business relationship. It does not prove the exact SAP document type, BAPI, OData entity, or whether portal-side stock-transport PO creation is a separate SAP API.

## SRC-SID-20260811-09 — API catalogue removals

- API-08, E-Invoice Correction, is not a project requirement and does not exist in the required API catalogue.
- API-04 Stock Availability and API-12 Inventory Reconciliation represented the same business read need. API-04 is retained as the sole stock-availability/physical-inventory read, and API-12 is removed.
- Existing API identifiers are not renumbered after those removals.

**Boundary:** removing API-12 removes the duplicate interface slot. It does not settle whether or how a physical-count variance is posted to SAP; that workflow remains a separate open implementation question.

## SRC-SID-20260811-10 — Configuration, ageing and FIFO

- The business-scope Incoterm codes stated for this client are `FTP`, `FTB`, and `EXW`/EX Works.
- The session states that sales organisation `1000` represents Shree Cement Limited and `1300` represents Shree Cement East.
- Division `10` means Cement. The supplied mapping image identifies table `TSPA`, field `SPART`.
- Two different ageing concepts must not be merged:
  - **Order ageing:** elapsed time from creation of the predecessor sales order or purchase order until confirmed depot arrival, or until the current date while the movement is still open/in transit.
  - **Stock ageing:** elapsed time that inventory has remained in stock.
- The stated outbound business rule is FIFO: the oldest eligible stock/batch is proposed first.

**Conflicts and boundaries:**

- `SRC-DOC-20260803-02` contains additional Incoterm values (`EXP`, `EXR`) in configuration. The business allowlist and the technical configuration universe therefore require reconciliation.
- Existing client mapping evidence treats `1300` as a company code and shows sales organisation `1000`; this remains conflict `C-10`. Do not hardcode `1300` into `VKORG` until SAP validation resolves the organizational-field binding.
- FIFO is now a direct business rule. Which SAP component owns determination and which stock-age field drives it remain implementation questions.

## SRC-SID-20260811-11 — E-Way Bill extension

- E-Invoice and E-Way Bill are government-mandated electronic documents; they are not ordinary company-to-company billing labels.
- The C&F application contains a management/list surface for existing E-Way Bills and a separate action to extend one selected E-Way Bill.
- The 11 August session stated that a successful extension adds 24 hours of validity.
- The 11 August timing description is superseded by `SRC-SID-20260812-01`: eligibility exists only during the eight hours immediately before expiry; there is no after-expiry window.
- Operational reason labels can cover accident, breakdown/wear-and-tear, or other delay reasons. The exact provider/government reason-code mapping is not yet supplied.
- Superseded by `SRC-SID-20260812-01`: the fixed 24-hour extension is now confirmed. It still does not become an `ExtensionHours` request field; the response returns the authoritative updated-valid-until timestamp.

**Boundary:** the government/provider response remains authoritative. `RemainingDistance`, `ConsignmentStatus`, conditional `TransitType`, code mapping, eligible caller identity, and exact validity calculation require adapter/SAP/GSP confirmation.

## SRC-SID-20260811-12 — Current operating model and study scope

- In the current landscape, C&F agents at depots perform the inbound MIGO process and outbound delivery/invoice process directly in SAP, creating operational friction and requiring SAP knowledge.
- The new C&F application is intended to present guided business actions and validations while remaining consistent with SAP S/4HANA rules.
- Operational SAP APIs are to be treated as real-time request/response interactions for Siddharth's current ABAP workstream.
- Detailed cognitive study of DSP/T1/T2 batch-versus-event mechanics is intentionally deferred. Those components remain part of the architecture and evidence base, but are not the present learning priority.

**Boundary:** a real-time API call does not imply that every downstream document in the invoice chain is completed in one blocking transaction. The validated document-flow UI independently exposes Generated, Processing and Not Generated states.
