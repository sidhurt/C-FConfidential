# SRC-SID-20260812-04 — Foundational API Study Scope

**Source:** direct instructions from Siddharth on 12 August 2026  
**Evidence tier:** Tier 3 under `CLAUDE.md`  
**Purpose:** freeze the current learning boundary and prevent later architecture research from contaminating the foundational study material

- Siddharth's immediate priority is to build a clinically reliable understanding of the existing business processes, SAP documents, endpoint responsibilities, request/response meaning and failure stakes.
- Within that foundation, the primary track is how each SAP API enters, observes or changes the inbound/outbound functional process. Pure contract mechanics, idempotency, security and technical envelopes remain important but are second-priority study topics.
- The later architecture fork around decomposing API-06 into more operation-specific endpoints is deliberately deferred.
- SEGW service-count and service-grouping debates are deliberately deferred.
- Predictive BAPI/class/table mappings are reference hypotheses for a later implementation phase, not material to memorize as current project truth.
- The standalone `API-10 Valid Storage Locations` contract was removed from the working v1.7 workbook during the 12 August study session. The supporting requirement to obtain valid/eligible storage-location choices remains, but its source and ownership are unresolved; it must not be taught as an approved standalone endpoint.
- Candidate `API-11 Create STO Purchase Order` keeps its current identifier and candidate status; removing API-10 does not authorize renumbering or promotion.

**Boundary:** this is a study-scope and working-contract clarification. It does not approve an SAP implementation architecture, resolve the final formal interface register, or settle the internal design of API-06.
