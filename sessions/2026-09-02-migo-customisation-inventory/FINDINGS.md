# MIGO customisation inventory — method and live result

**Date:** 2026-09-02 · **System:** QS4/700 · **User:** QNOVATE8
**Scope:** Read-only SE16 via SAP GUI Scripting. Nothing posted, activated or changed.

## The method — nine registries

A change to standard MIGO can hide in exactly nine places. Naming conventions are not evidence;
each has an authoritative registry table.

| # | Mechanism | Registry | Query used |
|---|---|---|---|
| 1 | Customer exits (SMOD/CMOD) | `MODACT` (project→enhancement), `MODATTR` (status), `MODSAP` (components) | full read of `MODACT` |
| 2 | Enhancement Framework — BAdI implementations | `ENHHEADER` where `ENHTOOLTYPE=BADI_IMPL` | `ENHNAME=Z..Z~`, `VERSION=A` |
| 3 | Enhancement Framework — source-code plug-ins (implicit **and** explicit) | `ENHHEADER` where `ENHTOOLTYPE=HOOK_IMPL` | same read |
| 4 | What each enhancement actually touches | `ENHOBJ` (`OBJ_TYPE`/`OBJ_NAME`) | `ENHNAME=Z..Z~`, `VERSION=A` |
| 5 | Exact source position of a plug-in | `ENHINCINX` (`ID`, `METHOD`, `FULL_NAME`) | not yet pulled |
| 6 | Classic BAdIs (pre-Enhancement-Framework) | `SXS_ATTR` / `SXC_EXIT`, surfaced as `OBJ_TYPE=SXCI` in `ENHOBJ` | via `ENHOBJ` |
| 7 | Modifications / repairs to SAP objects | `SMODILOG` | `OBJ_NAME=MI..MJ` and `M..N` |
| 8 | Business Transaction Events | `TBE01`, `TBE31`, `TPS34` | not yet swept |
| 9 | Validations / substitutions, output determination | `GB01`/`GB92`, `T160M`, NAST config | not yet swept |

Two range-query mechanics matter, both learned the hard way here:

- `_` (0x5F) sorts **above** `Z` (0x5A). An upper bound of `...ZZZZ` silently excludes every name
  containing an underscore. Use `Z..Z~` (`~` = 0x7E) or increment the last character.
- Class and service names truncate at 30 characters. `API_MATERIAL_DOCUMENT_SRV`'s provider is
  `CL_API_MATERIAL_DOCUME_DPC_EXT`, not `CL_API_MATERIAL_DOCUMENT_DPC_EXT`.

## What QS4 actually has

**242 active customer enhancement implementations** in the `Z*` namespace:

| Type | Count | What it is |
|---|---:|---|
| `HOOK_IMPL` | 171 | source-code plug-ins sitting inside SAP programs |
| `BADI_IMPL` | 71 | BAdI implementations |

Mapped across **610** enhancement→object links. Object types touched: `REPS` 144, `CLAS` 89,
`FUGR` 81, `ENHS` 81, `PROG` 79, `INTF` 72, `FUNC` 26, `SXCI` 17, `METH` 13, `ENHO` 8.

### Everything that touches MIGO or goods movement

**Six** BAdI implementations on `MB_MIGO_BADI` — not one:

| Enhancement implementation | Notes |
|---|---|
| `ZEI_MM_MB_MIGO_BADI` | the one already known; class `ZCLMM_MB_MIGO_BADI`, screen `ZMMR_MIGO_SCREEN_ADD` 0101 |
| `ZDACE_CUSTOM_MIGO_HEADER_TAB` | custom MIGO header tab |
| `ZDACE_CUSTOM_MIGO_HEADER_TAB_N` | second header-tab implementation |
| `ZEI_MM_DELIVERY_NOTE` | also has a classic BAdI object `ZSDEI_DELIVERY_NOTE3TR` |
| `ZIML_CAN_CHECK` | cancellation check |
| `ZMM_SEND_MAIL` | also classic BAdI object `ZMM_SEND_MAIL3TR` |

**Two** BAdI implementations on `MB_GOODSMOVEMENT` — the posting-level BAdI:

| Enhancement implementation | Notes |
|---|---|
| `ZEI_MM_GOODSMVT_BAPI_CUSTOM` | name indicates BAPI-path custom logic |
| `ZMB_DOCUMENT_BADI` | classic BAdI object `ZZEMPL_MB_DOC3TR` |

**Two** source-code plug-ins inside function group `MIGO` itself:

| Enhancement implementation | Include |
|---|---|
| `ZDACE_MODIFY_MIGO_ITEM_QTY` | `LMIGOKC2` |
| `ZMM_MIGO_DATA_CHECK` | `LMIGOKG1` |

**One** on function group `MBWL` (goods movement): `ZPP_COR6_RMC`.

### Customer exits (CMOD)

44 project→enhancement assignments. The only goods-movement-relevant one is
`ZMM_RESE` → `MBCF0007` (reservation update). No `MB_CF001`, `MBCF0002` or `MBCF0005`.
Activation status via `MODATTR` not yet confirmed.

### Modifications to SAP objects

`SMODILOG` filtered `OBJ_NAME=MI..MJ` returns **no entries**. No MIGO object has been modified
or repaired by hand. The broader `M..N` sample (200 rows, capped) shows only `MOD_USER=TC_USER`
with `OPERATION=ALL`, consistent with note/upgrade adjustment rather than hand modification.

**MIGO in this system is customised entirely through supported enhancement mechanisms.**

## Why this matters for Submit MIGO

The custom behaviour behind MIGO splits across two different layers, and they are reached by
different callers:

- `MB_MIGO_BADI` (6 implementations) is **MIGO transaction runtime**. A BAPI or OData caller
  does not pass through it.
- `MB_GOODSMOVEMENT` (2 implementations) is at the **posting layer**, which `BAPI_GOODSMVT_CREATE`
  does traverse.
- The 2 source plug-ins inside function group `MIGO` are likewise MIGO-runtime only.

So a wrapper around `BAPI_GOODSMVT_CREATE` inherits the 2 posting-layer implementations but
**not** the 6 MIGO-runtime ones nor the 2 MIGO source plug-ins. Any custom logic the business
depends on that lives in those 8 has to be either re-implemented in the wrapper or refactored
out of MIGO-specific structures. That is the real scoping question for the build, and it is
now enumerable rather than speculative.

## Still to sweep

- `MODATTR` — activation status of the CMOD projects
- `ENHINCINX` — exact source positions of `ZDACE_MODIFY_MIGO_ITEM_QTY` and `ZMM_MIGO_DATA_CHECK`
- `Y*` namespace (only `Z*` swept)
- BTEs (`TBE01`/`TBE31`/`TPS34`), validations/substitutions, output determination
- What each of the 6 `MB_MIGO_BADI` implementations actually does — source not yet read

## Evidence

`evidence/`: `MODACT_ALL.txt`, `ENHHEADER_Z.txt` (242 rows), `ENHOBJ_Z.txt` (610 rows),
`SMODILOG_ALL.txt`, `SMODILOG_M.txt`, `DD02L_ENH_TABLES.txt`, `DD03L_ENH.txt`
