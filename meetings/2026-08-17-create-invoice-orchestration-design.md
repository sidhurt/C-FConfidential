# Meeting Notes — Create-Invoice Orchestration, Error Ownership and Stage-Gate Design

- **Source ID:** `SRC-MTG-20260817-01`
- **Date/time:** 2026-08-17; 1h 40m 31s of diarized speech
- **Participants and roles:** Ten diarized speakers (`S0`–`S9`). Names heard in the room include Bharat, Sudhanshu, Yogesh, Hemant, Akshay, Kamal, Deep/Deepak, Shubhendu, Naman, Yash, Amit, Karan Kakkar, Dheeraj, Harinder, Sonu, Raju and Siddharth. **No name is mapped to a speaker ID.**
- **Decision owner(s):** Not established from the recording
- **Topic/workflow:** How many SAP calls the portal's single "Create Invoice" action decomposes into; synchronous vs asynchronous orchestration; who owns which class of error; T1 stage-gate redesign; and a readout of standard-API discovery
- **Recording/transcript location:** `17 Aug.m4a` (Google Drive, `1KDgIi1r2h4-Y0GHJptH6ABtIt4QzW_v0`; local copy `C:\Users\sidmy\Downloads\17 Aug.m4a`, 101,625,989 bytes) — outside the repository. Transcripts: `../sources/SRC-MTG-20260817-01_transcript.hi.txt`, `.en.txt`, `.raw.json`, `.raw.en.json`
- **Transcription method:** Sarvam AI batch STT, `saaras:v3`, independent `transcribe` (`hi-IN`, 1,479 turns) and `translate` (1,418 turns) passes, both diarized and timestamped
- **Sensitivity:** Client-sensitive

## Reading guidance

This is Tier-4 meeting evidence. It is also the most argumentative record in the set: several exchanges are interruptions, talk-over and open disagreement, and diarization splits overlapping speech across IDs. Where a claim matters, it was cross-read against the Hindi verbatim pass.

Confidence is unusually high on the core technical content because the participants speak the technical vocabulary in English inside Hindi sentences — e.g. `[00:12:48]` "शिपमेंट डॉक्यूमेंट वुड बी वन कॉल … कॉस्टिंग डॉक्यूमेंट रिलीज वुड बी वन" and `[00:13:17]` "पीजीआई एंड इनवेस्ट कांट बी क्लब्ड". The translate pass did not have to interpret these.

Frequent ASR artifacts in this recording: `high bridge` / `I-Bills` / `hybrid` → **Hybris** (confirmed at `[00:43:03]` "योर हाई ब्रिज"); `invest` → **invoice**; `SCPI` / `SEPI` / `CBI` / `CPM` → **CPI**; `MeeGo` → **MIGO**; `Bapi` / `baby` / `Bhabhi` / `puppy` / `bowler` → **BAPI**; `Odida` / `Odisha service` → **OData service**; `AC 37` → **SE37**; `PGA` / `GI` / `EJ` → **PGI**; `DG GST` / `Digi GST` → the **DigiGST** e-invoicing solution; `S-link`, `change gate`, `stage wave`, `Stage Gear` → **stage gate**; `con job` / `clone job` / `ground job` → **cron job**; `test directory` → **test data directory** (SE37 test sequence); `Sigma` → Figma; `SMP` / `SAB` / `SAT` / `asset` → SAP. Currency-shaped strings ("It is ₹1000", "two thousand rupees", "It is ₹1200") are ASR noise, not amounts.

## Purpose

Close the design of the portal's single Create Invoice action before development: decide the call decomposition, the failure model, and what the CNF user sees while the chain runs.

## Observed statements

| Observation | Speaker/source | Affected item |
|---|---|---|
| The portal exposes **one** "Create Invoice" action, but SAP needs several sequential documents behind it. The UI cannot map one click to one SAP call. | `S1`, `[00:02:24]` | API-06; Q-026 |
| The steps are strictly sequential, not parallel: each step's output is the next step's input (shipment number is required to create shipment cost). | `S6`/`S9`, `[00:01:30]`–`[00:02:24]` | Q-026 orchestration shape |
| Enumerated chain behind Create Invoice: shipment document → shipment costing document → costing release → **PGI** → invoice. Create Delivery and Change Delivery precede it as separate portal actions. | `S6`, `[00:07:00]`–`[00:09:47]`, `[00:09:56]` | API-03/API-06 |
| Change/Modify DI carries batch, transporter, vehicle number, LR number and LR date; it returns the same DI number with changed status, not a new identifier. | `S6`/`S9`/`S1`, `[00:07:34]`–`[00:08:38]` | API-05 contract |
| The whole SAP chain normally completes in **20–30 seconds**. | `S7`, `[00:09:52]` | Q-032 (first quantified figure on record) |
| **Costing-document creation and costing release will be merged into one call**, reducing four calls to three. Explicitly confirmed in Hindi. | `S6`, `[00:12:04]`–`[00:12:48]` | API-06 decomposition |
| **PGI and invoice cannot be clubbed** — each generates its own accounting document. Stated as a hard constraint. | `S6`, `[00:13:17]`–`[00:13:25]` | API-06 decomposition |
| Proposal to fire one call and let SAP complete everything in the background was rejected: no error visibility, and recovery would need reprocess jobs, job monitoring and extra manpower for critical jobs. | `S6`/`S9`, `[00:02:37]`–`[00:03:30]`, `[00:11:02]` | Q-008; D-decision candidate |
| Position stated as the decision rule: "If you believe that it is user dependent then you can proceed with this way. If you want that it is streamlined, no interventions required until unless the exception cases, then you have to proceed with the correct [approach]." | `S9`, `[00:19:32]` | Design principle |
| The existing SAP-internal automation is acknowledged to fail today too, but a human sits and fixes it — 4,000 logistics calls a day are cited, and training given to ~3,200–3,500 CFA agents. Portal users will not have that recourse. | `S9`/`S6`, `[00:19:11]`–`[00:21:15]`, `[00:23:29]` | Support model; error UX |
| **Two error classes are agreed**: (a) functional/business — no route, no price, no stock, master-data problems — which CNF or secondary logistics must resolve; (b) technical/non-functional — 503, network, CPI, response-not-received — which must be handled by the system and must **not** be routed to the functional/secondary-logistics person. | `S6`/`S0`, `[00:29:35]`–`[00:31:24]`, `[00:32:19]`–`[00:33:37]`, `[00:34:32]` | Error-handling ownership |
| Client asks the SI to produce the **classified list of error types** and states that error categorisation and technical error handling are the system integrator's design responsibility, not the functional team's. | `S6`/`S0`, `[00:25:55]`–`[00:26:25]`, `[00:33:04]`–`[00:34:32]`, `[00:46:14]` | Action; contract scope |
| Master-data errors are said to fail at the *first* stage, not mid-chain. | `S0`, `[00:28:39]` | Failure model |
| Errors that CNF has no role in should still be surfaced — proposed location is the **CNF admin/backend portal**, alongside access management. | `S0`, `[00:35:16]` | Screen scope |
| Existing precedent offered: in CRM, when SAP returns an error the request button is **disabled for 5–10 minutes** to prevent duplicate submissions, and the error goes to an admin portal. Proposed as the stop-gap pattern here. | `S0`, `[00:38:02]`–`[00:39:02]` | Duplicate-prevention design |
| **Resolution — Create Invoice becomes an asynchronous business process in Hybris**, stepwise, with error captured and stored at each step; the process exits at the failing step and can be resumed by Hybris's **"repair business process"**, which retriggers from the stuck step only. | `S1`, `[00:39:20]`, `[00:41:49]`–`[00:42:55]`, `[00:44:11]` | **Primary design decision of the meeting** |
| Consequence for the UI: the success pop-up showing the invoice number **must be replaced** with "Invoice generation is in progress, please check back later." | `S1`, `[00:39:50]`, `[00:47:44]`, `[00:57:00]` | Conflicts with `SRC-FIG-20260811-03` |
| Repair is driven by a cron job. Frequency disputed: `S1` proposes **once a day**; client rejects that as far too slow and settles on **10–15 minutes maximum**, treated as a tunable variable pending a stabilisation period of about six months. | `S1` vs `S6`/`S9`, `[00:50:20]`–`[00:52:01]` | Operational parameter |
| Error-code mapping agreed in shape: non-functional SAP error → auto-repair; functional SAP error → no repair, show a concatenated meaningful message directing the user to secondary logistics. SAP standard messages are message-class + message-number based and will need mapping. | `S1`/`S6`/`S9`, `[00:50:45]`–`[00:52:57]`, `[00:46:00]` | Interface contract |
| SAP must pass the correct error message; the portal must not hardcode its own error taxonomy. | `S9`, `[00:46:45]`–`[00:46:55]` | Contract requirement |
| Alternative UI proposed by `S3`: hyperlink the DI/DL number to a per-document stage screen with per-stage push buttons for individual repush, so the user watches ticks progress. Client asks for a prototype rather than settling it verbally. | `S3`, `[00:53:07]`–`[00:55:48]`; `S6`, `[00:55:52]` | Screen design action |
| **The Figma Document Flow ordering is wrong**: GI is positioned too early and must move to just before the invoice. Corrected order given as order → delivery → shipment document → shipment costing document → **GI** → invoice → e-invoice → e-way bill. | `S6`, `[00:14:39]`–`[00:14:50]` | Conflicts with `SRC-FIG-20260811-04` / D-050 |
| **T1 today has a single invoice stage gate that fires only on full success**, including e-invoice and e-way bill, and is **not triggered on failure**. Between DI modification and a successful invoice the CNF user therefore sees nothing — described as "binary, between zero and one". | `S8`/`S6`, `[01:05:31]`–`[01:07:27]`, `[01:15:02]`–`[01:15:15]` | Root cause of the visibility gap |
| DigiGST (an **EY** solution acting as ASP for IRN, QR code and link generation) frequently fails; e-invoice or e-way failure alone strands the whole invoice from the portal's view. | `S6`, `[01:06:35]`–`[01:07:05]` | Q-042/Q-055 context |
| **Proposed stage-gate split**: gate A = invoice generated **plus accounting document posted**; gate B = **e-invoice plus e-way bill** (compliance). Additionally three new gates for shipment number, shipment cost number and GI. | `S9`/`S6`/`S1`, `[00:57:32]`–`[00:58:06]`, `[01:08:08]`–`[01:09:15]` | T1 model change |
| Presentation-layer rule proposed: even if invoice data lands in T1, do not show it in the app until both gates complete — but the data should still reach T2 and OMS, because OMS needs it for SLA-breach calculation. | `S6`/`S8`, `[01:09:15]`–`[01:09:46]` | Visibility policy |
| **Unresolved architecture argument**: `S8` argues all stage gates eventually flow via T2, so build the split gates in T2 now and forward to T1 only the one gate T1 still needs. `S1` objects that the order/delivery/invoice record itself lives in T1 and stage gates are bound to that record, so they cannot originate in T2. | `S8` vs `S1`, `[01:10:08]`–`[01:12:32]` | **Open — parked** |
| CNF and OMS project tracks run near-parallel, less than a quarter apart per Amit's plan, so the design should serve both to avoid reversal and duplicated development. | `S6`/`S8`, `[01:02:28]`, `[01:20:47]`–`[01:21:23]` | Design constraint |
| Interim option floated: go live with CNF using OMS/T2 purely as a router, so touch points are built on T2 from the start. | `S8`, `[01:13:17]` | Sequencing option |
| Architecture diagram and API list must be rewritten to match: client asks for the full API list in an Excel sheet covering order creation, DI, shipment and everything discussed. | `S7`/`S6`, `[01:11:05]`, `[01:19:23]` | Action |
| Confirmed in passing: no master data is pulled from SAP, DSP or T1 for this flow. | `S3`, `[01:13:14]` | Scope |
| E-way bill and e-invoice are generated automatically via API through an ASP partner at invoice creation, not manually. | `S3`/`S7`, `[00:59:25]`–`[01:17:22]` | Q-042 |
| Encryption is handled by the standard CPI setup; no custom encryption is expected for this interface. | `S6`/`S3`, `[01:35:30]`–`[01:35:49]` | Security scope |

### Standard-API discovery readout (`[01:24:44]`–`[01:39:01]`)

| Observation | Speaker/source | Affected item |
|---|---|---|
| Create Invoice is reported to split into **six categories**: picking/batch split; shipment + shipment cost + cost release; PGI; billing create; billing read-back; e-invoice/e-way (DigiGST/EY — **evidence explicitly stated as incomplete**). | `S2`, `[01:25:07]` | API-06 decomposition |
| Discovery funnel stated: **2,626 services → ~400 candidates → 40 deep dives → 12 → 6 matching services** covering all the APIs, largely automated via GUI scripting, with the output held in an Excel file. | `S2`, `[01:30:25]`, `[01:32:57]` | Corroborates `SRC-SYS-20260815-01` (2,626 SEGW projects) |
| Recommendation: use **one API covering shipment / shipment cost / cost release with rollback**, not three. Splitting into three pushes error-handling responsibility into CPI, which is called out as a problem. Requires minimal ABAP; standard errors would be thrown and reflected directly. | `S2`, `[01:27:09]`–`[01:27:57]` | API-06 design input |
| `BAPI_SHIPMENT_COST_ESTIMATE` identified for cost estimate; **the cost-release counterpart was not found**. Client states release is a tick inside the transaction, not a separate BAPI copy. | `S2`/`S9`, `[01:26:22]`–`[01:27:04]` | Open gap |
| Everything presented is asserted to be **standard**, not `Z`, though the walkthrough of an existing custom program was used to harvest import structures. | `S2`/`S8`/`S6`, `[01:29:12]`–`[01:30:22]`, `[01:37:31]` | D-057..D-061 context |
| **Client direction: stop presenting catalogues.** Build SE37 test data directories against the BAPIs, run the payloads in **quality**, post real documents, and demonstrate the full OTC sequence — create DI → modify → BAPI shipment create → change → cost estimate/release → billing create — before anyone comments on the design. | `S6`/`S9`, `[01:27:57]`, `[01:29:51]`, `[01:31:19]`–`[01:33:45]` | **Primary action on the SAP track** |
| OData services to be activated by Basis from a list to be sent the same day. | `S2`/`S6`, `[01:34:41]` | Dependency |
| Challenge raised: whether the standard API's ~10 fields actually generate MIGO downstream — asked to be clarified explicitly. Counter-claim that the custom list was shown on Friday and the standard list across two days. | `S3` vs `S2`, `[01:37:42]`–`[01:38:30]` | Verification action |

## The disputes, recorded as disputes

Four disagreements ran hot and are worth preserving because two of them are still unresolved.

1. **One call vs many** (`[00:02:24]`–`[00:19:44]`). Settled against the single-call/background-automation option. The deciding argument was not elegance but error handling: the happy path works either way, and the failure path does not.
2. **Ownership of error handling** (`[00:25:47]`–`[00:34:32]`). This is where the meeting became personal. The client side stated that classifying and handling technical errors is what the system integrator is paid for; `S6` said plainly at `[00:27:03]`, "I am being very open and candid on this platform … this is spoon-feeding." `S3` replied at `[00:27:28]`, "I can debate on this too, but please do it logically, don't argue," and `S6`: "I don't have free time … for the debate." A participant twice tried to de-escalate by proposing they use SAP's phone-a-friend service rather than keep arguing (`[00:36:49]`, `[01:37:19]`). Outcome: the two-class error taxonomy plus a request for the classified error list — the substance was resolved even though the tone did not recover.
3. **Where stage gates live, T1 or T2** (`[01:10:08]`–`[01:12:32]`). **Unresolved.** Parked to a Bharat + Akshay session the following morning.
4. **Whether the standard-API work is credible yet** (`[01:37:42]`–`[01:39:01]`). Unresolved in substance — the client's position is that only a posted document in quality settles it. Ended civilly ("Good job. Very good work.").

## Interpretations

| Interpretation | Confidence | Supporting observations | Validation |
|---|---|---|---|
| Q-008 is effectively answered for invoice creation: it is **not** a synchronous atomic command. It is a staged asynchronous business process orchestrated in Hybris, with per-step persistence and resumable repair. | Strong inference | `[00:39:20]`, `[00:41:49]`–`[00:44:21]`, `[00:57:00]` | Confirm with a decision owner before promoting to `DECISION_LOG.md` |
| Q-026's ordering is now answerable: delivery → change delivery → shipment document → shipment costing document → costing release → PGI → invoice → e-invoice → e-way bill, with costing creation and release merged, and PGI/invoice necessarily separate. | Strong inference | `[00:07:00]`–`[00:14:50]`, `[01:25:07]` | Must be confirmed by posting documents in quality, per the client's own directive |
| The "20–30 seconds" figure is the first quantified latency on record for Q-032, but it is a recalled normal-case figure from inside SAP, not a measurement of the T2→CPI→S/4 round trip. | Weak — indicative only | `[00:09:52]` | Q-032 stays open; measure across the integration path |
| The orchestration location is genuinely ambiguous in the record. `S1` puts the business process in Hybris; earlier in the meeting `S1` proposed CPI/SCPI as the orchestrator (`[00:03:42]`). The Hybris answer is the one that survived to the end of the meeting. | Strong inference | `[00:03:42]` vs `[00:41:49]` | Confirm the orchestrator explicitly — this changes the CPI contract |
| Splitting the T1 invoice stage gate is a **change to an existing production system serving more than CNF**, and the participants recognised this by pulling OMS into scope mid-discussion. It is not a CNF-local change. | Strong inference | `[01:02:28]`, `[01:09:46]`, `[01:10:08]` | Needs a T1/OMS owner, not a CNF decision |
| The `S2` discovery funnel matches this repository's own SEGW evidence exactly (2,626 projects), which corroborates the catalogue work but not the six-service conclusion. | Verified on the input, open on the output | `[01:30:25]`; `SRC-SYS-20260815-01` | The six-service claim needs the posted-document proof the client asked for |
| The client's escalation from "show me the list" to "post a document in quality" is a shift in the acceptance bar for the whole standard-API track. | Strong inference | `[01:27:57]`, `[01:31:19]`, `[01:33:45]` | Treat as the working acceptance criterion |

## Conflicts with existing records

| ID | Conflict | Status |
|---|---|---|
| C-18 | **Document Flow step order.** `SRC-FIG-20260811-04` (validated production design, D-050) shows DI → PGI → Shipment No. → Shipment Cost → Invoice. This meeting states GI/PGI must sit **after** shipment costing and immediately before the invoice (`[00:14:39]`). SAP process order wins over the screen; the design artifact needs correction. | New — raise with product/design |
| C-19 | **Invoice success pop-up.** `SRC-FIG-20260811-03` shows a synchronous success state returning the invoice number. The async decision replaces it with a "processing, check back later" state (`[00:47:44]`, `[00:57:00]`). | New — screen change agreed in the meeting, not yet reflected in the design set |
| C-20 | **Stage-gate ownership, T1 vs T2.** Unresolved between `S1` and `S8` (`[01:10:08]`–`[01:12:32]`). Bears directly on the Option C topology in D-014 and the manager-shared architecture `SRC-ARCH-20260811-01`. | New — open |
| C-21 | **Orchestrator identity.** CPI (`[00:03:42]`) vs Hybris business process (`[00:41:49]`). Affects `SRC-CPI-20260811-01` interface expectations. | New — needs one explicit answer |

## Decisions

No statement is promoted to `DECISION_LOG.md`. Speaker identity and decision authority are not established from the audio, and per project rule an anonymous-speaker statement is not a decision. The following are recorded as **working directions with strong in-room agreement**, pending owner confirmation:

- Create Invoice runs as an asynchronous, resumable business process rather than a synchronous call.
- Costing-document creation and costing release merge into one call; PGI and invoice stay separate.
- Errors are classified into functional and technical, with technical errors handled by the system and never routed to secondary logistics.
- The T1 invoice stage gate splits into invoice+accounting and e-invoice+e-way.
- The standard-API track is not accepted on catalogue evidence; it needs posted documents in quality.

## Requirements changed or sharpened

- API-06 is confirmed as a multi-call orchestration, not one endpoint. Its decomposition and the merge/split constraints above are now specified.
- The portal needs a per-document stage view showing which step of the chain a DI has reached, its error, and a repush affordance — this did not exist in the design set.
- An error-code contract is required: SAP message class + number, mapped to a functional/technical classification, concatenated with a user-meaningful instruction.
- The SI owes a classified list of error types before the error UX can be finalised.
- Duplicate-submission prevention (button disable window) needs to be specified.
- The architecture diagram and the API inventory both need reissue; the client asked for the API list as an Excel sheet.
- Repair cron frequency must be a configurable parameter, initially 10–15 minutes.

## Terminology

| Term | Client meaning | Confidence |
|---|---|---|
| Stage gate | A completion checkpoint on a T1 document record; fires only on success, not on failure | Meeting-supported and consistent with prior `ZCRM_STAGEGATE_SRV` evidence |
| Repair business process | Hybris capability that resumes a failed business process from the step that failed, rather than restarting it | Meeting-supported; product capability not independently verified |
| DigiGST | EY-supplied ASP solution connecting to the government portal for IRN, QR code and link generation | Meeting-supported |
| Cost release | The release step on a shipment costing document; described as a tick inside the transaction rather than a distinct BAPI | Meeting-supported; the API/BAPI for it is not yet identified |
| Billing read-back | A read service returning the created invoice/accounting result, distinct from billing create | Meeting-supported |

## Open questions and actions

| Priority | Question/action | Owner |
|---|---|---|
| Critical | Post real documents in quality through the full OTC sequence (create DI → modify → shipment create → change → cost estimate/release → billing create) using SE37 test data directories, and show the payloads running. This is the stated acceptance bar. | SAP/ABAP track |
| Critical | Resolve whether the split stage gates are built in T1 or T2 (C-20). Blocks the architecture diagram and the CPI contract. | Bharat + Akshay session; architecture owner |
| Critical | Name the orchestrator explicitly — Hybris business process or CPI (C-21). | Architect / Commerce / CPI |
| High | Produce the classified list of functional vs technical error types, with SAP message class/number mapping. | SI + SAP functional |
| High | Identify the cost-release API/BAPI; `BAPI_SHIPMENT_COST_ESTIMATE` covers estimate only. | ABAP / LE |
| High | Correct the Figma Document Flow step order (C-18) and replace the synchronous invoice pop-up (C-19). | Product / design |
| High | Confirm that the standard API's field set actually drives the downstream MIGO/document creation, as challenged at `[01:37:42]`. | SAP functional |
| High | Get the OData service list to Basis for activation. | SAP track / Basis |
| Medium | Measure real end-to-end latency across T2→CPI→S/4 for the invoice chain; the "20–30 seconds" figure is SAP-internal recall only (Q-032). | Basis / integration |
| Medium | Specify the duplicate-submission button-disable window, following the CRM precedent. | Product / SI |
| Medium | Confirm whether OMS SLA calculation requires the invoice data before both stage gates complete, and how that interacts with the "don't show until complete" presentation rule. | OMS / product |
| Medium | Reissue the API inventory as the requested Excel sheet covering order creation, DI, shipment and invoice. | SI |

## Registers to update

Not yet reconciled into: `MEETING_INGEST.md` · `sources/README.md` · `PROJECT_BRAIN.md` (C-18..C-21) · `OPEN_QUESTIONS.md` (Q-008, Q-026, Q-032, Q-042 all materially advanced) · `DOMAIN_GLOSSARY.md` · `SYSTEM_OF_RECORD_MATRIX.md` · `HANDOVER_AI.md`
