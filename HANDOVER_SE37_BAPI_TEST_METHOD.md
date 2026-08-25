# SE37 BAPI Test Method — Client-Prescribed Procedure

**For:** the agent currently running SE37/SEGW evidence collection on `QS4` client `700`
**Status:** instruction addendum. Does not supersede `HANDOVER_STANDARD_API_DISCOVERY.md` or `HANDOVER_SEGW_CANDIDATE_DEEP_DIVES.md` — it adds a method they do not describe and moves one boundary.
**Provenance:** `SRC-MTG-20260817-01 @01:26:58–01:30:25`, cross-read against the Hindi verbatim pass. Client-side instruction given directly to the SAP track.

---

## 1. Why this exists

The catalogue work is done and the client has stopped accepting it as evidence. The stated acceptance bar moved from *"show me the list of services"* to **"post a real document in Quality and show me the payload running"** (`@01:27:57`, `@01:31:19`, `@01:33:45`). A service inventory, however complete, no longer advances the deliverable.

Two open gaps triggered the instruction:

- The cost-release counterpart to the shipment-cost BAPI was not found by name search (`@01:26:51`). The client's answer: **there is no separate BAPI — release is a tick inside the transaction** (`@01:27:04`). Name search was never going to find it.
- No payload had been run through any candidate BAPI (`@01:27:01`).

The method below is the client's prescribed way to close both without hand-authoring payloads.

---

## 2. Boundary change — read this before executing anything

Everything the agent has done to date is read-only, and `SAP_SEGW_SCRIPTING_HANDOVER.md` records "No SAP writes were made" as a standing fact.

**This procedure has two halves with different risk:**

| Half | Actions | Posture |
|---|---|---|
| **A — Harvest** (§4) | Where-used list, read Z source, read import structures, save test data | **Read-only.** Proceed under existing authorization. Saving a test data directory writes only to the FM test-data store, not to business data. |
| **B — Execute** (§5) | Run the BAPI, commit, post a document | **Writes business data.** Do **not** run without explicit per-run authorization from Siddharth. |

Half B creates real documents in `QS4`. Even in a Quality system these carry document numbers, consume number ranges, and may trigger downstream output or interfaces. Get a clear yes naming the BAPI and the test data before the first execution, and do not generalise one approval to the next BAPI.

Halt and report if a where-used trace or an execution attempt would touch a Production system. The method as given assumes Quality — the client said Dev was incomplete and to run it in Quality (`@01:28:16–01:28:18`).

---

## 3. The instruction in one line

Do not invent payloads. Find a `Z` program that already calls the standard BAPI in this system, lift its actual `CALL FUNCTION` parameters, save them as a reusable SE37 test data directory, then execute and record what the BAPI really throws.

Client's own framing, three times: **"मेहनत बच जाएगी"** — the effort is saved.

---

## 4. Half A — harvest (read-only, do this now)

Per target BAPI:

**A1. Open SE37** on the function module, Display.

**A2. Run the where-used list.** `Utilities → Where-used list`, or Ctrl+Shift+F3. In the scope dialog include at minimum Programs, Function modules, and Classes/Interfaces — the DPC_EXT classes already catalogued are a likely calling layer and the meeting's example was a program.

**A3. Filter the results to custom callers first.** The instruction is explicit: **"स्टैंडर्ड में मत जाना, पहले कस्टम देख लेना"** — don't go into standard, look at custom first (`@01:28:55`). Rank `Z*` / `Y*` callers above SAP-namespace ones. A standard caller tells you how SAP calls it; a `Z` caller tells you how *this client* calls it, with their field conventions and their master data. The second is what you need.

**A4. Open the calling object and locate the call block.** Capture the full `CALL FUNCTION '<BAPI>' EXPORTING … IMPORTING … TABLES … EXCEPTIONS …` statement plus enough surrounding lines to see how the parameters were populated — constants, `SELECT`s, and any hardcoded plant/sales-org/document-type values. The populating code matters as much as the call.

**A5. Read the import structure in SE37's test screen.** `F8` from SE37 gives the Test Function Module screen. Toggle between **tabular view and tree structure** for nested structures and tables — both were named (`@01:29:37`). Map the values found in A4 onto these parameters.

**A6. Save as a test data directory.** Save from the test screen; retrieve later via the test data directory. This is the reusable artifact the client asked for (`@01:27:57`, `@01:29:51`).

**Evidence to capture per BAPI**, under a new `SRC-SYS-20260817-*` directory following the existing manifest convention:

- the where-used result list, full, with a `standard` / `custom` classification column
- for each custom caller: object name, type, package, author, and the verbatim call block
- the SE37 import parameter tree, and the mapped values with their source (which caller, which line)
- the saved test data directory name
- a manifest that reconciles counts, as the existing `SRC-SYS-*` directories do

Half A alone materially advances the deliverable and needs no new authorization. Do all of it before asking about Half B.

---

## 5. Half B — execute (gated)

**B1. Do not expect a bare SE37 execution to post anything.** This is a technical caveat the meeting did not state and the agent must not learn the hard way: most BAPIs do not commit their own work. Executing the BAPI alone in SE37 typically returns a success `RETURN` table while the update task never fires, and **no document exists afterwards**. An agent reporting "posted successfully" on that basis would be reporting a false result.

Use SE37's **test sequence** (`Function module → Test → Test sequence`) to chain the BAPI followed by `BAPI_TRANSACTION_COMMIT`. Verify the posting independently — read the document number back from the relevant table or display transaction — before recording it as posted.

**B2. Record the `RETURN` table verbatim** on every run, success or failure. This is the second reason the client wanted execution at all: **"वो स्टैंडर्ड एरर हैंडलिंग भी दिखेगी, उसमें क्या-क्या मैसेजेस थ्रो कर रहे हैं"** (`@01:28:30`). Capture message class, message number, type and text for each row.

That output feeds a live open action: the meeting requires a **classified list of functional vs technical error types** with SAP message-class/number mapping, and the design of the portal's error handling is blocked on it (see `meetings/2026-08-17-create-invoice-orchestration-design.md`, error taxonomy at `@00:29:35`–`@00:34:32`). Every observed message is direct evidence for that list. Treat error capture as a primary output, not a by-product of a failed run.

**B3. Target sequence.** The client named the end-to-end run to demonstrate (`@01:33:45`):

`Create DI (delivery)` → `modify delivery` → `BAPI shipment create` → `change` → `cost estimate / release` → `billing create`

Build up to it one step at a time rather than attempting the chain first.

---

## 6. Open gaps this method is meant to close

| Gap | How the method addresses it | Status |
|---|---|---|
| No cost-release BAPI found by name search | Release is a status tick, not a BAPI (`@01:27:04`). Where-used on the shipment-cost BAPI, then reading how existing `Z` code performs the release, is the path to it. | Open — highest value target |
| Exact BAPI names | The name heard was rendered "BAPI cost shipment cost estimate" (`@01:26:47`). **Do not trust the transcript for identifiers.** Resolve every BAPI name in the system by search before use, and record the resolved name. | Must verify |
| The worked example's program name | The client demonstrated on a program the ASR rendered as "Automation of A2 sales/cells" (`@01:29:12`), reading a shipment-create BAPI's where-used list. The real name is recoverable from that where-used list directly. | Recover from system, do not guess |
| Whether the standard API's field set actually drives downstream MIGO | Challenged directly at `@01:37:42` and unresolved. Executing with real payloads is what answers it. | Open |

---

## 7. Reporting rules

Unchanged from existing practice, restated because Half B raises the stakes:

- Label confidence. A posted document number is verified evidence; a BAPI returning `S` with no commit is not.
- Cite `SRC-SYS-*` evidence paths for every claim, and reconcile manifests.
- Do not promote anything to `DECISION_LOG.md`. The instruction in this document came from an unmapped speaker in a meeting recording; it is a working direction, not an owner decision.
- Report failures with the full `RETURN` table rather than summarising them as "did not work" — the failure text is the deliverable here as much as the success is.
- If a step needs Basis (service activation, authorization), stop and name what is needed. An OData service activation list was already promised to Basis (`@01:34:41`).
