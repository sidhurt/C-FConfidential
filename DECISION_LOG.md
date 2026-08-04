# Decision Log

Only record decisions made by authorized owners. AI recommendations are proposals, not decisions.

| ID | Date | Decision | Owner | Evidence/source | Affected items | Status |
|---|---|---|---|---|---|---|
| D-001 | 2026-07-28 | Use labels Order Quantity and DI Quantity; Order = DI + Pending | Meeting chair/business | SRC-MTG-20260728-01 | Pending/DI reads | Approved in design walkthrough |
| D-002 | 2026-07-28 | One DI/invoice uses one storage location; multiple batches are allowed | Meeting chair/business | SRC-MTG-20260728-01 | DI, batch, invoice interfaces | Approved in design walkthrough |
| D-003 | 2026-07-28 | E-Way Bill extension transport mode is Road only | Meeting chair/business | SRC-MTG-20260728-02 | E-Way extension | Approved in design walkthrough |
| D-004 | 2026-07-28 | E-Way Bill Part B remains editable during validity | Meeting chair/business | SRC-MTG-20260728-02 | E-Way correction | Approved in design walkthrough |
| D-005 | 2026-07-28 | Only DI quantity is editable after DI creation and only while DI is open | Meeting chair/business | SRC-MTG-20260728-03 | DI edit | Approved in design walkthrough |
| D-006 | 2026-07-28 | Vehicle tracking link will use FleetX integration | Meeting chair/business | SRC-MTG-20260728-01 | Tracking | Product decision; integration pending |
| D-007 | 2026-07-29 | "DI" = Delivery (not "Delivery Instruction"). DI No. = outbound delivery number (LIKP-VBELN) | Siddharth | SRC-SID-20260729-01 (direct statement, this conversation) | DOMAIN_GLOSSARY DI entry; Q-003; SYSTEM_OF_RECORD_MATRIX DI row; IF-003/004/014/015/018/019 | Approved — predecessor (SO vs STO) remains open, see Q-031 |
| D-008 | 2026-08-03 | Sarvam AI may be used to transcribe and translate client meeting audio | Siddharth | SRC-SID-20260803-01 (direct instruction, this conversation) | AI_OPERATING_RULES confidentiality clause | Approved — scope is meeting audio only; see note below |
| D-009 | 2026-08-03 | Updating DI quantity resets batch determination | Design review (S1) | SRC-MTG-20260803-01 @00:30 | DI modify API (API-10/IF); batch determination; C-9 | Design-review agreement — not business-signed-off |
| D-010 | 2026-08-03 | Once a DI's invoice modal reaches final state it leaves the In-Progress list, on success **or** failure; moves to Invoice Management | Design review (S3) | SRC-MTG-20260803-01 @12:23–12:31 | Invoice orchestration; failure/retry surface (Q-035) | Design-review agreement — not business-signed-off |
| D-011 | 2026-08-03 | In-Progress list removal is keyed on **DI number**, not order number (one order may have multiple DIs) | Design review (S1/S3) | SRC-MTG-20260803-01 @16:35–17:11 | Correlation keys; idempotency (Q-010) | Design-review agreement — not business-signed-off |
| D-012 | 2026-08-03 | The "processing" modal is removed; processing status surfaces in Document Flow instead | Design review (S1) | SRC-MTG-20260803-01 @10:34, 11:22 | Document Flow; status API (Q-035) | Design-review agreement — not business-signed-off |
| D-013 | 2026-08-03 | Shipping cost estimate is read-only — SAP returns a value, the user cannot alter it | Design review (S1) | SRC-MTG-20260803-01 @03:30–03:40 | API-05 Shipment Cost (estimate mode) | Design-review agreement — not business-signed-off |
| D-014 | 2026-08-03 | **Architecture Option C selected** — Orders, Deliveries and Invoices served live from Hybris **T1 (CRM)** via OCC; Pending MRN and STO List sync DSP→T2 every 15 min; Stock Ageing daily from DSP; Depot→Sloc, Vehicle and Transporter masters daily from DSP to T2. Invoice download is an OCC query to T1 | Technology Architecture (team decision relayed by Siddharth) | SRC-ARCH-20260803-01 slides 6–8; SRC-SID-20260803-03 | **Removes most read APIs from SAP scope.** IF/API-01; SYSTEM_OF_RECORD_MATRIX; Q-005; Q-036; new Q-037/038/039 | Selected — deck's own stated cost is "two integration patterns to build and maintain" |
| D-015 | 2026-08-03 | Trade / non-trade is carried on the **material** at `MVGR5` (TVM5: `1` = TRADE, `002` = NON TRADE), and separately on the **customer** at `KDGRP` (T151) | Client SAP/functional team (document) | SRC-DOC-20260803-02, Material Grp sheet | DOMAIN_GLOSSARY; Q-021; every payload carrying trade/non-trade | Documented client configuration — treat as authoritative for field location, still to be system-verified |
| D-016 | 2026-08-03 | **Brand and grade are plain material group fields, not classification characteristics** — `MVGR3` = brand (SHREE/BANGUR/ROCKSTRONG/MAGNA), `MVGR2` = grade (OPC43/OPC53/PPC/PSC/…), `MVGR1` = product type, `MVGR4` = pack type. Descriptions in TVM1–TVM5 | Client SAP/functional team (document) | SRC-DOC-20260803-02, Material Grp sheet | DOMAIN_GLOSSARY; API-01/03/04 response shape; supersedes the classification (class type 022) hypothesis | Documented client configuration |
| D-017 | 2026-08-03 | Statutory e-Invoice and E-Way Bill run on **DigiGST** (`/DIGIGST/INVP` cockpit), a third-party add-on — **not** SAP Document and Reporting Compliance. E-Way Bill **extension is handled at the GSP/NIC portal, "not core SAP"** | Client SAP/functional team (document) | SRC-DOC-20260803-01 §3.4, §3.5, §3.6 | **Contradicts assumption A-07.** API-08, API-09 classification and effort; V-02; Q-009 | **Refined by D-023** — both frameworks are present |
| D-018 | 2026-08-04 | **Backend is SAP S/4HANA 2022 on-premise**, ABAP Platform 2022, HANA 2.00.087, Fiori FES 2022 SP04. Landscape is **three systems: DS4 (dev), QS4 (quality), PS4 (production)** | System observation, QS4 client 700 | `SRC-SYS-20260804-01` — System→Status, Installed Product Versions, and `ZSD_PENDING_ORDER_REP_PP` `max_use` SWITCH on `sy-sysid` | **Closes Q-002, Q-013.** RAP and released APIs available. Contradicts the vendor spec's "ECC or S/4 1909+" and its "two-system DEV→PRD" claim | **Verified by system observation** |
| D-019 | 2026-08-04 | **No `ZCNF*` objects exist** in packages or function modules | System observation, QS4 | `SRC-SYS-20260804-01` — SE80 search | **Closes Q-001.** The vendor specification describes objects that were never built. Greenfield confirmed against the system, not inferred | **Verified by system observation** |
| D-020 | 2026-08-04 | **`ZLETSPIMAP` is a valid-combinations table, not a determination table.** Keys `MANDT`+`LGORT`+`SDABW`. One storage location permits several SPIs (GDF permits five: RLCO, RLMI, SP01, SP04, SP08) | System observation, QS4 | `SRC-SYS-20260804-01` — SE11 + SE16 contents | API-03: storage location alone does **not** yield the SPI. A determination rule is undefined — see Q-044 | **Verified by system observation** |
| D-021 | 2026-08-04 | **"Pending MRN" = in-transit quantity on plant→depot movements**: dispatched quantity minus received quantity, per delivery. Sources are existing CDS views — `zsd_mrn_pending_cds_opt` (main), `zle_di_inv_details` (dispatched), `zle_mrn_goods_reciet_cds` (received) | Source code | `SRC-CODE-20260804-01` — `ZLE_MRN_PENDING_REPORT` FORM `get_data` | **Reclassifies API-01.** A consumable CDS view already exists. Supersedes the Gate-Entry hypothesis. Informs Q-004 | **Verified from source** |
| D-022 | 2026-08-04 | **`ZSD_PENDING_ORDER_FM` is an RFC-enabled function module** returning `zsd_st_pending_order_out`, called with `DESTINATION IN GROUP` for parallel processing | Source code | `SRC-CODE-20260804-01` — `ZSD_PENDING_ORDER_REP_PP` | Pending-order logic **is** wrappable, unlike the report programs. Revises Q-043 | **Verified from source** |
| D-023 | 2026-08-04 | **Both statutory frameworks are present.** SAP's eDocument framework is installed (standard `EDOC_COCKPIT` report, `EDOCUMENT` table, `CL_EDOC_COCKPIT_UI`, `ZEDOC_DCC_SRV` registered) **and** DigiGST supplies India-specific tables — E-Way Bill number reads from **`/DIGIGST/OWARD_H-EWBNUMBER`** | System observation + source code | `SRC-SYS-20260804-01`, `SRC-CODE-20260804-01` | Refines D-017: not either/or. SAP handles document lifecycle, DigiGST the statutory/GSP layer. API-08 has a concrete integration point | **Verified** |
| D-024 | 2026-08-04 | **Plant-level authorization uses custom object `ZLE_PLNT`, field `WERKS`** | Source code | `SRC-CODE-20260804-01` — `ZLE_MRN_PENDING_REPORT` FORM `authority_check` | NFR-05, Q-023. A plant-scoped custom auth object already exists and should be reused, not reinvented | **Verified from source** |
| D-025 | 2026-08-04 | **Vehicle number and LR/GR number are Z-fields on the shipment header** — `VTTK-ZZVEHICLE_NO`, `VTTK-ZZLR_GR_NO` | Source code | `SRC-CODE-20260804-01` | Confirms vehicle/LR belong on the shipment document, not a delivery Z-table. Supports the `EXTENSION_IN` design for API-03 | **Verified from source** |
| D-026 | 2026-08-04 | **Credit status is `CMGST`** with description from `DDTEXT`; the order quantity chain is contract (`ZMENG`) → order → schedule → delivery → invoice → rejected → **balance (`BAL_QTY`)** | Source code | `SRC-CODE-20260804-01` — `ZSD_PENDING_ORDER_REP_PP` field catalogue | The portal's two-value credit display is a simplification of a multi-value field. D-001's `Order = DI + Pending` is a simplification of a six-step chain | **Verified from source** |

### Note on D-008

`AI_OPERATING_RULES.md` prohibits sending client material to an unapproved external model. Siddharth explicitly directed the use of Sarvam AI for this audio and confirmed prior use for the same purpose. That instruction is the approval, logged here so the exception is traceable rather than silent. Scope is meeting audio transcription/translation only — it does not extend to sending SAP code, documents, payloads, or business data to any external model.

### Note on D-014 to D-017

D-015 to D-017 are read out of client-supplied mapping documents (`SRC-DOC-20260803-01/02`), not from a meeting where a decision owner spoke. They describe **existing client configuration**, which makes them the strongest evidence in this repository so far — but they are still documentation, not system observation. Confirm against SE11/SE16 on first DEV access.

D-014 is relayed by Siddharth as the team's selected option; the deck itself presents all three options neutrally and does not mark a selection. Confirm the selection is formally recorded somewhere client-side.

### Note on D-009 to D-013

These were agreed inside a UI/UX design review, not by a business decision owner, and the same session states explicitly that the design is **not** a final handoff (`SRC-MTG-20260803-01` @19:56) and that the demo and feedback cycle follow. They are recorded because they change SAP-side design, but they must not be treated as signed-off requirements. Re-confirm at formal handoff.

## Decision record template

### D-XXX — Title

- **Date:**
- **Status:** Proposed / Approved / Superseded / Rejected
- **Decision owner:**
- **Participants:**
- **Decision:**
- **Reason:**
- **Alternatives considered:**
- **Affected requirements/interfaces:**
- **Implementation consequence:**
- **Evidence/source:**
- **Supersedes / superseded by:**
- **Follow-up:**
