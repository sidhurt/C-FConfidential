# SRC-SID-20260812-02 — Create STO Purchase Order Candidate API

**Source:** direct clarification from Siddharth on 12 August 2026  
**Status:** confirmed functional requirement; SAP interface approval and implementation remain candidate

- The Intra-Warehouse Movement journey must include creation of the purchase order shown in the validated Figma flow.
- This operation applies only to the STO/intra-warehouse scenario.
- Trade and Non-trade continue to start from sales orders and do not call this operation.
- The Create Purchase Order action may require a new SAP API.
- In the working v1.7 catalogue it is incorporated as candidate API-11. Formal scope, owning service, SAP MM document configuration and implementation must still be approved.
- On success, the returned stock-transport purchase order becomes API-03's predecessor with `PredecessorType = STO_PO`; API-03 then creates the DI/SAP outbound delivery.

The supplied validated design captures Source Plant, Receiving Plant, Company Code, Shipping Type, Purchasing Group, Product, PO Quantity, Delivery Date, Requisition Number and Requisitioner, and shows the created PO number on success (`SRC-FIG-20260812-01`).

