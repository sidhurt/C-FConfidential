# Create DI — questions for the architect

**Date:** 17 September 2026 · **System tested:** QS4/700
**Evidence:** `sessions/2026-09-14-create-di-enhancement-equivalence/CREATE_DI_TEST_APPROACH_2026-09-17.md`

> **Status at end of 17.09.2026:** Q1 (enrichment write path) belongs to the later dispatch APIs and is
> deferred (`SRC-SID-20260917-08`). Q3 answered by the business: delivery block, billing block and
> bill-to-ship-to all apply (`SRC-SID-20260917-10`); delivery blocks are already refused by standard SAP,
> billing block is not — see `CREATE_DI_BILLING_BLOCK_DEVELOPMENT_APPROACH_2026-09-17.md`. Q4: bill-to-ship-to
> is in scope per the business; it is a factory-side paired-delivery flow still to be designed. Q5 answered
> (Hybris/CPI). Q2 (one material per DI) remains open.

## Background in one paragraph

C&F Create DI is a depot creating an outbound delivery from a Trade or Non-trade sales order, or a
depot-to-depot STO. We call SAP's standard delivery API (`API_OUTBOUND_DELIVERY_SRV;v=2`). The seven
agreed validations already exist as custom code inside SAP's delivery save hooks, which run for the
screen and the API alike. On 17 September we created delivery `9004953534` from a depot Trade order
through the API under the debugger, then ran negative and positive tests:

- **Works on the API:** the storage-location + SPI rule (rejected `DRD`, accepted `GDF`).
- **Covered by standard SAP:** over-quantity and credit-blocked orders are refused.
- **Skipped on the API:** the one-material and one-storage-location rules only run when the
  transaction is `VL01N`/`VL02N`; on the API the transaction code is blank.
- **Cannot be reached:** the two transporter rules need a transporter on the delivery, and the
  standard API cannot write one.
- **Timing (proven):** the rule checks run *before* the step that fills fields such as the
  transporter from custom field `ZZPARTNER`. Data that arrives through that step is invisible to
  the checks.

> **Answered (Siddharth, `SRC-SID-20260917-08`):** SAP must **build an API** that receives the
> enrichment fields from Hybris T2. SAP master data syncs to Hybris T2 near real time; SAP stays
> authoritative. **Design constraint from T0:** the API must write the transporter into the delivery
> partner table before SAP's save checks run; writing only `ZZPARTNER` would let the transporter
> rules skip. What remains for the architect is approval of the build approach (see below).

## Question 1 — Which interface writes the transporter and storage location/batch?

**Why we ask:** after the DI is created, the portal adds storage location/batch, transporter,
vehicle and LR/GR. The transporter rules (FTB self-transporter ban; transporter must be mapped to
the depot) only work if the transporter is already on the delivery when the checks run.

| Option | Transporter rules would… |
|---|---|
| A. Custom command that calls `BAPI_OUTB_DELIVERY_CHANGE` and writes the transporter as a delivery partner (the ILMS pattern) | Run, if the partner is written directly and not through `ZZPARTNER` |
| B. Extend the standard OData service with custom fields | Silently skip — custom fields are mapped after the checks — unless the check code is changed |
| C. Transporter recorded only on the shipment, not the delivery | Never run on the delivery; the rules would need to move to shipment/Pre-PGI |

**Answer needed:** the chosen interface for each enrichment field, and whether the transporter
belongs on the delivery, the shipment, or both. (Open item Q-082.)

**Follow-up to ask:** "We will build a SAP API that receives the DI enrichment fields from Hybris T2.
The standard delivery API cannot write the transporter or SPI, so the proposal is a custom command
that calls SAP's released delivery-change BAPI as delivered and writes the transporter as a
delivery partner, so the existing validations run unchanged. Do you approve that approach, and
which fields belong in this call versus the later Pre-PGI step?"

## Question 2 — Must the API reject multi-material or multi-storage-location DIs?

**Why we ask:** these two rules are protected by a transaction-code check and do not run on the
API. The portal creates one DI from one order item, so a multi-material DI may never be sent — but
the API itself would accept one. A second storage location can appear later through batch split.

| Option | Effect |
|---|---|
| A. Rely on the portal/CPI contract (one item; controlled batch split) | No SAP change; SAP no longer enforces the rule for API callers |
| B. Widen the check inside the existing BAdI implementation to include API calls | SAP enforces for everyone. The same check also serves ILMS and screen flows, so the new condition must not break them |
| C. Add a separate API-only check | SAP enforces for the portal only; two versions of one rule to maintain |

**Answer needed:** A, B or C for each of the two rules, and who owns changes to
`ZLE_SHP_DELIVERY_PROC`.

## Question 3 — Are delivery-block and billing-block orders a real C&F requirement?

**Why we ask:** the custom "blocked order" rule never runs for depot deliveries (it depends on
`ZZVBELN`). Standard SAP already refuses credit-blocked orders (tested). A delivery block on the
order is normally refused by standard SAP too (not yet tested). A billing block does **not** stop a
delivery in standard SAP.

**Answer needed:** must the API refuse a DI for an order with a billing block? If yes, that is a
small build; if no, nothing to build.

## Question 4 — Can we formally drop the `ZZVBELN` rules from C&F?

**Why we ask:** `ZZVBELN` links a factory stock-transfer delivery to a customer order (the
bill-to-ship-to flow). It was filled on 2 of 153,514 recent deliveries and on no depot delivery. We
do not yet know which program writes it.

**Answer needed:** confirm bill-to-ship-to is outside C&F, and name the owner of the `ZZVBELN`
writer so the rules can be recorded as dormant with a known wake-up condition.

> **Answered (Siddharth, `SRC-SID-20260917-08`):** the Hybris front end or CPI blocks duplicate DIs.
> No SAP build. Remaining caller obligation: after a timeout, look up existing deliveries for the
> order item before retrying, because SAP may already have committed.

## Question 5 (secondary) — Who prevents duplicate DIs?

**Why we ask:** standard SAP creates a second delivery from a repeated request. The Gateway
repeat-request configuration is empty in QS4.

**Answer needed:** duplicate protection in CPI, in SAP (Gateway `RequestID` configuration), or both.
(Open item Q-077.)
