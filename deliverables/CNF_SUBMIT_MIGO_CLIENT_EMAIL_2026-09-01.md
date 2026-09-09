# Response email — Submit MIGO custom logic study and implementation plan

**Draft, 1 September 2026**

---

**Subject:** C&F Submit MIGO — custom MIGO logic identified, and proposed approach

Dear all,

Following the review, I have completed the study of the custom MIGO logic in QS4. This note sets out what you asked for, what I found in your system, and how I propose we build it.

## What you asked for

1. The C&F receipt should be made against **Outbound Delivery and Delivery Item**.
2. **PO Number and PO Item should not be mandatory inputs** for the C&F user.
3. The receipt must be controlled against the **selected delivery quantity**, not the full PO quantity.
4. **Material Document Number and Year** must be returned.
5. It should be **one Submit MIGO action**, without a separate enquiry call in front of it.
6. The **custom fields captured at MIGO** — Token, LR, transporter, vehicle, challan and related information — sit outside the standard BAPI and must be accounted for.
7. The **custom programs, enhancements, BAdIs and exits** around MIGO must be studied so nothing is missed.

## What I examined

I ran the where-used list for `BAPI_GOODSMVT_CREATE` in QS4 and inspected every custom caller, concentrating on the movement type 101 branches. All inspection was read-only. Nothing was changed, executed or posted.

## What I found

**Your system already posts goods receipts against an outbound delivery with no purchase order supplied.** This is the yard / ILMS receipt path, and it is the model for C&F.

| Program | What it gives us |
|---|---|
| `ZLEIILMSDOCUMENTS_GRN_BTST` | The clean, minimal pattern. Reads the delivery item and derives material, plant, quantity, unit and batch. Passes no PO to the BAPI at all. |
| `ZLEIILMSDOCUMENTS_GOODSREC` | The same, plus the controls we need — quantity capping against the delivery, shortage handling, duplicate-receipt check, and the custom-field write. |
| `ZMMR_AUTOMIGO_RMC_GRN_M_FILI01` | Shows PO being read from the delivery item's own source document rather than asked of the caller. |
| `ZSD_INTRCO_MIGO` | A clean post-then-commit-or-rollback pattern in a single callable unit. |
| `ZMM_IFMS_AUTO` | An existing custom HTTP endpoint that takes simple business fields as JSON, derives the technical values inside SAP, posts, commits and returns a simple JSON result. Proof the single-call approach is already established here. |

On the custom fields specifically:

- `ZMMT_MIGO_HDR` is the custom table holding Token, LR number and date, transporter, vehicle and vehicle type, e-way bill, AFR manifest and challan information.
- `ZMMR_MIGO_SCREEN_ADD` is the MIGO **screen** program. It reads live MIGO session data, so it cannot be called from an interface. This is worth stating plainly, because it was the main risk: if the custom fields could only be captured through that screen, an API-based receipt would lose them.
- **That risk does not apply.** The ILMS programs above write `ZMMT_MIGO_HDR` themselves, directly after the goods receipt is committed. The custom data does not depend on anyone opening MIGO. It is available on an API path, and the values are derived from your yard tables — `ZLETILMSDELIVERY`, `ZLETILMSTOKEN`, `ZLET_VEHICLE` and `ZLETDDCREGISTER` — all reachable from the delivery number and item.

I also reviewed `ZMM_MIGO_POSTING` (ZMM063) and `ZMM_STO_AUTO_POSTING`. Both are useful references but neither is the model for C&F: the first takes its values from an uploaded file, and the second builds them from a document chain it creates itself.

## On the purchase order

To be precise, because this was discussed at length.

The PO is **not asked of the C&F user, and does not appear in the request**. Inside SAP the underlying PO/STO relationship still exists, and where the posting needs it, it is obtained without the caller's involvement — either resolved by SAP from the delivery reference, or read from the delivery item's source document. Both patterns are already in use in your programs.

So PO remains part of the document flow. It simply stops being the C&F agent's responsibility.

## The proposed interface

**Request:** Delivery Number and Delivery Item. Quantity optional — omitted means the full open delivery quantity.

**Everything else derived inside SAP:**

| Field | Source |
|---|---|
| Material, Unit, Batch | Delivery item |
| Receiving Plant | Delivery |
| Quantity | Open delivery item quantity |
| Movement Type, Movement Indicator, Dates | Determined by the service |
| PO / PO Item | Resolved internally, never requested |
| Token, LR, AFR manifest | Yard delivery record |
| Vehicle, Vehicle Type, Transporter | Token and vehicle master |
| Challan, GST Invoice, E-Way Bill | DDC register |

**Response:** Material Document Number, Material Document Year, and clear messages on failure.

**Controls inside the same call:** duplicate-receipt prevention at delivery-item level, a lock against simultaneous calls, quantity capped at the delivery quantity, and full rollback if the posting fails.

## Implementation plan

**Stage 1 — Confirm three business rules.** These are with you and are listed at the end of this note. Only the first can change the request format.

**Stage 2 — Runtime validation.** Two tests on a fresh, PGI-complete delivery: one through the function module in SE37 to confirm the delivery-only field set is accepted, and one through the standard API in Postman to establish whether it can be used directly or whether the derivation service is required. Both are prepared.

**Stage 3 — Build the C&F service.** A custom service following the `ZMM_IFMS_AUTO` pattern, with the derivation and control logic taken from the ILMS programs. Most of this is reuse rather than new development.

**Stage 4 — Custom fields and validations.** Populate `ZMMT_MIGO_HDR` after commit, as the ILMS programs do, and reimplement whichever MIGO validations apply to C&F. Please note that validations built into the MIGO application do not run on an API path, so we need to know which of them matter for C&F.

**Stage 5 — Error handling and CPI integration.** Map SAP messages to wording the C&F portal can show the agent, and confirm the session and token handling with Basis and the CPI team.

**Stage 6 — Controlled testing.** Separate delivery items allocated to each test case so that results stay clean.

## What I need from you

1. **Do C&F deliveries always pass through the yard and carry a Token?** The Token, vehicle, transporter, LR and e-way bill are all read from the yard records. If a C&F delivery has no yard record, these cannot be derived and would need to be sent in the request instead. This is the only open point that changes the request format.
2. **Can a C&F agent receive part of a delivery, or always the full quantity?** And where there is a shortage, should the difference go to blocked stock as it does in the yard process?
3. **Which storage location should a C&F receipt post to,** and does it vary by plant or depot? This is the one value that cannot be derived from the delivery.
4. **Which MIGO validations apply to C&F**, as distinct from the yard or other receipt scenarios?
5. **The approved bag/tonne conversion and rounding rules.**

## Testing status

The saved SE37 test entry was executed as directed. It produced no material document and returned a posting period error — the current posting period is not open for that company code. This is a system setting, not a problem with the approach, but it does block posting tests until resolved.

To proceed with runtime validation we need:

- the posting period opened for the relevant company code, or confirmation of which period we should post into; and
- outbound deliveries that are PGI-complete with no goods receipt yet posted, reserved for this testing.

Once those are in place, the remaining validation is short.

Happy to walk through any of this in more detail.

Best regards,
Siddharth
