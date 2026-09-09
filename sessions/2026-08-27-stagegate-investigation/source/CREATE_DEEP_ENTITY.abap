  METHOD /iwbep/if_mgw_appl_srv_runtime~create_deep_entity.
**TRY.
*CALL METHOD SUPER->/IWBEP/IF_MGW_APPL_SRV_RUNTIME~CREATE_DEEP_ENTITY
*  EXPORTING
**    iv_entity_name          =
**    iv_entity_set_name      =
**    iv_source_name          =
*    IO_DATA_PROVIDER        =
**    it_key_tab              =
**    it_navigation_path      =
*    IO_EXPAND               =
**    io_tech_request_context =
**  IMPORTING
**    er_deep_entity          =
*    .
**  CATCH /iwbep/cx_mgw_busi_exception.
**  CATCH /iwbep/cx_mgw_tech_exception.
**ENDTRY.
    DATA: ls_deep_data    TYPE zcl_zcrm_stagegate_mpc_ext=>ty_deep_data,
          ls_item         TYPE zcl_zcrm_stagegate_mpc_ext=>ts_deliveriesitems,
          lt_item         TYPE TABLE OF zcl_zcrm_stagegate_mpc_ext=>ts_deliveriesitems,
          response        TYPE REF TO if_ixml_element,
          header          TYPE REF TO if_ixml_element,
          lv_message      TYPE string,
          lo_ixml         TYPE REF TO if_ixml,
          lo_document     TYPE REF TO if_ixml_document,
          lo_xmldoc       TYPE REF TO cl_xml_document,
          lv_string       TYPE string,
          lv_string_value TYPE string,
          lv_date         TYPE sy-datum,
          lv_time         TYPE sy-uzeit.


***** Reading entity
    TRY.
        CALL METHOD io_data_provider->read_entry_data
          IMPORTING
            es_data = ls_deep_data.
        IF ls_deep_data IS NOT INITIAL.
          IF ls_deep_data-erporderid IS NOT INITIAL.
            SELECT * FROM vbak INTO @DATA(ls_vbak) UP TO 1 ROWS WHERE vbeln = @ls_deep_data-erporderid.
            ENDSELECT.
          ENDIF.
          IF ls_deep_data-dinumber IS NOT INITIAL.
            ls_item-di_number = ls_deep_data-dinumber.
            ls_deep_data-dinumber = |{ ls_deep_data-dinumber ALPHA = IN }|.
            ls_deep_data-deliverylinenumber = |{ ls_deep_data-deliverylinenumber ALPHA = IN }|.
            ls_deep_data-erporderid = |{ ls_deep_data-erporderid ALPHA = IN }|.
            ls_deep_data-erplineitemid = |{ ls_deep_data-erplineitemid ALPHA = IN }|.
            SELECT * FROM lips INTO TABLE @DATA(lt_lips) WHERE vbeln = @ls_deep_data-dinumber
                                                               AND vgbel = @ls_deep_data-erporderid
                                                               AND vgpos = @ls_deep_data-erplineitemid.
*                                                         AND posnr = @ls_deep_data-deliverylinenumber.
            SELECT * FROM likp INTO @DATA(ls_likp) UP TO 1 ROWS WHERE vbeln = @ls_deep_data-dinumber.
            ENDSELECT.
            IF lt_lips IS NOT INITIAL.
              SELECT * FROM vbrp INTO TABLE @DATA(lt_vbrp) FOR ALL ENTRIES IN @lt_lips
                WHERE vgbel =  @lt_lips-vbeln AND vgpos = @lt_lips-posnr.
            ENDIF.
            IF lt_vbrp[] IS NOT INITIAL.
              SELECT * FROM vbrk INTO TABLE @DATA(lt_vbrk) FOR ALL ENTRIES IN @lt_vbrp
                WHERE vbeln =  @lt_vbrp-vbeln.
            ENDIF.
            LOOP AT lt_lips INTO DATA(ls_lips) WHERE posnr+0(1) NE 9.
              ls_item-di_quantity = ls_lips-lfimg.
              IF ls_lips-lfimg IS   INITIAL.
                READ TABLE lt_lips INTO DATA(ls_lips_u) WITH KEY uecha = ls_lips-posnr.
                IF  sy-subrc = 0.
                  ls_item-di_quantity = ls_lips_u-lfimg.
                ENDIF.
              ENDIF.
*      LS_ITEM-di_quantity = ls_lips-kcmeng.
              CONDENSE ls_item-di_quantity.
              CONVERT DATE ls_lips-erdat TIME ls_lips-erzet INTO TIME STAMP DATA(tz) TIME ZONE 'INDIA'.
              ls_item-di_creation_date_and_time = tz.
              CONDENSE ls_item-di_creation_date_and_time.
******Truck Allocation data
              SELECT recordno,
                  token,
                  serial,
                  vbeln,
                  posnr
          FROM zletilmsdelivery
            WHERE vbeln = @ls_deep_data-dinumber AND posnr = @ls_deep_data-deliverylinenumber AND del IS INITIAL
            INTO TABLE @DATA(lt_ilms_del).
              IF lt_ilms_del[] IS NOT INITIAL.
                SELECT * FROM zletilmstoken INTO TABLE @DATA(lt_ilms_token)
                  FOR ALL ENTRIES IN @lt_ilms_del
                  WHERE recordno = @lt_ilms_del-recordno
                  AND token = @lt_ilms_del-token.
                SELECT * FROM zletilmstrans INTO TABLE @DATA(lt_ilms_trans)
                  FOR ALL ENTRIES IN @lt_ilms_del
                  WHERE recordno = @lt_ilms_del-recordno
                  AND token = @lt_ilms_del-token
                  AND stageid = '10'.
              ENDIF.
              IF lt_ilms_del[] IS NOT INITIAL.
                LOOP AT lt_ilms_del INTO DATA(ls_del).
                  READ TABLE lt_ilms_token INTO DATA(ls_trans) WITH KEY recordno = ls_del-recordno
                                                         token = ls_del-token.
                  IF sy-subrc = 0.
                    ls_item-erp_driver_number = ls_trans-drivernumber.
                    ls_item-token_number = ls_trans-token.
                    CONVERT DATE ls_trans-cpudt TIME ls_trans-cputm INTO TIME STAMP DATA(tz1) TIME ZONE 'INDIA'.
                    ls_item-truck_allocated_date  = tz1.
                    CONDENSE ls_item-truck_allocated_date .
                    CLEAR tz1.
                    ls_item-truck_allocated_qty = ls_trans-quantity.
                    CONDENSE ls_item-truck_allocated_qty.
                    ls_item-truck_no = ls_trans-vehical_no.
                    SELECT name_org1 FROM but000 INTO ls_item-transporter_name UP TO 1 ROWS
                      WHERE partner = ls_trans-fwdagent.
                    ENDSELECT.
                    ls_item-carrier_id = ls_trans-fwdagent.
                    SELECT telf1 FROM lfa1 INTO ls_item-transporter_phone_number UP TO 1 ROWS
                  WHERE lifnr = ls_trans-fwdagent. ENDSELECT.
                    ls_item-consignee_id = ls_likp-kunnr.
                    READ TABLE lt_ilms_trans INTO DATA(ls_trans1) WITH KEY recordno = ls_del-recordno
                                                          token = ls_del-token.
                    IF sy-subrc = 0.
                      CONVERT DATE ls_trans1-erdat TIME ls_trans1-ertim INTO TIME STAMP tz1 TIME ZONE 'INDIA'.
                      ls_item-truck_dispatched_date_and_time = tz1.
                      CONDENSE ls_item-truck_dispatched_date_and_time.
                      CLEAR tz1.
                    ENDIF.

                  ENDIF.
                ENDLOOP.

              ELSE.
                ls_item-truck_allocated_qty =   ls_item-di_quantity.
                CONDENSE ls_item-truck_allocated_qty.
                ls_item-truck_allocated_date = tz.
                CONDENSE ls_item-truck_allocated_date .
                ls_item-consignee_id = ls_likp-kunnr.
                ls_item-erp_driver_number = ls_likp-zzdrivermob.
                ls_item-truck_no = ls_likp-zzvehicle_no.
                SELECT kunnr FROM vbpa INTO @DATA(lv_tpr) UP TO 1 ROWS WHERE vbeln = @ls_lips-vbeln
                              AND parvw = 'SP'. ENDSELECT.
                SELECT name_org1 FROM but000 INTO ls_item-transporter_name UP TO 1 ROWS
                      WHERE partner = lv_tpr.
                ENDSELECT.
                ls_item-carrier_id = lv_tpr.
                SELECT telf1 FROM lfa1 INTO ls_item-transporter_phone_number UP TO 1 ROWS
                  WHERE lifnr = lv_tpr. ENDSELECT.
*                SELECT gps_chk FROM zlet_vehicle INTO @DATA(lv_gps) UP TO 1 ROWS
*                WHERE vehical_no = @ls_likp-zzvehicle_no. ENDSELECT.
*                IF lv_gps = 'X'.
*                  ls_item-is_gps_enabled = 'true'.
*                ELSE.
*                  ls_item-is_gps_enabled = 'false'.
*                ENDIF.
*                CLEAR: lv_gps.

              ENDIF.
              LOOP AT lt_vbrp INTO DATA(ls_vbrp).
                READ TABLE lt_vbrk INTO DATA(ls_vbrk) WITH KEY vbeln = ls_vbrp-vbeln.
                IF sy-subrc = 0.
                  ls_item-tax_invoice_number = ls_vbrk-xblnr.
                ENDIF.
                ls_item-invoice_quantity = ls_vbrp-fkimg.
                CONDENSE: ls_item-invoice_cancel_quantity,ls_item-invoice_quantity.
                ls_item-invoice_line_number = ls_vbrp-posnr.
                ls_item-invoice_number = ls_vbrp-vbeln.
                CONVERT DATE ls_vbrp-erdat TIME ls_vbrp-erzet INTO TIME STAMP tz TIME ZONE 'INDIA'.
                ls_item-invoice_creation_date_and_time = tz.
                CLEAR:tz.
                CONDENSE ls_item-invoice_creation_date_and_time.
              ENDLOOP.
              ls_item-erp_order_number = |{ ls_deep_data-erporderid ALPHA = OUT }|.
              ls_item-erp_order_type = ls_vbak-auart.
              CONVERT DATE ls_vbak-erdat TIME ls_vbak-erzet INTO TIME STAMP tz TIME ZONE 'INDIA'.
              ls_item-order_creation_date_and_time = tz.
              CONDENSE ls_item-order_creation_date_and_time.
              CLEAR:tz.
              ls_item-erplineitemid = ls_deep_data-erplineitemid.
              ls_item-entrynumber = ls_deep_data-entrynumber.
              ls_item-erporderid = ls_deep_data-erporderid.
              ls_item-crmordrcode = ls_deep_data-crmordrcode.
              ls_item-dinumber = ls_deep_data-dinumber.
              ls_item-deliverylinenumber = ls_deep_data-deliverylinenumber.
              ls_item-delivery_line_number = ls_deep_data-deliverylinenumber.



              APPEND ls_item TO lt_item.
              CLEAR: ls_item.
            ENDLOOP.
          ELSE.

          ENDIF.
          ls_deep_data-dinumber = |{ ls_deep_data-dinumber ALPHA = OUT }|.
          ls_deep_data-deliverylinenumber = |{ ls_deep_data-deliverylinenumber ALPHA = OUT }|.
          ls_deep_data-erporderid = |{ ls_deep_data-erporderid ALPHA = OUT }|.
          ls_deep_data-erplineitemid = |{ ls_deep_data-erplineitemid ALPHA = OUT }|.
          ls_deep_data-deliveriesitemsset = lt_item.

          CALL METHOD me->copy_data_to_ref   "Populating the ER_DEEP_ENTITY
            EXPORTING
              is_data = ls_deep_data
            CHANGING
              cr_data = er_deep_entity.

        ENDIF.
      CATCH /iwbep/cx_mgw_tech_exception.
    ENDTRY.



  ENDMETHOD.
