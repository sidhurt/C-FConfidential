# Meeting Notes — Postman Walkthrough Review: Create DI and Submit MIGO

- **Source ID:** `SRC-MTG-20260827-01`
- **Date/time:** 2026-08-27 (inferred from Drive upload time — confirm); 15m 37s of diarized speech
- **Participants and roles:** Three diarized speakers (`S0`–`S2`). Names spoken but **not** mapped to speaker IDs: "Rish ji", "Hemant ji", "Thakur".
- **Decision owner(s):** Not established from the recording
- **Topic/workflow:** Client-side review of the developer's Postman collection evidencing Create DI and Submit MIGO; CSRF/token mechanics, authentication model, and SAP-side business validations the APIs will meet
- **Recording/transcript location:** Google Drive — **"Somebs"** (`1B0pSgkhPSl5q9zccZLiwJ2GMhwHmQcIU`) and **"Di migo postman feedback"** (`1yfqZzhlQG6nN3Qji0SV83uI3MEQuowdL`) are the **same recording** (identical decoded-audio hash `8ea4d48b6d66fc4f7a8867b8d491efcc`; container bytes differ only). Audio SHA-256 `28fd872dd094331fbd1d493bac3f8527261276ba082f9f57c35e6a0ac86554f1`; audio held outside the repository. Transcripts: `../sources/SRC-MTG-20260827-01_transcript.hi.txt`, `.en.txt`, `.en.text-translate-raw.txt`, `.raw.json`, `.raw.en.json`
- **Transcription method:** Sarvam AI batch STT, `saaras:v3`, diarized + timestamped, `hi-IN` detected at p=0.991. Three passes held: (1) `transcribe` — the authoritative source-language pass; (2) audio `translate` — **materially unreliable here, retained only for audit** (`.raw.en.json`); (3) Sarvam `/translate` text pass over the `hi` transcript, line-aligned, 182/182 lines, which is the basis of `.en.txt` after the glossary below was applied. `.en.text-translate-raw.txt` is that pass before glossary correction.
- **Sensitivity:** Client-sensitive

## Reading guidance

Tier-4 meeting evidence, and **weaker than most sources in this repository**. Three cautions:

1. **Roughly 40% of the recording is non-substantive** — rain, commute, where people live, Marathi/Bigg Boss banter, someone leaving in 15 minutes. Ignore `03:28–06:00` and `14:27–14:44` almost entirely.
2. **Diarization is unreliable here.** Many lines appear duplicated across `S1` and `S2` at the same timestamp (heavy overlapping speech on one mic). Speaker attribution below is inferred from content and role consistency, not trusted from the diarizer.
3. **The English pass is materially wrong on the load-bearing terms.** Read `.hi.txt` for anything technical. Confirmed ASR corrections:

| English pass says | Actually | Where |
|---|---|---|
| "many user **exists** ... already written" | **user exits** (SAP enhancement exits) | `11:42` |
| "the **potency** you mentioned" | **idempotency** | `11:30` |
| "in-ball" / "the **in-ball**" / "in **Vivo**" | **inbound (delivery)** | `14:17`, `14:47` |
| "communicating with an external service" | "communicating **SEGW** with an external service" | `10:37` |
| "**SSC** certificate" / "secret channel" | **SSL** certificate / secure channel | `11:00` |
| "difference between delivery and **yoga**" | delivery vs **PO** | `15:02` |
| "three-day **TET**" | three-day **TAT** | `13:05` |
| MeeGo / MIMO / Bego | **MIGO** | throughout |
| "This is a temple", "Jai Mahal", "Tulsi leaves" | noise — discard | various |

Unresolved tokens, do not guess: **`GDRK`** (`13:24`, appears to be a storage location or movement type), **`FSTS`** (`06:25`), **"W document" / "WD document inventory"** (`02:46–03:02`).

## Purpose

`S1` (client functional/business side) is reviewing the Postman collection that `S2` (developer) built to evidence Create DI and Submit MIGO. This is an **approval gate**, not a design session: `S1` states plainly he will sign off on the collection once it is presented in a form he can follow.

## Observed statements

| Observation | Speaker/source | Affected item |
|---|---|---|
| A field under discussion is **derived from the predecessor document**, not entered — it was already present because the new document inherited it. | `S2`, `00:08–00:33` | Field lineage; DI request model |
| To determine the receiving location, `S1` directs checking the **PO** of the document. | `S1`, `00:33` | Field lineage |
| Discussion of transaction type / FI document / "W document inventory". `S1` states he must be able to explain to an end user what the code means: *"the end user will say, what does W mean to me? If I don't have an answer, I will say I don't have right now, I will give it."* Suggests posting it to the group chat. | `S1`/`S2`, `02:16–03:28` | Document/movement type semantics; unresolved |
| Postman **Get CSRF Token** request is demonstrated; the token is **auto-populated** into subsequent requests. | `S2`, `06:38` | Postman collection structure |
| `S1` repeatedly asks **where the CSRF token and the request parameters come from** — he cannot trace them from the collection as presented. Asked at `06:44`, again at `08:24`, again at `08:53`. | `S1`, `06:44–08:58` | **Primary friction of the meeting** |
| `S2` explains the mechanism: the token request is sent first, and the token is **stored in a Postman environment variable** so it flows automatically into the next call. | `S2`, `07:43`, `08:34` | Postman collection structure |
| **Explicit deliverable demanded.** *"It is simplified for me and Rish ji because we are not much technical like you guys... simplified that it is like a token you generated, what you have passed, what output comes, that output you have to pass into your main post method. In the post method, what you have passed, what is the input, show that, show the payload, that's it, clear."* | `S1`, `09:32–10:00` | **Action A-1** |
| **Approval gate.** *"Send me the collection, I will check and I will okay it."* | `S1`, `10:00` | **Action A-1** |
| Token is characterised as an authentication method / *"a method to open the gate"*, used for SAP and non-SAP alike, and is **per session**. | `S1`/`S2`, `10:00–10:17` | Auth model |
| `S1` challenges **why basic auth (username/password) is needed in addition to the token**. `S2`: because SEGW is communicating with an external service, a user must be assigned. | `S1`/`S2`, `10:18–10:37` | Auth model; Q-062 |
| **Developer is currently testing under his own personal SAP user.** `S1`: acceptable for testing, but a dedicated **service/technical user ID** must be created and passed going forward. | `S1`/`S2`, `10:45–10:58` | **Q-062; Action A-2** |
| `S1` raises **SSL certificate** over a secure channel as a second authentication method alongside the token. | `S1`, `11:00–11:21` | Auth model; NFR |
| **Open point named by `S2`: idempotency / duplication.** | `S2`, `11:30` | Q-024; C-? |
| `S1`: *"See the **user exits** — many, many, many user exits are already written"*, and the team must understand why they behave as they do. | `S1`, `11:42–11:48` | **Enhancement surface — new scope risk** |
| **Validation V-A:** if MIGO is **not completed for the full dispatch quantity**, the system will **not allow the vehicle to be returned** and will **not allow yard registration** of that vehicle. Yard registration is **linked to MIGO**. Rationale: the transporter is responsible for unloading the full consignment. | `S1`, `11:48–12:33` | **API-02 error contract** |
| **Validation V-A (cont.):** the alternative to full receipt is to **book a shortage** — but the full quantity must reconcile (*"हिसाब मिलना चाहिए"*) before the trip is released. | `S1`, `12:33` | API-02 request model — shortage bucket |
| `S1`: *"this is the kind of validation we build — **so many validations are there**."* | `S1`, `12:39` | Scope |
| On whether these block the API: *"that might not stop you from processing, because the **happy path always works**, and secondly the **system might throw the error**."* | `S1`, `12:51` | **Error-handling contract** |
| **Validation V-B / alerting:** three-day **TAT** — if MIGO is still not complete and the document still shows **in transit**, an **alert must go to the respective CNF**. `S1` asks the developer directly how he will set that alert. | `S1`, `13:05` | **New requirement — alerting/monitoring** |
| **Validation V-C:** **RSD goods must not be brought in as "normal"** — *"that should be GDRK only."* | `S1`, `13:24` | Q-059 (RSD = rail-siding depot); movement/storage rules |
| `S1`: *"there must be many such validations written, and more — **which even I probably don't know**. So we have to figure that out. That's a **separate exercise**."* | `S1`, `13:32–13:39` | **Action A-3** |
| **MIGO reference document.** `S2` assumes GR is posted against the PO. `S1`: *"you can do it in **inbound** too — why are you not taking the inbound first?"* | `S1`/`S2`, `14:17–14:53` | **API-02 contract — reference document type** |
| `S0`: GR **can be posted against the delivery**; where there are **multiple deliveries**, GR is taken against that delivery. | `S0`, `14:55` | API-02 contract |
| **Key functional reason**, `S1`: *"there is a difference between delivery and PO. If you take the PO, you have taken the **entire PO contract** — so you have taken the one you never intended to take."* | `S1`, `15:02–15:09` | **API-02 contract — decisive** |

## Interpretations

| Interpretation | Confidence | Supporting observations | Validation |
|---|---|---|---|
| **Submit MIGO should reference the inbound delivery, not the PO.** Posting at PO level pulls the whole PO contract quantity and over-receives. This is the most actionable technical output of the meeting. | Strong inference — stated with functional authority and an explicit reason | `14:47`, `14:55`, `15:02–15:09` | Confirm with MM which reference the portal will always have available; then fix the API-02 request model |
| The review **did not pass**. `S1` could not trace parameter provenance and asked three times; the collection was not approved in the room. | Verified from the recording | `06:44`, `08:24`, `08:53`, `10:00` | Re-present per A-1 |
| **The SAP-side validation surface is largely unmapped, and the client knows it.** Three validations were named ad hoc; `S1` explicitly says many more exist and that he does not know them himself. Any API-02/API-03 error contract built only from the happy path will be incomplete. | Strong inference | `12:39`, `12:51`, `13:32–13:39` | A-3 — enumerate from user exits + config, not from interviews |
| **`user exits` is a newly-surfaced enhancement surface.** Custom validation logic in exits is not visible in service metadata or in any SEGW artifact already catalogued. It is a source that must be read directly. | Strong inference | `11:42–11:48` | Extract exit implementations for the MIGO/delivery objects in QS4 |
| The **three-day TAT alert is a new requirement**, not previously in the API register — it implies a scheduled read of in-transit-but-not-received documents and a notification path to the CNF. | Strong inference | `13:05` | Confirm owner: portal-side job, SAP-side job, or CPI |
| **Q-062 is now concrete, not theoretical.** Development is proceeding on a personal SAP user. The identity model was deferred; a service user must exist before any shared/UAT testing. | Verified distinction | `10:45–10:58` | Raise with Basis/Security immediately |
| `S1` and "Rish ji" are the **business/functional approvers** and are self-declared non-technical. Evidence packaging materially affects sign-off speed. | Strong inference | `09:32–10:00` | Applies to all future demo artifacts |

## Decisions

**None promoted to `DECISION_LOG.md`.** Speaker identity and decision authority are not established from the recording, per standing practice. The inbound-delivery-vs-PO position and the service-user requirement are recorded as **working directions pending owner confirmation** — both were stated by the dominant functional voice with a reason attached, which makes them strong candidates but not decisions.

## Requirements changed or sharpened

- **API-02 (Submit MIGO)** must state its **reference document type explicitly** — inbound delivery, with multiple-delivery handling — and must not default to PO.
- **API-02** needs a **shortage booking path**, not only a full-receipt path; the full quantity must reconcile either way.
- **API-02/API-03 error contract** must carry the SAP validation failures as typed, actionable errors — the happy path is not sufficient evidence of correctness.
- **New requirement:** three-day TAT alerting to the respective CNF for MIGO-incomplete / still-in-transit documents. Owner unassigned.
- **RSD-origin goods** are subject to a storage/movement restriction (`GDRK` only). Connects to Q-059.
- **Auth:** token (CSRF, per session) **plus** basic auth under a dedicated service user, with SSL over a secure channel. Personal-user testing must not persist.
- **Idempotency/duplication** confirmed as a live open point by the developer.

## Open questions and actions

| Priority | Question/action | Owner |
|---|---|---|
| **A-1 — High** | Re-present the Postman collection in the linear form `S1` demanded: token request → what was passed → what came back → that token into the main POST → the full request payload → the response. Then send the collection for sign-off. | Developer (`S2`) |
| **A-2 — High** | Create and provision a **dedicated service/technical SAP user** for the integration; stop testing under a personal user before any shared testing. Feeds **Q-062**. | Basis / Security |
| **A-3 — High** | Run the **validation-enumeration exercise** `S1` scoped: extract the SAP-side validations affecting MIGO and delivery — starting from **user exits**, not from interviews. `S1` has stated he cannot enumerate them himself. | Developer + MM/SD functional |
| **Q-072 — High** | Which **reference document** does Submit MIGO post against — inbound delivery (per `S1`/`S0`) or PO? How are **multiple deliveries** against one PO handled, and does the portal always hold the delivery reference at MIGO time? | MM / SD |
| **Q-073 — High** | What is the complete set of SAP validations blocking MIGO/vehicle return/yard registration, and **which are implemented in user exits** versus standard config? | MM / ABAP |
| **Q-074 — Medium** | Who owns the **three-day TAT in-transit alert** — portal job, SAP job, or CPI — and what is the notification channel to the CNF? | Architect |
| **Q-075 — Medium** | What are **`GDRK`** and the RSD-goods restriction in SAP terms (storage location, movement type, or both)? Relates to Q-059. | MM |
| **Q-076 — Medium** | What is the **"W" / "WD" document / transaction type** raised at `02:46–03:02`, in end-user-explainable terms? `S1` explicitly wants an answer he can give a user. | MM / FI |
| **Q-077 — Medium** | **Idempotency/duplicate submission** handling for Submit MIGO and Create DI — named as an open point by the developer, not resolved. Connects to Q-024. | Architect |

## Terminology

| Term | Client meaning | Confidence |
|---|---|---|
| Yard registration | Gate/yard entry step for a returning vehicle; **blocked by SAP unless MIGO is complete for the full dispatch quantity** | Meeting-supported, stated with authority |
| Shortage booking | Accepted alternative to full receipt; the full quantity must still reconcile before the trip is released | Meeting-supported |
| User exits | SAP enhancement points carrying custom validation logic; described as numerous and already written | Meeting-supported; contents unread |
| RSD | Rail-siding depot (per Q-059); its goods may not be received as "normal" | Corroborated across sources |
| GDRK | Unresolved — target storage location or movement type for RSD goods | **Unresolved; do not guess** |
| TAT | Turnaround time; three days quoted for MIGO completion before alerting | Meeting-supported |

## What this meeting did not settle

Do not read more into this recording than it holds. It did **not** address the invoice chain, e-Way Bill, stage-gate, CPI's role, STO, or the T1/T2 topology. It is narrowly a **collection review plus an unplanned dump of MIGO-side business validations** — the validations are the valuable part, and they arrived incidentally rather than as an agenda item.
