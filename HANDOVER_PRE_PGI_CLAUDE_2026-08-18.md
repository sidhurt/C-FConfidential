# Handover — pre-PGI / API-03, written by Claude, 2026-08-18 (evening)

**For:** the next AI agent on the CNF pre-PGI problem.
**Read `HANDOVER_V18_SESSION.md` and the pre-PGI mechanism handover first.** This file is one session's worth of *new* work on top of them, plus an honest account of what I got wrong.
**Systems touched:** DS4/200 (read-only this session, though it is write-authorised) and QS4/700 (read-only). Nothing was posted, created, changed or committed anywhere.

---

## 1. The one-paragraph state of the problem

The portal shows a single "Generate Billing Documents" button. Behind it SAP performs six independently committed states, and the pre-PGI half of that chain — create the shipment-cost document, calculate it, account-assign it, settle it — has **no released, RFC-callable SAP interface at all**. Shipment creation (`BAPI_SHIPMENT_CREATE`) and PGI (`PostGoodsIssue` on delivery v2) are fine and standard. Everything between them is internal `SD_SCDS_*` / `SD_SCD_*` function modules in package `VTRA`, none remote-enabled, none released. **Custom SAP development is therefore mandatory for API-03 Stage B.** That is an evidenced finding, not a design preference, and it is no longer in dispute.

---

## 2. What I verified myself this session

Everything here was run by me against a live system today. Method: SAP GUI scripting via 64-bit `cscript.exe` (PowerShell COM does not work on this machine). Scripts are in `sessions/2026-08-18-runtime-certification/scripts/`.

### 2.1 `SD_SCDS_SAVE` where-used, full scope — DS4/200 — 9 hits

Evidence: `stageb-route/WHEREUSED_SD_SCDS_SAVE.txt`

The important row is **`LV54CU10`**, which is `SD_SCDS_CREATE`'s own include. **So `SD_SCDS_CREATE` calls `SD_SCDS_SAVE` internally.** Two of the six pre-PGI states collapse into one call. Do not spec them as separate stages the caller drives.

Custom callers found: `ZCLDACE_WT_TRNASFER::SHIP_COST_CAN`, `LZDACEFG_SHIP_COSTU01`, `LZDACEFG_SHIP_COSTU02`, `LZOTC_SHIP_SCD_DELETE_FGU01`, `ZSDR_PGI_SHIP_REV`.

### 2.2 `ZDACEFM_SHIP_COST` interface — DS4/200

Evidence: `stageb-route/if/ZDACEFM_SHIP_COST.tsv`

| Attribute | Value |
|---|---|
| Function group | `ZDACEFG_SHIP_COST` "Shipment Cost FG" |
| Package | `ZDEL_ACE` |
| Short text | "Shipment Cost Posting FM" |
| Changed | 08.05.2025 |
| RemoteEnabled | **blank** |
| Release status | Not released |

Interface: `I_TKNUM` (shipment number, mandatory) · `I_FKART` (cost type, mandatory) · `I_COMMIT` (flag, optional). **No EXPORT and no RETURN parameter at all.**

**Read this carefully — see §4.1.** I initially presented this as "the client already built the CNF wrapper." That was wrong. Package `ZDEL_ACE` is the same ACE family as the weighbridge programme, which is **out of C&F scope**. Treat it as a *shape template* — it proves what a narrow single-shipment cost call looks like in this system — not as a CNF asset to reuse.

### 2.3 `FKART` is not a constant — QS4/700

Evidence: `stageb-qs4/VFKK_sample2000.txt`, `stageb-qs4/VFKK_settled.txt`

| Sample | Rows read | `FKART` | Statuses | Dates |
|---|---|---|---|---|
| `VFKK` unfiltered | 201 | all **`Z006`** | `STBER=C`, STFRE/STABR **blank** | all 31.03.2026 — one batch |
| `VFKK` where `STABR=C` | 201 of 2000 | all **`Z001`** | `STBER=C`, `STFRE=C`, `STABR=C` | spread Sep–Oct 2024 |
| `VFKK` doc `2100005093` | 1 | **`Y003`** | `STBER=C` only | Feb 2024 |

Three cost-document types, behaving differently. **`Z001` is the only type observed completing the full lifecycle.** `Z006` documents calculate and then stop — and remember that blank `STFRE`/`STABR` means *"not relevant"*, not *"not done"*.

**Consequence for the contract:** `ZDACEFM_SHIP_COST`-style calls take `I_FKART` as a **mandatory** input, so CNF must supply a cost type. It cannot be hardcoded to one value. Either derive it from the shipment/planning point or make it a caller-supplied field in API-03 §4. This is an unfilled cell in the workbook today.

**Confidence limit:** 201 of 2000 rows read — the ALV lazy-loads and I did not page it. The settled sample is 2024-dated while the `Z006` block is 2026, so a type migration over time is not ruled out. Page the ALV before treating the distribution as population-scale.

### 2.4 A PGI counter-example — QS4/700

Evidence: `stageb-qs4/VFKP_Z006_probe.txt`, `VTTP_1600697272.txt`, `LIKP_0180915535.txt`

```
cost doc 1600698899  FKART=Z006  FKPTY=Z004  STBER=C  STFRE=blank  STABR=blank  EBELN=none  LBLNI=none
  └─ VFKP-REBEL → shipment 1600697272
       └─ VTTP → delivery 0180915535
            └─ LIKP: WBSTK=C, WADAT_IST=31.03.2026   ← PGI posted
```

**PGI completed on a delivery whose cost document was never settled.** So SAP does not universally block PGI on settlement.

**This does not close the question, and you must not report it as if it does.** The delivery is `LFART = EL`, not a `ZLF`/`ZNL` dispatch type, and `Z006` is settlement-*irrelevant* by configuration. It proves PGI proceeds when settlement is not relevant. It does **not** prove PGI is permitted when settlement *is* relevant but incomplete.

**The decisive test is a `STABR = A` document** — relevant, started, not finished — traced to its delivery's `WBSTK`. `VFKK` with `ctxtI11-LOW=A` gets you the candidates. **This is runnable in QS4 read-only and does not need the DS4 data unblock.** It is the single highest-value query left and I ran out of session before doing it.

---

## 3. What I read but did not produce

- **v1.8 API-03 sheet, in full**, via `sessions/2026-08-18-runtime-certification/workbook/WORKBOOK_VALUES.json` (PowerShell `ConvertFrom-Json`; there is no working `node` or `python` on this machine). This is much cheaper than opening the workbook. Sheet keys are the short names — `API-03 Invoice Create`, `API-04 Shipment Cost`, etc.
- The certification-session documents, the Stage-B findings, and the captured `SD_SCDS_*` interfaces.

**The precise hole in the workbook:** API-03 §4 *Request properties* has field-level rows for stages A, C, D and E, and **nothing for stage B** — just a prose note that the route is unidentified. §8 parks the transport fields (`ZZVEHICLE_NO`, `ZZDRIVER_NAME`, `ZZDRIVERMOB`, `ZZLR_GR_NO`, `ZZLR_GR_DATE`, `ZZGROSS_WT`/`ZZNET_WT`/`ZZTARE_WT`) as "belong to the unidentified stage-B route." **They are now placeable** — they sit on `BAPISHIPMENTHEADER` as client append fields, and the shipment-create call is the request surface. Filling §4 stage B is the concrete next deliverable.

---

## 4. Where I was wrong — read this before trusting anything above

### 4.1 I claimed the wrapper was already built

I found `ZDACEFM_SHIP_COST`, saw an interface that matched the CNF need almost exactly, and told the user the custom gap was nearly free — "one standard call plus one existing wrapper to expose, not three custom services." Then the user's handover established that the surrounding `ZDACE_*` code is **weighbridge processing, out of C&F scope**, cited as precedent only.

The finding is still real and worth having. The conclusion I hung on it was not. If you are tempted to reuse an ACE-family object, check its scope first.

### 4.2 I called `BAPI_SHIPMENT_COST_ESTIMATE` released

I told the user "unreleased isn't what we found," reasoning from the 2026-08-17 Stage-B trace where `TFDIR-FMODE = R`. **`FMODE = R` is remote-enablement, not release status.** The 2026-08-18 SE37 capture — in this session's own handover, which I had read — says remote-enabled **but not released**, alongside `BAPI_OUTB_DELIVERY_CHANGE` and `BAPI_SHIPMENT_CHANGE`. Codex had it right.

### 4.3 I misread `SD_SCD_ITEM_ACCT_ASSIGNMENT`

I saw `I_OPT_BACKGROUND = 'X'` and called it "the background-ready exception." The better reading is the one in the user's handover: `T185`/`T185V` + `SY-CPROG` + `E_FCODE` make it **heavily screen-flow bound — do not wrap directly.** `E_FCODE` and `I_CUA_ROUTINE_EXT` are CUA constructs. A default flag does not override structural coupling.

### 4.4 The pattern

All three errors are the same mistake: reasoning from an older or partial artefact when a newer one was already on disk and already read. **This repository has multiple documents describing the same fact at different dates, and the older ones are frequently wrong.** Sort by mtime, not by filename. The frontier of the work is often a file in a subdirectory, newer than everything at the session root.

---

## 5. My opinion, labelled as opinion

**One external command, not three.** The user's handover argues this and I agree, on grounds stronger than the earlier "concede it to the client for relationship reasons" advice:

1. A custom SAP wrapper is required no matter what, so three endpoints is three wrappers — more build, not less.
2. Stage state lives in SAP documents (`VTTK`, `VFKK`/`VFKP`, `LIKP`). Only SAP can answer "how far did it get." CPI driving three calls would be guessing at state it does not own.
3. Check-then-act against those documents makes retry naturally safe and prevents duplicate shipments — the single most valuable property this API can have.

**Keep the SAP wrapper thin, and be explicit about what it does not own.** It should expose the call, control commit deliberately rather than inheriting `SD_SCDS_CREATE`'s `I_OPT_COMMIT = 'X'` default, return a stage-level status, and read back `VTTK-FBGST`/`ARGST` and `VFKP-EBELN`/`LBLNI`. It should **not** own `ProcessId`, `ProcessStatus`, `Stages[]`, `RequestId` or `IsReplay` — v1.8 §8 and §10 assign those to CPI/T2 and that assignment is correct, because SAP holds no cross-stage process state and cannot roll back a committed PGI regardless of how the ABAP is written. If the wrapper starts holding process state you have rebuilt `ZMM_SCRUM_SER_PO`, which §10 cites as the cautionary example.

**Say "not atomic" out loud, early, in writing.** Once the shipment commits it is committed. Recovery is reversal, not rollback. This is true for one API and for three, so it is not an argument between them — but it is the thing that will be held against the design later if nobody wrote it down.

**On naming — this is a real risk, not fussiness.** The business hard-stopped `ZCNF_*` custom OData services on 2026-08-14, and v1.8 was rebuilt specifically to drop those names. The engineering is justified now and the evidence supports it. But framing matters: this is *exposing internal SAP function modules that have no released interface*, which is a narrow and defensible ask. Presenting a `ZCNF_DISPATCH_SRV` service tree reopens a decision that already went against the project.

**On `BAPI_SHIPMENT_COST_ESTIMATE` (API-04):** it is unreleased. If it is adopted, that needs a named owner for upgrade risk, the same as the `SD_SCDS_*` modules. Its non-posting behaviour is still **unproven** — the certification matrix is right to flag that, and it should be proven with before/after `VFKK`/`VFKP` key counts, not assumed from the word "estimate."

---

## 6. What I would do next, in order

1. **The `STABR = A` trace in QS4** (§2.4). Read-only, no dependencies, closes the highest-priority open question or sharpens it. Start here.
2. **Read `meetings/2026-08-17-create-invoice-orchestration-design.md`.** I never opened it. The API-03 design should be checked against what was actually agreed in the room before anything is written into the workbook — there may be commitments that cut across the technical recommendation.
3. **Fill v1.8 API-03 §4 stage B** with the `BAPISHIPMENTHEADER` + `ZZ*` request contract and a decision on how `FKART` is supplied. Produce it as a separate delta/correction report — **do not edit the v1.8 workbook directly**; that rule is in the certification handover and it is a good one.
4. **`SAPLV56I_BAPI` source** — does saving via `BAPI_SHIPMENT_CREATE` trigger `SD_SCDS_CREATE`? If yes the exposed surface shrinks materially. Note the where-used on `SD_SCDS_CREATE` returned only custom callers, which is evidence against, but does not exclude a dynamic call.
5. **`SD_SCDS_RELEASE` invoker** — zero static callers at full scope. Needs SAT/ST05 during a real VI02 settlement. Low priority until someone can run one.

---

## 7. Practical traps I hit today

- **The ABAP editor cannot be dumped.** `SE37 → Source code` exposes a `GuiShell` with `SubType = AbapEditor`; its `.Text` returns 19 characters. Do not burn a cycle on it. Use where-used and interface capture instead, which are ALV-based and read reliably.
- **SE16 selection fields are positional and stateful.** `ctxtI1-LOW`, `txtI2-LOW`, … and the type prefix differs per field. Worse, **a value left in a field from a previous run silently ANDs into the next query** and you get a confusing empty result. Always run `FIELDS` mode first and clear fields you are not using.
- **Verify the positional map with a positive control.** For `VFKK` I confirmed `I14`/`I17` were the time fields because they pre-fill `00:00:00`, which fixed the whole 17-field mapping.
- **Result columns are positional too.** `LIKP` needed `$9` for `LFART` and `$221` for `WBSTK`; guessing the index gives plausible-looking garbage. Read the `HDR` line and count.
- **Two SE16 reader scripts exist and behave differently.** `ds4_se16.vbs` writes a file and is DS4-guarded; `se16_read_list.vbs` reconstructs a classic list from control ids and prints to stdout only — passing it an output path silently treats it as a selection field. `qs4_se16_read.vbs` locates QS4 by system name, never by index.
- **QS4 and DS4 are separate connections.** `sap_probe.vbs` first, every time. QS4 was not connected when I started and the user had to open it.
- **One SAP script at a time.** Concurrent `cscript.exe` processes corrupt the session. `tasklist //FI "IMAGENAME eq cscript.exe"` before starting.

---

## 8. Working with this user

Direct, fast, technically strong, under deadline pressure. Wants decisions, not surveys, and will say so bluntly if you produce volume instead of answers. **Do not write long documents when a short answer will do** — I was told to stop mid-session for exactly that, and the criticism was fair. Prefer real system work over documentation; write things down only when the finding is settled and someone else needs it.

Pushes back hard and is usually right. When wrong, say so once, plainly, and move on — no ceremony.

`SPI` is parked by client-side disagreement; the glossary overstates it. **Do not raise it as a finding.**
