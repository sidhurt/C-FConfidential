# CreateDI & SubmitMIGO

## An evidence-led ABAP study guide

Prepared for Siddharth Srivastava | Evidence cut-off: 31 August 2026

**Internal study material. Not an approved MOM, final API contract or posting authorization.**

The aim is to explain the process, defend the findings, and identify the next proof needed. A successful API call, a source-code branch and a client requirement are three different kinds of evidence.

### The position in one minute

We have real historical API posting evidence. The installed MIGO API explicitly maps outbound-delivery references. We have also identified customer-specific MIGO screens, persistence, validations and an outbound ILMS call. We have NOT yet certified a reduced request without supplied PO fields, complete custom-logic coverage, or duplicate protection in QS4.

The reviewed Postman pack removes the second verification GET, but retains the CSRF GET and PO fields. The client's stricter requirement is now one call per operation, including concern about the cost of token requests. That needs a security/call-count design decision, not just a collection cleanup.

### How to study this guide

- **10-minute meeting revision:** read sections 1, 2, 12, 13, 15 and 17.
- **Full understanding:** read sections 3-11 with the source extracts open.
- **Before any execution:** read sections 14 and 16. Historical examples are not permission to post.
- **Prove you own it:** answer section 18 without looking, then check section 19.

### Evidence labels

- **OBSERVED:** a screenshot or saved runtime result shows it, at that time.
- **SOURCE-CONFIRMED:** active code contains the branch; execution for our API is not implied.
- **OPEN:** not established by the evidence reviewed.
- **PROPOSED:** an implementation or test approach, not something already built.

Use source IDs such as [S3] throughout. Section 20 locates the sources. No live SAP state was refreshed to produce this guide.

<!-- PAGEBREAK -->

## 1. The mental model: what are we actually building?

### Business process versus technical interface

In the stock-transfer example we studied, the important business steps are delivery creation, dispatch and receipt. They are not interchangeable.

**CreateDI creates an outbound delivery. Goods issue records dispatch. SubmitMIGO records the receiving goods movement.** An outbound delivery is a dispatch document from the supplying side; it can be the reference used when the receiving side records its receipt.

Our DI and MIGO demonstrations used separate examples. A successful DI on one order and a successful MIGO on another delivery do not prove a connected end-to-end flow. The previously created delivery 9004953278 still had no goods issue at its last recorded check. [S9]

### Four layers you must keep separate

- **Postman:** the HTTP client used to send requests. It is not the SAP business engine.
- **OData service:** receives the request, validates/maps input, calls posting logic, and maps output/errors.
- **BAPI/posting engine:** performs goods-movement processing with the supplied and derived context.
- **Custom business logic:** customer screens, checks, tables, notifications and downstream dependencies, where applicable.

No frontend, application backend or CPI project has been built as part of our current implementation. Architecture options discussed later are proposals, not existing components.

### Three meanings of success

**HTTP success:** the request returned a success status.

**Persisted posting success:** the intended document exists in SAP with the expected keys and values.

**Business-process compliance:** the posting uses the correct reference, quantities, locations, custom data, controls and downstream behaviour, including safe retries.

The earlier evidence established persisted postings for particular payloads. It did not establish every business requirement.

> SAY IT: "The APIs have created real documents. I am separately verifying the delivery-based contract and the applicable business controls."

**Recall check:** Why does creating a delivery not prove that it is ready for goods receipt?

<!-- PAGEBREAK -->

## 2. Meeting requirements: what we must answer

This is a paraphrased requirements map, not a verbatim or speaker-attributed MOM. The transcripts contain technical recognition errors; Siddharth's explanations are not treated as client acceptance. [S1, S2]

### Reference and input requirements

**Outbound delivery, not a PO-based receipt disguised by extra fields.** On 31 August, the discussion around 14:40-15:07 selected goods receipt against outbound delivery. Around 20:05-20:25, the requested experiment was to remove PO number and PO item.

**Simplify what the caller must supply.** Around 22:53-26:21, delivery/item were emphasized as mandatory caller identifiers; material should not have to be reconstructed manually. Later, the BAPI walkthrough discussed material, plant, dates and quantity. The division between caller-supplied and internally determined values remains to be finalized.

**Return results, do not request them as inputs.** Material document/year belong in the response. A header delivery-note reference alone does not prove item-level delivery-referenced posting.

### Controls and workflow requirements

**Control receipt against the selected delivery.** Their quantity objection was substantive. Do not rely on a future UI to prevent an invalid request from reaching SAP. Their numerical PO-versus-delivery example expressed a risk; we did not reproduce that exact over-receipt behaviour in a test.

**No duplicate saved copy on repeat submission.** A second click, retry or overlapping request must not become another unintended posting. This is separate from the quantity ceiling.

**One call per operation, including the cost objection to CSRF GETs.** The latest clarification is stricter than merely removing a verification GET. Hidden requests do not meet a strict total-call limit. The charging boundary remains unverified.

**Preserve applicable custom behaviour.** Both reviews raised existing exits, custom fields and validations. The August 27 discussion also mentioned full dispatch reconciliation, vehicle/yard restrictions, shortage handling and a three-day pending alert. We have not traced all of those.

**Demonstrate failures and unit handling.** August 31, around 33:32-34:20, explicitly raised bags/tonnes and failure cases. Our historical TO-to-TO example does not test conversion.

**Finish a simplified SubmitMIGO demonstration first.** The review around 33:02 prioritized completing one operation properly before expanding the presentation.

<!-- PAGEBREAK -->

## 3. The investigation: why each step mattered

### Start: historical API and Postman proof

The earlier MIGO record shows material document 5007138597/2026, HTTP 201, and SAP readback. Its accepted payload was PO-referenced. CreateDI also had historical posting evidence, including delivery 9004953174. Neither is proof of the newly requested minimal delivery-referenced receipt. [S7, S12]

The live meeting screenshot showed the literal unresolved value `{{materialDocumentHeaderText}}` in a 400 error. That establishes a payload-variable problem in that attempt, not proof of an authentication failure or an unsupported business scenario.

### Follow the client's saved example

We opened the SE37 test directory and inspected `prashant_22_nov`. Then we opened the delivery, document flow and existing material document. This tested whether the saved input and the real receipt were actually equivalent. They were not proven equivalent.

### Follow a custom field to its implementation

F1 technical information on Token identified the Z-screen and custom table. A table where-used search then identified a relevant BAdI method. This replaced "there may be custom exits" with named objects and active code.

### Check the suggested existing-program route

We inspected the bulk MIGO program as a potential reusable reference. Its receipt branch supplied PO fields, and custom-field persistence was not established there. We ruled it out as a ready-made solution rather than copying it blindly.

### Return to the actual service

We traced the OData creation path, then the header/item preparation, delivery mapping and permitted-field check. This proved the standard API knows how to map outbound delivery references and identified the next exact unknown: the field rules for our posting combination.

### Stop at a consequential boundary

We did not post, reverse, activate code or change SAP during the manual source walkthrough. The earlier DS4 configuration work was a separate authorized task. The night's outcome was a defensible technical position and a bounded proof plan, not finished implementation. [S8]

> LESSON: Inspect the object that answers the meeting question. Do not count the number of tables or programs opened as progress.

<!-- PAGEBREAK -->

## 4. The saved example versus the actual receipt

**OBSERVED:** QS4/700, saved SE37 record 5, `prashant_22_nov`, for `BAPI_GOODSMVT_CREATE`. It was inspected, not executed. [S6]

| Detail | Saved input | Historical receipt |
|---|---|---|
| Delivery / item | 0082562455 / 000010 | Linked receipt in document flow |
| Material | 15000275 | 15000275 |
| Receiving plant | 1041 | 1041 |
| Storage location | RMYD | FBGU |
| Quantity | 0.000 | 33.600 TO |
| Batch | Blank | 2436000341 |
| Posting date | 22 Nov 2024 | 24 Nov 2024 |
| Bill of lading | 5263/SEN/18 | Blank |

The existing receipt is **5002024552/2024**. The flow also shows predecessor purchase order/STO **5600035281** and goods-issue document **4905394767**. Observing that predecessor does not settle the client's required posting interface or authorize a PO-based payload.

### What we learned

- A saved test record is stored input, not execution evidence.
- A document number displayed in MIGO is evidence of an existing document, not evidence that the saved test produced it.
- Zero quantity is not a verified instruction to receive the full outstanding balance.
- A receipt already in the document flow means this is historical learning material, not a fresh test case.
- The user's name in the MIGO title is not proof of who originally created the document.

### The LIPS inspection exposed another assumption

For this delivery item, LIPS showed plant **5263**, blank location and `LFIMG = 0.000`. The receipt showed plant **1041**, location **FBGU** and 33.600 TO; VL03N also showed 33.600 TO. The cause of the quantity discrepancy remains OPEN.

Therefore do not copy the outbound item plant/location into receiving fields, or use the observed zero as the remaining receivable quantity. Quantity determination and receiving-location determination need an established source and rule.

**Recall check:** Which two differences alone invalidate calling the saved record the exact proven posting payload?

<!-- PAGEBREAK -->

## 5. Field vocabulary: stop mixing different codes

| Field or concept | Meaning in our investigation |
|---|---|
| MIGO action A01 | Goods-receipt action selected in the GUI. |
| MIGO reference R05 | Outbound-delivery reference branch identified in the custom code and walkthrough. |
| GoodsMovementCode / GM_CODE | BAPI transaction category; the saved example uses 01. |
| GoodsMovementType / BWART | Movement type; the receipt example uses 101. |
| GoodsMovementRefDocType / MVT_IND | Movement indicator; the saved input uses B. It is not the delivery number. |
| Delivery + DeliveryItem | Identifies the delivery line being referenced. |
| MaterialDocument + year | Key of the created material document; output from posting. |
| InventoryTransactionType | Returned classification; WE was observed. Do not conflate it with 01, 101 or the material-document key. |

SAP documents GM_CODE 01 as goods receipt for purchase order and indicator B for that category. These standard labels must not be renamed "outbound delivery" to make the presentation sound simpler. The outbound-delivery item fields and the actual processing result must establish the intended reference. GM_CODE 02 is goods receipt for production order, not a generic "goods change." [W2]

### Other distinctions that matter

**Posting date versus document date:** the posting's accounting date and the source-document date are separate fields. Our reviewed collection currently uses one date variable for both; that is an implementation choice, not proof they must always be equal. [S10]

**Header reference versus item reference:** `REF_DOC_NO`/delivery-note text helps identify the source at header level. `DELIV_NUMB` and `DELIV_ITEM` are item-level posting reference fields. A matching header number alone is insufficient proof.

**Delivery quantity versus receipt quantity versus remaining quantity:** dispatched/document quantity, the quantity in this posting, and the quantity still eligible are different measures. Reversals, units, splits and existing history affect the calculation.

**Entry unit versus base unit:** values in different units cannot safely be added or compared without the appropriate conversion. No universal bags-to-tonnes factor was established for all materials.

**Token versus request ID:** the custom business Token, CSRF token and duplicate-handling request ID have unrelated roles. See section 12.

<!-- PAGEBREAK -->

## 6. The actual API path we traced

**SOURCE-CONFIRMED:** the local QS4 source captures and the methods pasted from SAP show this path. [S3, S5]

```text
CL_API_MATERIAL_DOCUME_DPC_EXT
  CREATE_DEEP_ENTITY -> CREATE_DOCUMENT
    CL_MDOC_API_FACTORY -> CL_MATERIAL_DOCUMENT_API
      CREATE_MATERIAL_DOCUMENT
        PREPARE_HEADER
        PREPARE_ITEMS
        PREPARE_SERIAL_NUMBERS
        CREATE_GOODS_MOVEMENT_BAPI (delegated call)
        map output header and messages
```

### What each stage does

The OData layer reads the deep request, maps allowed fields and performs forbidden-field checks. The material-document API prepares header, item, extension and serial-number data. It stops when preparation reports failure. After the delegated posting call, it maps the returned header and BAPI messages.

`PREPARE_ITEMS` explicitly rejects a missing movement type and checks that the type exists in T156. It then runs allowed-field, extension, batch and WBS processing before item mapping.

### The decisive delivery mapping

`MAP_ITEM_INPUT` asks whether the supplied delivery is inbound or outbound:

```abap
" Outbound branch
es_goodsmvt_item_input-deliv_numb = ir_item->delivery.
es_goodsmvt_item_input-deliv_item = ir_item->deliveryitem.
```

The inbound branch instead fills `DELIV_NUMB_TO_SEARCH` and `DELIV_ITEM_TO_SEARCH`. Prashant's saved record filled both pairs; the API chooses according to direction. Do not invent additional JSON properties by copying all BAPI field names.

PO fields are copied separately from input. Material, plant, location, quantity and unit are also copied here. This mapper does not visibly derive missing receiving data or require a PO. Later checks and derivations remain unverified.

### The BAPI-count answer

The inspected creation method contains one delegated goods-movement posting call. Preparation methods are not separate BAPIs. We have not inspected the delegated implementation enough to certify the complete nested BAPI/commit-call count. A raw BAPI test sequence and an OData-managed request are not the same transaction wrapper.

<!-- PAGEBREAK -->

## 7. Minimum input: what is proven and what is open?

**Proven:** a literal delivery-and-item-only request cannot pass the inspected `PREPARE_ITEMS` path because movement type is explicitly required. [S5]

**Open:** the complete required/permitted field list for the intended delivery-referenced receipt.

### How ITEM_CHECK_ALLOWED_FIELDS works

It calls `GET_RELEVANT_FIELDS` using movement type, special-stock type and movement reference document type. For each input component:

| Condition | Outcome in this check |
|---|---|
| Listed as mandatory and empty | Error 010: mandatory property missing |
| Not in the permitted list and populated | Error 011: property unsupported |
| Neither condition applies | Passes this particular check |

The code does not contain the returned rule list. We cannot infer PO optionality, material mandatory status or all receiving-data requirements from this method alone.

### Why this matters in practice

In the earlier PO-referenced test, the API rejected PO properties until `GoodsMovementRefDocType = B` was added. That is historical evidence that the posting combination changes field acceptance. It does not prove the new delivery-referenced payload is complete. [S7]

### Caller contract and internal inputs are different

The client may reasonably want to identify only a delivery/item while SAP resolves other values. That experience needs an implemented, correct source of defaults and derivations. It is not achieved by deleting fields and hoping the posting engine supplies them.

Material, destination, unit, quantity and custom requirements must be obtained or validated somewhere. We have not built a wrapper and have not demonstrated all necessary standard derivations. A wrapper is an option, not a proven necessity or a finished object.

### Exact next evidence

Inspect the relevant-field rules for the intended movement/reference combination. Record each permitted property, mandatory flag and its source. Then establish which required values can be derived without changing the requested posting reference. Do not add more unrelated report discovery before answering this.

> SAY IT: "The API contains the outbound reference mapping. I am verifying its required-field rules and the derivation gap before promising the reduced contract."

<!-- PAGEBREAK -->

## 8. Custom screen fields: from label to persistence

F1 technical information on the header Token field showed: [S6]

```text
Program:       ZMMR_MIGO_SCREEN_ADD
Screen:        0101
Table:         ZMMT_MIGO_HDR
Field:         TOKEN
Data element:  ZILMSTOKEN
Screen field:  GS_MIGO_HDR-TOKEN
Host program:  SAPLMIGO
```

This is the business/logistics Token, not an HTTP CSRF token.

### Screen-event logic we found

`ZMMR_MIGO_SCREEN_ADD` contains input/output modules, dynamic access to MIGO's GOHEAD/GOITEM structures, and logic triggered by screen commands. It defaults or restores values, normalizes transporter data, hides some fields and clears values in certain states. [S4a]

It reads `ZLETILMSDELIVERY`, `ZLETILMSTOKEN`, `ZLET_VEHICLE`, `ZMMT_RESERV_HDR`, LFA1 and existing receipt/custom records. The information includes token, transporter, vehicle/type, LR/challan dates and numbers, document date and gate-pass indicator. Several lookup branches use PO plus invoice/challan information.

For PO type ZP04, it reads project/WBS data and builds custom references/project text. Applicability to C&F is OPEN; do not transplant it into every receipt.

### Custom saving we actually traced

The table where-used list led to `ZCLMM_MB_MIGO_BADI`, method `IF_EX_MB_MIGO_BADI~POST_DOCUMENT`. Under its conditions, this method writes `ZMMT_MIGO_HDR`, using the material-document key and screen-supplied custom values. It also performs cancellation-related flag updates. [S4b]

It prepares `ZMMT_MIGOITEM`-typed item data and schedules `ZMMF_MIGO_UPDATE_DETAIL` in the update task. Fields include accepted/rejected quantities, audit data, remarks, warranty, reasons, reservation/vendor/purchasing references and old-rate information. The called function module's body was not reviewed.

### The integration gap

Some saving depends on `SY-UCOMM`, a dynamically assigned Z-screen global, MIGO action/reference state and internal screen tables. A standard API does not gain this context just because it eventually creates a material document. Runtime coverage remains OPEN.

Blank custom fields on one historical receipt do not prove that all these fields are optional, irrelevant, or absent from the custom database.

<!-- PAGEBREAK -->

## 9. The custom business validations we found

All findings below are source-confirmed in the inspected POST_DOCUMENT method. They are not a complete validation catalogue and are not certified as executing through the API. [S4b]

### Delivery quantity ceiling: ZMM 067

Under `GV_ACTION = A01` and `GV_REFDOC = R05`, the code aggregates current entry quantities and selected previous material-document quantities per delivery/item. It compares the total with `LIPS-LFIMG` and raises error 067 on excess.

This directly addresses the client's delivery-limit concern. However, the shown calculation combines current ERFMG, historical MENGE and delivery LFIMG without visible normalization in that block. That is a unit-consistency risk to verify, not a demonstrated failure for every case.

### Conditional full quantity: ZMM 070

The active logic includes a full-quantity comparison for shipping type `03` and delivery freight group `A0000001`, with delivery-item date selection from 23 July 2024 onward.

Therefore "post only one unit to preserve the example" is not universally safe. The business case may require full reconciliation.

### Conditional receiving locations: ZMM 075 and 074

- Error 075 checks RSD as the receiving location for the matching shipping-type/freight-group case.
- Error 074 checks a matching receiving location when the selected delivery location is GDRK.
- These branches also use date filtering and MIGO item context. They are not generic rules for all plants and materials.

### AFR and cancellation

For material type ZAFR and movements 101/103, custom company-related configuration in `ZGPT_MM_PARAM` affects whether AFR manifest number/date and waste category are required.

The cancellation branch checks `ZMMT_MIGO_SERV` and raises an error where a service entry sheet exists for the referenced original material document.

### Does our historical example exercise these?

Delivery 0082562455 showed `LIPS-MFRGR = A0000007` and blank delivery location. It does not exercise the particular A0000001 full-quantity/RSD predicates or GDRK predicate. Both observed units were TO, so it does not prove bag conversion either. General quantity checks and other controls remain separate questions.

**Recall check:** Why is passing one historical case not evidence that every custom validation is covered?

<!-- PAGEBREAK -->

## 10. The ILMS call and downstream consequences

### A real outbound integration exists in the custom method

The inspected BAdI contains code to POST JSON to ILMS, with token, DI number/quantity, truck, GRN number/date/time and receipt quantity. Cancellation handling can negate the transmitted quantity. [S4b]

Configuration and mappings come from `ZSGT_URL`, `ZLETILMSAPIFLDS` and an HTTP destination constant. Eligibility includes `MARC-MFRGR = A0000003` for material/plant, among other enclosing conditions.

**Do not use LIPS-MFRGR to declare this branch inactive.** The ILMS condition reads a different table/context from the delivery-level validation condition.

### Why we stopped short of posting

The HTTP send appears before some later quantity/location checks in the same method. An SAP transaction rollback does not by itself prove that an already-sent external HTTP operation has been undone. We did not observe a send in this walkthrough, but the potential side effect is enough to require a controlled test plan.

The shown code reads the response body but does not establish robust HTTP-status handling or recovery. Some exception handling is empty. This is an identified risk; the complete runtime outcome is not verified.

### Mapping to the meeting

The clients described downstream yard registration, full dispatch reconciliation, shortage treatment and pending alerts. We found relevant receipt checks and a notification path, but did not trace the whole yard/alert chain.

Do not say "yard integration is covered" merely because a quantity check or ILMS POST exists.

### Design implications, not approved changes

- Identify when and where this external notification runs for the proposed service path.
- Establish whether it is required for C&F and whether it crosses a billed API boundary.
- Verify behaviour on validation failure, timeout, retry and reversal.
- Assess a transaction-safe notification/recovery pattern if needed; no such redesign has been implemented.

> SAFETY: Do not use a real posting, reversal or assumed harmless TESTRUN to discover side effects. Establish the relevant execution path and test controls first.

<!-- PAGEBREAK -->

## 11. Enhancement inventory: what kind of object is each?

### Confirmed customer-specific mechanisms

**Custom dynpro/screen modules:** `ZMMR_MIGO_SCREEN_ADD`, with input/output event logic and MIGO global-state dependencies.

**Custom BAdI implementation:** `ZCLMM_MB_MIGO_BADI`, implementing the inspected POST_DOCUMENT method. A BAdI is a standard extension mechanism; this implementation contains customer behaviour.

**Z tables and structures:** custom header/item storage, configuration, mapping and logistics lookup tables. Table existence alone proves neither mandatory input nor correct API persistence.

**Custom update function module:** `ZMMF_MIGO_UPDATE_DETAIL`, scheduled in update task; its body remains unreviewed.

**Custom HTTP integration:** the conditional ILMS receipt/reversal notification discussed in section 10.

**Custom report and BDC automation:** `ZMM_MIGO_POSTING`, including distinct goods-movement branches and a screen-driven 311 EWM branch.

**CDS/report/print consumers:** the where-used list included multiple downstream readers. Fifty-four references do not mean fifty-four validations or BAPI calls.

### What the bulk report did and did not prove

The inspected receipt branch supplies PO/item and calls `BAPI_GOODSMVT_CREATE`, then commits or rolls back. Its delivery-number assignment was commented. Custom values in Excel/ALV structures did not establish their persistence through this branch. An extension table was passed, but its population was not established in the reviewed receipt code. [S4c-S4e]

The separate 311 EWM branch calls transaction MIGO through BDC and manipulates user defaults. That is not evidence that the 101 BAPI branch executes the same screen events. No branch was executed during this investigation.

### Standard mechanisms, not newly discovered Z enhancements

The API's preparation, delivery mapping, permitted-field rules, batch/WBS checks and active extensibility handler are standard-path mechanisms in the supplied source. The older commented extension-packing block does not negate the separate active handler.

SAP's repeat-request mechanism is also a standard framework, not a custom duplicate database we built.

### Explicitly unproven

We have not completed an inventory of classic customer exits, implicit/explicit enhancement implementations, standard-code modifications or all active BAdIs. Do not use "all exits checked" as a completion statement.

<!-- PAGEBREAK -->

## 12. GETs, security and the three different tokens

### The client's clarified constraint

They object to the cost of any extra API call, including the CSRF-token GET. Removing only the second verification GET addresses part of the concern, not the whole requirement.

### Three identifiers with different jobs

| Identifier | Purpose | Does not prove |
|---|---|---|
| CSRF token + matching cookies | Security validation of modifying HTTP requests | Authentication by itself, duplicate protection, business receipt identity |
| Submission RequestID | Correlates a submission for configured repeat handling | Correct quantity, correct delivery or indefinite retry safety |
| Custom MIGO Token | Logistics/business information in the Z implementation | HTTP security or request deduplication |

Authentication identifies the caller; authorization governs permitted actions. TLS protects transport. CSRF protection is separate. A certificate is not automatically a substitute for the Gateway CSRF check. [W1]

### Current standard-service behaviour

SAP documents obtaining a CSRF token via a non-modifying request and sending the token with modifying requests. The token and matching cookie context can be reused while valid; expiration or invalid context requires renewal. Do not assume one service's token is valid for another without verifying scope and cookies. [W1, W3]

For a fresh context, the existing protected API is not a zero-setup one-request flow. With valid context already available, a normal submission can be one POST. Renewals, failures and retries still exist.

### What does not remove a call

- Hiding GET inside a Postman pre-request script, SDK or middleware.
- Replacing GET with HEAD.
- Calling a token fetch "technical" rather than "business."
- Wrapping the operation in another ordinary protected OData service.

Batch is not a CSRF loophole: the outer POST still requires protection. [W4]

### What we know about charges

We have not verified their subscription, metering product or charged network boundary. One client-visible request may cause additional downstream requests, including ILMS. Do not claim one billable unit or a monetary saving without that information.

**Recall check:** Why is "the frontend only sees one call" insufficient when the concern is per-call charging?

<!-- PAGEBREAK -->

## 13. One-call designs: options, not promises

### Option A: retain standard OData and reuse security context

A caller retains a valid token and cookies, instead of fetching before every submission. An already-required compatible read may also fetch the token without introducing a separate request. This reduces redundant calls, but initialization and renewal remain. No reuse guarantee across users, clients or service scopes has been established here.

This fits "one normal business POST after setup," not "no other HTTP calls can ever occur."

### Option B: a server-side orchestrator

One incoming operation performs necessary internal steps and returns one result. If it calls protected OData behind the scenes, the token calls still exist. Whether they are billable depends on the routing and commercial boundary.

No such frontend/backend/CPI component currently exists in our implementation. Adding one requires a deliberate scope and ownership decision.

### Option C: a dedicated machine-to-machine SAP endpoint

PROPOSED: a security-approved non-browser interface could accept one incoming request, resolve delivery data, apply controls, call supported ABAP posting logic, persist required custom data and return the result. Local ABAP method calls and database reads need not become HTTP GETs.

This is new development. It must preserve authentication, authorization, secure transport, transaction handling and retry protection. It is not permission to disable CSRF on the existing services, and it is not automatically license-free. SAP's integration guidance distinguishes browser CSRF concerns from technical backend communication, but the selected interface must be evaluated on its own merits. [W5]

### The decision we should request

Agree what "one call" means: one incoming business request, one call through a specific billed gateway, or exactly one network request including all setup/retries. Then choose the smallest supported design that meets that definition and the delivery/custom-logic requirements.

### A hypothetical internal SubmitMIGO sequence

Resolve delivery/item -> validate input and eligibility -> apply retry/business controls -> post and persist in the correct transaction -> return document/year and correlation -> coordinate required external notification safely.

This describes responsibilities, not an approved algorithm. A new wrapper still needs proof of each step and cannot simply invoke the screen-dependent BAdI method without its expected context.

<!-- PAGEBREAK -->

## 14. Duplicate prevention: locking is not enough

### The requirement

The same intended submission must not create two saved copies because of a double click, retry or overlapping call. The user experience should not show a confusing second failure where the first posting actually succeeded.

### Four controls with different jobs

- **Button/dispatch guard:** reduces repeated actions in one client. We have no frontend project implementing a button lock.
- **Concurrency lock:** prevents conflicting work while a resource is in use. A lock alone does not remember a completed request after it is released.
- **Idempotency/replay record:** recognises a repeated operation and, where supported, returns the original outcome instead of posting again.
- **Business validation:** rejects invalid receipts such as excess quantity or an ineligible delivery. It does not necessarily identify duplicate intent.

Example: if 50 TO remain, two accidental 1 TO postings may both fit under a quantity ceiling. That is why an over-receipt check is not duplicate protection.

### Earlier implementation work

The installed Gateway repeat-request mechanism was inspected. Local Postman logic sends a stable RequestID and RepeatabilityCreation value, consumes confirmation before dispatch, preserves document results and supports a controlled QA replay. Ninety-seven offline tests were recorded; they are not live concurrency certification. [S8]

DS4/200 configuration and two standard housekeeping jobs were initialized and read back in the earlier authorized setup. QS4 was unchanged. Retention is finite, and lock contention may return an error needing caller handling. We have not demonstrated universal error-free overlap handling.

### Correct retry discipline

Keep the same operation identity, timestamp and payload for a permitted replay. Do not generate a new identity merely because the response was lost. Do not reuse one identity for a different operation. A retry after retention expiry is not automatically protected.

Different request IDs for the same delivery require a business policy too: a deliberate partial receipt and an accidental duplicate may otherwise look alike.

### Proof still needed

One successful posting, a sequential replay, overlapping requests, lost-response recovery and failed-validation retry behaviour must be tested with approved data and expected outcomes. Repeated HTTP requests may be unavoidable during recovery; repeated business documents must not be.

<!-- PAGEBREAK -->

## 15. Current artifacts and test-data status

This is the recorded state at the evidence cut-off, not a new live revalidation. [S8-S10]

### What is actually in the reviewed four-file pack

Each collection contains a CSRF GET and a business POST. The second MIGO verification GET is removed. The MIGO body still supplies PO/item, material, receiving plant/location, movement 101, reference indicator B, quantity/unit and delivery/item.

Therefore this pack is NOT yet the approved reduced delivery-only implementation. Re-importing a local file is required to update an older imported collection; file edits do not silently update Postman.

The POST response can provide material-document number/year. An earlier successful response had an empty nested item collection, despite persisted items. Do not infer posting failure from that alone or promise detailed returned item quantities without verification. [S7]

### Historical and candidate records

| Record | How to use the information |
|---|---|
| Delivery 0082562455; GR 5002024552/2024 | Historical learning case, already receipted. |
| Delivery 9004952821 | Earlier findings called it available; Siddharth subsequently confirmed it was used in the live meeting. Do not treat it as fresh. |
| Delivery 9004953161; GR 5007138638/2026 | Previously consumed, not a fresh candidate. |
| Delivery 9004952820 / 000010 | Candidate at earlier check, 45.560 TO; not currently reserved or cleared. |
| Delivery 9004952850 / 000010 | Candidate at earlier check, 46.340 TO; not currently reserved or cleared. |
| DI 9004953278 / 000010 | Own 1 TO example; no GI and blank source location at last check. Not receipt-ready. |

Do not copy receiving location RMYD across plants solely because it worked elsewhere. The replacement-data report contains old availability statements and a PO-based proposed flow; it is historical evidence, not today's approved contract.

### Scope boundary

The manual night established facts and risks. It did not transport a new service, change the client contract, certify custom-field persistence, create a frontend, or prove target-client idempotency. The earlier DS4 setup must not be described as QS4 setup.

<!-- PAGEBREAK -->

## 16. The bounded next-session plan

### First: finish the input/reference proof

Inspect the rule list returned by GET_RELEVANT_FIELDS for the intended combination. Establish required values and legitimate derivations. Verify the actual delivery/item mapping and downstream reference behaviour without assuming that blank PO fields alone settle it.

### Second: establish applicable custom coverage

For each relevant rule and custom value, identify its entry point, conditions, source of data, persistence and service-path coverage. Separate GUI-only dependencies from logic that is already usable by a non-GUI caller. Establish ILMS side-effect controls before any execution.

### Third: agree the call-count boundary

Confirm what is billed and whether token initialization/renewal is acceptable. Decide whether standard OData reuse is sufficient or whether a new interface is required. Do not promise one charged call from Postman appearance alone.

### Then: controlled tests, not an improvised live demo

| Test category | Required proof |
|---|---|
| Valid receipt without supplied PO fields | Correct reference and persisted delivery-linked result |
| Missing/unsupported fields | Expected validation, no unintended posting |
| Wrong delivery/item or mismatched values | Rejection or documented correct determination |
| Excess cumulative receipt | Delivery-specific control, including relevant history |
| Partial/full receipt | Correct rule for the selected business case |
| Units/batch/location | Appropriate scenario-specific validation and conversion |
| Custom data | Correct requiredness and persisted values |
| Replay/concurrency | Same intent does not create a second document |
| Timeout/failure/notification | No ambiguous duplicate or unmanaged external side effect |

These are planned tests, not authorization to execute them. Some need different datasets; one historical TO case cannot cover all rows. Revalidate availability, periods, destination, units and owners before a business posting.

### Definition of ready for presentation

One frozen collection/environment, a known payload, an approved current example, recorded successful response and SAP evidence, expected negative results, and an honest list of remaining limitations. Show the simplified operation first, then the evidence when challenged.

<!-- PAGEBREAK -->

## 17. Meeting answers you can defend

### Opening statement

"I traced the saved BAPI example, the historical delivery and receipt, the custom MIGO implementation and the actual OData mapping. The API explicitly maps outbound deliveries. The remaining proof is the minimum accepted request without supplied PO fields, applicable custom-control coverage, and target-client repeat handling. I have separated those from the earlier successful postings."

### "Why is PO still in your request?"

"The reviewed collection still contains the older payload. I am not presenting that as the final delivery-based contract. The mapping supports outbound delivery; the required-field and runtime proof must establish the revised request."

### "Why do we need any GET if each call costs money?"

"With a valid token context, a normal submission can be one POST. Fresh or expired contexts need security setup on the existing services. If even those calls are unacceptable, we need to agree a different approved interface and the actual billing boundary. Hiding GETs would not solve it."

### "Will all MIGO exits run?"

"I have not assumed that. I found screen-state dependencies in the custom implementation and specific quantity, location, AFR and persistence logic. I am mapping the applicable behaviour to the service path."

### "Can two clicks create two documents?"

"Preventing that is a separate acceptance test. Standard repeat handling and local guards have preparation in place, but we have not certified sequential and concurrent target-client posting behaviour."

### "How many BAPIs are called?"

"The inspected API method delegates posting once to a goods-movement wrapper. Preparation methods are not BAPIs. I have not yet certified the complete nested call and transaction-control count."

### "Can you demonstrate now?"

"I can show the existing evidence and the source findings. A new posting requires a freshly checked case and a controlled plan because the custom code includes a possible outbound notification."

### Phrases to retire

Avoid "standard SAP will handle everything," "all exits are covered," "only two fields definitely work," "we removed all GETs," and "duplicate protection is done." Replace each with the confirmed scope and the next proof.

<!-- PAGEBREAK -->

## 18. Self-test: answer before turning the page

Use this as an oral exercise. A good answer names the evidence, explains its significance and states its limit. You do not need to memorize every Z-table spelling; you do need to know where to find it.

1. What is the difference between CreateDI, goods issue and SubmitMIGO?
2. What did the earlier successful API calls prove, and what did they not prove?
3. Why is Prashant's saved test not an exact proven posting payload?
4. Why is LIPS-WERKS 5263 not automatically the receiving plant?
5. Which BAPI field pair does the actual API populate for an outbound delivery?
6. Why should you not copy both delivery field pairs from SE37 into JSON?
7. Which field is explicitly required before the remaining item checks?
8. Which three values select the allowed-field rules?
9. What is the difference between errors 010 and 011 in that check?
10. Why can an API have extension support and still fail to save these custom values?
11. What is the difference between CSRF Token, RequestID and the MIGO Token?
12. How can two duplicate 1 TO receipts both pass a 50 TO ceiling?
13. Why does a concurrency lock alone not solve a retry after completion?
14. What do ZMM 067, 070, 074 and 075 relate to?
15. Why does our historical example not exercise all those rules?
16. What makes a diagnostic posting or reversal potentially affect another system?
17. Why does the LIPS freight-group value not establish ILMS eligibility?
18. Why is a hidden token GET not a saving under a per-request charge model?
19. What remains in the reviewed collection, despite removal of the verification GET?
20. What exactly do we inspect next, and what is the stopping condition before a demo?

### Confidence check

Mark each answer as: can explain; can explain with source open; cannot explain yet. Revisit only the weak sections. The objective is accurate ownership, not memorized certainty.

### A useful rehearsal

Explain the entire task in two minutes without starting with a class name: business outcome, delivery reference, input derivation, controls, safe retries, response, then implementation evidence.

<!-- PAGEBREAK -->

## 19. Answer key and rapid revision

1. DI creates the delivery; GI records dispatch; MIGO records receipt. A created delivery is not automatically dispatched.
2. Particular payloads created persisted documents; they did not certify the new contract, all custom controls or retry safety.
3. The saved record was not executed in this walkthrough; quantity, date, location and batch differ from the historical receipt.
4. The actual receipt is at 1041/FBGU. Outbound item data cannot be blindly used as receiving data.
5. DELIV_NUMB and DELIV_ITEM.
6. The API selects the pair by direction; its JSON contract is not the raw BAPI structure.
7. GoodsMovementType; the shown preparation rejects it when initial.
8. Movement type, special-stock type and movement reference document type.
9. 010 means a mandatory listed field is empty; 011 means a populated field is not permitted by that list.
10. Standard extensions do not automatically supply GUI globals, custom tables or the BAdI's conditions.
11. CSRF is request security; RequestID is submission identity; the MIGO Token is business/logistics data.
12. Two units are still below the ceiling; the check does not recognize repeated intent.
13. Once released, a lock does not retain the previous result. Replay recognition requires durable, valid operation history or equivalent handling.
14. 067: excess receipt; 070: conditional full quantity; 074: GDRK location; 075: RSD location.
15. Different freight group, blank delivery location and equal TO units do not exercise the special branches/conversion.
16. The custom BAdI contains a conditional HTTP POST to ILMS, before some later checks.
17. ILMS uses MARC material/plant freight group, not the same LIPS field context.
18. The HTTP request still occurs. Visibility and billing are different.
19. CSRF GET, old PO fields and other technical inputs; no final delivery-only implementation is proven.
20. GET_RELEVANT_FIELDS for the intended combination; then applicable custom coverage, approved data and recorded controlled outcomes before a live demo.

> REMEMBER: The stronger stance is not "everything is done." It is "this is observed, this is source-confirmed, this remains open, and this is the exact proof required."

<!-- PAGEBREAK -->

## 20. Evidence register and reading boundaries

Sources are local project evidence and user-supplied SAP extracts, supplemented by SAP documentation. The source snippets are not independently certified transport versions. A screenshot or successful test proves its captured state, not the state of the shared system tomorrow.

### Meeting and runtime records

**S1 - 31 August meeting.** `sources/SRC-MTG-20260831-01_transcript.en.txt` and `.hi.txt`. Read together for technical recognition errors. Speaker/name attribution remains uncertain; do not promote Siddharth's explanation to client acceptance.

**S2 - 27 August meeting.** `sources/SRC-MTG-20260827-01_transcript.en.txt` and `.hi.txt`. Includes simplification, security questions, duplicate handling and downstream validation concerns.

**S3 - QS4 API entry path.** `sessions/2026-08-31-submit-guard/evidence/qs4_migo_create_deep_entity.txt`, `qs4_migo_create_document.txt`, `qs4_mdoc_factory.txt`.

**S7 - Earlier successful MIGO.** `evidence/qs4-migo-2026-08-25/QS4_SUBMIT_MIGO_SUCCESS.md`. Proves the recorded PO-based example; not the new delivery-based contract.

**S8 - Repeat-request work.** `sessions/2026-08-31-submit-guard/README.md` and `DS4_SETUP_COMPLETED.md`. Distinguish initial findings, subsequent DS4 setup, unchanged QS4 and offline tests.

**S9 - Replacement test data.** `sessions/2026-08-31-testdata-revalidation/FINDINGS_2026-08-31_DI_MIGO_TEST_DATA.md`. Some availability statements predate the live meeting. Candidate status requires fresh checks; old proposed PO-based payload guidance is not the new contract.

**S10 - Reviewed collections.** `deliverables/postman/Postman collection - SubmitMIGO CreateDI - Reviewed/`. Exactly four collection/environment JSON files at review. No credentials are reproduced in this guide.

**S12 - Earlier CreateDI evidence.** `deliverables/CREATE_DI_SD_CONSULTANT_HANDOFF.md` and `SAP_MANUAL_VERIFICATION_RUNBOOK.md`.

### Scope of conclusions

No direct SAP updates or new postings were performed to compile this study guide. The guide is not a complete enhancement audit, security approval, transport inventory or agreed commercial metering interpretation. Retain source evidence when changing the contract; do not overwrite historical proof to make it look like the latest design.

<!-- PAGEBREAK -->

## 20. Evidence register - source extracts and screenshots

### User-supplied ABAP extracts

All attachment directories below are under `C:/Users/sidmy/.codex/attachments/`; each contains `pasted-text.txt`.

**S4a - Custom screen program:** `4a7f6a15-aecf-4850-b115-264bbc1ea891`.

**S4b - MIGO BAdI POST_DOCUMENT:** `618f4aee-2864-47f9-856a-8255d4b2341e`.

**S4c - Bulk program main:** `42c9ab7b-1e92-436c-8f00-4d26efbdc0d4`.

**S4d - Bulk program FORMS:** `3cfdb371-e72e-43b2-bef9-c1d99235ac2f`. Relevant receipt logic and branch/call scans were reviewed; not every unrelated movement branch was fully audited.

**S4e - Bulk program declarations:** `86295ddf-aa92-48a1-8973-e936f708be84`.

**S5 - Standard API methods:** CREATE_MATERIAL_DOCUMENT, PREPARE_ITEMS and ITEM_CHECK_ALLOWED_FIELDS were pasted in the conversation. MAP_ITEM_INPUT is in attachment `4e6d4f66-2233-46cb-86ec-4e0d2c434fb5`. Do not confuse markdown damage in a pasted extract with a confirmed SAP syntax defect.

### Screenshot index: what to look for

**S6 - Screenshots supplied in the conversation.** The following files were in `C:/Users/sidmy/AppData/Local/Temp/` at authoring. Temporary paths are not a durable archive.

| Screenshot suffix | What it established |
|---|---|
| 2b0bfd26-030a-4114-8b56-179b7b3a09ff | Document flow: delivery and existing receipt |
| 7a67bbdc-5b77-4a68-b9b8-f15fc7446c8a | Receipt Where tab: plant 1041, FBGU, movement 101 |
| 1e2d5f90-faed-49e0-a4aa-fd605b14a05b | F1 technical information: custom screen/table/Token |
| a2616fea-a2ad-4fe6-ac0e-7fa45cd19487 | LIPS detail: plant 5263, blank location, LFIMG zero |
| 9c2d9f61-a80e-4481-bca7-f07525243051 | LIPS material freight group A0000007 |

Full screenshot filename pattern: `codex-clipboard-<suffix>.png`.

Other supplied images show the saved header/item input, both delivery field pairs, the additional fields and the table where-used results. Reading a screenshot means naming the field, value, system/client, document and limitation - not just pointing to a green status.

<!-- PAGEBREAK -->

## 20. SAP documentation and final study checklist

### External references

**W1 - SAP Gateway: Cross-Site Request Forgery Protection.** Non-modifying token retrieval, modifying-request validation and authentication prerequisite.

[SAP Gateway CSRF documentation](https://help.sap.com/docs/ABAP_PLATFORM_BW4HANA/68bf513362174d54b58cddec28794093/b35c22518bc72214e10000000a44176d.html)

**W2 - SAP: Goods Movements with BAPI.** Goods-movement code/indicator terminology and BAPI transaction-control responsibilities. Do not infer the exact OData wrapper implementation from generic BAPI documentation.

[Goods movements with BAPI](https://help.sap.com/docs/SUPPORT_CONTENT/erpscm/3362167803.html?locale=en-US)

**W3 - SAP-authored Gateway CSRF explanation.** Matching cookies, token reuse and renewal. The article was retrieved through search; direct opening was access-restricted during review.

[How CSRF tokens work in SAP Gateway](https://community.sap.com/t5/technology-blog-posts-by-sap/how-does-csrf-token-work-sap-gateway/ba-p/13520186)

**W4 - SAP Gateway: Handling Confidential Data in OData URLs.** Includes the requirement for CSRF protection on batch POSTs.

[Gateway batch and CSRF](https://help.sap.com/docs/ABAP_PLATFORM_NEW/68bf513362174d54b58cddec28794093/2582215150e92414e10000000a44176d.html)

**W5 - SAP Cloud Integration: Use CSRF Protection.** Distinguishes browser-facing and technical backend communication. This is design context, not authorization to disable protection in our SAP services.

[SAP integration security guidance](https://help.sap.com/docs/cloud-integration/sap-cloud-integration/use-csrf-protection?locale=enUS)

### Before closing the guide

- Can I distinguish client requirements from our assumptions and from observed SAP behaviour?
- Can I explain why standard outbound mapping is promising but not complete runtime proof?
- Can I name the custom controls and say which conditions we have and have not checked?
- Can I explain the one-call security/billing trade-off without hiding requests?
- Can I state exactly what remains before a new demo, without saying everything is finished?

**If yes, you have a defensible technical position. The next step is targeted proof, not more confident guessing.**
