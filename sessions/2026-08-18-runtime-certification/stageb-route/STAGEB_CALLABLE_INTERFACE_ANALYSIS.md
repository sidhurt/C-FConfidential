# Stage-B callable interface analysis — `SD_SCDS_*` / `SD_SCD_*`

**System:** DS4/200 · **Method:** SE37 interface display, read-only · **Date:** 2026-08-18
**Raw evidence:** `stageb-route/if/*.tsv` (9 files, UTF-16LE, captured 17:10–17:18)
**Status:** `INTERFACE ONLY`. Nothing in this document has been executed. It is the exact contract of each module, not proof that any of them behaves as described.

This closes the second bullet under *"What this does not settle"* in [CALLABLE_MECHANISM_FOUND.md](CALLABLE_MECHANISM_FOUND.md) — the interfaces are now captured and read.

---

## 1. Release status — stronger evidence than before

`CALLABLE_MECHANISM_FOUND.md` inferred "not remote-enabled" from a blank `TFDIR-FMODE`. The SE37 capture carries the attribute **explicitly**, and it is worse than not-RFC:

| Module | Function group | `RemoteEnabled` | `ReleaseStatus` | Changed on |
|---|---|---|---|---|
| `SD_SCDS_CREATE` | `V54C` | *(blank)* | **Not released** | 20.11.2020 |
| `SD_SCDS_RELEASE` | `V54R` | *(blank)* | **Not released** | 06.06.2015 |
| `SD_SCDS_SAVE` | `V54U` | *(blank)* | **Not released** | 06.06.2015 |
| `SD_SCDS_REVERSE` | `V54R` | *(blank)* | **Not released** | 06.06.2015 |
| `SD_SCDS_SHIPMENT_UPDATE` | `V54U` | *(blank)* | **Not released** | 30.01.2017 |
| `SD_SCD_ITEM_CALCULATE` | `V54B` | *(blank)* | **Not released** | 06.06.2015 |
| `SD_SCD_ITEM_ACCT_ASSIGNMENT` | `V54K` | *(blank)* | **Not released** | 06.06.2015 |
| `SD_SCD_HISTORY_SETTLEMENT` | `V54O` | *(blank)* | **Not released** | 06.06.2015 |
| `ZDACE_FM_WEIGH_BRIDGE_INT` | *(custom)* | `X` | — | — |

All nine SAP modules sit in package **`VTRA`**. Every one is `RegularFunctionModule = X`, `UpdateModule` blank.

**Two independent locks, not one.** Not remote-enabled means no RFC/CPI caller. Not released means no contract stability guarantee across upgrades. Either alone would require a wrapper; both together mean the wrapper carries named, ongoing upgrade-risk ownership.

**Mitigating fact, stated honestly:** the change dates are old and stable — seven of the nine last changed in 2015. Low churn is not a release guarantee, but it is the difference between "unsupported and volatile" and "unsupported and quiet." Say it that way; do not upgrade it to "safe."

---

## 2. The three findings that change the design

### 2.1 `SD_SCDS_CREATE` commits by itself unless told not to

```
I_OPT_COMMIT   TYPE BOOLE_D   DEFAULT 'X'   optional
```

A caller that omits this parameter **gets a database commit it did not ask for**. Combined with `I_OPT_LOG_SAVE` (also default `'X'`), the module's default posture is fire-and-persist.

This is the single most important fact for the orchestration design. Any wrapper must set `I_OPT_COMMIT` explicitly on every call — including the ones where it wants the default — so the commit boundary is visible in the code rather than inherited from a default that a later SAP release could change.

It also means the **check-then-act** pattern is available: create with `I_OPT_COMMIT = ' '`, inspect, then commit deliberately. That was previously an assumption; it is now supported by the interface.

### 2.2 `SD_SCDS_CREATE` is range-based, and it already returns partial completion

```
CHANGING  C_REFOBJ_RANGE         TYPE V54A0_REF_TAB
EXPORT    E_REFOBJ_RANGE_LOCKED  TYPE V54A0_REF_TAB
IMPORT    I_OPT_PACKAGE_SIZE     LIKE RV54A-PACSZ  DEFAULT '1'  optional
```

Short text: *"Frachtkosten anlegen (online, batch)"* — freight costs, online **and batch**. This is SAP's own mass entry point, not a single-document call. It takes a range of reference objects and processes them in packages.

`E_REFOBJ_RANGE_LOCKED` returns the reference objects it **could not lock**. That is a ready-made partial-completion surface: the caller learns exactly which items did not process and why, without inventing its own reconciliation. The v1.7/v1.8 requirement for partial-completion handling has a standard answer here.

`I_OPT_PACKAGE_SIZE` defaults to `1`, so single-document behaviour is the default and the batch capability is opt-in.

### 2.3 "Release" means transfer — SAP's own naming now confirms it

`STAGEB_RELEASE_FINDING.md` §3 concluded from status-field distributions that settlement (`STABR`) was the strongest candidate for what the business calls "release." The module naming agrees independently:

| Module | Function-group text | Short text (German) | Literal meaning |
|---|---|---|---|
| `SD_SCDS_RELEASE` | Release - shipment cost items | *Überleitung der Frachtkostenpositionen* | **transfer / handover** of freight cost items |
| `SD_SCDS_REVERSE` | Release - shipment cost items | *Storno der Frachtkostenpositionen* | reversal of freight cost items |
| `SD_SCD_ITEM_ACCT_ASSIGNMENT` | Account assignment - shipment costs | *Ermittlung der Kontierung…* | determination of account assignment |
| `SD_SCD_ITEM_CALCULATE` | Shipment cst cal | *…für Berechnung vorbereiten und berechnen* | prepare and calculate |

SAP's English label is "Release"; SAP's own German short text for the same module is *Überleitung* — transfer. **Two independent evidence lines now agree that release = the transfer/settlement step**, the one that produces `VFKP-EBELN` and `LBLNI`. This is no longer an inference from one status sample.

It does **not** establish that the client uses the word the same way. That remains a functional confirmation (see §6).

---

## 3. The dialog coupling — the real reason exposure is non-trivial

Three modules take `I_T180` as a **mandatory, non-optional** import:

| Module | Mandatory `I_T180`? |
|---|---|
| `SD_SCDS_SAVE` | **yes** |
| `SD_SCD_ITEM_CALCULATE` | **yes** |
| `SD_SCDS_SHIPMENT_UPDATE` | **yes** |

`T180` is *"Screen Sequence Control: Transaction Default Values"* — a dialog-transaction construct. A non-dialog caller has to synthesise screen-sequence control data that has no meaning outside `SAPMV54A`.

Three modules also default to dialog behaviour:

| Module | Parameter | Default |
|---|---|---|
| `SD_SCDS_RELEASE` | `I_OPT_WITH_DIALOG` | **`'X'`** |
| `SD_SCDS_SAVE` | `I_OPT_RELEASE_WITH_DIALOG` | **`'X'`** |
| `SD_SCD_ITEM_ACCT_ASSIGNMENT` | `I_OPT_BACKGROUND` | `'X'` *(background — the exception)* |

**A background caller that omits `I_OPT_WITH_DIALOG` on `SD_SCDS_RELEASE` will attempt to open a dialog.** In an RFC or batch context that is a failure mode, not a prompt.

`SD_SCD_ITEM_ACCT_ASSIGNMENT` is the interesting counter-example: it defaults to background *and* carries `I_CALLING_PROGRAM DEFAULT 'SAPMV54A'` plus `I_CUA_ROUTINE_EXT DEFAULT 'CUA_SET'`. SAP anticipated non-dialog use for account assignment specifically, while leaving the surrounding modules dialog-first.

**This is the concrete technical argument for why the exposure layer is real work.** It is far stronger than "the modules are internal." The modules are internal *and* structurally coupled to a screen sequence.

---

## 4. Granularity mismatch — the wrapper spans two levels

| Level | Modules | Parameter |
|---|---|---|
| Document range | `SD_SCDS_CREATE` | `C_REFOBJ_RANGE` (`V54A0_REF_TAB`) |
| Document table | `SD_SCDS_RELEASE`, `SD_SCDS_SAVE`, `SD_SCDS_REVERSE`, `SD_SCDS_SHIPMENT_UPDATE` | `C_SCD_TAB` / `I_SCD_TAB` (`V54A0_SCDD_TAB`) |
| Single item | `SD_SCD_ITEM_CALCULATE`, `SD_SCD_ITEM_ACCT_ASSIGNMENT` | `C_SCD_ITEM` (`V54A0_SCD_ITEM`) |

Three different working structures across one business sequence. A wrapper cannot pass one document handle through the chain — it must hold and convert state between range, document-table and item level. That is state the caller owns, and it is why this is orchestration rather than a passthrough.

---

## 5. The one safe thing that can be exposed today

`SD_SCD_HISTORY_SETTLEMENT` is a **pure read**:

```
IMPORT  I_VFKP           TYPE V54A0_VFKP
IMPORT  I_ONLY_INVOICE   LIKE RV54A-SELKZ  DEFAULT 'X'  optional
EXPORT  E_SETTL_HIST     TYPE V54A0_ITEM_SETTL_HISTORY
```

No `CHANGING` parameters, no commit option, no `I_T180`, function group `V54O` *"Shipment costs document flow"*, short text *"Ermitteln der Abrechnungsbelege zu Frachtkostenpositionen"* — determine the settlement documents for freight cost items.

**This answers "did settlement happen, and which MM documents resulted."** It is the natural backing for a `GetPrePgiProcessStatus`-style read and carries no posting risk. It is still not released and not RFC-enabled, so it still needs the wrapper — but it is the lowest-risk element in the whole Stage-B surface and the obvious first thing to build and test.

Caveat: it takes `I_VFKP` — a cost-document item structure, not a shipment or delivery number. The caller must already have located the cost item (via `VFKP-REBEL → VTTK-TKNUM`, per the corrected join). It is a second-hop read, not an entry point.

---

## 6. What this still does not settle

1. **Nothing has been executed.** Every statement here is read from an interface definition. Behaviour, mandatory-in-practice rules, error catalogue and actual commit semantics remain unproven — and per §8 of the standard-API handover, layers 2 and 4 routinely disagree.
2. **Whether `BAPI_SHIPMENT_CREATE` internally triggers `SD_SCDS_CREATE` on save.** Still needs source inspection of `SAPLV56I_BAPI`. If it does, the cost document may already arrive as a side effect of the released BAPI, which would materially shrink the custom surface. **This is the highest-value remaining read-only investigation** and it needs no DEV data.
3. **Who invokes `SD_SCDS_RELEASE`.** Where-used at full scope found no caller. The static index demonstrably covers standard code (`SD_SCD_ITEM_CALCULATE` returned `LV54CF02`/`LV54CF03`), so the absence is real for static calls — meaning it is invoked dynamically or from screen-flow logic. Settlement remains the one stage whose invoker is unidentified.
4. **Whether the client's "release" is this transfer step or a prior approval.** Two evidence lines now point at transfer. Functional must still confirm the vocabulary before anything is minuted.
5. **Whether settlement is a technical PGI prerequisite.** Unchanged — only a DS4 attempt to PGI an unsettled delivery decides it, and that needs the blocked test chain.

---

## 7. Consequence for the API-03 Stage-B design

The picture is now specific enough to state plainly:

- The **orchestration already exists** in `ZDACE_CL_STO_PROCESS` (weighbridge-driven, dialog entry point `ZDACE_WT`). CNF does not design the sequence.
- The **engine is standard** — `SD_SCDS_CREATE` and the `V54*` family — and the client already wraps `SD_SCDS_CREATE` in three places.
- The gap is an **exposure layer**: not released, not RFC-enabled, dialog-coupled, three granularity levels, with a commit that fires by default.

That is a `CUSTOM SAP GAP` on evidence, and it is now evidenced rather than inferred from a failed search. But it is a **thin exposure wrapper over existing standard and existing client code** — not a new freight-costing implementation. The estimate and the risk conversation should be framed that way.

---

## 8. GUI session 2026-08-18 (later) — the client already built the wrapper

Read-only DS4/200, SE37 where-used + `TFDIR` + SE37 interface capture.

**`SD_SCDS_SAVE` where-used, full scope — 9 hits.** `LV54CU10` is `SD_SCDS_CREATE`'s own include, so **create calls save internally**. Custom callers: `ZCLDACE_WT_TRNASFER::SHIP_COST_CAN`, `LZDACEFG_SHIP_COSTU01` ("Shipment Cost Posting FM"), `LZDACEFG_SHIP_COSTU02` ("Ship Cost Delete FM"), `LZOTC_SHIP_SCD_DELETE_FGU01`, `ZSDR_PGI_SHIP_REV` ("PGI Shipment Reversal"). Evidence: `WHEREUSED_SD_SCDS_SAVE.txt`.

**`ZDACEFM_SHIP_COST` — the finding.** Function group `ZDACEFG_SHIP_COST` "Shipment Cost FG", package `ZDEL_ACE`, changed **08.05.2025**. Interface: `if/ZDACEFM_SHIP_COST.tsv`.

| Parameter | Type | Optional |
|---|---|---|
| `I_TKNUM` | `TKNUM` — shipment number | no |
| `I_FKART` | `FKART_T` — shipment cost type | no |
| `I_COMMIT` | `FLAG` | yes |

**The client has already built a single-shipment cost-posting wrapper over `SD_SCDS_CREATE`/`SD_SCDS_SAVE`, with explicit commit control.** That is very close to the CNF `PrepareForPgi` shape and it is actively maintained.

Two caveats, both material:
1. **`RemoteEnabled` is blank** — not RFC-enabled, so CPI cannot call it today. That is a function-module attribute change, not a build.
2. **No `EXPORT` or `RETURN` parameter was captured** — only the three imports. A caller gets no document number and no message table back. Any exposure must add a result surface; do not assume one exists.

Not executed. Interface evidence only.
