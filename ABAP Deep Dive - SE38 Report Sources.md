---
tags: [sap, abap, shree-cement, cnf, deep-dive, source-evidence]
source: SRC-CODE-20260804-01_SE38_report_sources.txt
evidence-tier: 1 (system observation / source)
extracted: 2026-08-04
system: QS4 client 700, S/4HANA 2022
status: living note
---

# ABAP Deep Dive — SE38 Report Sources

> [!abstract] What this note is
> A line-by-line reading of the three programs you pulled from SE38 on 4 Aug 2026. These are **the actual production programs behind the reports the C&F portal is meant to replace**.
>
> This is Tier-1 evidence — read from the system, not from a document, not from a meeting. Where this note and any deck, spec, or meeting disagree, **this note wins**.

> [!tip] How to use this
> Read §1 and §5 before every meeting. §5 is the part the functional consultants do not have — they know *what* the reports show; this tells you *how the data actually moves, what is computed versus stored, what runs in parallel, and what can take twenty minutes*.

---

## 1. The three programs at a glance

| # | Program | Type | What it really is | Your interface |
|---|---|---|---|---|
| 1 | `ZLE_MRN_PENDING_REPORT` | Custom (client) | In-transit reconciliation between despatch and goods receipt | **Pending MRN** — API-01 |
| 2 | `ZSD_PENDING_ORDER_REP_PP` | Custom (client) | Parallel-processed pending-order extract | **Pending Orders** — the portal's first screen |
| 3 | `EDOC_COCKPIT` | **SAP standard** | eDocument framework cockpit | Statutory e-Invoice / E-Way Bill |

Three facts to carry from this table alone:

1. Two of the three are **custom client code with years of defect history**. That history tells you the business rules that were learned the hard way.
2. One is **SAP standard, unmodified** — which is itself the finding (§4).
3. The two custom reports use **completely different architectural patterns**. One is a straightforward CDS read. The other is an asynchronous parallel-RFC engine. Nobody in the architecture meetings appears to know the second one exists.

---

## 2. `ZLE_MRN_PENDING_REPORT` — the in-transit reconciler

### 2.1 Significance

This is the source of **Pending MRN**, one of the eight report visibilities and a dashboard tile. It answers one question: *for every despatch that left a plant, how much has not yet been received at the depot?*

> [!important] The core semantic — write this on your hand
> **Pending MRN = quantity invoiced − quantity goods-received, per delivery document.**
>
> Not ordered. Not delivered. **Invoiced.** The despatched side is summed from invoice quantities (§2.4). If anyone says "pending MRN is dispatched minus received," ask them what *dispatched* means in the code. It means invoiced.

### 2.2 Naming inconsistency — spot it before it bites you

```abap
*& Report ZSD_MRN_PENDING_REPORT     " ← the header comment
REPORT zle_mrn_pending_report.        " ← the actual program name
```

The header says `ZSD_`, the program is `ZLE_`. The `TVARVC` variable it reads is named `ZLE526_EXCLUDE_DI`, implying transaction **`ZLE526`**. When you search for this object, search on `ZLE`, and expect the functional team to call it by the `ZSD` name or by the T-code.

`ZLE` = Logistics Execution. `ZSD` = Sales & Distribution. The prefix tells you which team originally owned it.

### 2.3 The type declaration is a gift — it maps every field to its home

Lines 12–42. This structure is effectively **the Pending MRN API response contract, already written**:

```abap
TYPES : BEGIN OF ty_list,
          supplyingplant      TYPE i_purchaseorderapi01-supplyingplant,
          material            TYPE i_purchaseorderitemapi01-material,
          productdescription  TYPE i_productdescription-productdescription,
          receivingplant      TYPE i_plant-plant,
          deliverydocument    TYPE matdoc-vbeln_im,
          billingdocument     TYPE i_billingdocument-billingdocument,
          tax_invoice_code    TYPE bkpf-xblnr,
          zzvehicle_no        TYPE vttk-zzvehicle_no,
          ewbnumber           TYPE /digigst/oward_h-ewbnumber,
          quantityinbaseunit    TYPE matdoc-menge,   " despatched (invoiced)
          recquantityinbaseunit TYPE matdoc-menge,   " received
          intransitqty          TYPE matdoc-menge,   " the answer
          lrnumber            TYPE vttk-zzlr_gr_no,
        END OF ty_list.
```

> [!success] Three things this proves
> **a) The client already builds custom code on released SAP CDS interface views.** `I_PurchaseOrderAPI01`, `I_Plant`, `I_ProductDescription`, `I_BillingDocument`, `I_Address_2`, `I_RegionText`. This is a *huge* signal for your own design — you are not introducing an unfamiliar pattern by using released CDS and released APIs. Their own developers already do. Use this when Q-046 (SEGW vs RAP) comes up.
>
> **b) `/DIGIGST/OWARD_H-EWBNUMBER`** — the E-Way Bill number lives in the DigiGST add-on, confirming **D-023**. The report reads it directly.
>
> **c) `VTTK-ZZVEHICLE_NO` and `VTTK-ZZLR_GR_NO`** — vehicle and LR/GR number are Z-fields on the **shipment header**, confirming **D-025**. They are not on the delivery. If the portal wants vehicle number, the shipment document must exist.

### 2.4 The data spine — three CDS views, not tables

Lines 140–176. This is the whole read:

```abap
SELECT FROM zsd_mrn_pending_cds_opt          " 1. the base population
  FIELDS *
  WHERE supplyingplant IN @s_werks AND receivingplant IN @r_werks
    AND deliverydocument IN @delivery AND spart IN @s_div
    AND zregion IN @s_zregio AND material IN @s_matnr
    AND vsart IN @s_shpmod AND materialfreightgroup IN @s_mfrgr
    AND postingdate IN @s_date AND statecode IN @statecod
  INTO CORRESPONDING FIELDS OF TABLE @it_data.

SELECT FROM zle_di_inv_details               " 2. the despatched side
  FIELDS vbeln, inv_doc_no, inv_qty
  FOR ALL ENTRIES IN @it_data
  WHERE vbeln = @it_data-deliverydocument ...

SELECT FROM zle_mrn_goods_reciet_cds         " 3. the received side
  FIELDS vbelnim, recmaterialdocument, recquantityinbaseunit
  FOR ALL ENTRIES IN @it_data
  WHERE vbelnim = @it_data-deliverydocument ...
```

Then the arithmetic (lines 199–204):

```abap
wa_data-quantityinbaseunit    = REDUCE #( ... FOR wa_inv IN it_inv_details
                                  WHERE ( vbeln = wa_data-deliverydocument )
                                  NEXT val = val + wa_inv-inv_qty ).
wa_data-recquantityinbaseunit = REDUCE #( ... FOR wa_mrn IN it_mrn
                                  WHERE ( vbelnim = wa_data-deliverydocument )
                                  NEXT val = val + wa_mrn-recquantityinbaseunit ).

wa_data-intransitqty = wa_data-quantityinbaseunit - wa_data-recquantityinbaseunit.
```

Then `DELETE it_data WHERE intransitqty IS INITIAL.` — zero in-transit means it is not pending, so it disappears.

> [!warning] The join key is the delivery document, everywhere
> `deliverydocument` = `MATDOC-VBELN_IM`. All three views join on it. This is the correlation key for the entire MRN flow. Remember it — §2.6 shows what happened when someone forgot.

**This directly confirms D-021 and answers Q-043:** a consumable CDS view already exists. You do not need to rebuild pending-MRN logic. You need to wrap `zsd_mrn_pending_cds_opt` and reproduce the three-step arithmetic — or better, get that arithmetic pushed into a CDS view so it is computed once.

### 2.5 The hardcoded scope — `INITIALIZATION`, lines 103–120

```abap
INITIALIZATION.
  MOVE : 'I' TO s_mfrgr-sign, 'EQ' TO s_mfrgr-option,
         'A0000001' TO s_mfrgr-low.  APPEND s_mfrgr.
  MOVE 'A0000002' TO s_mfrgr-low.    APPEND s_mfrgr.
  ...
  MOVE 'A0000022' TO s_mfrgr-low.    APPEND s_mfrgr.
```

Seven material freight groups are defaulted: `A0000001`–`A0000006` and `A0000022`. Cross-reference the **Material Freight Group (`TMFG`)** sheet in the KDS catalogue (`SRC-DOC-20260803-02`).

> [!question] Ask this
> The report *defaults* to seven freight groups but the user can change them. Should the API hardcode the same seven, expose them as a parameter, or return everything? Nobody has specified this. It silently defines what "cement" means in this report.

### 2.6 The defect archaeology — the most valuable 25 lines in the file

Lines 213–238. Read the comments as a timeline:

```abap
***********Added by IBMABAP25 on 27-01-2024*******************
LOOP AT it_data INTO DATA(is_data).
  DATA(lv_index) = sy-tabix.
  SELECT SINGLE ebeln, charg_sid FROM matdoc
    INTO ( @DATA(lv_ebeln), @DATA(charg_sid) )
    WHERE vbeln_im = @is_data-deliverydocument
      AND werks    = @is_data-supplyingplant.
  IF sy-subrc = 0.
*   SELECT SINGLE menge ... WHERE ebeln = @lv_ebeln AND charg_sid = @charg_sid
*                             AND bwart = '101'.
*                   "Commented by Satyam Agarwal for SR/ME/45764 on 24-SEP-2025
    SELECT SINGLE menge FROM matdoc INTO @DATA(lv_menge)
      WHERE ebeln = @lv_ebeln AND charg_sid = @charg_sid
        AND bwart = '101' AND vbeln_im = @is_data-deliverydocument.
*                   "Added by Satyam Agarwal for SR/ME/45764 on 24-SEP-2025
    IF sy-subrc = 0.
      IF lv_menge = is_data-intransitqty.
        DELETE it_data INDEX lv_index.
      ENDIF.
*   Begin of Change by Satyam Agarwal for SR/ME/44107 on 23-SEP-2025
    ELSE.
      SELECT SINGLE menge FROM matdoc INTO @lv_menge
        WHERE ebeln = @lv_ebeln AND xblnr = @is_data-deliverydocument
          AND bwart = '101'.
      ...
```

**The timeline, and what each fix teaches you:**

| Date | Ticket | Change | The lesson |
|---|---|---|---|
| 27-01-2024 | — (IBMABAP25) | Whole `matdoc` cross-check block added | The CDS arithmetic alone was producing false positives — rows showing as pending that were actually fully received |
| 23-09-2025 | `SR/ME/44107` | Added the `ELSE` fallback matching on `XBLNR` | Some goods receipts don't carry `VBELN_IM` — they reference the delivery in the **reference field** `XBLNR` instead |
| 24-09-2025 | `SR/ME/45764` | Added `AND vbeln_im = ...` to the primary select | **The original matched on PO + batch + movement 101 only, and picked up the wrong goods receipt** when one PO had several deliveries |

> [!danger] This is your Q-004 answer, learned expensively by someone else
> `Q-004` asks for "the exact reference used at MIGO entry." Here it is, with a ticket number: **the goods receipt must be matched on `VBELN_IM` (the delivery), not on `EBELN` (the PO) alone** — because one STO produces many deliveries and the PO is not unique per receipt. And there is a documented exception where the link lives in `XBLNR`.
>
> If you build the MRN API joining on PO alone, you will reproduce `SR/ME/45764` in a new system. Cite this ticket in the meeting; it ends the conversation.

> [!bug] Code-quality observation — flag, do not assume
> `DELETE it_data INDEX lv_index` executed **inside** `LOOP AT it_data` is the classic ABAP index-shift anti-pattern: after a delete, remaining rows move up while the loop cursor advances, so the next row is skipped. This *may* mean the report occasionally leaves a fully-received delivery on the pending list.
>
> **Unverified — I cannot run it.** Do not state it as fact. Worth a controlled test when you have access, and worth *not* copying into your API.

### 2.7 The `TVARVC` escape hatch — lines 179–197

```abap
SELECT low FROM tvarvc INTO TABLE @DATA(lt_tvarvc)
  WHERE name = 'ZLE526_EXCLUDE_DI'.
...
READ TABLE lt_tvarvc ... WITH KEY low = wa_data-deliverydocument BINARY SEARCH.
IF sy-subrc EQ 0.
  CLEAR wa_data-intransitqty.     " → then DELETE WHERE intransitqty IS INITIAL
```

Added 02-APR-2026 (`ME61644`) — four months ago, so it is live and current.

Specific delivery numbers are maintained in a `TVARVC` variable and **silently disappear from the pending list**. This is a manual override with no audit trail and no expiry.

> [!question] Q-047, and it matters more than it looks
> Why does this exist? Stuck deliveries? Cancelled despatches the system can't close? Data errors?
>
> **Whatever the answer, your API must decide whether to honour it.** If the portal shows pending MRN *without* the exclusion, CFAs will see deliveries the SAP report deliberately hides — and someone will chase a phantom. If it *does* honour it, you have imported an untracked manual override into a new system.

### 2.8 Authorization — `ZLE_PLNT`, lines 538–578

```abap
FORM authority_check .
  IF r_werks[] IS NOT INITIAL.
    SELECT FROM t001w FIELDS DISTINCT werks WHERE werks IN @r_werks
      INTO TABLE @DATA(it_plant).
    LOOP AT it_plant INTO DATA(wa).
      AUTHORITY-CHECK OBJECT 'ZLE_PLNT' ID 'WERKS' FIELD wa-werks.
      IF sy-subrc <> 0.
        ... MESSAGE 'You Are Not Authorised For Plant ...' TYPE 'E'.
```

Confirms **D-024**. Note three details:

- It checks the **receiving** plant (`r_werks`, the depot), not the supplying plant.
- It runs `AT SELECTION-SCREEN` — before data selection, so it is a **gate**, not a filter. Unauthorised → hard error, no results at all.
- The check only fires `IF r_werks[] IS NOT INITIAL` — and `r_werks` is `OBLIGATORY`, so it always fires here.

> [!important] For your API design
> A gate is the wrong pattern for a portal. A CFA authorised for 3 of 5 requested depots should get **3 depots of data**, not an error. Your API should use `ZLE_PLNT` as a **filter**: derive the authorised plant list, then restrict the selection. Same auth object, different behaviour — and that difference is a design decision you should record, not slip in.

---

## 3. `ZSD_PENDING_ORDER_REP_PP` — the parallel engine

> [!abstract] Why this program is your single strongest asset
> This is the source of **Pending Orders** — the portal's first screen, the tile the 4 August meeting spent forty minutes arguing about.
>
> It is **not** a simple read. It is an asynchronous parallel-RFC job that slices a date range into per-day tasks, dispatches them across a work-process group, and waits **up to twenty minutes** for them to come back.
>
> In the 4 August meeting, someone asserted *"all SAP transaction calls are synchronous"* (`@00:29:09`). This program is the counter-example, and it is the exact data they most want in real time.

### 3.1 The `_PP` suffix means Parallel Processing

The suffix is the tell. There is almost certainly a non-`_PP` predecessor (`ZSD_PENDING_ORDER_REP`) that ran serially and was too slow. **Someone already hit a performance wall on this exact dataset and re-engineered it.** Find the original when you have access; the comparison will tell you the volume that broke it.

### 3.2 The parallel infrastructure — lines 589, 656–685

```abap
CONSTANTS: gc_rfcgr TYPE rzllitab-classname VALUE 'parallel_generators'.

FORM f_init_server_group.
  CALL FUNCTION 'SPBT_INITIALIZE'
    EXPORTING group_name  = gc_rfcgr
    IMPORTING max_pbt_wps = gv_total
              free_pbt_wps = gv_available
    ...
  CASE sy-subrc.
    WHEN 0 OR 3.
      max_use = SWITCH #( sy-sysid WHEN 'DS4' THEN 6
                                   WHEN 'QS4' THEN 15
                                   WHEN 'PS4' THEN 15 ).
      gv_available = COND #( WHEN gv_available GE max_use THEN max_use
                             ELSE gv_available ).
```

> [!success] Four findings in nine lines
> **a) An RFC server group named `parallel_generators` exists and is configured.** That is Basis infrastructure. It exists in DS4, QS4 and PS4.
>
> **b) The landscape is `DS4` / `QS4` / `PS4`** — this `SWITCH` is the evidence behind **D-018**, and it kills the vendor spec's "two-system DEV→PRD" claim stone dead. The code itself knows there are three systems.
>
> **c) DEV is deliberately throttled** — 6 work processes vs 15 in QAS and PRD. **Any performance measurement you take in DS4 is roughly 2.5× pessimistic.** Say this out loud before anyone quotes a DEV timing as a real number.
>
> **d) Concurrency is capped in code, not just by the group.** `gv_available` is clamped to `max_use`, and separately `lv_wproc = 10` caps in-flight tasks.

### 3.3 The dispatch loop — lines 686–775

The mechanism, in order:

```abap
DO.
  CALL FUNCTION 'SPBT_GET_CURR_RESOURCE_INFO'          " 1. how many WPs free?
    IMPORTING max_pbt_wps = lv_max_wps free_pbt_wps = lv_free_wps ...
  IF lv_free_wps GT 2 AND gv_pp_running LT lv_wproc.   " 2. throttle: >2 free, <10 running
  ELSE.
    WAIT UP TO 1 SECONDS.  CONTINUE.                   "    else back off and retry
  ENDIF.

  CALL FUNCTION 'FIAPPL_ADD_DAYS_TO_DATE'              " 3. advance ONE DAY
    EXPORTING i_date = r_erdat-low i_days = 1
    IMPORTING e_calc_date = r_erdat-low.

  CALL FUNCTION 'ZSD_PENDING_ORDER_FM'                 " 4. fire async task
    STARTING NEW TASK gv_taskname
    DESTINATION IN GROUP gc_rfcgr
    PERFORMING f_call_back_mif_in ON END OF TASK
    EXPORTING vbeln = vbeln[] auart = auart[] erdat = r_erdat[] ...
ENDDO.

WAIT UNTIL gv_receive_jobs >= gv_send_jobs UP TO 1200 SECONDS.   " 5. THE CEILING
```

And the collector:

```abap
FORM f_call_back_mif_in USING gv_taskname.
  gv_receive_jobs += 1.
  RECEIVE RESULTS FROM FUNCTION 'ZSD_PENDING_ORDER_FM'
    TABLES lt_final = it_table.
  APPEND LINES OF it_table TO lt_final.
  gv_pp_running -= 1.
ENDFORM.
```

> [!important] The four facts that make you the most informed person in the room
> **1. The date range is sliced one day per task.** A 30-day query fires 30 parallel RFC calls. Query cost scales with the *date range*, not with result size. **A one-day query is one task and will be fast.**
>
> **2. `WAIT UNTIL ... UP TO 1200 SECONDS` — a twenty-minute ceiling.** Someone chose that number because real runs approach it. This is a batch report, not an online query.
>
> **3. It self-throttles on available work processes.** Under load it *waits*. Response time is not just data volume — it is a function of what else the system is doing. A portal calling this at 10am when finance is running month-end will behave differently than at 3pm.
>
> **4. `ZSD_PENDING_ORDER_FM` is RFC-enabled** (**D-022**) — so it is directly callable. But it was designed as a *worker for one day-slice*, not as a portal API.

> [!question] The design question that is genuinely yours
> If the portal asks for pending orders for **one depot, today**, that is one slice — probably sub-second, and the parallel wrapper is dead weight.
>
> If it asks for **30 days across 3 depots**, you are looking at the batch engine, and a synchronous HTTP call will time out long before 1200 seconds.
>
> So: **call the FM directly for narrow queries, or reimplement the orchestration for wide ones?** Nobody has asked this. It is the single most important open question about the portal's first screen, and you are the only person positioned to raise it. Measure the single-slice call the moment you have access.

### 3.4 The empty authorization check — lines 645, 817–819

```abap
START-OF-SELECTION.
  ...
  PERFORM auth_check.        " ← line 645, it is called
  ...

FORM auth_check.             " ← line 817
                             " ← line 818: nothing
ENDFORM.                     " ← line 819
```

> [!danger] Read this twice
> **The pending-order report performs no authorization check whatsoever.** The FORM exists, is called, and is empty. Any user who can run transaction `ZSDR512` sees every order for the sales org and division they enter — across all depots.
>
> Contrast with the MRN report, which properly checks `ZLE_PLNT` (§2.8). **Two reports, two authorization models, one of them absent.**

Why this matters enormously right now: the 4 August meeting spent real time on exactly this — *"if the user sees their specific… depots… that authorization"* (`@00:14:34`), and the whole system-user bulk-fetch design (`@00:45:04`) assumes SAP hands over everything and **T2 filters by authorization afterwards**.

That design works *because* the SAP side has no filter. But it means:

- The authorization boundary moves from SAP to Commerce.
- A bulk fetch by a system user pulls **all** depots' orders into T2.
- Whether a CFA sees only their depots becomes a **Commerce-side correctness property**, not a SAP-enforced one.

> [!important] What to say, carefully
> This is a real finding and it is security-adjacent, so state it factually and without drama: *"The pending-order report has no authorization check in SAP today. If T2 fetches in bulk with a system user, depot-level authorization is enforced entirely in Commerce. Is that the intended design, and who signs off on it?"*
>
> That is a question three teams have to answer, and none of them currently know the premise is true. Cross-reference `NFR-05` and `D-024`.

### 3.5 The field catalogue IS the API contract — lines 836–900

**65 fields.** You do not need to design the pending-order response — the client already specified it. Grouped by meaning:

**The quantity chain — confirms D-026 exactly**

| Field | Label | Note |
|---|---|---|
| `ZMENG` | Contract Qty | Contract, not order |
| `ORDER_QTY` | Order Qty | |
| `SCHEDULE_QTY` | Schedule Qty | Schedule line level |
| `DEL_QTY` | Delivery Qty | |
| `INV_QTY` | Invoice Qty | |
| `REJ_QTY` | Rejected Qty | |
| **`BAL_QTY`** | **Balance Qty** | **This is "pending"** |
| `DELE_QTY` | Delivery Qty With Token | token concept — see below |
| `QTY_TOKEN` | Pending for Execution | |

> [!warning] `D-001` is a simplification and now you can prove it
> D-001 records `Order = DI + Pending`. The actual chain is **seven steps**, plus two token quantities. When the portal shows "Order Qty" and "Pending Qty," which of these nine is it showing?
>
> That is **Q-048**, and this field list is the evidence for it. Also note `DELE_QTY` / `QTY_TOKEN` introduce a **token** concept that appears nowhere in the portal design — worth asking about.

**The CRM / T1 linkage — the field that solves a live architecture argument**

| Field | Label |
|---|---|
| `CUSTOMER_REF` | **CRM Order No.** |
| `LONGTEXT` | CRM Remarks |

> [!success] Bring this to the next architecture meeting
> **The SAP sales order already carries the CRM order number.** The 4 August meeting went in circles on how T1 and S/4 documents correlate (`@00:56:28` onward, the whole "T1 → S4 → T1 → T2" loop).
>
> The correlation key exists, in the order, today. You found it in the field catalogue of their own report. This is the kind of contribution that costs you fifteen seconds and changes how the room sees you.

**Fields that map to your open questions**

| Field | Label | Register link |
|---|---|---|
| `SPECPROCID` | Spec.Proc.ID | **SPI** — D-020, Q-044. It surfaces at *order* level here |
| `INCO_TERM` | Inco Terms | Q-022, Q-033, Q-034 (FTP / FTB / EX) |
| `MFRGR_I` / `BEZEI` | Packing / Packing Description | Material freight group is presented as **"Packing"** to the business — glossary item |
| `CMGST` / `DDTEXT` | Credit Status / Description | D-026. Multi-valued; the portal shows two states |
| `STATUS1`, `BLOCK_REASON_TXT`, `SALEBLOCK` | Status (Block), Reason of Block, Blocked in BP | **Three separate block concepts.** Not in any portal design so far |
| `MVGR3` / `MVGR3_DES` | Brand / Brand Description | D-016 — brand is `MVGR3`, a plain material group |
| `UDATE` / `UTIME` | Order Release Date / Time | Orders have a release step |
| `STATUS` | "Reason Of Rejecetion" *(sic)* | Typo is in the source. Field name says status, label says rejection reason |

### 3.6 Mandatory selection fields = mandatory API parameters

Lines 618–633:

```abap
SELECT-OPTIONS: vbeln FOR vbak-vbeln,
                auart FOR vbak-auart,
                erdat FOR vbak-audat OBLIGATORY NO-EXTENSION,   " ← mandatory
                kunnr FOR vbak-kunnr,
                vkorg FOR vbak-vkorg OBLIGATORY,                " ← mandatory
                vtweg FOR vbrk-vtweg,
                spart FOR vbak-spart NO-EXTENSION NO INTERVALS OBLIGATORY,  " ← mandatory, single
                vkbur FOR vbak-vkbur,
                werks FOR vbap-werks,
                matnr FOR vbap-matnr,
                land1 FOR kna1-land1 DEFAULT 'IN' NO-DISPLAY,
                regio FOR kna1-regio,
                city2 FOR zsdtprice-zdist_ext.
PARAMETERS : chk AS CHECKBOX, chk1 AS CHECKBOX, chk2 AS CHECKBOX.
```

**Every API call must carry:** a date range (`ERDAT`), a sales organisation (`VKORG`), and exactly one division (`SPART` — `NO INTERVALS` means single value, not a range).

Note also: **`WERKS` (plant/depot) is optional.** The report does not require a depot. That is precisely why the bulk-fetch design in §3.4 is possible.

> [!question] Three unexplained checkboxes
> `chk`, `chk1`, `chk2` are passed straight through to the FM (lines 752–754) and their text elements are not in this extract. **They are behaviour switches on the pending-order logic and nobody knows what they do.** Get the text elements — this is a 30-second lookup that could change the contract.

### 3.7 The scheduled-email mechanism — lines 913–933

```abap
IF sy-batch = abap_true.
  SELECT FROM zautomail_id FIELDS * WHERE module1 = 'SD' AND tcode = 'ZSDR512'
                                      AND user_id = @sy-uname AND status = 'X' ...
  DATA(lo_obj) = NEW zcl_auto_mail( ).
  CALL METHOD lo_obj->send_mail EXPORTING lv_report_name = 'Pending Order Report' ...
```

Two things fall out:

1. **The transaction code is `ZSDR512`.** Useful for finding it, and for asking who has it.
2. **There is an existing scheduled-email framework** (`ZAUTOMAIL_ID` + `ZCL_AUTO_MAIL`) delivering this report to users on a batch schedule, as XLS or TXT.

> [!question] Who is receiving this today?
> If CFAs currently get pending orders as a scheduled email, the portal is replacing an **email habit**, not a transaction. That changes adoption, change management, and the "auto-refresh" argument from 4 August (`@00:08:13`) entirely — the current baseline may be *once a day by mail*, in which case a 15-minute refresh is already a massive improvement and the real-time argument is over.
>
> Query `ZAUTOMAIL_ID` for `tcode = 'ZSDR512'` when you have access. It is a one-line select that could settle a forty-minute argument.

---

## 4. `EDOC_COCKPIT` — the one that is standard

Lines 959–999. Short, and the significance is in what it *isn't*.

```abap
REPORT edoc_cockpit.
DATA: gs_edocument TYPE edocument.                    "2853195
SELECT-OPTIONS: so_guid FOR gs_edocument-edoc_guid NO-DISPLAY.
INCLUDE edoc_cockpit_class.
INCLUDE edoc_cockpit_pai.
INCLUDE edoc_cockpit_pbo.
START-OF-SELECTION.
  CREATE OBJECT go_report.
  go_report->get_criteria( IMPORTING et_range = gt_range ).
  go_report->display_main_screen( EXPORTING it_range = gt_range ).
```

Those trailing numbers — `2853195`, `2765690`, `2927542`, `3005076` — are **SAP Note numbers**, the standard way SAP annotates note-delivered code changes. Combined with the `Z`-free naming and the `CL_EDOC_COCKPIT_UI` reference, this is **unmodified SAP standard**.

> [!success] What this proves — confirms D-023
> **SAP's eDocument framework is installed and current** (patched to recent notes), alongside DigiGST.
>
> The split is: **SAP owns the eDocument lifecycle** (`EDOCUMENT` table, GUIDs, status); **DigiGST owns the statutory/GSP layer** (`/DIGIGST/OWARD_H`, which is where §2.3 reads the E-Way Bill number from).
>
> This refines **D-017** — it is not either/or. Both frameworks are live, with a clean division. For API-08/API-09 that means there are **two** possible integration points, and Q-042 (what is the ABAP integration surface for DigiGST) is the one to settle.

---

## 5. Cross-cutting — what you know that they don't

> [!abstract] This section is the point of the note
> Functional consultants know what the reports *show*. This is how the data actually *moves*. Read it before every meeting.

### 5.1 "Pending" is computed, never stored — in both reports

| | Pending MRN | Pending Orders |
|---|---|---|
| Where computed | ABAP, after 3 CDS reads | Inside `ZSD_PENDING_ORDER_FM` |
| Formula | invoiced − goods-received, per delivery | `BAL_QTY` from a 7-step chain |
| Stored anywhere? | **No** | **No** |
| Post-processing | `TVARVC` exclusion + `matdoc` 101 cross-check | unknown (inside the FM) |

> [!danger] The Datasphere consequence — this is Q-039 and it is serious
> **If DSP replicates raw tables, it will not have "pending."** Neither figure exists as a field anywhere in SAP. Both are derived, and the MRN one has three layers of correction on top (`SR/ME/44107`, `SR/ME/45764`, `ME61644`) that took two years to get right.
>
> Any independent reimplementation in Datasphere **will drift from SAP's definition**, and the drift will show up as CFAs seeing different numbers in two places. The correction history in §2.6 is the proof of how hard this logic was to get right.
>
> The safe pattern is to expose the existing CDS view, not to rebuild the logic in DSP. Say exactly that when the DSP-vs-S4 source question comes up (it did on 4 Aug at `@01:15:21` and `@01:15:35`, unresolved).

### 5.2 Synchronous, asynchronous, parallel — the honest picture

| Operation | Reality | Evidence |
|---|---|---|
| Create delivery / MIGO / invoice | Synchronous transactional call, returns document number | Meeting `@00:30:18` — **asserted, unverified** |
| Invoice chain end-to-end | **Never measured by anyone** | Q-032, open since 3 Aug |
| Pending MRN read | Synchronous CDS read + ABAP post-processing | §2.4 — **source-verified** |
| Pending Orders read | **Asynchronous parallel RFC, up to 1200 s** | §3.3 — **source-verified** |

> [!important] The single most valuable sentence you own right now
> *"The pending-order report is a parallel-processing job with a twenty-minute wait ceiling. Whether it can serve a synchronous portal call depends entirely on how narrow the query is — and nobody has measured it."*
>
> This is source-verified, it directly contradicts a confident claim made in the last meeting, and no functional consultant in that room has read this program.

### 5.3 Two authorization models, and the gap between them

| | Pending MRN | Pending Orders |
|---|---|---|
| Object | `ZLE_PLNT`, field `WERKS` | **none** |
| Style | Gate — hard error before selection | — |
| Scope | Receiving plant (depot) | — |
| Plant mandatory? | Yes (`r_werks OBLIGATORY`) | **No** |

Design implication: **your APIs need one consistent model.** `ZLE_PLNT` exists and should be reused (D-024) — but as a *filter*, not a gate (§2.8). And the pending-order path needs an authorization design that does not exist today, which is a genuinely new decision rather than a port.

### 5.4 Naming and ownership tells

- `ZLE_*` → Logistics Execution team. `ZSD_*` → Sales & Distribution team. Different owners, different conventions, different quality bars.
- Header comments do not always match program names (§2.2). Trust the `REPORT` statement.
- Developer names in comments — Satyam Agarwal, Ashutosh Prakash, `IBMABAP25` — indicate an **IBM-supported ABAP team** maintaining this code. Those are the people who actually know it. `IBMABAP25` suggests a numbered contractor pool.
- Ticket prefixes `SR/ME/*` and `ME*` are the client's change-request system. **Every one of those is a documented business rule you can ask for.**

### 5.5 What the client's own code says about your design choices

- They already build on **released SAP CDS interface views** (`I_*`) — §2.3. Using released APIs and CDS is *their* existing pattern, not a new imposition. Useful for **Q-046**.
- They already use **`CL_SALV_TABLE`**, modern ABAP syntax, inline declarations, `REDUCE`, `SWITCH`, `COND`. This is a reasonably current ABAP shop, not a 4.6C shop.
- They already run **parallel RFC** infrastructure with a configured server group.
- Their MRN logic already sits in **reusable CDS views** — which means your API can consume it rather than rebuild it (**Q-043**).

---

## 6. Meeting ammunition

Short, source-backed lines. Each one is defensible from this file.

> **On real-time:** "The pending-order report runs as a parallel RFC job with a twenty-minute wait ceiling and slices the date range one day per task. Whether it can serve a synchronous call depends on the query width. Has anyone measured a single-day, single-depot slice?"

> **On Datasphere as a source:** "Pending is not a stored field in SAP — both pending figures are computed, and the MRN one has three separate production corrections layered on it. If DSP recomputes it independently, it will drift."

> **On T1 ↔ S/4 correlation:** "The SAP sales order already carries the CRM order number in `CUSTOMER_REF`. The correlation key exists today."

> **On MIGO matching:** "Goods receipts must be matched on the delivery, `VBELN_IM`, not the PO. There's a production defect from September 2025 — `SR/ME/45764` — where PO-level matching picked up the wrong receipt."

> **On authorization:** "The pending-order report has no authorization check in SAP today. If T2 bulk-fetches with a system user, depot-level authorization is enforced entirely in Commerce. Is that intended?"

> **On the DEV landscape:** "The report throttles to 6 work processes in DS4 and 15 in QS4 and PS4. Any performance number measured in DEV is roughly 2.5× pessimistic."

> **On scope:** "The MRN report defaults to seven specific material freight groups. Should the API hardcode those, expose them, or return everything?"

---

## 7. Questions this file raises

New or sharpened, for the registers:

| # | Question | Owner | Links |
|---|---|---|---|
| a | Can `ZSD_PENDING_ORDER_FM` serve a synchronous portal call for a narrow query, or is the parallel wrapper load-bearing? **Measure it.** | ABAP (you) | Q-008, Q-032 |
| b | The pending-order report has **no** authorization check. Where is depot-level authorization enforced under the T2 design, and who signs off? | Architect / Basis / Security | D-024, NFR-05 |
| c | What are `chk`, `chk1`, `chk2`? They are behaviour switches passed into the FM. | ABAP lead / SD | contract shape |
| d | Should the MRN API honour `ZLE526_EXCLUDE_DI`? | MM / SD | **Q-047** |
| e | Which of the nine quantity fields does the portal's "Order Qty" and "Pending Qty" mean? What are `DELE_QTY` / `QTY_TOKEN`? | SD | **Q-048**, D-001 |
| f | Should the seven defaulted material freight groups be fixed, parameterised, or dropped? | SD / business | scope |
| g | Who currently receives `ZSDR512` by scheduled email, and how often? | SD / business | change management; the auto-refresh argument |
| h | Does `DELETE ... INDEX` inside `LOOP AT` cause skipped rows in the MRN report? **Unverified.** | ABAP (you) | data quality |
| i | Is there a non-`_PP` predecessor, and what volume made it necessary? | ABAP lead | sizing |

---

## 8. What to do next with this

1. **When SAP access returns:** measure a single-day, single-depot call to `ZSD_PENDING_ORDER_FM`. That one number settles question (a) and reshapes the whole pending-orders design.
2. **Get the text elements** for `chk`/`chk1`/`chk2` — 30 seconds in SE38.
3. **Query `ZAUTOMAIL_ID`** for `ZSDR512` — one select, settles question (g).
4. **Pull `ZSD_PENDING_ORDER_FM` source.** It is the actual pending-order logic and you have only seen its caller. That is the biggest remaining gap in this note.
5. **Ask for the `SR/ME/*` tickets** in §2.6. Each one is a documented business rule.

---

## Related

- `DECISION_LOG.md` — **D-018**, **D-020**, **D-021**, **D-022**, **D-023**, **D-024**, **D-025**, **D-026** all trace to this file
- `OPEN_QUESTIONS.md` — Q-004, Q-039, Q-042, Q-043, Q-044, Q-046, Q-047, Q-048
- `MEETING_CARD.md` — the questions to walk in with
- `sources/SRC-MTG-20260804-01_transcript.en.txt` — the architecture meeting this note arms you for
- `sources/SRC-DOC-20260803-02_CNF_KDS_Catalogue.xlsx` — material freight groups, customer groups, SPI mappings

> [!note] Evidence status
> Everything in §2–§4 is read directly from source and is **Tier 1**. Items explicitly marked *unverified* (§2.6 loop-delete, §3.1 predecessor program) are **inference** — do not promote them to fact without testing. Meeting timestamps cite `SRC-MTG-20260804-01`, which is **Tier 4** (secondhand transcript) and carries ASR noise; check `sources/README.md` before quoting it.
