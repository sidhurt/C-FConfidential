# DS4/200 standard idempotency setup completed

Date: 2026-08-31. Operator: QNOVATE8. User explicitly authorized DS4 initialization and jobs.

## Changed and verified

- Ran the standard WSIDPADMIN / SRT_WS_IDP_CUSTOMIZE setup once.
- Preflight SM37: SAP_BC_IDP_WS_SWITCH_* across all users/statuses and 2000-9999 dates
  returned no matching jobs. Therefore no existing jobs were replaced.
- SRT_IDP_CONF changed from no client entry to one entry for client 200.
- Generated storage shown in the readback includes /1SAP1/IDPBD1200,
  /1SAP1/IDPBD2200 and /1SAP1/IDPID1200.
- SRT_IDP_ADM has SWITCH_BD / SWITCH_ID rows, with periods 360 / 720 minutes.
- SM37 shows exactly these two jobs, both Released, created by QNOVATE8:
  SAP_BC_IDP_WS_SWITCH_BD and SAP_BC_IDP_WS_SWITCH_BDID.
- SAP's two explicit “Job ... scheduled” information messages were acknowledged.
- DS4 service-root GETs returned 200 for API_MATERIAL_DOCUMENT_SRV and
  API_OUTBOUND_DELIVERY_SRV;v=2.

The intervals are switch-job intervals, not a promise of permanent replay protection.
Their future executions have not yet been observed. No jobs were manually forced to run.

## Not done / not claimed

- No QS4 configuration changes.
- No real DI creation or MIGO posting, and no replay/concurrent business-post proof.
- No business document was created by these checks.
- The service-root GETs did not return RepeatabilityResult; GET reachability is not proof
  that a business POST is protected. The pack requires that header on a valid POST result.
- No modification of SAP service code and no transport released.
- Local Postman JSON edits are not an automatic update to an already imported collection.

## Postman answer

Confirmed directly from JSON: each Reviewed collection has exactly two requests, token GET
then business POST. No second MIGO verification GET. Original evidence collections remain
unchanged and may still contain readbacks. Re-import the reviewed four-file pack.

The shipped environments still target QS4/700, so keep them unarmed until QS4 setup is
authorized and completed. The original packs and all populated SAP credentials were untouched.

Next: choose fresh approved business test cases and certify same-GUID sequential/concurrent
POST results before declaring end-to-end duplicate prevention complete. QS4 initialization
requires its own authorization; DS4 client configuration is not implicitly active in QS4.

## Evidence

See evidence/ds4_jobs_before.txt, ds4_initialize_attempt.txt, ds4_ack_bd.txt,
ds4_ack_bdid.txt, ds4_conf_after.txt, ds4_adm_after.txt and ds4_jobs_after.txt.

[SAP's configuration instructions](https://help.sap.com/docs/SAP_NETWEAVER_750/68bf513362174d54b58cddec28794093/09f82651c294256ee10000000a445394.html?locale=en-US&state=PRODUCTION&version=7.5.29)
describe the six-hour document / twelve-hour request-ID intervals used for this setup.
