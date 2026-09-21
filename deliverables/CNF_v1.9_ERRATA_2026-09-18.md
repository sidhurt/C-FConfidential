# v1.9 workbook — errata

**Raised:** 2026-09-18
**Applies to:** `deliverables/CNF_API_Request_Response_Specification_v1.9.xlsx` (dated 2026-08-19)
**Status:** corrections identified, not yet applied to the workbook

Two defects. Both are visible to a client reading the file. Fix before the next circulation.

---

## Defect 1 — three competing numbering schemes

### The symptom

The sheet tabs and the sheet contents disagree about what every sheet is called.

| Sheet | Tab name | Overview index and all body cross-references |
|---|---|---|
| Stock availability | `OF-03 Stock Avail` | OF-02 |
| Pre-PGI | `OF-05 Pre-PGI` | OF-04 |
| Create PGI | `OF-06 Create PGI` | OF-05 |
| Create Invoice | `OF-07 Create Invoice` | OF-07 |
| Create Order STO | `OF-08 Create Order STO` | OF-06 |

`CURRENT_STATE.md` follows the **body** scheme, so the repository's status authority and the
workbook's own tabs disagree as well.

### The root cause

The tabs were renumbered to match the client's agreed API list. The Overview sheet index and
every in-sheet cross-reference were left in the earlier scheme. It is one change applied in
one place instead of three.

### Where it is visible

- **`OF-06 Create PGI` §1** — "Runs after OF-04 (pre-PGI) and before OF-06 (invoice)." Under
  its own tab name this sheet *is* OF-06, so the sentence points at itself.
- **`OF-05 Pre-PGI` §3** — the operations table marks `PostGoodsIssue` and `ReverseGoodsIssue`
  as "belongs to OF-05". OF-05 is the sheet the reader is on. Under the body scheme this was
  correct; under the tab scheme it is not.
- **Overview, SHEET INDEX** — lists five sheet names that no longer match any tab.

### Recommended fix

Adopt the **tab** scheme, because it matches the client's agreed API list, and correct the
Overview index plus every in-sheet cross-reference to it. Add a one-line mapping note to the
Overview so anyone holding an earlier draft can reconcile.

`CURRENT_STATE.md` must be updated in the same pass or the conflict simply moves.

---

## Defect 2 — runtime status is stale on at least two sheets

### The symptom

Sheets state that nothing has been activated and nothing has been called. Both statements
were true on 19 August and are false now.

| Sheet | Text as written | Actual position |
|---|---|---|
| `OF-01 Create DI` §11 | "Not activated in QS4 and no `$metadata` has been fetched. Nothing on this sheet has been called." | `API_OUTBOUND_DELIVERY_SRV;v=2` created and persisted outbound delivery `9004953174` in QS4/700 on 21.08.2026. HTTP 201, independently read back in `LIKP` / `LIPS`. |
| `OF-03 Stock Avail` §11 | "NOT activated in QS4. No `$metadata` retrieved. Property names are SAP-documented, not locally verified." | `API_MATERIAL_STOCK_SRV` returned real QS4 stock at account-model grain, per `CURRENT_STATE.md`. |

### Why it happened

v1.9 is dated 2026-08-19. The Create DI runtime proof landed on 21.08.2026, two days later.
This is ordinary drift, not an error in the original work.

### Why it matters

A client reading v1.9 today concludes that nothing has been executed. That is the opposite of
the project's actual position, and it understates delivered work on the two APIs that are
furthest along.

### Recommended fix

Update §11 on both sheets with the executed evidence and its date, and add a
"RUNTIME STATUS AS AT" line carrying the revision date so future drift is visible rather than
silent.

---

## Note on precedence

`CURRENT_STATE.md` already records the correct position for both defect-2 sheets, and
`AGENTS.md` states that v1.9 is the business-contract baseline rather than the technical
certification record. The repository's own precedence rules are sound — the workbook simply
has not caught up with them.

Neither defect changes any field-level contract in the workbook. The payloads, service names,
parameter counts and SAP field mappings are unaffected.
