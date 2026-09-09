*&---------------------------------------------------------------------*
*& Enhancement implementation : ZCNF_SUBMIT_MIGO_MAP2I
*& Spot                       : ES_SAPLMB_BUS2017
*& Enhancement point          : MAP2I_B2017_GM_ITEM_TO_IMSEG_1
*& Include                    : LMB_BUS2017U17  (line 1135, before ENDFORM)
*& Package                    : ZSCL
*&
*& PURPOSE
*&   Let a goods receipt be posted from Delivery + DeliveryItem + Plant with
*&   no purchase order in the payload.
*&
*&   API_MATERIAL_DOCUMENT_SRV maps an OUTBOUND delivery to DELIV_NUMB /
*&   DELIV_ITEM (CL_MATERIAL_DOCUMENT_API=>MAP_ITEM_INPUT, CM00V:34-48),
*&   which lands in IMSEG-VBELN / IMSEG-POSNR. Those fields are descriptive.
*&   The fields that make SAP resolve the purchase order are VLIEF_AVIS /
*&   VBELP_AVIS, and the service never populates them for outbound.
*&   Result: M7 030 "Purchase order does not exist".
*&
*&   This enhancement copies the delivery into the search fields so that
*&   ME_CONFIRMATION_SEARCH_GR resolves the PO, and defensively derives the
*&   item data the caller no longer sends.
*&
*& WHY HERE
*&   LMB_BUS2017U04:223  CALL FUNCTION 'MAP2I_B2017_GM_ITEM_TO_IMSEG'
*&   LMB_BUS2017U17:961    PERFORM map2i_b2017_gm_item_to_imseg  (unconditional)
*&   LMB_BUS2017U17:1135     >>> THIS ENHANCEMENT POINT <<<
*&   LMB_BUS2017U04:385  APPEND t_imseg
*&   LMB_BUS2017U04:632  PERFORM mb_create_goods_movement
*&
*&   Every standard move into the fields we touch happens earlier in the
*&   same include - VLIEF_AVIS:191, VBELP_AVIS:296, EBELN:338, KZBEW:545,
*&   VBELN:688, POSNR:691 - so nothing overwrites us afterwards.
*&
*& GATE CONDITIONS (LMBWLU14:1729)
*&   The PO search runs only when VLIEF_AVIS is filled AND KZBEW = 'B'
*&   AND EBELN IS INITIAL. Never set IMSEG-EBELN here - doing so disables
*&   the delivery resolution completely.
*&
*&   LMBWLU14:2057 reads LT_LIPS WITH KEY POSNR = IMSEG-VBELP_AVIS, so
*&   VBELP_AVIS must carry LIPS-POSNR. Never UECHA.
*&
*& SAFETY
*&   This form runs for EVERY goods movement item in the system. The guard
*&   short-circuits on cheap field comparisons before any database read, and
*&   the delivery range confines the spike to the 18 CNF candidates.
*&   No MESSAGE is raised: if anything is not as expected the routine leaves
*&   IMSEG untouched and lets standard SAP produce its own error.
*&
*&   >>> The delivery range below is a SPIKE GUARD. Outside that range this
*&   >>> code does nothing at all. Widen LC_CNF_DELIV_TO before testing with
*&   >>> any other delivery, or the test will silently do nothing.
*&---------------------------------------------------------------------*

  CONSTANTS:
    lc_cnf_bwart      TYPE bwart     VALUE '101',
    lc_cnf_kzbew      TYPE kzbew     VALUE 'B',
    lc_cnf_deliv_from TYPE vbeln_vl  VALUE '9004952595',
    lc_cnf_deliv_to   TYPE vbeln_vl  VALUE '9004952614',
    lc_cnf_lgort_dflt TYPE lgort_d   VALUE 'RMYD'.

* Cheap guard first - no database access unless every condition holds.
  IF imseg-bwart      = lc_cnf_bwart
 AND imseg-kzbew      = lc_cnf_kzbew
 AND imseg-vbeln     IS NOT INITIAL
 AND imseg-posnr     IS NOT INITIAL
 AND imseg-vlief_avis IS INITIAL
 AND imseg-ebeln     IS INITIAL
 AND imseg-vbeln     BETWEEN lc_cnf_deliv_from AND lc_cnf_deliv_to.

    SELECT SINGLE vbeln, posnr, matnr, charg,
                  lfimg, vrkme, lgmng, meins,
                  vgbel, vgpos
      FROM lips
      INTO @DATA(ls_cnf_lips)
      WHERE vbeln = @imseg-vbeln
        AND posnr = @imseg-posnr.

*   The delivery item must exist and must reference a source document.
*   If it does not, leave IMSEG alone - standard SAP will report it.
    IF sy-subrc = 0 AND ls_cnf_lips-vgbel IS NOT INITIAL.

*     ---------------------------------------------------------------
*     The fix. VLIEF_AVIS / VBELP_AVIS are what trigger the PO search.
*     IMSEG-VBELN / POSNR stay as the service set them; MIGO populates
*     both in the dialog case as well.
*     ---------------------------------------------------------------
      imseg-vlief_avis = ls_cnf_lips-vbeln.
      imseg-vbelp_avis = ls_cnf_lips-posnr.

*     ---------------------------------------------------------------
*     Derivation. Every field below is filled ONLY when the caller left
*     it empty, so an explicit value in the payload always wins.
*     ---------------------------------------------------------------
      IF imseg-matnr IS INITIAL.
        imseg-matnr = ls_cnf_lips-matnr.
      ENDIF.

*     Quantity and unit must come from the same basis - never mix
*     delivery quantity with base unit or vice versa.
      IF imseg-erfmg IS INITIAL.
        IF ls_cnf_lips-lgmng IS NOT INITIAL AND ls_cnf_lips-meins IS NOT INITIAL.
          imseg-erfmg = ls_cnf_lips-lgmng.
          imseg-erfme = ls_cnf_lips-meins.
        ELSE.
          imseg-erfmg = ls_cnf_lips-lfimg.
          imseg-erfme = ls_cnf_lips-vrkme.
        ENDIF.
      ENDIF.

      IF imseg-charg IS INITIAL AND ls_cnf_lips-charg IS NOT INITIAL.
        imseg-charg = ls_cnf_lips-charg.
      ENDIF.

*     Receiving storage location: take it from the STO item the delivery
*     references, and fall back to RMYD.
*     RMYD is not a guess - every 101 receipt posted against an outbound
*     delivery in QS4 uses it (40 of 40 sampled, STOs 5600083620 /
*     5600077216), and it matches the candidate register. EKPO-LGORT is
*     frequently blank on STO items, which is why the fallback exists.
*     NOTE: the client's own MIGO rules (ZMM 074 / ZMM 075) can require
*     RSD or GDRK, but only for rail deliveries (LIKP-VSART = '03').
*     The CNF candidates are VSART = '01', so those rules do not apply -
*     and they live in the MIGO dialog BAdI, which does not run on this
*     path anyway. See the disposition document, section 4.
      IF imseg-lgort IS INITIAL.
        SELECT SINGLE lgort
          FROM ekpo
          INTO @DATA(lv_cnf_lgort)
          WHERE ebeln = @ls_cnf_lips-vgbel
            AND ebelp = @ls_cnf_lips-vgpos
            AND loekz = @space.
        IF sy-subrc = 0 AND lv_cnf_lgort IS NOT INITIAL.
          imseg-lgort = lv_cnf_lgort.
        ELSE.
          imseg-lgort = lc_cnf_lgort_dflt.
        ENDIF.
      ENDIF.

*     IMSEG-WERKS is left exactly as supplied - it is the receiving plant
*     and comes from the caller. Never copy LIPS-WERKS: that is the
*     SUPPLYING plant and would post the receipt in the wrong place.
*
*     IMSEG-EBELN is deliberately never set. See LMBWLU14:1729.

    ENDIF.

  ENDIF.
