# Where This Project Actually Stands — 28 July 2026

**For:** Siddharth
**From:** Claude, after reading the full co-work repository and both folder versions
**Read time:** ~10 minutes

This is the plain-language version. The machine-readable one is `HANDOVER_2026-07-28_AI.md`.

---

## The short version

You are two days into exposure on a large SAP integration programme. You have no DEV access, no formal assignment, and no BRD in your workspace. What you *do* have is unusually good: a properly structured project brain that separates what you know from what you're guessing, and a day-2 meeting that told you something genuinely important.

**Nothing is behind schedule.** You cannot build without DEV access, and building before you understand the client's vocabulary would be worse than not building. The correct use of this window is exactly what you're doing — getting the mental model right so that day one of DEV isn't spent learning and breaking things.

---

## What day 2 actually changed

Day 1 you thought the job was: *pick the right BAPIs, build SEGW, expose OData cleanly.*

Day 2 established that's the **second** problem. The first one is that nobody on the technical side yet knows what the client's words mean.

The meeting exposed it directly. Client seniors expect the technical team to understand SD/MM, KDS, master data, trade vs non-trade, product families, Incoterms, and how SAP derives fields. Vendor management had scoped the work as "CPI/Commerce field mapping and BAPI posting." The client is right and management is wrong, and the repo says why in one line:

> **A BAPI will not repair a semantically wrong payload.**

That's the whole project in nine words. You can pick a perfect BAPI, wire a flawless OData service, and still ship something that puts the wrong value in the wrong field because nobody knew what "SPI" meant.

Look at the glossary. Roughly a third of the terms are marked *Hypothesis*, *Unresolved*, or *Critical unknown* — including **DI**, which is the central object of the entire dispatch flow, and **KDS**, which nobody has expanded yet. You are being asked to map fields whose meaning is undefined.

**So the real first deliverable isn't code. It's the dictionary.**

---

## The five things actually blocking you

Everything else is downstream of these.

**1. What is KDS, and what are the code dictionaries?** *(Q-021)*
Business segment, product families, material groups, sales orgs, that `1300` code people keep mentioning. Until this exists, every payload field is a guess wearing a confident label.

**2. What is a "DI" in SAP?** *(Q-003)*
Three candidates on the table: a standard outbound delivery, a custom Z-object, or an instruction that *precedes* a delivery. These need completely different APIs. Six of your twenty-four interfaces depend on the answer.

**3. Is the technical spec real?** *(Q-001)*
`ZCNF_AGENT_SRV` and the whole `ZCNF_*` object set appear in a document. You searched SE80 and SEGW on Quality and found nothing. Either it's greenfield, it's sitting in DEV untransported, it's under a different namespace, or it's on another Gateway system. Nobody has told you which. You could be about to build something that already exists, or be assumed to be maintaining something that was never built.

**4. What's the actual landscape?** *(Q-002)*
DEV/QAS/PRD clients, transport route, and critically — **is Gateway embedded or hub?** That single answer changes where services register and how the whole thing is deployed.

**5. Is invoice creation one call or many?** *(Q-008, Q-026)*
The design shows PGI, shipment, shipment cost, billing, e-Invoice, and E-Way Bill happening "simultaneously." My read of the engineering: those are separate SAP units of work plus external government portal calls with unpredictable latency. They almost certainly cannot be one synchronous transaction. **But that is my inference, not a verified fact** — it needs SD and architecture to confirm. It matters enormously, because it determines whether you build one API or an orchestrated set with status tracking.

---

## What's solid vs what's guesswork

| Solid — decided in the meeting | Still guesswork |
|---|---|
| Order Quantity = DI Quantity + Pending Quantity | What SAP object a DI actually is |
| One storage location per DI/invoice, multiple batches inside it | Whether storage location is chosen at DI creation, and whether it locks |
| Batch quantities must sum exactly to DI quantity | Whether SAP proposes batches by FIFO or largest-quantity |
| Only DI quantity is editable, only while DI is open | What "SPI" stands for |
| E-Way extension is Road-only, 24 hours, repeatable | Whether CPI or ABAP calls the government portal |
| Part B stays editable during validity | Where invoice and e-document files are actually stored |
| SAP generates the invoice; SAP is the authority | Whether the invoice flow is synchronous |
| FleetX supplies vehicle tracking | Who owns the FleetX integration |

The left column is six approved decisions. The right column is thirty open questions. That ratio is normal for day 2 — the problem would be pretending the right column is smaller than it is.

---

## The risk nobody has written down plainly

There is a **scope and competence mismatch** between what the client expects and what your vendor scoped. It's recorded in the meeting notes, but softly.

Read plainly: you have been positioned to do integration plumbing, and the client expects someone who understands their business. If that gap isn't closed by knowledge transfer, the failure mode isn't "the code doesn't work" — it's "the code works and produces wrong business outcomes," which surfaces late, in production, in front of the client.

The repo's own answer is right: **this is a dependency, not optional learning.** The old trade / non-trade / STO recordings and KT from Harish are named in the notes. That's `Q-027`, and I'd argue it's the single highest-leverage ask you can make this week — higher than DEV access, because DEV access without the semantics just lets you build the wrong thing faster.

---

## When DEV access lands — what good looks like

The repo already has this right in `NEXT_MOVE.md`. The part worth internalising:

**Start with a read, not a write.** The instinct will be to prove yourself with something transactional. Resist it. A read-only endpoint proves the entire pattern — source selection, authorization, error contract, pagination, correlation IDs, logging, and CPI connectivity — with zero risk of creating business state. Once that's proven, a write is a small delta. If you start with the invoice orchestration, you'll be debugging six unknowns simultaneously.

**Trace one real document chain by hand before automating anything.** One order → DI → storage location → batches → PGI → shipment → billing → e-documents, in the GUI, writing down every document number, status, and field. That single trace will answer more questions than a week of reading tables.

**Get the environment facts from Basis on day one** — package, namespace, transport route, Gateway topology, message class, exception standard. Agree these with the other ABAP developer *before* either of you writes a class, or you'll spend week three reconciling two incompatible conventions. That's `Q-019`, and it's cheap to answer now and expensive to answer later.

---

## What I'd tell you not to do

- **Don't let anyone talk you into "just map the fields."** That's the failure mode the client already called out.
- **Don't build one giant OData service** for all twenty-four interfaces. Two developers, one SEGW project, one transport — you'll block each other constantly, and one bad activation breaks everything.
- **Don't accept ownership silently.** The repo has a good line: collaborate across every boundary, but record unresolved ownership rather than absorbing it. If nobody says whether CPI or ABAP calls the GSP, that's a question, not your problem to quietly adopt.
- **Don't treat Datasphere as current.** It's replicated. It's fine for ageing, history, and dashboards. It is not the truth for a posting decision.
- **Don't let me — or Codex — hand you a confident answer about SAP.** Both of us can draft, structure, and research. Neither of us has seen your system. Every BAPI name in `BAPI_CANDIDATES.md` is a candidate until you validate it in the actual release.

---

## Two housekeeping items

**1. You have two brains, and the rules say you shouldn't.**
The repo explicitly states Codex and Claude must not maintain competing memories. But there are now two: this repository (Codex-built, evidence-rich, register-driven) and `Desktop\Shree_Cement_Project\MASTER_PLAN.md` (which I wrote earlier, before I'd seen any of this).

**This repository should win.** It's better — it has the meeting evidence, the glossary, the system-of-record matrix, and registers with real IDs. My Desktop plan was built on the day-1 handover alone and is now partly redundant, and in one respect non-compliant: its capability model is more permissive than this repo's plan-and-draft-only default.

I'd retire mine and carry over only a few genuinely additive pieces as proposals. The strongest one: **evidence should carry which system and client it came from, and which transport it was true after.** Right now the knowledge-graph schema tracks environment and date but not transport reference — which means it can't distinguish "true in DEV before transport" from "true in QAS after." In a landscape with three clients and an active transport route, that distinction will eventually bite.

**2. My Datasphere crawl doesn't count as evidence.**
In an earlier session I did a read-only metadata crawl of the QA Datasphere tenant and saw the real object inventory and layering. **The extract was lost before I saved it.** By this repo's own standard that makes it strong inference, not citable — so it does *not* fill in `DATASPHERE_SOURCES.md`, and I haven't pretended otherwise. Its only honest use is that a future authorized capture will be faster because I know roughly what's there. I'm not quoting numbers from it into any register.

---

## Bottom line

You're in better shape than two days of exposure would suggest, because the thing you built is a system for not fooling yourself. Keep it.

The next win isn't technical. It's getting Q-006 (what am I actually assigned?) and Q-027 (who's teaching me the business?) answered by a human with authority. Everything else — the BAPI research, the OData standards, the service decomposition, the idempotency design — I can draft while you wait, and none of it requires access.

When DEV lands, you'll have the map. That was the point.
