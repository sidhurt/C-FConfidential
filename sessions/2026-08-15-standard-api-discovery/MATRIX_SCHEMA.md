# CNF standard-API documentation matrix — schema

**Purpose:** every deep dive from here writes its results as rows in one flat table, so the final Excel deliverable is assembled rather than re-derived. The matrix is the deliverable's backbone; the per-project markdown reports are its evidence trail.

**Live data file:** `sessions/2026-08-15-standard-api-discovery/CNF_STANDARD_API_MATRIX.tsv` (UTF-8, tab-separated, one row per requirement × candidate operation).

**Grain:** one row answers *"can this SAP operation satisfy this one v1.7 requirement, on what evidence, and what is still open?"*

Never widen the grain. A row that says "API_X covers API-01" is not a matrix row — it is a summary, and summaries hide the gaps this exercise exists to find.

---

## Columns

| # | Column | Values | Notes |
|---:|---|---|---|
| 1 | `BizOpId` | `API-01` … `API-12` | v1.7 business operation. The spine — always populate. |
| 2 | `BizOpName` | free text | From the v1.7 workbook sheet name. |
| 3 | `RequirementId` | `<BizOpId>-R<nn>` | Stable id per requirement so rows can be revised without renumbering. |
| 4 | `Requirement` | free text | One field, verb or behaviour from v1.7. Not a whole journey. |
| 5 | `RequirementNecessity` | `Mandatory` / `Optional` / `Derived` / `Assertion only` | Exactly as v1.7 states it. |
| 6 | `SegwProject` | e.g. `API_INBOUND_DELIVERY_0002` | Design-time project. Blank if the candidate is not a SEGW project. |
| 7 | `ApiHubIdentity` | e.g. `API_INBOUND_DELIVERY_SRV_0002` | `SAP-OFFICIAL` artifact identity. **Not** the runtime path. |
| 8 | `ExternalServiceName` | e.g. `API_INBOUND_DELIVERY_SRV` | Runtime service name. |
| 9 | `VersionSelector` | e.g. `;v=2` | Empty means not yet established — never guess. |
| 10 | `Protocol` | `OData V2` / `OData V4` / `SOAP` / `BAPI` / `RFC` | |
| 11 | `SapOperation` | e.g. `POST A_InbDeliveryHeader`, `PostGoodsReceipt` | The exact callable thing. |
| 12 | `Coverage` | `DIRECT` / `PARTIAL` / `NO FIT` / `UNPROVEN` | Handover §5 Gate 2 vocabulary. Nothing else. |
| 13 | `CoverageScope` | `ALONE` / `IN-PROCESS` | **Required.** A service can be `NO FIT` alone and `PARTIAL` as one step inside a larger orchestration. Splitting these prevents the single most likely misreading of this matrix. |
| 14 | `EvidenceClass` | `LOCAL-DESIGN` / `LOCAL-RUNTIME` / `SAP-OFFICIAL` / `BUSINESS-DEMAND` / `INFERENCE` | Handover §10.2. Multiple classes separated by `+`. |
| 15 | `EvidenceRef` | file path or URL | Must resolve. A claim without a reference does not belong in the matrix. |
| 16 | `LocalDesignTime` | `PRESENT` / `ABSENT` | Is there a SEGW project in QS4? |
| 17 | `LocalRuntimeRegistered` | `YES` / `NO` / `UNKNOWN` | From the 522-row Gateway catalogue **only**. Never inferred from Runtime Artifacts, and never from SAP publishing the API. |
| 18 | `IcfNodeActive` | `YES` / `NO` / `UNKNOWN` | Almost always `UNKNOWN` at this stage. Say so. |
| 19 | `ActivationRequirement` | free text | What Basis would have to do, including the version. |
| 20 | `GapOrConstraint` | free text | The specific missing field, verb, or documented restriction. |
| 21 | `OpenItemId` | e.g. `ID-1`, `MD-3` | Cross-reference into the owning deep dive's open-items table. |
| 22 | `Disposition` | `KEEP-PRIMARY` / `KEEP-SIBLING-BASELINE` / `CONDITIONAL-BUSINESS-GATE` / `REJECT-WRONG-OBJECT` / `REJECT-MISSING-OPERATION` / `OUTSIDE-SEGW-GAP` / `PENDING-DEEP-DIVE` | Handover §5 Gate 6 vocabulary plus `PENDING-DEEP-DIVE` for candidates not yet examined. |
| 23 | `Status` | `OPEN` / `SETTLED` | `SETTLED` only when every cell in the row rests on evidence, not on inference. |
| 24 | `Notes` | free text | |

---

## Rules

1. **Identity is not availability.** Columns 7–10 describe what SAP publishes. Columns 16–18 describe what QS4 can actually call. A row may have a complete SAP identity and `LocalRuntimeRegistered = NO`. That is a normal, honest row — not a contradiction.

2. **`CoverageScope` is mandatory.** Any coverage verdict without it is ambiguous. `NO FIT / ALONE` plus `PARTIAL / IN-PROCESS` is a common and correct pair for the same service.

3. **Conflicts get a row, not a verdict.** When two sources disagree, set `Coverage = UNPROVEN`, `Status = OPEN`, name both sources in `EvidenceRef`, and point `OpenItemId` at the deep-dive entry that records the conflict. Do not average the sources and do not pick the more convenient one.

4. **No derived keys.** Document numbers, fiscal years and document years are read from the SAP source that owns them. `MaterialDocumentYear` in particular must never be derived from a posting date, a document date, or the current date. A row proposing any such derivation is invalid.

5. **`PENDING-DEEP-DIVE` is a real, valid state.** Candidates are entered with the requirement rows they are *expected* to be tested against, `Coverage = UNPROVEN` and `Status = OPEN`, before any extraction. This keeps the shape of the remaining work visible without implying a result. Nothing is selected until its deep dive is complete.

6. **`INFERENCE` is never alone on a settled row.** If `EvidenceClass` is only `INFERENCE`, `Status` must be `OPEN`.

---

## Assembly

The Excel deliverable is built from this TSV at the end, not maintained in parallel. Expected sheets:

- **Coverage by business operation** — pivot on `BizOpId` × `Coverage` × `CoverageScope`; the answer to "which SAP services cover API-0n, and what remains uncovered".
- **Activation list for Basis** — filter `Disposition` starting `KEEP` or `CONDITIONAL`, then `ExternalServiceName` + `VersionSelector` + `LocalRuntimeRegistered` + `ActivationRequirement`.
- **Open items** — filter `Status = OPEN`, grouped by `OpenItemId`.
- **Rejected candidates** — filter `Disposition` starting `REJECT`, carrying `GapOrConstraint` as the reason so rejections stay justified and do not get resurrected.
- **Evidence index** — distinct `EvidenceRef`.

Do not build the workbook until the Tier A set is complete. Handover §15 is explicit that no contract workbook may be produced prematurely; this matrix is a working register, and only the finished register earns a workbook.
