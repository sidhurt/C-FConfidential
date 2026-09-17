# Create DI test tool — SAP Gateway Client

**Source ID:** `SRC-SID-20260917-07`  
**Date:** 2026-09-17  
**Source type:** Direct instruction from Siddharth

Siddharth stated that Create DI testing will use transaction `/IWFND/GW_CLIENT` (SAP Gateway Client), not Postman.

## Consequences

- Requests run as the logged-on SAP user in QS4/700; no basic-auth credentials or manual CSRF/cookie handling are needed in the client.
- The Postman packs under `deliverables/postman/` are no longer the primary Create DI test vehicle. Their confirmation switches and scripted assertions do not exist in the Gateway Client; equivalent checks are manual (see `sessions/2026-09-14-create-di-enhancement-equivalence/CREATE_DI_TEST_APPROACH_2026-09-17.md`).
- The 15 Sep attempt (`SRC-SID-20260915-04`) failed because the Gateway Client was left on `HEAD` against the service root. Method and full entity-set URI must be checked on every write.
