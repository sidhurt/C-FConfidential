# Source Documents

Primary evidence for this project. Files are prefixed with their source ID so a claim citing `SRC-DOC-20260803-02` can be traced to the file without a lookup.

Registered in `../MEETING_INGEST.md`. Confidence rules in `../README.md §Evidence standard`.

## Originals

| Source ID | File | What it is | Status |
|---|---|---|---|
| `SRC-TECH-001` | `SRC-TECH-001_SAP_ABAP_OData_Technical_Specification.pdf` | Vendor-proposed ABAP/OData specification, v1.0, July 2026. No author, reviewer or approver named | **Assessed, 32 defects logged** — see `../SAP_API_DOSSIER.md` §Part A. Greenfield build instruction, not as-built. Do not implement as written |
| `SRC-DOC-20260803-01` | `SRC-DOC-20260803-01_CNF_Feature_to_SAP_Mapping.docx` | Feature → SAP table / T-code mapping: Login & Authorisation, Common Masters & KDS, Functionalities (MIGO, DI, Invoice, e-Invoice/e-Way, STO), 8 report visibilities, KDS reference index | **Authoritative for client configuration** |
| `SRC-DOC-20260803-02` | `SRC-DOC-20260803-02_CNF_KDS_Catalogue.xlsx` | **The KDS catalogue.** 11 sheets of real code values — SPI↔Sloc (`ZLETSPIMAP`), Plant↔Sloc (`T001L`), Sales area↔plant (`TVKWZ`), ↔sales office (`TVKBZ`), Incoterm↔plant (`ZISP`), Customer group (`T151`), vendor/customer master, Material Groups 1–5 (`TVM1`–`TVM5`), Nielsen indicator, Material freight group (`TMFG`) | **Highest-value document in the project.** This is what Q-021 / V-12 was asking for |
| `SRC-DOC-20260815-01` | `SRC-DOC-20260815-01_CNF_API_Request_Response_Specification_v1.7.xlsx` | Authoritative current demand model: 13 sheets covering Overview plus API-01..API-12; API-01..10 formal sequence and API-11/12 explicit candidates | **Current business/API requirement baseline.** Proposed `ZCNF_*` service names are superseded implementation placeholders. SHA-256 `41E67DA30B152F11D25B0315CDD247D7BABB5CC0EC557AE3CA6DEA782311C5A6` |
| `SRC-ARCH-20260803-01` | `SRC-ARCH-20260803-01_CNF_Architecture_Options_v1.2.pptx` | Three DSP data-integration options. **Option C selected** (D-014) — note the deck itself presents all three neutrally and does not mark a selection | Authoritative for the topology; selection is relayed |
| `SRC-ARCH-20260811-01` | `SRC-ARCH-20260811-01_CNF_Architecture_Manager_Shared.png` | Manager-shared formal C&F architecture screenshot: seven real-time T2→S/4 operations plus T1/T2 and DSP batch paths | **Formal documented baseline; version/date/approver not visible.** SHA-256 `2E41F3671F2C10F514B1261F06988365C1B7B0AF62EEFA57776B01454B09B304` |
| `SRC-CPI-20260811-01` | `SRC-CPI-20260811-01_Interface_Summary_Manager_Shared.png` | Integration-team interface-summary screenshot, visible rows 1–16 | **Formal documented baseline for visible rows; not the complete workbook.** SHA-256 `E11587C4535179BBAF68F3A943686F905E5B292D2A2C573FCF91B9FC0E336876` |
| `SRC-FIG-20260811-02` | `SRC-FIG-20260811-02_Delivery_Instruction_Production_Flow.png` | Validated production-design flow for Pending Orders → Create Delivery Instruction, including quantity and credit-block validations and DI-number success response | **Validated functional/product design** per `SRC-SID-20260811-03`; not by itself SAP object/BAPI proof. SHA-256 `D6F09C66A6A7A7572AD2A328512B25E95C01542FB33C023BAFB23E7C37140A96` |
| `SRC-FIG-20260811-03` | `SRC-FIG-20260811-03_Invoice_Shipment_Production_Flow.png` | Validated production-design flow from an in-progress DI through quantity, batch, transporter, freight estimate and shipment details to Generate Invoice & E-Way Bill | **Validated functional/product design** per `SRC-SID-20260811-03`; not by itself SAP object/BAPI proof. SHA-256 `B6AC3C17748229E44AB8F00C94BFCD9501493D469984E622A97C885EC28B46D9` |
| `SRC-FIG-20260811-04` | `SRC-FIG-20260811-04_Document_Flow_Production_Status.png` | Validated production Document Flow after DI creation: PGI, shipment, shipment cost, invoice, e-Invoice, E-Way Bill and download with per-stage status | **Validated functional/product design** per `SRC-SID-20260811-03`; not by itself proof of transaction boundaries or implementation timing. SHA-256 `6E8850542AF999ABE9B8A975E4B9AEDA53880B5A55713A024BF7489A4F339E8C` |
| `SRC-FIG-20260811-05` | `SRC-FIG-20260811-05_Physical_Inventory_Reconciliation_Production_Flow.png` | Validated production flow for physical inventory reconciliation: choose warehouse/plant, list every product and its storage-location system stock, enter physical quantity, calculate variance/reason, and post the reconciliation | **Validated functional/product design** per `SRC-SID-20260811-04`. Establishes API-04's inventory-listing use case; not by itself proof of SAP posting mechanics. SHA-256 `3A7F950BD64023CADA409CDEE81981042B6B28A94656080E9D417A230B0BCEC7` |
| `SRC-FIG-20260811-06` | `SRC-FIG-20260811-06_Invoice_Management_Generated_Production_Flow.png` | Validated production Invoice Management view for successfully generated invoices, their SAP/e-document references and downloadable invoice/E-Way Bill PDF | **Validated functional/product design** under `SRC-SID-20260811-03`; mapped to formal CreateInvoice by `SRC-SID-20260811-06`. The screen is a result/read surface, not proof that every displayed field belongs in the create request. SHA-256 `CCAB3D12F6E6A4650A7B8EC05CA8C21F0C41B9E8F488491665068297FC0FE4E9` |
| `SRC-FIG-20260811-07` | `SRC-FIG-20260811-07_Invoice_Details_Correction_Production_Flow.png` | Validated production Invoice Details Correction view: independent e-Invoice/E-Way Bill states, read-only invoice context, and editable transporter/distance/vehicle fields | **Validated functional/product design** under `SRC-SID-20260811-03`; mapped to formal Invoice Correction by `SRC-SID-20260811-06`. Does not by itself prove cancel/regenerate mechanics. SHA-256 `BAD531F9C0A409B56EF93FCAE2B7516632C828DCF7A89A031FFBD21211271EDC` |
| `SRC-FIG-20260811-08` | `SRC-FIG-20260811-08_MIGO_Production_Flow.png` | Validated production MIGO worklist and modal states: Pending/Partial rows, prior inward allocation, current operational classification, validation errors, and success identifier | **Validated functional/product design.** Establishes the portal state machine and quantity validations, not the SAP meaning of the success label or inventory effect of each code. STG/DMG semantics are supplied by `SRC-SID-20260811-07`. SHA-256 `7883AB3086778BBD3E2B17249E6973F1C0B05EBD89C1513BE3FD069525C52CBB` |
| `SRC-FIG-20260812-01` | `SRC-FIG-20260812-01_STO_Create_Purchase_Order_Production_Flow.png` | Focused validated STO/intra-warehouse Create Purchase Order screen, mandatory business inputs and successful PO-number result | **Validated functional/product design.** Supports candidate API-11; exact SAP MM document type, service/BAPI and ownership remain unverified. SHA-256 `CF615EFA6B8601343B659C4787F418552D2CDA81927FC0A555E2B7EBFD536719` |
| `SRC-SID-20260812-02` | `SRC-SID-20260812-02_Create_STO_PO_Candidate_API.md` | Direct clarification that Create PO is STO-only and candidate API-11; successful PO feeds API-03 as `STO_PO` predecessor | Direct project clarification; technical implementation remains candidate |
| `SRC-SID-20260812-03` | `SRC-SID-20260812-03_API_Numbering_Clarification.md` | Authoritative current v1.7 numbering: API-08 E-Way, API-09 Modify DI, API-10 storage locations, candidate API-11 Create STO PO | Direct instruction superseding the earlier no-renumbering statement |
| `SRC-SID-20260812-04` | `SRC-SID-20260812-04_Foundational_Study_Scope.md` | Current learning boundary: foundations first; API-06 decomposition and service grouping deferred; standalone API-10 removed while API-11 stays a candidate | Direct project clarification; supersedes only the API-10 retention and immediate study-sequencing parts of `SRC-SID-20260812-03` |
| `SRC-MTG-20260803-01` | `SRC-MTG-20260803-01_transcript.en.txt` / `.hi.txt` / `.raw.json` | UI/UX design walkthrough. Hindi/Hinglish with English technical code-switching; Sarvam AI transcription (D-008), two passes. Diarized, timestamped | Reconciled in `../meetings/2026-08-03-ui-design-walkthrough.md`. Read the ASR-artifact table there before quoting |
| `SRC-MTG-20260804-01` | `SRC-MTG-20260804-01_transcript.en.txt` / `.hi.txt` / `.raw.json` / `.raw.en.json` | Architecture walkthrough over the T1↔T2↔S4 topology — pending-order refresh strategy, near-real-time polling vs Event Mesh, T2 transaction/audit store, dual-channel creation risk, STO/MRN, CNF stage-gate scope. 77 min, 9 speakers, timestamps `[HH:MM:SS]` | **Reconciled 2026-08-05.** C-11, C-12 and C-13 are in `../PROJECT_BRAIN.md`. Heavy ASR noise on product names — see the artifact list below |
| `SRC-MTG-20260810-01` | `SRC-MTG-20260810-01_transcript.en.txt` / `.hi.txt` / `.raw.json` / `.raw.en.json` | UI/process walkthrough covering shipment, invoice/e-document correction, MIGO/MRN, STO, physical reconciliation, visibility and dashboard. 29 min, 4 speakers, timestamps `[MM:SS]` | **Reconciled** in `../meetings/2026-08-10-ui-process-walkthrough.md`. Read the new-source ASR cautions below before quoting |
| `SRC-MTG-20260810-02` | `SRC-MTG-20260810-02_transcript.en.txt` / `.hi.txt` / `.raw.json` / `.raw.en.json` | Internal KT on MIGO/order fulfilment and the T1↔T2↔DSP↔CPI↔SAP path. 28 min, 5 speakers, timestamps `[MM:SS]` | **Reconciled** in `../meetings/2026-08-10-migo-order-fulfilment-alignment.md`. Read the new-source ASR cautions below before quoting |

## 2026-08-15 SEGW system evidence

| Source ID | Directory | What it proves | Status |
|---|---|---|---|
| `SRC-SYS-20260815-01` | `SRC-SYS-20260815-01_QS4_700_SEGW_PROJECT_CATALOG/` | Unrestricted Open Project catalogue: 2,626 QS4 design-time projects and their front-list metadata | **Complete catalogue metadata; not project internals or runtime callability** |
| `SRC-SYS-20260815-02..05` | Outbound-delivery, inbound-delivery v2/base and material-document evidence directories | Complete target trees and grid exports for the first released families, including sibling deltas and material-document coverage | **Design-time evidence audited; runtime unproven** |
| `SRC-SYS-20260815-06..13` | GR4PO, material-document UI, LE shipment-create candidates, billing-create/read, MMIM STO and purchase-order-processing directories | Complete Tier-A project trees/grids used to distinguish released APIs, Fiori/internal services and false positives | **Manifests reconcile; decisions in Tier-A findings/matrix** |
| `SRC-SYS-20260815-14..16` | Material stock, ATP availability and stock-in-date-range directories | Three-way API-05 stock comparison | **Proves book stock vs ATP vs interval analysis; none supplies StockAgeingDays** |

Across `SRC-SYS-20260815-06..16`, 476 distinct grids were exported and every manifest reconciles to its physical files. Use the per-project manifests and Tier-A findings for exact counts and caveats.

## Not held here

| Source ID | Why |
|---|---|
| `SRC-MTG-20260803-01` audio | `Morecontext.m4a`, 27 MB. Excluded — binary, undiffable, and the transcripts are the usable artifact. Original in `C:\Users\sidmy\Downloads\` |
| `SRC-MTG-20260804-01` audio | `Chaayos 10.m4a`, 74 MB. Excluded for the same reason. Original in `C:\Users\sidmy\Downloads\` |
| `SRC-MTG-20260810-01` audio | `Chaayos 11.m4a`, 29 MB. Excluded as binary/undiffable. Original at `C:\Users\sidmy\Downloads\drive-download-20260810T071433Z-1-001\Chaayos 11.m4a`; SHA-256 `A758AA04C3A6852BA4E95FE312ED0A4D4A331E466B37C0888FBDDC88C4FE9FA3` |
| `SRC-MTG-20260810-02` audio | `New Recording 20.m4a`, 29 MB. Excluded for the same reason. Original at `C:\Users\sidmy\Downloads\drive-download-20260810T071433Z-1-001\New Recording 20.m4a`; SHA-256 `11363CFDE5326E3A8A7BD73FFE666D70CAA9322E02BA05E2C8E680F6349ECC7A` |
| `SRC-MTG-20260728-01..04`, `-SUM` | **Lost.** The 28 July recordings (`Chaayos_3/4/6`, `New_Recording_12`, `MEETING-SUMMARY.md`) are no longer present on disk. Every 28 July claim — including approved decisions **D-001 to D-006** — rests permanently on secondhand reconciliation in `../meetings/2026-07-28-design-walkthrough.md`. It cannot be re-adjudicated. Re-confirm those decisions with the business rather than treating the meeting note as primary |
| `SRC-BRD-001` | Business Requirements Document — **not held in this repository**. Both 10 Aug meetings report that project members have BRD access and use it for validations/Figma mapping. Obtain the approved version before treating any copy as authoritative |
| `SRC-CPI-001` | Approved CPI interface workbook original — **not supplied**. A manager-shared screenshot of visible rows 1–16 is ingested separately as `SRC-CPI-20260811-01`; do not infer unseen workbook rows from it |

## `extracted/`

Plain-text extractions of the Office documents, produced locally. An agent can read these directly without parsing OOXML. They are **derived, not primary** — where an extraction and its original disagree, the original wins.

| File | From |
|---|---|
| `SRC-DOC-20260803-01_extracted.txt` | The mapping docx — all five sections, tables flattened |
| `SRC-ARCH-20260803-01_extracted.txt` | The architecture deck — 9 slides incl. Option C detail |
| `KDS_00_Index.txt` … `KDS_10_Material_freight_group.txt` | One file per KDS workbook sheet. Large sheets truncated at 400 rows — go to the xlsx for the full set |

## ASR artifacts — `SRC-MTG-20260804-01`

Sarvam mangles product names badly in this recording (poor line, several speakers on speakerphone). Read this before quoting anything from it.

| Actually said | Appears in the transcript as |
|---|---|
| S/4 (`S4`) | `SAP`, `SMP`, `S&P F4`, `SNPF`, `F4`, `recipe`, `sports exam`, `XUV` |
| MIGO | `MeeGo`, `Meecom`, `Megu`, `Mego`, `MIG or` |
| OCC | `OC`, `TOCC`, `OPA`, `OCC IPL` |
| OMS | `Omess`, `OMF`, `ONS`, `OEM`, `omess` |
| Event Mesh | `event match`, `even mesh`, `event matches`, **`dividends`** |
| STO | `H2`, `H2O`, `'82`, `ST`, `SCO`, `STB`, `HD`, `HTO`, `Steve's` |
| MRN | `MRM`, `MRI`, `MRP`, `mRNA`, `Emirates` |
| DI | `DII`, `DA`, `D.O.`, **`design`** ("can I not do a *design* without a pending order" = *DI*) |
| CNF / CFA | `CNS`, `CFHS`, `PNF`, `DNF`, `CRF`, `CFL`, `C1`, `CRT2` |
| DSP (Datasphere) | `DHP`, `SDP` |
| Spartacus | `Sparta touch` |
| T2 | `Titu`, `Tito`, `Kittu`, `D2`, `72`, `two-in-two` |

Two further cautions:

- **Quantities are rendered as currency.** Tonnage and message counts come out as `₹50`, `₹30`, `₹200`, `₹14000`. Every `₹` in this transcript is a tonne, a unit or a message count — never money. The one genuine cost discussion (Event Mesh per-message pricing, ~`01:03:22`) has no figure attached.
- **The two passes disagree on a name.** At `00:00:02` the Hindi pass has `कृष्ण बंधु` and the English pass has `Shubhendu`. Neither is confirmed. Speaker IDs `S0`–`S8` are **not** mapped to names anywhere — the diarization is reliable about *turns*, not *identity*. Do not attribute a claim to a person from this file without confirming with Siddharth.

**Extraction caveat:** the KDS sheets were flattened cell-by-cell with column boundaries rendered as ` | `. Merged cells and multi-row headers may misalign. Verified spot-checks: SPI↔Sloc, Customer group, Material groups 1–5, Material freight group. The four 400-row sheets (Plant↔Sloc, Sales area↔plant, ↔sales office, Incoterm↔plant) were sampled, not fully verified.

## ASR artifacts — `SRC-MTG-20260810-01` and `SRC-MTG-20260810-02`

Both recordings are Hindi/Hinglish with dense SAP and architecture code-switching. Use the source-language pass to adjudicate the English translation and preserve genuine disagreements rather than silently normalizing them.

| Actually said | Common transcript forms / caution |
|---|---|
| MIGO | `MeeGo`, `Bego`, `ego` |
| MRN | `MRM`, `MRI`, `MRL`, `MRF`, `mRNA`. **The expansion/lifecycle is genuinely disputed; see C-14** |
| Hybris | `Highbrisk`, `high brace`, `high-breach` |
| CPI | `SCPI`, `SEPI`, `SIPI` |
| T1 / T2 | `D1`, `Titu`; resolve only from the surrounding flow |
| LR/GR | `LRG`, `LRGS` |
| BRD / Figma | `BRT`, `BID` / `Sigma` |
| STO | `STU`, `SDO`; `HQ` in the first meeting is unusable ASR |
| ePOD | `EPO`, `EP` |
| Billed Quantity | `built quantity` |

Additional cautions:

- `SRC-MTG-20260810-01 @22:40` appears to equate FTB with stock transfer. Do **not** use it to redefine FTB; it conflicts with the existing glossary and may be a speaker slip.
- `SRC-MTG-20260810-02 @19:13` expands DI as “Delivery Instructions.” This is consistent with the current D-007 clarification: Delivery Instruction / DI and SAP outbound delivery are interchangeable project terms for the same document.
- Statements that all calls are synchronous apply, at most, to the immediate Submit-MIGO/Create-DI response examples. The first meeting explicitly describes asynchronous invoice-chain processing states.
