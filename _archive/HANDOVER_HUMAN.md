# Where This Project Stands — 3 August 2026

**For:** Siddharth, or whoever picks this up next
**Read time:** ~15 minutes
**Machine-readable version:** `HANDOVER_AI.md`

---

## The short version

Ten days ago you were the ABAP developer on a project whose vocabulary you didn't speak, holding a technical specification written by someone who had never logged into the client's system. You still don't have DEV access.

What changed is that you now know more about how this client's SAP is actually configured than the specification you were handed does. That's not a small thing, and it's worth being precise about what it means: **you are no longer dependent on being told. You can read their configuration and reason about it.**

You are also, still, the only SAP ABAP developer on this workstream. That's the risk and the opportunity in the same sentence.

---

## What you actually know now that you didn't

### The vocabulary is no longer a wall

Two weeks ago the glossary had roughly a third of its terms marked *Hypothesis*, *Unresolved*, or *Critical unknown* — including **DI**, the central object of the whole dispatch flow, and **KDS**, which nobody had expanded.

Now:

- **DI is the outbound delivery.** DI number is `LIKP-VBELN`. That was the single biggest unknown and it's closed.
- **KDS is Key Data Structure** — the client's own name for their code catalogue. And you have the catalogue. Eleven sheets of real values.
- **SPI is Special Procurement Indicator**, mapped to storage locations in a custom table `ZLETSPIMAP`. Both earlier guesses — mine (shipping point) and yours (a mis-transcription of SCPI) — were wrong. The document settled it.
- **GDF, DTP, GDRK, RSD** and the rest aren't "categories". They're literal four-character storage location codes.
- **Brand is `MVGR3`. Grade is `MVGR2`. Trade/non-trade is `MVGR5`.** Plain material group fields, not classification characteristics. I had guessed classification; I was wrong, and the real answer is much simpler to build against.

That's the thing the client seniors were complaining about in the 28 July meeting — that the technical team didn't speak their language. You now do, in the specific sense that matters: you can name the field behind the word.

### The architecture question got answered, and it shrank your job

Option C was selected. Read it carefully, because it changes what you're building:

- **Orders, deliveries and invoices are read live from Hybris T1 (CRM).** Not from SAP.
- **Pending MRN, STO list, stock ageing come from Datasphere into T2** on a schedule.
- **Master data — depot mapping, vehicle, transporter — syncs daily from Datasphere.**

Almost every *read* in the original ten-API list is no longer a SAP API. What's left on your side is the **write commands** plus two real-time reads.

This is good news, not bad. Reads were always the boring half. Writes are where the engineering is.

### The statutory piece isn't what anyone assumed

Everyone — including me, in writing — assumed SAP Document and Reporting Compliance handled the e-invoice and E-Way Bill. **It doesn't. The client runs DigiGST**, a third-party add-on, cockpit `/DIGIGST/INVP`.

And E-Way Bill extension is documented as *"handled at GSP/NIC portal, not core SAP"* — meaning one of your ten APIs may not be your work at all.

I had that assumption at the centre of the effort estimate for two weeks. It was wrong. The document corrected it. That's the system working.

### Several things you were going to build already exist

`ZLE526` returns the pending DI/MRN list. `ZSDR512N` returns pending orders. `ZSDR513` is the sales register. `ZMM5013` is stock ageing.

Before building a composite view from scratch, check whether wrapping one of these does the job. That may be the single cheapest hour of investigation available to you on day one of access.

---

## The gap nobody has named — and it's yours to name

This is the most valuable thing in this document.

Option C says the portal reads **deliveries and invoices live from T1**. Fine. But those documents are **created in S/4** — VL01N makes the delivery, VF01 makes the invoice. T1 doesn't create them.

**So something has to push S/4 → T1. That push is in no API inventory, has no named owner, and no specified trigger or latency.**

On the SAP side it's real work — change pointers, output determination, a BAdI on save, or an event. And by default, unnamed SAP-side work lands on the ABAP developer.

The question to ask, in the next architecture conversation:

> *"Option C reads deliveries and invoices live from T1. Those are created in S/4 — what's the mechanism that pushes them, what triggers it, and is that in anyone's scope? Because it isn't in the API list."*

Two more in the same category:

> *"Stock ageing from DSP daily is fine, that's analytical. But batch availability for allocation has to be real-time from S/4 — we're committing to specific batches and the sum has to match at PGI. That's not on the Option C diagram."*

> *"Is Datasphere replicating raw tables via SLT, or consuming a CDS view? 'Pending' is derived logic, not a stored field. ZLE526 already implements it correctly in SAP. If Datasphere reimplements it independently, we'll have two definitions of pending and they will diverge."*

You asked how to stop being the ABAPer who just listens. That's how. Not by knowing more SAP than the functional consultants — by being the person who notices where the architecture doesn't close.

---

## On "SAP to T2 APIs are becoming my responsibility"

Coherent, with one distinction worth making explicitly rather than letting it blur:

- **The OData services T2 and CPI call into SAP** — yours, always were.
- **The outbound push from S/4** — reasonable as yours, but it's **new scope that's in no estimate**. Name it as new. Don't absorb it.
- **The CPI iFlows and the Commerce-side ingestion** — not yours. `ROLE_BOUNDARIES.md` is explicit, and its standing rule is *collaborate across every boundary, but do not silently accept ownership*.

Suggested framing: *"Happy to own the SAP side — the OData services and the outbound trigger from S/4. To be clear on the boundary: I own up to and including the call to CPI. The iFlow and Commerce ingestion sit with CPI and Commerce."*

Also worth asking which entities, because under Option C, T2 gets its data from Datasphere, not from SAP.

---

## What's solid vs what's still guesswork

| Solid | Still open |
|---|---|
| DI = outbound delivery, `LIKP-VBELN` | ECC or S/4HANA, and which release |
| KDS catalogue — all the code values | What pushes S/4 → T1 |
| Brand `MVGR3`, grade `MVGR2`, trade `MVGR5` | Where real-time stock availability sits |
| SPI = Special Procurement Indicator, `ZLETSPIMAP` | Whether DSP replicates tables or CDS views |
| Storage location codes are literal `T001L` values | FIFO — who owns the rule (explicitly TBD) |
| Classic LE-TRA shipment and costing | DigiGST integration surface |
| DigiGST, not SAP DRC | Whether API-09 is your work at all |
| Authorization via derived roles, `TVKWZ`/`TVKVZ` | Measured invoice-generation latency |
| DI predecessor is both SO **and** STO | Pickup code: FTP or not FTP (contradicted in one session) |
| Batch determination resets on quantity change | `1000`/`1300` — sales org or company code |
| C&F agent is customer group `31`, vendor + customer | The BRD and CPI workbook — never supplied to anyone |

The right column is shorter than it was two weeks ago, and the left column now contains real field names instead of concepts. That's the actual progress.

---

## What I'd tell you not to do

**Don't let the timeline become a promise you didn't make.** The compressed schedule (all APIs by 9 Oct, UAT-ready 28 Oct) assumes three ABAP developers from day 14 and DEV access on 3 August. Neither has happened. If the date is quoted back at you, the conditions come with it.

**Don't build a composite before checking the Z-report.** `ZLE526` and friends may already do the job.

**Don't accept the S/4 → T1 push silently.** Name it as new scope the first time it's mentioned, or it becomes yours retroactively and unfunded.

**Don't treat the UI design as frozen.** The 3 August session said explicitly *"don't take this as the final handoff"* and *"you'll have to start only after that."* If field-level contracts can't be settled until the design freezes, that's a second dependency alongside access — and it isn't in the plan.

**Don't trust the pre-evidence documents.** `PROJECT_BRAIN.md`, `MASTER_PLAN.md`, `NEXT_MOVE.md`, `SEGW_ODATA_PLAN.md`, `BAPI_CANDIDATES.md` and `CPI_CONTRACTS.md` were written before any client documentation arrived. The method in them is sound; the SAP specifics are guesses. `HANDOVER_AI.md` §0.2 lists exactly what's stale, and the retired interface and requirements registers now sit in `_archive/` with a mapping to the current API numbering.

---

## Two structural problems worth fixing

**The repo has five parallel numbering systems.** `API-01..10`, `Q-001..043`, `D-001..017`, plus superseded `IF-001..024` and `R-001..027`, plus `V-01..29` in the workbook. They overlap and partly contradict. `HANDOVER_AI.md` §0.1 sets the precedence, but the real fix is retiring the dead ones.

**The source documents aren't in the repo.** The spec PDF, the KDS workbook, the architecture deck, the meeting recordings all live in `Downloads`. The repo references them by source ID, but anyone picking this up — human or AI — can't actually read them. Worth copying the ones you're allowed to keep into a `sources/` folder.

---

## Where you actually stand

Two weeks in, blocked on access, with no formal assignment, you have produced: a defect review of the vendor specification that found thirty-two issues including six that wouldn't compile; a ten-API classification separating standard from custom; a dated delivery plan; and a knowledge base that decodes the client's own configuration.

The thing that will make the difference now isn't more documentation. It's walking into the next architecture meeting and saying the deliveries-to-T1 push has no owner.

That's a five-second contribution that changes how the room sees the ABAP seat. You have the evidence for it. Use it.
