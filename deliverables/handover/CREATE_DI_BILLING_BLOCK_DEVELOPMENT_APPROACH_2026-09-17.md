# Create DI — billing block check: development approach

**Date:** 17 September 2026 · **System basis:** QS4/700
**Requirement:** a DI must not be created for a sales order that carries a billing block
(`SRC-SID-20260917-10`).
**Evidence:** `sessions/2026-09-14-create-di-enhancement-equivalence/CREATE_DI_TEST_APPROACH_2026-09-17.md` §8, §18.

## 1. In one paragraph

Standard SAP does not stop a delivery when the sales order has a billing block. On 17 September a
billing block `15` was set on credit-OK depot order `5284465`, and the standard delivery API created
DI `9004953540` sixteen seconds later. The client already has a custom delivery check that looks at
billing blocks, but only on a different order (the bill-to-ship-to order held in `LIKP-ZZVBELN`), so
it never runs for depot DIs. The proposal is to add one small check to that same existing BAdI
implementation: when a delivery is created, read the billing block of each sales order it is created
from, and reject the delivery if one is set. No new service, no change to the API call.

## 2. Extension rung — stated first

| Rung | Option | Verdict |
|---|---|---|
| 1. Configuration | Delivery block configuration (`TVLS`) controls delivery blocks only. No standard setting makes a billing block (`TVFS`) stop delivery creation. | **Ruled out** — no such setting |
| 1. Business process | Whoever sets a billing block also sets a delivery block (already refused by SAP, Tests 6a/6b). | **Valid alternative, no code** — depends on user discipline; not enforced. Ask the business first. |
| 2. Standard API as delivered | Proven not to enforce (DI `9004953540`). | **Ruled out** |
| 3. Released BAdI / customer exit | Existing customer implementation `ZEI_LE_DELIVERY_PROCESS` of released BAdI `LE_SHP_DELIVERY_PROC`, method `DELIVERY_FINAL_CHECK`. | **Proposed** |
| 3. Alternative | Delivery copy-control requirement routine (VOFM) for the sales-order → delivery item copy. | Possible, but spreads the rule into copy control for each order/delivery type pair; the BAdI already hosts the neighbouring block checks |
| 4–6 | Explicit/implicit enhancement, modification | **Not needed** |

## 3. Why this hook works for the API — proven, not assumed

The T0 trace on 17 September (DI `9004953534`, OData, HTTP work process) showed:

- `ZCLLE_DELIVERY_PROCESS~IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK` **is called** on the OData
  create path.
- It runs **before** the save (`SAVE_DOCUMENT_PREPARE`) and an error placed in `CT_FINCHDEL` stops the
  save and returns to the caller as HTTP 400 with the message text (proven with `ZLE/104` on 17.09).
- `SY-TCODE` is blank and `IF_TRTYP = 'H'` on create — so the new check must **not** use a
  transaction-code gate.
- `IT_XLIPS` carries the predecessor (`VGBEL`/`VGPOS`, category `C` for a sales order).

## 4. Proposed logic

Location: class `ZCLLE_DELIVERY_PROCESS`, method `IF_EX_LE_SHP_DELIVERY_PROC~DELIVERY_FINAL_CHECK`,
as a separate private method called from it. Existing checks stay untouched.

```text
IF switch active (TVARVC)                                   " see §6 decision 5
AND if_trtyp = 'H'                                          " create; see §6 decision 3
  collect distinct VGBEL from IT_XLIPS
    where UPDKZ <> 'D' and VGTYP = 'C'                      " sales-order items only; STO untouched
  read VBAK-FAKSK for those orders                          " one SELECT ... FOR ALL ENTRIES
  (optional) read VBAP-FAKSP for the referenced VGBEL/VGPOS " see §6 decision 2
  for each order with a billing block that is in scope      " see §6 decision 1
    append one CT_FINCHDEL row:
      VBELN = delivery, MSGID = ZLE, MSGNO = <new>, MSGTY = 'E',
      MSGV1 = order number, MSGV2 = billing block code
```

Proposed message (new number in class `ZLE`):
"Sales order &1 has billing block &2; delivery instruction cannot be created".

Notes for the developer:

- **Do not copy the existing pattern of inserting only while `CT_FINCHDEL` is initial.** That
  pattern hides this error behind any earlier one (recorded defect 6 in
  `CREATE_DI_VALIDATION_MATRIX.md`). Append the row regardless.
- No `SY-TCODE` gate, so VL01N, collective delivery processing and the API behave the same
  (see §6 decision 4).
- No ABAP-memory or screen-program dependencies.

## 5. Test plan (Gateway Client, same method as 17.09)

Use credit-OK orders only; saving an order in VA02 re-runs the credit check, so re-read `VBAK-CMGST`
before each POST.

| # | Case | Expected |
|---|---|---|
| 1 | Depot Trade order, header billing block in scope, credit `A` | HTTP 400 with the new `ZLE` message; no delivery created |
| 2 | Same order, billing block removed | 201, delivery created |
| 3 | Billing block code **not** in scope (if a list is used) | 201 |
| 4 | Depot Non-trade order with billing block | HTTP 400 |
| 5 | Depot STO (`ZNL`) | 201, check not applied |
| 6 | Item-level billing block (only if decision 2 = yes) | HTTP 400 |
| 7 | VL01N on a billing-blocked order | Same rejection as the API |
| 8 | Change of an existing delivery (`IF_TRTYP V`) | Unaffected, unless decision 3 says otherwise |

Evidence per case: request, HTTP status and body, breakpoint confirmation for the first run, and a
delivery re-read or non-persistence check.

## 6. Decisions needed before build

| # | Decision | Default proposed |
|---|---|---|
| 1 | **Which billing block codes stop a DI** — every code, or a list (e.g. `14` Stop Supply, `15` Depot Blocking, `11` Legal Case, `ZA` Inactive)? QS4 has 33 codes, several about pricing or memos. | A TVARVC list, maintained by the business |
| 2 | Header block only (`VBAK-FAKSK`), or item block too (`VBAP-FAKSP`)? | Header and item |
| 3 | Create only, or also when an existing DI is changed? | Create only |
| 4 | Same rule in VL01N and background delivery creation, or API only? | Everywhere (one rule, one behaviour) |
| 5 | Emergency switch to turn the check off without a transport? | Yes — TVARVC flag |
| 6 | Does the business-process alternative (always set a delivery block with the billing block) make this build unnecessary? | Ask first |
| 7 | Who owns and transports changes to `ZEI_LE_DELIVERY_PROCESS`, which also serves screen and ILMS flows? | ABAP lead |

## 7. Out of scope

Bill-to-ship-to (`ZZVBELN`) checks, delivery block and credit block (already refused by standard SAP),
duplicate DIs (Hybris/CPI), later dispatch steps.
