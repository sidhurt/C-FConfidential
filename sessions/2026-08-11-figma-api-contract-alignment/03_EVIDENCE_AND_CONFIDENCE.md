# Evidence and Confidence Ledger

## 1. Evidence policy

Apply the hierarchy in `AGENTS.md`:

1. system observation;
2. client document/design artifact;
3. Siddharth's direct project clarification;
4. meeting transcript.

Validated Figma establishes product/business behavior. It does not automatically establish SAP DDIC fields, BAPIs, tables, service names, transaction boundaries or persistence.

## 2. New durable evidence preserved in this session

| Source ID | Repository file | What it establishes | SHA-256 |
|---|---|---|---|
| SRC-FIG-20260811-09 | `sources/SRC-FIG-20260811-09_STO_Purchase_Order_Production_Flow.png` | STO/intra-warehouse PO list and Create New Purchase Order design | `8E7690DE4B41351B31ADF15C858E2B5B7E19B466C6FDCCFA978D5C44C99CC789` |
| SRC-FIG-20260811-10 | `sources/SRC-FIG-20260811-10_STO_Create_DI_Production_Flow.png` | Full/partial DI creation against PO pending quantity | `D9C59325CD2275889D0683CC4EA402314FF7318B65BF72998194649817D17B4F` |
| SRC-FIG-20260811-11 | `sources/SRC-FIG-20260811-11_STO_In_Process_Production_Flow.png` | Shared STO quantity/batch/transporter/shipment flow | `A35BF233B70774F0508EC3C0B4A431757F4FBAE501A116598496297080BF9DBF` |
| SRC-FIG-20260811-12 | `sources/SRC-FIG-20260811-12_STO_Document_Flow_Production_Status.png` | STO document flow through receiving-side GR | `9B7544B38A3971AC80121573761E522D254A865F8E9CD011F5E74ADE4776B3C8` |
| SRC-FIG-20260811-13 | `sources/SRC-FIG-20260811-13_EWay_Bill_Management_Extension_Production_Flow.png` | E-Way management list and separate extension form/result | `B51A6AFEF347FE0F0EBD44A8C3E3A307DF231259974F927DC9BAA0A47C24F2DE` |
| SRC-DOC-20260811-02 | `sources/SRC-DOC-20260811-02_Division_Mapping.png` | Division 10 = Cement; source table TSPA; field SPART | `7C536A7FA0A9535406405684C62CB5899E48D072E48305EB651C8E844FE0D8F1` |
| SRC-DOC-20260811-03 | `sources/SRC-DOC-20260811-03_STO_Field_Mapping.png` | Candidate STO attributes and EKKO/EKPO/EKET/DSP lineage | `222F6760A2FD31519513097666C8D35347F0C6E74B69207D0FBBF230CDB7D049` |
| SRC-DOC-20260811-04 | `sources/SRC-DOC-20260811-04_Stock_Ageing_Field_Mapping.png` | Candidate plant/material/storage-location/inventory-age report fields | `8474994294318EF16227F740DF4552280AC781660656DE89EE82503259F34BAC` |
| SRC-SID-20260811-08..12 | `sources/SRC-SID-20260811-08_to_12_Direct_Clarifications_Session_Record.md` | Direct business clarifications preserved in structured form | Markdown source record created this session |
| SRC-SID-20260812-01 | `sources/SRC-SID-20260812-01_EWay_Extension_Timing_Clarification.md` | Superseding rule: eligible only in the eight hours before expiry; success adds exactly 24 hours | Direct clarification |
| SRC-FIG-20260812-01 | `sources/SRC-FIG-20260812-01_STO_Create_Purchase_Order_Production_Flow.png` | Focused validated STO Create Purchase Order fields and successful PO-number result | `CF615EFA6B8601343B659C4787F418552D2CDA81927FC0A555E2B7EBFD536719` |
| SRC-SID-20260812-02 | `sources/SRC-SID-20260812-02_Create_STO_PO_Candidate_API.md` | Create PO is STO-only and is candidate API-11; successful PO feeds API-03 | Direct clarification |
| SRC-SID-20260812-03 | `sources/SRC-SID-20260812-03_API_Numbering_Clarification.md` | Siddharth's current v1.7 API-01..11 numbering supersedes the earlier non-renumbering statement | Direct clarification |

## 3. Claim-to-evidence map

| Claim | Best evidence | Confidence | Do not overclaim |
|---|---|---|---|
| DI = SAP outbound delivery | SRC-SID-20260811-02; D-007 | Directly confirmed terminology | Exact creation API/BAPI still unverified |
| STO is intra-warehouse and shares post-DI flow | SRC-SID-20260811-08; SRC-FIG-09..12 | Direct + validated design | PO type/API/technical mapping remains open |
| API-04 replaces API-12 | SRC-SID-20260811-09; current v1.7 sheet set | Direct and artifact-observed | Variance-posting workflow remains open |
| Standalone E-Invoice Correction is absent; current API-08 is E-Way Bill Extension | SRC-SID-20260811-09; SRC-SID-20260812-03; current v1.7 sheet set | Direct and artifact-observed | Do not reuse the removed operation's old number mapping |
| Candidate API-11 creates an STO PO before API-03 | SRC-FIG-20260812-01; SRC-SID-20260812-02 | Validated design + direct clarification | Exact MM document type, API/BAPI and ownership remain open |
| MIGO returns material document + year | SAP document model; current API-02 design | Strong technical model | UI's “MRN Document Number” identity remains C-14 |
| DMG/STG are rejected/non-stock | SRC-SID-20260811-07 | Direct project clarification | Workbook currently conflicts; exact rejection ledger unknown |
| FIFO oldest eligible first | SRC-SID-20260811-10 | Direct business rule | Determination owner and stock-age field unverified |
| Division 10 = Cement | SRC-DOC-20260811-02 | Client mapping artifact | Other divisions are outside today's contract focus |
| Only FTP/FTB/EXW in business scope | SRC-SID-20260811-10 | Direct business clarification | KDS includes EXP/EXR; configuration conflict remains |
| 1000/1300 are sales organisations | SRC-SID-20260811-10 | Direct statement | Higher-tier client mapping contradicts 1300/VKORG; C-10 remains open |
| E-Way management list is separate from extension command | SRC-FIG-20260811-13 | Validated design inference | Exact list source/API is not established |
| Extension timing is only the eight hours immediately before expiry | SRC-SID-20260812-01 | Confirmed direct project rule | No after-expiry window; provider error mapping remains technical work |
| Successful extension adds exactly 24 hours | SRC-SID-20260812-01 | Confirmed direct project rule | Fixed rule, not an `ExtensionHours` request field |

## 4. Session conflicts and validation gates

These are session-local labels. Promote them into the canonical conflict/question registers tomorrow instead of inventing competing permanent IDs.

| Local gate | Conflict or uncertainty | Required evidence/owner |
|---|---|---|
| SG-01 | Current v1.7 models DMG/STG as posting storage locations; direct clarification says rejected/non-stock | MM/warehouse owner plus actual SAP configuration/posting trace |
| SG-02 | “MRN Document Number” UI label vs SAP material document/year | MM/SD owner and one successful API/MIGO trace |
| SG-03 | Candidate API-11 now models the STO Create Purchase Order action, but the formal SAP API list has no Create STO PO | Product owner + integration architect + SAP MM |
| SG-04 | API-04 replaces API-12, but physical-difference posting/audit is still undefined | Inventory/finance owner + SAP MM/FI design |
| SG-05 | Session says sales org 1300; mapping evidence treats 1300 as company code | SAP SD configuration owner, TVKO/T001/system check |
| SG-06 | Business allowlist is FTP/FTB/EXW; KDS contains EXP/EXR | SD/configuration owner; distinguish active scope from configured values |
| SG-07 | FIFO rule is confirmed, but batch-determination owner and age source are not | SAP batch-determination/configuration trace |
| SG-08 | API-08 visible fields vs mandatory government/provider payload | GSP/DigiGST integration owner and actual destination/request trace |
| SG-09 | Exact provider response/error mapping for the confirmed pre-expiry window and fixed 24-hour result | GSP/DigiGST integration owner; sample extended E-Way response |
| SG-10 | “All SAP APIs synchronous/real-time” vs multi-stage invoice UI states | Confirm per-call response semantics without reopening deferred landscape study |

## 5. Existing evidence that remains essential

- `SRC-ARCH-20260811-01` — formal manager-shared architecture.
- `SRC-CPI-20260811-01` — formal interface summary.
- `SRC-FIG-20260811-02`..`08` — DI, shipment/invoice, document flow, physical inventory, invoice correction and MIGO production designs.
- `SRC-CODE-20260804-01` — pending-MRN report source evidence.
- `SRC-DOC-20260803-01` and `SRC-DOC-20260803-02` — feature mapping and KDS catalogue.
- `SRC-MTG-20260810-01` and `SRC-MTG-20260810-02` — reconciled workflow/KT transcripts, with ASR caveats.
