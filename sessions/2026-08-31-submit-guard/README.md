# DI / MIGO: live SAP findings and remaining work

2026-08-31. SAP GUI Scripting connected successfully to QS4/700 and DS4/200 as QNOVATE8.
Initial inspection was read-only. In the subsequent user-authorized setup, DS4/200 was
initialized using WSIDPADMIN and two standard housekeeping jobs were created/released.
No business POST, custom code activation or transport was performed. QS4 was unchanged.

Current outcome: see [DS4 setup completion](DS4_SETUP_COMPLETED.md).

## Outcome

Prefer the installed SAP Gateway repeat-request framework before building any custom ABAP
duplicate store. The earlier assumption that a custom wrapper was necessary was premature.
`RequestID` is an HTTP header, not a property that must appear in the service's EDM metadata.

Live SE24 evidence shows `/IWBEP/CL_IDP_UTIL` activates this mechanism from
`RepeatabilityCreation` + `RequestID`, acquires the request lock, and stores the result through
the standard Web Service idempotency helper. `CL_WS_IDP_CONF->CONF_READ` raises a fault if
the client configuration is absent.

SE16 found no `SRT_IDP_CONF` entry in either DS4/200 or QS4/700. QS4 selection fields were
also inspected and blank, with maximum hits 20. This is a configuration prerequisite, not
a missing SAP GUI scripting permission. No HTTP rejection was executed; configuration
failure is inferred from the actual installed source and the empty client table.

WSIDPADMIN opens in DS4 and shows program SRT_WS_IDP_CUSTOMIZE. Its displayed values were
2 hours for Document and 1 day for Document ID. These are screen values, **not evidence of
existing active configuration or scheduled jobs**. Schedule was not pressed.

## Local implementation

The neighboring `deliverables/postman/Postman collection - SubmitMIGO CreateDI - Reviewed`
folder still contains exactly four JSON files. Originals remain unchanged.

- Token GET then business POST only; no second MIGO verification GET.
- MIGO validates both PO/item and selected delivery/item, movement 101, reference type B.
- Stable submission GUID is normalized to 32 characters and sent in the standard headers.
- Confirmation is consumed before dispatch; ordinary repeat clicks are skipped locally.
- A response passes only with 201, a document key, and RepeatabilityResult=supported.
- A returned document is retained even if repeatability verification fails.
- Explicit sequential QA replay preserves GUID/time/body and checks the original key.
  It requires a verified retention window and cannot replay failed/pending/expired attempts.
- 97 offline tests pass. These test embedded scripts with mocked Postman APIs, not live SAP
  idempotency, network concurrency, transaction atomicity or actual Postman execution.

## Next authorized action

User authorized the DS4/200 shared configuration and jobs. That setup is now complete;
do not run the initialization script again. The initial empty-table findings above are
historical, not the current DS4 state.

The supported initialization workflow was used after verifying that SM37 had no matching
jobs. Configuration/admin rows and both released jobs were verified afterward. Leave QS4
configuration unchanged until explicit release direction. Do not directly edit framework
configuration tables.

Then select one approved fresh eligible case per operation, retain the exact GUID/request,
and prove sequential and overlapping calls result in one business document. Do not reuse
already-consumed historical MIGO delivery 9004953150 as a new receipt case. Native request
lock contention can surface a retryable error (see HAS_BEEN_PROCESSED evidence); do not
claim a universally error-free concurrent UI experience without testing/caller handling.
Normal button locking belongs to the eventual caller; no frontend/CPI project exists today.

Request-ID retention is finite. Never generate a new GUID on a retry, reuse one for another
operation, or retry a forgotten ID after retention as though it were still protected.

## Sources

- [SAP Gateway idempotent services](https://help.sap.com/docs/SAP_NETWEAVER_750/68bf513362174d54b58cddec28794093/09f82651c294256ee10000000a445394.html?locale=en-US&version=7.5.29)
- [SAP GUI ABAP editor scripting API](https://help.sap.com/docs/sap_gui_for_windows/b47d018c3b9b45e897faf66a6c0885a8/06d283b024964f689fdf55ea1f2bd0d9.html)
- Live method source extracts in `evidence/`; safely reproducible inspection scripts in `scripts/`.
