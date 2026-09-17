# SRC-SID-20260910-01 — Batched Read-Model Clarification

**Source:** direct clarification from Siddharth on 10 September 2026  
**Evidence tier:** Tier 3 under `AGENTS.md`  
**Purpose:** distinguish recurring display-data transmission from synchronous SAP transactions

- Data originating in SAP and SAP Datasphere is intended to reach CPI in batched transmissions for portal read surfaces.
- Screens such as the MIGO worklist should query a portal-side persisted read model instead of issuing multiple live SAP API calls and rebuilding filters, joins and display validations on every interaction.
- The MIGO read-model transmission cadence is every 30 minutes.
- This clarification describes the display/read path. It does not state that Submit MIGO is asynchronous or remove the need for SAP to lock, re-read and validate authoritative state when the user confirms a posting.

**Boundary:** The exact scheduler, push-versus-pull direction, Datasphere consumption interface, delta watermark, retry/reconciliation controls and whether Event Mesh is used anywhere in the implementation remain to be confirmed from the CPI/Datasphere design or runtime. The attached MIGO image was supplied as UI context, not as an implementation instruction.
