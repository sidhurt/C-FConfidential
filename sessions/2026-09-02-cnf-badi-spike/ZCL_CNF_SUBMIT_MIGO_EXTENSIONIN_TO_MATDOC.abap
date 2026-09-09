*&---------------------------------------------------------------------*
*& ZCL_CNF_SUBMIT_MIGO
*& Method: IF_EX_MB_BAPI_GOODSMVT_CREATE~EXTENSIONIN_TO_MATDOC
*& BAdI:   MB_BAPI_GOODSMVT_CREATE  (spot MB_GOODSMOVEMENT, multiple-use)
*& Package: ZSCL
*&
*& v2 - 2026-09-02. Fixes the defect that made v1 inert.
*&   lc_item_spike was TYPE ebelp (5 chars, '00010') but LIPS-VGPOS is
*&   TYPE vgpos (6 chars, '000010'). The comparison never matched, so every
*&   item hit CONTINUE before any derivation or error path ran. The STO/item
*&   restriction is removed entirely - the delivery range already scopes the
*&   spike to the 18 candidates, which are all on STO 5600074803.
*&
*& Runtime position: BAPI_GOODSMVT_CREATE (LMB_BUS2017U04)
*&   223  MAP2I_B2017_GM_ITEM_TO_IMSEG   BAPI item -> IMSEG
*&   385  APPEND t_imseg
*&   546  THIS BADI  (ct_imseg = t_imseg[])
*&   632  PERFORM mb_create_goods_movement -> MB_CREATE_GOODS_MOVEMENT
*&
*& Verified mechanics (LMBWLU14):
*&   1729  PO search runs only when vlief_avis filled AND kzbew = 'B'
*&         AND ebeln IS INITIAL.  Do NOT set imseg-ebeln.
*&   2057  READ TABLE lt_lips WITH KEY posnr = imseg-vbelp_avis
*&         -> vbelp_avis must be LIPS-POSNR, never UECHA.
*&
*& Error contract (LMB_BUS2017U04:558):
*&   IF NOT return IS INITIAL -> global_error = true -> posting aborts.
*&   CT_RETURN is a single BAPIRET2 STRUCTURE, not a table.
*&   Any message aborts regardless of type. Set one, only to stop the posting.
*&---------------------------------------------------------------------*
METHOD if_ex_mb_bapi_goodsmvt_create~extensionin_to_matdoc.

  CONSTANTS: lc_lgort   TYPE lgort_d  VALUE 'RMYD',
             lc_delfrom TYPE vbeln_vl VALUE '9004952595',
             lc_delto   TYPE vbeln_vl VALUE '9004952614'.

  " Spike scope: development and quality only.
  IF sy-sysid <> 'DS4' AND sy-sysid <> 'QS4'.
    RETURN.
  ENDIF.

  LOOP AT ct_imseg ASSIGNING FIELD-SYMBOL(<ls_imseg>).

    " Anything outside the CNF scenario is left completely untouched.
    IF <ls_imseg>-bwart        <> '101'
       OR <ls_imseg>-kzbew     <> 'B'
       OR <ls_imseg>-vbeln      IS INITIAL
       OR <ls_imseg>-vlief_avis IS NOT INITIAL
       OR <ls_imseg>-ebeln      IS NOT INITIAL
       OR <ls_imseg>-vbeln      < lc_delfrom
       OR <ls_imseg>-vbeln      > lc_delto.
      CONTINUE.
    ENDIF.

    SELECT SINGLE vbeln, posnr, matnr, charg, lfimg, vrkme, lgmng, meins,
                  vgbel, vgpos
      FROM lips
      INTO @DATA(ls_lips)
      WHERE vbeln = @<ls_imseg>-vbeln
        AND posnr = @<ls_imseg>-posnr.
    IF sy-subrc <> 0.
      ct_return = VALUE #( type       = 'E'
                           id         = '00'
                           number     = '398'
                           message_v1 = 'CNF: delivery item not found'
                           message_v2 = <ls_imseg>-vbeln
                           message_v3 = <ls_imseg>-posnr ).
      RETURN.
    ENDIF.

    " Outbound delivery only.
    SELECT SINGLE vbtyp FROM likp INTO @DATA(lv_vbtyp)
      WHERE vbeln = @ls_lips-vbeln.
    IF sy-subrc <> 0 OR lv_vbtyp <> 'J'.
      ct_return = VALUE #( type       = 'E'
                           id         = '00'
                           number     = '398'
                           message_v1 = 'CNF: delivery is not outbound'
                           message_v2 = ls_lips-vbeln ).
      RETURN.
    ENDIF.

    " The delivery must reference an STO that receives into the requested plant.
    IF ls_lips-vgbel IS INITIAL.
      ct_return = VALUE #( type       = 'E'
                           id         = '00'
                           number     = '398'
                           message_v1 = 'CNF: delivery has no source document'
                           message_v2 = ls_lips-vbeln ).
      RETURN.
    ENDIF.

    SELECT SINGLE ebeln FROM ekpo INTO @DATA(lv_sto)
      WHERE ebeln = @ls_lips-vgbel
        AND ebelp = @ls_lips-vgpos
        AND werks = @<ls_imseg>-werks
        AND loekz = @space.
    IF sy-subrc <> 0.
      ct_return = VALUE #( type       = 'E'
                           id         = '00'
                           number     = '398'
                           message_v1 = 'CNF: STO item does not receive into plant'
                           message_v2 = ls_lips-vgbel
                           message_v3 = ls_lips-vgpos
                           message_v4 = <ls_imseg>-werks ).
      RETURN.
    ENDIF.

    "--------------------------------------------------------------
    " Derivation. ebeln stays initial so ME_CONFIRMATION_SEARCH_GR
    " resolves the purchase order from the delivery.
    "--------------------------------------------------------------
    <ls_imseg>-vlief_avis = ls_lips-vbeln.
    <ls_imseg>-vbelp_avis = ls_lips-posnr.
    <ls_imseg>-matnr      = ls_lips-matnr.

    " Quantity and unit must come from the same basis.
    IF ls_lips-lgmng IS NOT INITIAL AND ls_lips-meins IS NOT INITIAL.
      <ls_imseg>-erfmg = ls_lips-lgmng.
      <ls_imseg>-erfme = ls_lips-meins.
    ELSE.
      <ls_imseg>-erfmg = ls_lips-lfimg.
      <ls_imseg>-erfme = ls_lips-vrkme.
    ENDIF.

    IF ls_lips-charg IS NOT INITIAL.
      <ls_imseg>-charg = ls_lips-charg.
    ENDIF.

    IF <ls_imseg>-lgort IS INITIAL.
      <ls_imseg>-lgort = lc_lgort.
    ENDIF.

    " werks stays as supplied - it is the receiving plant.
    " Never copy LIPS-WERKS: that is the supplying plant.

  ENDLOOP.

ENDMETHOD.
