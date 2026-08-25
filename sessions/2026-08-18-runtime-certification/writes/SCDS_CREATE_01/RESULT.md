# EVIDENCE RUN — SD_SCDS_CREATE driven standalone

**System:** DS4 client 200 · **User:** QNOVATE8 · **Date:** 2026-08-19
**Question being answered:** can the internal, non-RFC shipment-cost function modules be driven from outside their dialog transaction? This is the make-or-break input to the wrapper design.

## Why this mattered

`SD_SCDS_CREATE` and `SD_SCDS_RELEASE` are not released and not RFC-enabled. They are internal SAP function modules normally driven by transaction `VI01`/`VI02` (`SAPMV54A`). If they turn out to depend on dialog/screen state, a wrapper around them is not viable and the whole design changes.

## Input

Target: shipment `0000001001`, created and committed earlier the same session (see `../SHIPMENT_CREATE_01/RESULT.md`).

| Parameter | Value | Note |
|---|---|---|
| `C_REFOBJ_RANGE` row 1 — `VBTYP` | `8` | shipment document category |
| `C_REFOBJ_RANGE` row 1 — `REBEL` | `0000001001` | the shipment |
| `I_FKART` | `0001` | cost type, from `TVFT` |
| `I_OPT_COMMIT` | `X` | **SAP's own default** |
| `I_OPT_PACKAGE_SIZE` | `1` | default |
| `I_OPT_LOG_SAVE` | `X` | default |

## Result

Runtime **3,043,997 µs** (~3 s). No short dump. No error. No modal.

| Parameter | In | Out |
|---|---|---|
| `C_REFOBJ_RANGE` | 1 entry | **0 entries** — consumed |
| `E_REFOBJ_RANGE_LOCKED` | — | **0 entries** — nothing rejected or locked |

Table state afterwards: `VFKK` 0 rows, `VFKP` 0 rows — **no cost document created**.

## What this proves

**`SD_SCDS_CREATE` runs standalone.** Called directly from SE37, with no `VI01` transaction context, no screen state and no dialog, it accepted its parameters, executed cleanly in three seconds, consumed the input range and returned normally.

That is the answer we needed. **The internal function is drivable from custom code, so the wrapper is viable.** It also matches the fact that the client's own `ZDACEFM_SHIP_COST` calls this same module from a plain function module today.

Note also that `I_OPT_COMMIT` **defaults to `X`** — unlike `BAPI_SHIPMENT_CREATE`, this module persists on its own unless told otherwise. The two behave differently, which is exactly the kind of thing a wrapper must normalise rather than leave to the caller.

## What this does not prove

**No cost document was produced**, so we have not yet seen the module do its actual job.

The most likely reason is the target: shipment `1001` is a bare header with **no deliveries, no service agent, no route**. There is genuinely nothing to cost. `E_REFOBJ_RANGE_LOCKED` came back empty, which is the module's way of saying it did not reject or fail to lock the reference object — it processed it and had nothing to do.

That reading is consistent but **not confirmed**. It cannot be confirmed until a cost-relevant shipment exists, which requires a delivery, which requires the DS4 master data still outstanding.

## `SD_SCDS_RELEASE` — interface captured, not executed

Opened in SE37. Not run, because there is no cost document to release.

| Parameter | Default | Relevance |
|---|---|---|
| `I_OPT_WITH_DIALOG` | **`X`** | Defaults to dialog mode. It is optional and settable, so a headless call is possible — but this is the parameter that decides whether it can run unattended, and it has **not** been tested. |
| `I_REFOBJ_TAB` | 0 entries | reference objects, same shape as the create |
| `I_TCODE` | blank | calling transaction |
| `I_POCRMSG` | 0 entries | |
| `C_SCD_TAB` | 0 entries | the cost documents to settle |

## Standing risk

Settlement remains the least-evidenced step in the chain:

- no static callers anywhere in the system
- defaults to dialog mode
- never executed

`SD_SCDS_CREATE` is now proven drivable. **Do not extend that claim to `SD_SCDS_RELEASE`** — present the create half as evidenced and settlement as the piece still needing proof.

## Evidence files

`RUN.txt` · `RESULT_FULL.txt` · `POST_VFKK.txt` · `POST_VFKP.txt`
