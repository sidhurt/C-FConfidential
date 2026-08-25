# Next Move

When DEV access and the first formal assignment arrive:

1. **Get the assignment in one sentence.** Record the business outcome, owner, priority, and acceptance criteria.
2. **Get the missing KT.** Ask for the relevant trade/non-trade/STO recording and the SD/MM/KDS owner for this workflow.
3. **Confirm the environment with Basis.** DEV client, Gateway topology, package, transport, service registration, roles, test data, and approved automation policy.
4. **Trace one valid example manually.** Identify the real SAP predecessor, document flow, statuses, KDS/master fields, and resulting document.
5. **Complete one interface-discovery sheet.** Establish source of record, field owners, SAP/Datasphere sources, CPI owner, and open questions.
6. **Validate the SAP API.** Test the correct released API/BAPI safely before designing SEGW around it.
7. **Agree the CPI contract.** Request, response, keys, units, errors, correlation ID, timeout, retry, and idempotency.
8. **Design thin Gateway + testable classes.** No large business logic in `DPC_EXT`.
9. **Build one vertical slice in DEV.** Backend class → SEGW endpoint → Gateway test → CPI call → SAP document → downstream reconciliation.
10. **Capture evidence and decisions.** Update the registers after every meeting/test. Do not absorb adjacent ownership.

First target: the smallest formally approved interface that proves the complete SAP-to-CPI pattern, preferably a read-only query before a transactional POST. Do not begin with the full invoice orchestration.
