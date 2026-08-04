# Domain and KDS Glossary

This glossary is intentionally incomplete. A term is not implementation-ready until its client meaning, SAP representation, owner, and evidence are recorded.

| Term | Working meaning | SAP representation | Confidence | Validation owner |
|---|---|---|---|---|
| C&F Agent | Depot/warehouse operational user | User/partner/authorization mapping TBD | Verified business meaning | Business/Basis |
| Order | Source demand document | Sales order or other type TBD | Supported | SD |
| Pending Order | Order quantity not yet fulfilled by DI | Status/open-quantity derivation TBD | Supported | SD |
| Credit-free | Order available for fulfilment without credit block | Credit status fields/config TBD | Supported | SD |
| Credit-blocked | Order restricted by credit status | Credit status fields/config TBD | Supported | SD |
| DI | Delivery (not "Delivery Instruction"). "DI No." = delivery number | Outbound delivery document; DI No. = LIKP-VBELN | Verified | Siddharth (direct statement, 2026-07-29) — see D-007 |
| Open DI | DI without completed invoice | Status derivation TBD | Supported | SD |
| DI Quantity | Quantity assigned to a DI | Delivery item quantity (LIPS), predecessor (SO vs STO) still open | Supported | SD |
| SPI | **Special Procurement Indicator** — governs which storage locations are eligible for a given process | Custom mapping table **`ZLETSPIMAP`** (Storage Location ↔ SPI). Values `SP01`–`SP09`, `RLCO`, `RLMI`, `RLOP`, `VT21`. Used by MIGO, Stock and Invoice for SLoc eligibility | **Documented** (`SRC-DOC-20260803-02`, SPI to Sloc sheet; `SRC-DOC-20260803-01` §5) — supersedes both the "shipping point" and the "SCPI transcription error" hypotheses | MM/SD |
| GD/GDF, DTP, GDRK, RSD, CUT, DMG, DRD, FRSH, ASST, CLYC, PRST, RCPT, RMYD, SOW | **Literal 4-character storage location codes**, not categories | `T001L` (`WERKS` + `LGORT`). Descriptions in the Plant→Sloc sheet (e.g. `ASST` = Asset Sale, `CLYC` = CLN_Co_Yard, `BMYD` = B_M_Yard) | **Documented** (`SRC-DOC-20260803-02`, Plant to Sloc + SPI to Sloc sheets) | Operations/MM |
| FTP | Freight-to-Pay/Ship — company arranges the shipping | Incoterm/pricing/freight process TBD | Supported business term | SD/FI |
| FTB | Freight-to-Bill — the second of three shipping types; "mostly they use FTP and FTB". Distinction is who arranges freight: company vs customer | Incoterm/pricing/freight process TBD | Strong inference — added 2026-08-03 (`SRC-MTG-20260803-01` @01:59, @02:58). See Q-034 | SD/FI |
| EX / EX-works | Ex-works Incoterm; third shipping-type tab, not walked through in the 3 Aug review | Incoterm/customizing TBD | Supported | SD |
| Shipping type | The FTP/FTB/EX selection, presented as three tabs and **determined by the Incoterm**, which is decided upstream | Incoterm-driven; SAP field TBD | Strong inference — `SRC-MTG-20260803-01` @01:59, @04:20 | SD |
| Credit Block | Order status with exactly two values — `-` (credit-free) and `Credit Block`. "Credit-free" is defined as the absence of a block, not a separate status | Credit status field TBD | Verified as design intent — `SRC-MTG-20260803-01` @22:00 | SD |
| Document Flow | Portal surface showing per-document generation status; used for status visibility and download only | Not an SAP object — portal view over document statuses | Verified as design intent — `SRC-MTG-20260803-01` @07:29, @17:20 | Product/SD |
| Invoice Management | Portal tab receiving DIs that have left the In-Progress list (success or failure) | Not an SAP object — portal view | Verified as design intent — `SRC-MTG-20260803-01` @11:53. Detailed walkthrough deferred | Product/SD |
| Freight/route | Maintained rate/route between source and destination | Route/freight condition/shipment cost TBD | Supported | SD/LE |
| Batch determination | Choosing stock batches for DI quantity | Batch stock/strategy TBD | Supported | MM/SD |
| FIFO | Oldest eligible batch first | Current SAP behavior disputed | Unresolved | MM/ABAP |
| PGI | Post Goods Issue | Delivery goods issue/material document | Verified concept | SD/MM |
| Shipment | Transportation document | LE-TRA/TM/custom object TBD | Supported | SD/LE |
| Shipment cost | Estimated/actual freight cost | Shipment cost document/conditions TBD | Supported | SD/LE/FI |
| Invoice | SAP-generated sales billing output | Billing document and output TBD | Verified concept | SD/FI |
| ODN series | State-wise invoice number/display identifier | Exact SAP field/object TBD | Supported | SD/FI |
| Accounting document | FI document produced by billing | BKPF/BSEG or universal journal relationship | Supported | FI |
| E-Invoice | Government e-document/IRN process | SAP eDocument/GSP/custom TBD | Supported | Tax/CPI |
| IRN | Invoice Reference Number | E-document field TBD | Supported | Tax |
| E-Way Bill | Government goods-movement document | E-document/GSP/custom status TBD | Supported | Tax/CPI |
| Part A | E-Way Bill transporter/distance correction area | External/SAP integration fields TBD | Supported | Tax |
| Part B | E-Way Bill vehicle update area | External/SAP integration fields TBD | Supported | Tax |
| LR/GR | Logistics receipt/consignment reference | Shipment/delivery custom field TBD | Supported | Logistics |
| Pickup code | Code required in some Incoterm scenarios | Source/validation TBD | Unresolved | SD/Operations |
| MRN | **Material Receipt Note — the plant→depot in-transit position.** "Pending MRN" = dispatched quantity minus received quantity for a delivery. Chain: STO → outbound delivery from supplying plant → goods issue → in transit → goods receipt (mvt 101) at receiving plant | Derived, not stored. CDS `zsd_mrn_pending_cds_opt`; dispatched from `zle_di_inv_details`, received from `zle_mrn_goods_reciet_cds`; `MATDOC-VBELN_IM` links the receipt to the delivery | **Verified from source** (`SRC-CODE-20260804-01`) — see D-021. Supersedes the Gate-Entry hypothesis | MM |
| `zsd_mrn_pending_cds_opt` | Existing CDS view behind the MRN pending report — supplying/receiving plant, material, delivery, division, region, freight group, posting date, state code | CDS view | **Verified from source** — directly consumable for API-01 | ABAP |
| `ZSD_PENDING_ORDER_FM` | **RFC-enabled** function module returning the pending-order result set (`zsd_st_pending_order_out`); called in parallel via `DESTINATION IN GROUP` | Function module | **Verified from source** — wrappable, unlike the report programs | ABAP |
| `ZLE_PLNT` | Custom authorization object, field `WERKS` — plant-level access control already in use | Authorization object | **Verified from source** — reuse, do not reinvent (NFR-05) | Basis/Security |
| Vehicle no. / LR-GR no. | Captured on the **shipment header** as Z-fields | `VTTK-ZZVEHICLE_NO`, `VTTK-ZZLR_GR_NO` | **Verified from source** — confirms shipment, not a delivery Z-table | SD/LE |
| E-Way Bill number (source) | Read from the DigiGST outward header table | `/DIGIGST/OWARD_H-EWBNUMBER` | **Verified from source** — concrete DigiGST integration point | Tax/ABAP |
| Credit status | Multi-value SAP credit status with text; the portal's two-value display is a simplification | `CMGST` + `DDTEXT` | **Verified from source** — see D-026 | SD |
| Order quantity chain | contract (`ZMENG`) → order (`ORDER_QTY`) → schedule → delivery (`DEL_QTY`) → invoice (`INV_QTY`) → rejected (`REJ_QTY`) → **balance (`BAL_QTY`)** | `zsd_st_pending_order_out` | **Verified from source** — richer than D-001's three-term model. See Q-048 | SD |
| Man-made state (`ZREGION`) | Client-defined regional grouping, distinct from the SAP state/region | `ZSDTPRICE-ZREGION` / `ZREGION_TEXT` | **Verified from source** | SD |
| Landscape | Three systems | **DS4** (development), **QS4** (quality), **PS4** (production) | **Verified** (`SRC-CODE-20260804-01`, `sy-sysid` SWITCH) — contradicts the vendor spec's two-system claim | Basis |
| KDS | **Key Data Structure** — the client's own term for their master/reference code catalogue. Not an SAP object; a client artifact | The KDS workbook (`SRC-DOC-20260803-02`) *is* the catalogue: 11 sheets of mapping tables | **Verified** — expansion from Siddharth (`SRC-SID-20260803-02`); catalogue received 2026-08-03 | SD/business |
| Material Group 1 (`MVGR1`) | **Product type** — `000` OPC, `001` PPC, `002` PSC, `003` CC, `004` AAC, `005` RMC, `006` Clinker, `007` Rubble, `008` Mortar, `009` Raw Material, `010` Scrap, `011` Synthetic Gypsum, `012` Limestone, `013` Misc. Service sales | `MVKE-MVGR1`, text in `TVM1-BEZEI` | **Documented** (`SRC-DOC-20260803-02`) | Material/SD |
| Material Group 2 (`MVGR2`) | **Grade** — `0` OPC43, `1` OPC53, `2` PPC, `3` PSC, `4` CC, `5` PPC PREMIUM, `6` PPC POWER, `7` PPC CS, `8` CLINKER, `9` AAC BLOCK, `10` MORTAR, `11` OPC 53 S | `MVKE-MVGR2`, text in `TVM2-BEZEI` | **Documented** — see D-016 | Material/SD |
| Material Group 3 (`MVGR3`) | **Brand** — `000` SHREE, `001` BANGUR, `002` ROCKSTRONG, `003` MAGNA | `MVKE-MVGR3`, text in `TVM3-BEZEI` | **Documented** — see D-016. Supersedes the classification-characteristic hypothesis | Material/SD |
| Material Group 4 (`MVGR4`) | **Pack type** — `000` HDPE, `001` LPP, `002` LOOSE | `MVKE-MVGR4`, text in `TVM4-BEZEI` | **Documented** | Material/SD |
| Material Group 5 (`MVGR5`) | **Trade / Non-trade** — `1` TRADE, `002` NON TRADE | `MVKE-MVGR5`, text in `TVM5-BEZEI` | **Documented** — see D-015 | Material/SD |
| Customer Group (`KDGRP`) | 45 values incl. `10` Dlr-Wholesale, `11` Dealer-Retail, `12` Consignee (Ship-to), `13` Retailer/Sub Dealer, `14` Institutional, `15` Industrial, `16` Builder & Developers, `19` Obligatory Non Trade, `27` Transporter, `28` Depot, `29` Plant, **`31` Handling Agent (HA)** | `KNVV-KDGRP`, text in `T151` | **Documented** (`SRC-DOC-20260803-02`, Cust grp sheet) | SD |
| Business segment `10` | Earlier heard as "generally trade". Now resolves to two distinct axes: **customer group 10** (Dlr-Wholesale, a trade channel) and **MVGR5** (material-level trade/non-trade). Not a single field | See MVGR5 and KDGRP rows | Reframed 2026-08-03 — the original single-field reading was wrong | SD |
| Material Freight Group (`MFRGR`) | Freight classification — `A0000001` Cement Packed, `A0000002` Cement Loose, `A0000003` Clinker, `A0000004` AACB, `A0000005` Mortar … `A0000022` Cement Loose (F) | `TMFG` | **Documented** — drives shipment cost | SD/LE |
| Material Pricing Group (`KONDM`) | `01` Normal, `02` Spare parts, `W1`–`W3` Warranty variants | `T178` | **Documented** — feeds invoice pricing | SD |
| Nielsen Indicator | Brand-segmentation code — `01` SC, `02` Bangur, `03` RC, `04` Magna, `05`–`08` combinations, `09` Others | `MARC` / `TNLS`; linked to `MVGR3` via condition table **`KOTG508`** and a **`MV45AFZZ` user exit** in sales-order processing | **Documented** — note the custom enhancement | Material/SD |
| Sales organisation `1000` | Shree Cement Ltd. The only sales org appearing across every KDS mapping sheet | `TVKO-VKORG` | **Documented** | SD |
| `1300` | Relayed as "Shree Cement East, a sales organisation"; the KDS document lists 1000 and 1300 as **company codes** (`T001-BUKRS`) and shows only sales org 1000 | Company code vs sales org — **conflict C-10** | Conflicted 2026-08-03 — see Q-040 | SD/FI |
| Division / Distribution channel | Division `10` = Cement (`TSPA-SPART`); distribution channels `10`, `20`, `99` (`TVTW-VTWEG`) | `TSPA`, `TVTW` | **Documented** | SD |
| Sales area → plant / sales office | Sales org + distribution channel → plant via **`TVKWZ`**; + division → sales office via **`TVKBZ`** | `TVKWZ`, `TVKBZ` | **Documented** — also the basis of CNF user authorization scoping | SD/Basis |
| ODN | **Official Document Number** — India GST statutory invoice numbering, distinct from the SAP billing document number | Generated at invoice creation (VF01 family). Exact config object still to confirm | Strong inference — expansion inferred from "other derived numbers" (`SRC-SID-20260803-02`); see Q-029, Q-041 | SD/FI |
| DigiGST (`/DIGIGST/INVP`) | Third-party GST compliance add-on providing the e-Invoice and E-Way Bill cockpit. **Not** SAP Document and Reporting Compliance | `/DIGIGST/*` namespace | **Documented** (`SRC-DOC-20260803-01` §3.4–3.5) — see D-017 | Tax/Basis |
| CNF agent (master-data representation) | Enrolled in SAP as **both vendor and customer** — customer group `31` (Handling Agent), account group `ZDOM`, created via T-code `ZMDM_BP` | `LFA1`/`LFB1`/`LFBK` + `KNA1`/`KNB1`/`KNVV` | **Documented** (`SRC-DOC-20260803-01` §1) | Basis/SD |

## Required KT outputs

For each KDS/master code, capture:

- business definition;
- SAP table/field/domain;
- allowed values and descriptions;
- derivation or user input;
- valid combinations;
- owning team;
- process impact;
- API field(s) using it;
- sensitive-data classification;
- evidence and last validation.

