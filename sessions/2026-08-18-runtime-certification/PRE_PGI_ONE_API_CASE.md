# Pre-PGI: one API, not three — the evidence

**Scope:** shipment creation → shipment cost estimate → shipment cost document + cost release. Ends immediately before PGI. Billing, e-invoice, e-way and the Hybris repair cron are out of scope for this decision.
**Evidence:** QS4/700 read-only, DS4/200 read-only, 2026-08-18. Every figure below is a live system read, not an estimate.

---

## 1. The finding that decides it

**10,496 shipment-cost documents in QS4 are stranded right now** — calculated, settlement relevant, never completed.

Full population, true `SE16` hit counts:

| `VFKK-STABR` | Meaning | Count | Share |
|---|---|---|---|
| `C` | fully transferred | 3,021,454 | 52.4% |
| blank | not relevant for transfer | 2,737,318 | 47.4% |
| **`A`** | **relevant, not transferred** | **10,496** | **0.18%** |
| `B` | partially transferred | 0 | — |
| **Total** | | **5,769,268** | |

**State the 0.18% yourself before anyone computes it.** This is not a systemic collapse and must not be presented as one. It is a small tail — and that is precisely why it matters:

> This is the **best case**. It comes from ABAP running inside SAP, in the same LUW, with no network between the stages, tuned over years. It still strands 10,496 documents. A new integration that splits these stages across a network boundary, with an orchestrator that cannot see `VFKK`, will not beat 0.18%.

At the 4,000 logistics calls/day cited on 2026-08-17, 0.18% is roughly **7 stranded documents per day, ~2,600 a year**, each carrying unposted freight cost with no freight PO and no service entry. That is an accrual exposure, not a rounding error.

`VFKK` where `STABR = A`:

| Field | Value | Meaning (from domain `STABR_K`) |
|---|---|---|
| `STBER` | `C` | fully calculated |
| `STFRE` | `A` | account assignment **relevant, not completed** |
| `STABR` | `A` | transfer **relevant, not completed** |
| `EBELN` | blank | no freight purchase order |
| `LBLNI` | blank | no service entry sheet |

`A` does **not** mean "not applicable". The domain text for `A` is *"Not transferred"*. Blank is the "not relevant" value, and these are not blank. These documents were supposed to complete and did not.

Worked example, traced end to end:

```
VFKK 1300105310   FKART=Z003   STBER=C  STFRE=A  STABR=A
 └ VFKP 000001    FKPTY=Z002   12,144.00 INR   TDLNR=0013000913
                  EBELN=blank  LBLNI=blank
     └ REBEL → shipment 1300105363
         └ VTTP → delivery 0080387199
             └ LIKP  LFART=ZLF   WBSTK=C   WADAT_IST=13.03.2024   FKSTK=C
```

**The delivery went on to PGI and was billed anyway.** Freight cost was never transferred to MM. No freight PO, no service entry sheet, no accrual clearing — on 10,496 documents.

This is not a hypothetical failure mode. It is the current production behaviour of a stage-split process.

---

## 2. Why three APIs makes this worse, not better

The argument for three APIs is error visibility. The evidence says the opposite.

| | Three separate calls | One resumable call |
|---|---|---|
| Who knows the chain stalled at stage 3? | Nobody — call 2 returned success | The call reports `stage`, so the caller always knows |
| Where is chain state held? | CPI/portal, which cannot see `VFKK`/`VTTK` | SAP, which owns the documents |
| Retry semantics | Re-invoking a stage may duplicate | Check-then-act reads existing documents, resumes, never double-creates |
| Failure signature | three opaque successes, one silent gap | one response naming the failed stage and SAP's own message |

The 10,496 are what "each stage reports its own success" leaves behind, even at 0.18%, even inside one system. Three endpoints across a network boundary removes the two things that keep that number low today: shared program state, and a caller that can read the documents.

**Do not overclaim this.** The honest sentence is: *"splitting the stages is survivable — SAP's own implementation survives it at 0.18% — but nothing about three endpoints makes that number smaller, and several things make it larger."*

---

## 3. Three of the four stages have no callable SAP interface

| Stage | Mechanism | Released? | RFC-enabled? |
|---|---|---|---|
| Shipment create | `BAPI_SHIPMENT_CREATE` | Yes | **Yes** |
| Cost estimate | `BAPI_SHIPMENT_COST_ESTIMATE` | **No** | Yes |
| Cost document create | `SD_SCDS_CREATE` | No | **No** |
| Cost release / transfer | `SD_SCDS_RELEASE` | No | **No** |

Verified by `TFDIR` (`FMODE` control: `BAPI_SHIPMENT_CREATE` = `R`, all `SD_SCDS_*` blank) and full-scope SE37 where-used with a positive control proving the index covers SAP standard code.

**Custom ABAP is mandatory either way.** Three endpoints means three wrappers, not less build. The choice is only how many doors we cut, not whether we cut any.

---

## 4. SAP itself refuses to split two of the stages

`SD_SCDS_CREATE` calls `SD_SCDS_SAVE` internally — proven by where-used: `SD_SCDS_SAVE` is called from `LV54CU10`, which is `SD_SCDS_CREATE`'s own include.

Create and persist are **one** operation at the SAP level. Exposing them as separate endpoints would be inventing a boundary SAP does not have.

This matches what the room already agreed on 2026-08-17: *"costing-document creation and costing release will be merged into one call"* (`S6`, `[00:12:04]`–`[00:12:48]`). The technical evidence supports the decision that was already taken.

---

## 5. The wrapper shape is already proven in this system

`ZDACEFM_SHIP_COST` — function group `ZDACEFG_SHIP_COST`, package `ZDEL_ACE`, "Shipment Cost Posting FM", changed 08.05.2025:

| Parameter | Type | |
|---|---|---|
| `I_TKNUM` | shipment number | mandatory |
| `I_FKART` | cost type | mandatory |
| `I_COMMIT` | flag | optional |

One shipment in, cost document posted, commit under caller control. **This is the shape we are proposing, and it already exists and runs here.**

**Two caveats, stated plainly.** First, this object belongs to the weighbridge programme, which is **out of C&F scope** — it is cited as proof of feasibility and shape, not as a CNF asset to reuse. Second, it has **no EXPORT and no RETURN parameter**: it cannot tell the caller what it created or why it failed. Our version must return document numbers and messages. That is the one thing to improve on, not copy.

---

## 6. What the response must carry

Modelled on a real completed chain (delivery `9004953084`, 17.08.2026):

```json
{ "shipment":      "1100605471",
  "costDocument":  "1100608871",
  "costType":      "Z001",
  "calculated":    true,          // VFKP-STBER = C
  "accountAssigned": true,        // VFKP-STFRE = C
  "settled":       true,          // VFKP-STABR = C
  "freightPO":     "6000105831",  // VFKP-EBELN
  "serviceEntry":  "1003382363",  // VFKP-LBLNI
  "stage":         "READY_FOR_PGI" }
```

That chain completed in **two seconds** — shipment created 11:11:28, settled 11:11:30. This is not a long-running process that needs external checkpointing between stages.

---

## 7. Two things the room does not know yet

**7.1 `FKART` is a required input and is not constant.**

| Cost type | Observed behaviour |
|---|---|
| `Z001` | completes the full lifecycle — `STBER`/`STFRE`/`STABR` all `C`, freight PO + service entry created |
| `Z003` | calculated, then stranded — this is the 10,496 population |
| `Z006` | calculates, settlement not relevant |
| `Y003` | calculated only |

Any cost-posting call takes `I_FKART` as **mandatory**. It cannot be hardcoded. Either it is derived from shipment/planning point, or it becomes a caller-supplied field in the API-03 request contract. **This cell is currently empty in v1.8 §4.**

On 2026-08-17 the client described release as *"a tick inside the transaction"* (`[01:26:22]`–`[01:27:04]`). That is true in the GUI, but the callable form requires a cost type to be chosen. This is new information for them.

**7.2 Cost settlement is not a technical prerequisite for PGI.**

Proven by the §1 example: `STABR=A` (relevant, incomplete) and the delivery still shows `WBSTK=C`. SAP does not block PGI on unsettled freight.

So "release before PGI" is a **business rule, not a SAP constraint**. If CNF wants it enforced, CNF must enforce it. Equally, an orchestration that stalls waiting for settlement is imposing a constraint SAP does not impose. Worth deciding deliberately rather than inheriting.

---

## 8. Recommendation

**One pre-PGI API.** Inputs: delivery, transporter, vehicle/driver/LR fields, cost type. Internally: shipment create → cost document create+calculate → release. Returns the document numbers and per-stage status above.

Non-negotiable conditions to state at the same time:

1. **It is not atomic and cannot be.** Once the shipment commits it is committed; recovery is reversal, not rollback. Anyone presenting "with rollback" should drop that word — it will not survive a test.
2. **It is resumable, not fire-and-forget.** Re-invoking reads `VTTK`/`VFKK`/`VFKP` to determine where it got to and continues. This is what prevents a second shipment and what prevents another 10,496.
3. **The SAP wrapper does not own process state.** No `ProcessId`, no `Stages[]`, no replay ledger in ABAP — SAP holds no cross-stage process state. That belongs to the orchestrator.

---

## 9. Evidence index

| Claim | File |
|---|---|
| 10,496 stranded `STABR=A` | `stageb-qs4/VFKK_STABR_A.txt` |
| Stranded chain traced to PGI-complete delivery | `VFKP_1300105310.txt`, `VTTP_1300105363.txt`, `LIKP_0080387199.txt` |
| Completed chain + freight PO / service entry | `VFKP_sample200.txt`, `VTTK_1100605471.txt` |
| `SD_SCDS_CREATE` → `SD_SCDS_SAVE` | `stageb-route/WHEREUSED_SD_SCDS_SAVE.txt` |
| RFC / release status | `stageb-route/TFDIR_SD_SCDS.txt`, `TFDIR_control.txt`, `if/*.tsv` |
| Existing wrapper shape | `stageb-route/if/ZDACEFM_SHIP_COST.tsv` |
| Cost-type distribution | `stageb-qs4/VFKK_sample2000.txt`, `VFKK_settled.txt` |

**Sampling limit:** the `STABR=A` count of 10,496 is a true `SE16` hit count. Cost-type distributions come from 201-row reads and are indicative, not population-scale — the ALV lazy-loads and was not paged.
