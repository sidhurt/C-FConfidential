# Meeting Card

Carry this in. Every item is **open**, **high-leverage**, and **unanswerable by anyone currently in the room** — that last property is what makes it leverage. You are not trying to answer their questions. You are converting circular arguments into action items with a named owner.

Rule of thumb: two or three of these per meeting. Ask, get a name against it, stop talking.

---

## Tier 1 — ask these regardless of agenda

**1. "Has anyone actually measured the invoice-chain latency?"** — Q-032

PGI → shipment → shipment cost → billing → e-Invoice → E-Way Bill. Nobody has measured it. Established 3 Aug; the UI is designed to an explicit best-case assumption, and on 4 Aug someone asserted *"all SAP transaction calls are synchronous"* (`SRC-MTG-20260804-01` @00:29:09) with nothing behind it.

*Why it lands:* it is a factual question with no available answer, and the entire orchestration shape depends on it. It cannot be argued away.

**2. "Show me the existing SAP→CPI→T1 delivery/invoice interface — what object triggers it, and how is it different from `ZCRM_STAGEGATE`?"** — Q-037

Option C reads them live from T1, but S/4 creates them. QS4 proves a pull-shaped stage-gate service. The 10 Aug KT separately claims an existing trigger-shaped SAP→CPI→T1 projection for DI, invoice and order changes (`SRC-MTG-20260810-02` @20:45–21:18). The two may coexist; neither the trigger object nor the full-document payload/latency has been shown.

*Why it lands:* asking for the actual object turns an architecture assertion into something observable and names the owner/support path.

**3. "Can Basis activate the four released A2X services in DEV?"** — Q-045

`API_OUTBOUND_DELIVERY_SRV`, `API_BILLING_DOCUMENT_SRV`, `API_MATERIAL_DOCUMENT_SRV`, `API_MATERIAL_STOCK_SRV`. They ship with S/4HANA 2022 (D-018) and are **not registered on this Gateway** — you verified that yourself.

*Why it lands:* concrete, verifiable, Basis-owned, and it may remove several custom builds from scope. Also demonstrates you have been in the system and they have not.

---

## Tier 2 — ask when the topic surfaces

**4. When duplicate / double-DI comes up: "Which system enforces the over-delivery rule?"** — Q-024 + Q-010

The 4 Aug proposal was a reservation store in T2 (@00:24:19). That puts SAP business validity in Commerce. SAP already computes the chain: contract → order → schedule → delivery → invoice → rejected → **`BAL_QTY`** (D-026).

*Follow-up if pushed:* "Then who owns the lock?" The correct answer was already spoken in that meeting (@01:35:58, *"whoever clicked first, refuse the other — that is standard"*).

**5. When DI creation comes up: "Which predecessor creates the DI — sales order or STO?"** — Q-031

`BAPI_OUTB_DELIVERY_CREATE_SLS` vs `..._STO`. Trade / non-trade / STO may differ. This blocks your actual build and is a pure SD question.

**6. When stock or batches come up: "Is batch stock availability a real-time S/4 read, or is it expected from the DSP snapshot?"** — Q-038

Stock *Ageing* is DSP/D-1 and display-only. The 10 Aug UI walkthrough says fulfilment stops at system batch determination when stock is unavailable (`SRC-MTG-20260810-01` @25:09–26:02), but the live S/4 source/API still appears nowhere in Option C.

**7. When integration is discussed: "Is CPI in the command path at all?"**

New, from 4 Aug. In 77 minutes on integration architecture, CPI was mentioned **once** (@00:54:13). Every flow described was Commerce calling SAP directly. ARCHITECTURE.md assumes `Commerce → CPI → Gateway → ABAP`.

*Why it lands:* it changes who owns contract, retry, correlation and error mapping — i.e. whether half your design work exists.

**8. When your own build comes up: "SEGW or RAP, and does CPI need OData V2?"** — Q-046

S/4HANA 2022 makes RAP available; SEGW is deprecated for new development; RAP defaults to V4. The client's catalogue is entirely classic Z-copies.

---

## Tier 3 — the ownership question

**9. "What is the first formally assigned interface, and what are its acceptance criteria?"** — Q-006

Ownership was explicitly deferred on 4 Aug — *"first understand the architecture, then we'll do the who and what later"* (@00:00:42), in response to a direct question about who would develop.

Ask it once per meeting until it has an answer. It is the only question on this card that protects your scope rather than improving the design.

---

## Conflicts to raise, not questions to ask

Say these as statements. They are already evidenced.

- **T2-as-persistent-store vs Option C.** You state T2 stores recurring data from SAP, DSP and T1. D-014 selected Option C (*direct T1 query + scheduled DSP sync*); a persistent Hybris store is **Option B**. The 4 Aug meeting contradicts itself on this within 35 minutes (@00:12:08 "nothing stored locally in T2" → @00:45:44 "store it locally").
- **STO / MRN source is unsettled three ways.** D-014 says DSP→T2 every 15 min. On 4 Aug: S4→T2 direct (@01:15:21) and DSP→T2 (@01:15:35), four minutes apart.
- **Stage-gate scope.** @01:06:09 *"in the architecture of CNF there is no such thing as a stage gate"* — contradicted at @01:09:14 and @01:09:23 in the same meeting.
- **MRN identity and response key.** Source code defines Pending MRN as a derived in-transit position. Two 10 Aug meetings variously place MRN before MIGO, after MIGO, expand it as Movement Reference Number and expect Submit MIGO to return an “MRN number” (C-14). Do not freeze current v1.7 API-01 until MM/SD names the posting reference and SAP document key.

---

## What not to do

- Do not try to out-recall them on Udaan history or cement domain. You will lose, and it is not your job.
- Do not accept an action item that has no owner named yet. Silence on ownership defaults to you.
- Do not answer a question you have not verified in the system. Your entire advantage is that your claims are checkable. Say "I'll verify that in QS4 and come back" — then do, that day.
