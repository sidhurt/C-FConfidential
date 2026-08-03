# Meeting Intelligence — UI/UX Design Walkthrough (Invoice Flow, Dashboard, Reports)

- **Source ID:** `SRC-MTG-20260803-01`
- **Recording:** `Morecontext.m4a` (28:35, user-supplied local source, `C:\Users\sidmy\Downloads\`)
- **Transcripts:** `Morecontext.hi.txt` (Hindi/Hinglish, diarized, timestamped) · `Morecontext.en.txt` (English) · `Morecontext.sarvam-raw.json` (raw)
- **Transcription method:** Sarvam AI batch STT, `saaras:v3`, two passes — `mode=transcribe` (hi-IN) and `mode=translate`, both with diarization and timestamps. See D-008 for the approval basis.
- **Date:** 2026-08-03 — **inferred from audio file mtime, not stated in the recording.** Confirm.
- **Sensitivity:** Client-sensitive
- **Language:** Hindi/Hinglish with heavy English technical code-switching

## Reading guidance

Both passes were produced independently from the same audio and cross-read against each other. Where they agree, confidence is high. Sarvam consistently garbles three proper nouns — treat these as ASR artifacts, not evidence:

| Heard as | Almost certainly |
|---|---|
| "app", "recipe", "SST", "S.A.P.", "पैसीपी", "रेसिपी" | **SAP** |
| "high bridge", "IBPS", "IBIS", "hybrid", "हाइब्रिज" | **Hybris** (Commerce) |
| "DSP", "SDP", "VSP", "वीएसपी" | **Datasphere** (unconfirmed) |
| "Meecom", "मी को" | **MIGO** (low confidence) |

Timestamps below cite `Morecontext.hi.txt`.

## Participants

Diarization resolved four speakers. **Role attribution is inference from content, not stated — confirm before weighting any claim by speaker authority.**

| ID | Inferred role | Basis |
|---|---|---|
| S1 | UI/UX designer, presenting | Drives the Figma walkthrough; "I know more about the UI"; owns/shares the design file; says of the product "I also don't have much idea" [23:21] |
| S0 | Frontend developer (Spartacus/Commerce) | Talks modal instances, common components, URL/page state, "I will write some logic"; repeatedly argues state must be backend-driven |
| S3 | Functional/BA or tech lead | Drives functional interrogation; "we'll sit with the tech team and discuss" [10:11] |
| S2 | Integration/solution mapping owner | Doing screen-by-screen field-level source mapping across Hybris/SAP/Datasphere [25:04–28:31] |

**Named but not present:** **Sujal** — business analyst, "knows the product in proper detail", joining the next session [23:21]. **Subhash** — gatekeeper for Figma subscription/Dev Mode access [21:06]. **Deep** — sent a file, context unclear [19:27].

**Unresolved:** which speaker, if any, is Siddharth. S1 addresses someone who is being onboarded ("when you get access, log in to Figma", "have you used Figma before?") and S3 says "today is the first day here" [19:09]. This matters for evidence weighting — confirm.

---

## Verified observations

Ordered by consequence for the SAP workstream.

### Source of record — the highest-value item in this recording

| Observation | Timestamp |
|---|---|
| **Total Pending Orders on the dashboard comes from Hybris (Commerce), not SAP.** S2 asks directly "where are the total pending orders coming from?" — answer: Hybris. S2 then confirms the mapping document: "so what we wrote for Hybris T1 is correct?" S1 confirms the figure is brought from T1. | 26:52–27:29 |
| S2 is running a **screen-by-screen, field-by-field source mapping** exercise — for each screen, which fields are user input, which are auto-derived, and for the derived ones whether the data originates in Hybris, SAP, or Datasphere. Stated rationale: a screen-level mapping can silently miss a field, and the mapping must be defensible to business later. | 25:04, 27:37–28:07 |
| S1 pushes back that source is already clear at screen level; S2 holds that field-level granularity is required ("one field may be missed"). | 26:25, 28:13 |

**This independently corroborates `HANDOVER_2026-07-30_AI.md` §2.3** — that the portal's pending-order dashboard is served by Commerce T1, not read from S/4. That claim previously rested on a single client-supplied architecture diagram. It now has a second, independent source. Raise to **Verified**.

### DI quantity edit

| Observation | Timestamp |
|---|---|
| **Updating DI quantity resets batch determination.** Explicit and unambiguous in both passes: "once you update your DI quantity, whatever you did in batch determination also gets reset — because obviously the quantity has changed." | 00:30 |
| DI quantity is validated against pending quantity on every edit — cannot exceed what pending allows. | 00:19 |
| The edit screen shows current vs. changed values side by side (e.g. 30 → 25). | 00:56–01:04 |
| Nothing persists until an explicit Save; save **hits SAP**, shows a processing state, then auto-navigates to batch determination. | 01:12, 01:36 |
| Result surfaced to the user as a toast. | 01:46 |

### Transporter and shipping type

| Observation | Timestamp |
|---|---|
| **Three shipping-type tabs: FTP, FTB, and EX.** Previously only FTP and EX-works were in the glossary. | 01:59 |
| S1 glosses them as "one is freight to **pay**/ship, one is freight to **bill**" — the operative distinction being **who arranges shipping: the company, or the customer themselves**. | 02:58 |
| "Mostly they use two — FTP and FTB." | 02:49 |
| The applicable tab is **determined by the Incoterm**, which is already decided upstream. | 01:59, 04:20 |
| Transporter searched by code or name; a card renders the transporter's details on match. | 01:59–02:29 |

### Shipment details and pickup code — **contains a direct contradiction**

| Observation | Timestamp |
|---|---|
| Shipment fields: lorry number, vehicle/truck number, driver details, pickup code. | 04:02 |
| S1: pickup code **"is disabled in FTP."** | 04:19 |
| S3, immediately after: pickup code "is not mandatory — **only on FTP** do they put the pickup code in." | 04:20 |
| Both agree the field's behaviour is **driven by Incoterm**, and that the same form renders with different fields disabled depending on it. | 04:28, 04:35 |

The two statements are mutually exclusive on which Incoterm enables the field. This is a **new conflict, C-8**, and it also conflicts with the 28 July record ("pickup code is currently specified for FTP"). Do not encode pickup-code logic until resolved — see Q-033.

### Shipping cost estimate

| Observation | Timestamp |
|---|---|
| A dedicated API will be built for the estimate: on click, **SAP returns a value** which the portal displays. | 03:30 |
| **The estimate is strictly read-only** — "this is just to validate. You can't change this, you can't do anything about it." | 03:40 |

Directly relevant to **API-05**. It confirms the estimate is a genuine SAP-sourced read with no write-back and no user override — which is the cleaner of the two shapes the dossier considered, and consistent with the pricing-simulation approach recommended in `HANDOVER_2026-07-30_AI.md` §4.3.

### Invoice generation — the longest and most consequential discussion

| Observation | Timestamp |
|---|---|
| **Nobody present knew how long SAP takes to generate the invoice.** S1 asks directly; S3: "I haven't looked at it from the back end yet." | 05:03–05:05 |
| S1 states plainly the team is designing to the **best case**: "we'll sit down with the tech team and discuss this. We're going for the best-case scenario — if it doesn't work, tell us, we'll see." | 10:11 |
| **Three terminal states agreed: invoice number / error / processing.** | 15:22 |
| The "processing" modal was **removed** during the meeting — S1: "remove the processing one, it was only there to give the modal something to dismiss." | 10:34 |
| Immediately reopened: if generation is slow, what does the user see? Resolution — **processing status surfaces in Document Flow**, not in a modal. | 10:58–11:22 |
| **Once a DI enters the invoice flow and the modal reaches its final state, that DI leaves the In-Progress list — whether the invoice succeeded or failed.** S3: "success or failure — if you got in here, it gets removed." | 12:23–12:31 |
| The removed DI moves to the **Invoice Management** tab. | 11:53 |
| **Removal is keyed on DI number, not order number** — order number also appears in the Pending list and would collide. Noted: one order can have multiple DIs. | 16:35–17:11 |
| **"Continue" is purely a modal-dismiss control — it triggers no action.** Clicking outside the modal is equivalent. | 13:13, 14:39 |
| The invoice number originates in SAP. | 15:12–15:18 |
| S0 objects that list-state is being driven from the frontend when it should be backend-driven: "you're getting it done from the front end — basically it should be from the back end." Raised twice, **never resolved**. | 12:34, 16:24 |
| S1 raises the polling problem: if the backend re-checks whether the invoice was created, the UI needs something to display meanwhile. | 10:04 |

### Document Flow, Invoice Management, Reports

| Observation | Timestamp |
|---|---|
| Document Flow shows per-document generation status and is the surface for "invoice not created, for whatever reason". | 07:29 |
| Its purpose is **status visibility and download only**. | 17:20 |
| **Invoice Management was deferred** — "let us discuss this with everyone", too much information to absorb in this session. | 17:27 |
| Reports: filter bar on top, download button exports **Excel**. | 18:01–18:29 |
| Stated intent: existing operational reports are long Excel files (~25 fields each); the portal gives them a usable view. | 18:36 |
| **Pending MRNs / Completed MRNs** are report sections. | 18:48 |

### Dashboard

| Observation | Timestamp |
|---|---|
| Dashboard is under review and **explicitly not final**. | 21:23 |
| Top three tiles: Total Pending Orders, Pending Orders Credit-Free, Credit Block. | 21:32, 22:00 |
| **Credit block status has exactly two values: a hyphen (`-`) and "Credit Block".** Credit-free is defined as *not* credit-blocked. | 22:00 |
| Tiles apply a filter and redirect into the corresponding list/tab. | 22:34, 22:36 |
| An "In Process" tile redirects to the In-Process tab. A further tile (heard as "STO in transit"/MIGO — low confidence) routes to its tab. | 22:36 |
| **One tile does not redirect at all — it is a pure data point.** | 22:36 |

### Process and access

| Observation | Timestamp |
|---|---|
| **The design is explicitly not a final handoff** — "don't take this as the final handoff, just a brief overview." | 19:56 |
| Formal handoff comes only after the review cycle closes; S1: "I think you'll have to start only after that." | 20:12 |
| A review session with feedback was scheduled for the following day; the full demo comes at the end, after feedback is incorporated. | 12:08 |
| **Figma Dev Mode requires a paid seat** — free accounts cannot use it. Access request goes to Subhash. | 20:46, 21:06 |
| Sujal (BA) joins the next session to explain product functionality; S1 will cover UI questions only. | 23:21 |

---

## Interpretations

| Interpretation | Confidence | Supporting observations | Validation |
|---|---|---|---|
| The batch-determination reset on DI quantity change is a **hard SAP-side sequencing constraint**, not a UI convenience — any DI-modify API must either reset batch allocation or reject the change when batches are already determined | Strong inference | 00:30, 01:26 | SD + Q-031 |
| The invoice journey is being designed **without any measured knowledge of SAP latency**, on an explicit best-case assumption | Verified as stated | 05:03, 10:11 | This is the empirical input Q-008/V-04 needs |
| Removing a DI from In-Progress on *failure* as well as success means **failed invoices have no retry surface in the In-Progress list** — recovery must exist in Invoice Management or Document Flow, and neither was specified | Strong inference | 12:23–12:31, 07:29 | Functional — see Q-035 |
| The frontend-vs-backend argument about list state is really an **unowned idempotency/state-authority question**, not a UI preference | Strong inference | 12:34, 16:24, 10:04 | Architect; ties to Q-010 |
| "FTB" is a distinct commercial/Incoterm treatment not previously captured; the FTP/FTB split maps to who arranges freight | Strong inference | 01:59, 02:58 | SD/FI — Q-034 |
| Three portal-visible states (number/error/processing) imply the SAP side must expose a **queryable status**, not just a fire-and-forget create | Strong inference | 15:22, 10:04 | Architect/CPI — Q-035 |
| S2's field-level source mapping is the **single most useful non-SAP artifact** for the ABAP workstream — it is precisely the input the SAP-side contract design needs, and it is being built right now | Strong inference | 25:04–28:31 | Ask S2 for it (Action A-3) |

---

## Conflicts

| ID | Conflict | Evidence |
|---|---|---|
| **C-8** | Pickup code: **disabled in FTP** (S1) vs **only present in FTP** (S3). Also conflicts with the 28 July record. | 04:19 vs 04:20; `meetings/2026-07-28-design-walkthrough.md` |
| **C-9** | 28 July D-005 says DI quantity is editable "while the DI is open"; this meeting establishes that editing resets batch determination — which implies the edit window closes at, or reaches back through, batch determination. Sharpens the pre-existing D-005 wording conflict rather than resolving it. | 00:30 vs D-005 |

---

## Terminology

| Term | Client meaning | Confidence |
|---|---|---|
| **FTB** | Freight to Bill — shipping type where freight is billed; paired with FTP. One of three tabs (FTP/FTB/EX). "Mostly they use FTP and FTB" | Strong inference — SAP representation unknown |
| FTP | Freight to Pay/Ship — company arranges shipping | Refined from 28 July |
| EX | Third shipping-type tab (Ex-works) — present but not walked through | Supported |
| Credit Block | Order status with exactly two values: `-` (free) and `Credit Block` | Verified as design intent |
| Document Flow | Status-visibility and download surface for generated documents | Verified as design intent |
| Invoice Management | Destination tab for DIs that have left the In-Progress list | Verified as design intent |

---

## Actions

| Action | Owner | Why it matters |
|---|---|---|
| **A-1** — Obtain S2's screen-by-screen field-level source mapping | Siddharth → S2 | Highest-value artifact in the recording; it is the field-level input SAP contract design needs, and it exists now |
| **A-2** — Resolve C-8 (pickup code) before any Incoterm-conditional logic is written | SD/functional | Blocks Q-022 |
| **A-3** — Get a measured figure for SAP invoice-generation latency | Siddharth/tech team | The design is explicitly running on an unvalidated best-case assumption |
| **A-4** — Request Figma + Dev Mode seat from Subhash | Siddharth | Dev Mode needs a paid seat; blocks design-accurate field reading |
| **A-5** — Book the Sujal (BA) session and run it against `DOMAIN_GLOSSARY.md §Required KT outputs` | Siddharth | First named person who can serve V-12/Q-027 |
| **A-6** — Confirm meeting date and speaker identities | Siddharth | Evidence weighting depends on who said what |

## Registers updated

`MEETING_INGEST.md` (source index) · `DECISION_LOG.md` (D-008 transcription approval; D-009 to D-013 design-review agreements) · `OPEN_QUESTIONS.md` (Q-032 to Q-036; Q-005/Q-008/Q-022/Q-027 updated) · `DOMAIN_GLOSSARY.md` (FTB, FTP, EX, Credit Block)
