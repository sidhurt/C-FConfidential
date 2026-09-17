# SRC-SID-20260910-02 — Existing CPI/T1 Delivery Enrichment

**Source:** direct clarification from Siddharth on 10 September 2026  
**Evidence tier:** Tier 3 under `AGENTS.md`  
**Purpose:** assign responsibility between the existing read-side integration and SAP transactional APIs

- Batch processing and the field/table relationships used to assemble delivery context are already filled in CPI/T1 for a delivery number.
- Portal-facing delivery/MRN context is therefore an existing integration/read-model responsibility, not a requirement for Submit MIGO or another SAP standard transactional service to assemble all screen fields by joining SAP tables for each delivery or purchase order.
- A SAP write service remains responsible for the fields and derivations required to execute its transaction and for authoritative validation at posting time.

**Boundary:** This is a direct project-state clarification. The existing CPI/T1 implementation has not yet been independently runtime-traced in this repository. Exact persistence in T1 versus T2, the deployed iFlow/view names, refresh watermark and error-recovery behavior remain to be captured rather than rebuilt by assumption.
