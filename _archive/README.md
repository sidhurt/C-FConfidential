# Archive

Superseded documents. Kept for provenance only — **do not treat anything here as current.**

If a belief appears here and not in `../HANDOVER_AI.md`, the belief is obsolete.

| File | Retired | Why |
|---|---|---|
| `INTERFACE_REGISTER.md` | 2026-08-03 | `IF-001..IF-024` numbering superseded by `API-01..API-10`, which aligns 1:1 with the client's own process register. Mapping below |
| `REQUIREMENTS_MATRIX.md` | 2026-08-03 | `R-001..R-027` numbering superseded. Requirements now tracked as business rules per API in `deliverables/CNF_Delivery_Planning.xlsx` |
| `HANDOVER_2026-07-30_AI.md` | 2026-08-03 | Predates Option C (D-014), the KDS catalogue, DigiGST (D-017), and the SPI / brand-grade resolutions. Superseded by `../HANDOVER_AI.md` |
| `HANDOVER_2026-07-28_AI.md` | 2026-07-30 | Day-2 snapshot |
| `HANDOVER_2026-07-28_HUMAN.md` | 2026-07-30 | Day-2 snapshot |
| `BRAIN_MAP.md` | 2026-07-30 | Supplementary diagrams, not referenced as required reading |
| `DATASPHERE_SOURCES.md` | 2026-07-30 | Empty scaffolding — DS-001..DS-008 were all Hypothesis/TBD. Recreate from `../templates/` when real Datasphere discovery starts |

## IF → API mapping

Where the old interface IDs went. Several did not become SAP APIs at all — Option C (D-014) moved them to Commerce or Datasphere.

| Old | Became |
|---|---|
| IF-001 Check MIGO / pending receipt | **API-01** (class W — `ZLE526` exists) |
| IF-002 Submit MIGO | **API-02** |
| IF-003 Create DI | **API-03** |
| IF-004 Modify DI | **API-10** |
| IF-005 Stock/batch availability | **API-04** |
| IF-006 Invoice/PGI orchestration | **API-06** |
| IF-007 E-Way Bill extension/retry | **API-09** (may be out of ABAP scope — Q-042) |
| IF-008 Invoice/e-doc correction | Split → **API-07** (billing) + **API-08** (e-invoice). The client register correctly separates these |
| IF-009 Document flow/status | → Commerce T1 under Option C; SAP side is API-06 status only |
| IF-010 Datasphere analytical feed | → Datasphere, not ABAP |
| IF-011 Inventory reconciliation | Not in the client's 9-process register — out of current scope |
| IF-012 Cancellation request | Not in the client's register — out of current scope |
| IF-013 Pending order list | → **Commerce T1** (live OCC) |
| IF-014 Open DI list/details | → **Commerce T1** (live OCC) |
| IF-015 Edit open DI quantity | **API-10** |
| IF-016 Batch proposal | **API-04** |
| IF-017 Transporter lookup | → Commerce T2 / Datasphere (daily sync) |
| IF-018 Freight/route validation | **API-05** |
| IF-019 Invoice process command | **API-06** |
| IF-020 Process/document status | → Commerce T1 + API-06 status endpoint |
| IF-021 E-Way Part A correction | **API-08** family |
| IF-022 E-Way Part B vehicle update | **API-08** family |
| IF-023 E-Way extension | **API-09** |
| IF-024 FleetX tracking link | External. Product decision D-006; integration owner still unassigned |
| — | **NEW: S/4 → T1 outbound push.** Has no IF- predecessor because nobody identified it until the Option C review. Q-037 |
