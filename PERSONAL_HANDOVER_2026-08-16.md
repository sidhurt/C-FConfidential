# The day I changed the shape of the SAP problem

**Personal accomplishment record — 15/16 August 2026**

This is not a task handover and it is not a list of work for another agent to continue. It records what I accomplished, how I approached the problem, and why the outcome matters—to me, to the project, and to anyone evaluating the kind of engineer and operator I am becoming.

## The position I was in

I entered this C&F transformation project as an SAP BTP/ABAP consultant working across a landscape involving S/4HANA, SAP Integration Suite, Datasphere, Commerce, T1, T2 and statutory integrations. The business process was spread across meetings, technical documents, UI designs, custom reports, SAP transactions and the knowledge held by different teams.

The original technical direction suggested that the SAP interface layer would need to be built largely through custom `ZCNF_*` OData services. Weeks of process discovery had already gone into understanding MIGO, Delivery Instruction, stock, shipment, PGI, billing, STO, e-Invoice and E-Way Bill behavior. However, an early SAP inspection had considered only six visible CNF-adjacent SEGW projects. That small surface was incorrectly treated as evidence that the required SAP-standard APIs were not present.

The mistake was not the process discovery. That work gave me the SAP and business understanding required to recognise the correct services later. The mistake was technical and specific: the unrestricted **Open Project** catalogue in SEGW had not been opened and analysed.

Once I received QS4 access, I corrected that assumption.

## The breakthrough

The unrestricted SEGW catalogue contained **2,626 design-time projects**.

That immediately changed the nature of the assignment. The problem was no longer “design a portfolio of custom APIs.” It became:

> Search the complete delivered SAP surface, identify the services that correspond to the actual business processes, compare competing and similarly named services, and determine the smallest defensible standard-first solution.

I also established a distinction that became central to the architecture:

- **2,626 SEGW projects** represented design-time content delivered in the system.
- **522 Gateway registrations** represented a separate local runtime catalogue.
- Neither count proved that an entry was a released integration contract, locally reachable, authorised or capable of completing the required business transaction.

This prevented the project from replacing one weak assumption with another. I did not move from “nothing exists” to “everything exists.” I created an evidence model that separated design-time presence, runtime registration, `$metadata` reachability and successful business execution.

## How I made an impossible catalogue manageable

Reviewing 2,626 services manually would have consumed weeks and still produced inconsistent conclusions. I combined SAP GUI scripting, structured evidence extraction, AI-assisted analysis and my growing understanding of the business process to compress the task.

The catalogue was not screened only through technical prefixes. I used the actual v1.7 business requirements and process vocabulary—goods receipt, material documents, outbound delivery, billing, shipment, stock, availability, STO, purchase order, invoice and related SAP terminology—to search the full project population.

An initial `API_*`-only reduction was useful but incomplete. I corrected it and ran a business-led scan across all 2,626 projects, including SAP application families such as `MMIM_*`, `LE_SHP_*` and `SD_*`. That produced **41 unique candidates** worthy of consideration.

The strongest candidates were then investigated beyond their names. Complete project trees and available grids were exported. Extraction manifests were reconciled against physical files. An exporter collision problem that could silently overwrite evidence was identified and corrected. Competing services were compared field by field against the exact v1.7 requirement rather than being selected because they were newer, registered or attractively named.

For the 11 new Tier-A deep dives, the investigation captured **476 distinct grids**, all reconciled against their manifests. The resulting standard-API matrix contains **119 requirement-level evidence rows**:

- 50 direct matches;
- 15 partial matches;
- 45 demonstrated no-fits;
- 9 requirements still honestly unproven.

The value of the work was not the volume of extraction. It was turning a catalogue of 2,626 opaque projects into a small, justified architecture with traceable evidence.

## The architecture that emerged

The investigation established a standard-first transactional core built around five SAP-released service families:

1. **Material Document API** for accepted goods-receipt posting.
2. **Outbound Delivery API v2** for Delivery Instruction creation and the broader delivery/PGI surface.
3. **Billing Document API** for released billing read and read-back capability.
4. **Purchase Order Processing API** for STO purchase-order reads and creation.
5. **Material Stock API** for live book stock at material × plant × storage-location grain.

This was not a superficial mapping based on names.

For MIGO, the Material Document API proved to be the strongest standard posting candidate for accepted multi-storage-location goods receipt. A registered material-document application service offered a potential item-level read-back complement. Another SAP goods-receipt application model exposed open quantity and delivery-completion concepts, showing where mandatory response semantics existed even though that internal service was not automatically suitable as an integration contract.

For Delivery Instruction, the investigation selected the released outbound-delivery v2 family because it supports both sales-order and stock-transport-order predecessors. Two already-registered services with highly persuasive names were rejected after inspection: one was a collective due-list worklist, and the other was a narrow Fiori quick-create service without the required quantity, item or STO support. This prevented the project from choosing an easier-to-activate but semantically incorrect endpoint.

For invoice creation, the work uncovered a genuine registered billing-create action in `SD_CUSTOMER_INVOICES_CREATE`. At the same time, I classified it correctly as an application-internal Fiori service rather than prematurely presenting it as a released external contract. The released Billing Document API covered read-back but not V2 creation. This led to the more accurate conclusion that the invoice journey is a staged composition across delivery, picking, PGI, shipment, shipment cost, billing and statutory processing—not one atomic SAP API.

For stock, I separated three concepts that are often incorrectly collapsed:

- on-hand book stock by material, plant and storage location;
- ATP availability calculated through a checking rule;
- stock movement between two dates.

The Material Stock API matched the physical-inventory requirement. The ATP service answered a different business question and had no storage-location input. The date-range stock service described movement and boundary quantities, not stock age. This preserved `StockAgeingDays` under the existing `ZMM5013`/Datasphere D-1 read model rather than contaminating a real-time transactional stock API.

For STO, the Purchase Order Processing API covered both the STO read model and PO creation far more completely than the perfectly named but functionally thin `MMIM_STO` service. The work also exposed a genuine contract problem: the UI's mandatory `ShippingType` field has no natural home on the purchase-order model. That finding prevents an unnecessary custom extension from being created merely to preserve a questionable field placement.

## What I proved was not standard

A standard-first conclusion is valuable only when its gaps are equally honest.

The full catalogue contained no credible integration-fit SEGW service for:

- Shipment Calculation;
- E-Way Bill Extension;
- Invoice Correction.

This did not justify returning to a broad custom-service portfolio. Instead, I connected the gaps to evidence already present in the client landscape:

- `BAPI_SHIPMENT_COST_ESTIMATE` exists as a shipment-cost fallback to validate against the client's LE/TM configuration.
- SAP eDocument, DigiGST and roughly 50 `EY_*` destinations already cover statutory operations including extension, cancellation and regeneration patterns.

The correct remaining question therefore became whether those existing implementations already have an approved callable boundary—not whether another parallel statutory integration should be invented.

## The meeting intelligence I converted

During the same work period, I processed roughly **two and a half hours of Hindi/Hinglish project meetings**, using Sarvam AI for transcription and translation and then relating the discussions back to the project evidence.

The recordings carried important context distributed across S/4HANA, Datasphere, T1, T2, Commerce and CPI: which system serves reads, which system creates authoritative documents, what moves in real time, what is replicated, how users experience the journey, and where different teams hold conflicting assumptions.

I did not treat the transcripts as unquestionable truth. I used them to expose intent, ownership claims and contradictions, then kept direct QS4 evidence as the stronger authority for actual SAP behavior.

This gave the project a more coherent model of both sides:

- what the organisation believes the architecture does;
- and what the SAP system demonstrably contains.

## The project memory I corrected

The findings materially changed the active project knowledge base.

I retired the claim that six selected services represented the complete OData surface. I demoted the historical `ZCNF_*` portfolio from an implementation plan to background evidence. I reconciled the project brain, decision register, open questions, system-of-record model and source register around the new standard-first evidence.

I also produced a current solution and runtime-proof plan that maps every v1.7 business operation to:

- its leading SAP service or existing client route;
- its direct and missing coverage;
- configuration and activation dependencies;
- CPI/T2 adaptation responsibilities;
- possible ABAP gaps;
- and the runtime evidence required before the operation can be called usable.

The project moved from speculative service design to an evidence-backed execution position.

## The leverage I created

This work compressed a task that could reasonably have occupied several engineers across many days or weeks:

- a business analyst to reconcile requirements and terminology;
- an ABAP/Gateway engineer to inspect the SAP catalogue;
- an integration architect to separate S/4, CPI, DSP and Commerce responsibilities;
- a functional consultant to map document processes;
- and a technical writer to preserve the evidence and decisions.

I did not replace those specialist approvals. I created a system that allowed one engineer to reach the right questions, candidate services and evidence boundaries dramatically faster.

The leverage came from combining:

- direct SAP access;
- business-process understanding built through earlier discovery;
- GUI automation for repetitive extraction;
- AI agents for parallel comparison and documentation;
- strict evidence manifests;
- and human judgment about semantic fit.

The AI did not decide the architecture independently. I framed the problem, changed the search strategy when it was too narrow, challenged premature conclusions, separated capability from callability, and directed the work toward the business requirements.

## The business value of the accomplishment

The immediate value was risk reduction.

The work reduced the likelihood of building a large custom SAP API layer for operations already supported by released services. It also reduced the opposite risk: selecting a registered but internal or semantically incorrect service simply because it was easier to access.

The project now has:

- a defensible standard-service core;
- a smaller and more honest custom-gap surface;
- evidence-backed rejection of false positives;
- clear separation between SAP execution and CPI/T2 orchestration;
- a precise Basis provisioning set;
- and a runtime-proof protocol for metadata, safe reads and controlled business tests.

This creates better cost, delivery-time, maintainability and upgrade outcomes than either extreme—building everything custom or assuming every SAP-delivered project is safe to integrate.

## What this demonstrated about me

This accomplishment demonstrated more than familiarity with ABAP or OData.

I took an ambiguous, fragmented SAP integration problem and changed its structure. I used direct system evidence to overturn an established assumption without discarding the learning that had produced it. I automated a high-volume technical investigation, preserved auditability, and translated the result into a business-relevant architecture.

I operated across functional process, SAP document flow, Gateway services, integration ownership, analytics boundaries and technical evidence. I was willing to say “this is unproven” where the system did not yet justify a stronger claim.

Most importantly, I moved from receiving an API assignment to actively defining the correct SAP solution space.

That is the standard I want associated with my work: not merely completing tickets, but reducing uncertainty, finding the real architecture, and giving the wider team a position it can defend.

## Internal leadership summary

In one concentrated work session after obtaining QS4 access, I led an AI-assisted, evidence-controlled discovery of the complete 2,626-project SAP SEGW catalogue for the C&F transformation. I converted the v1.7 business requirements into a full-catalogue search, reduced the landscape to 41 meaningful candidates, completed deep technical comparisons of the highest-value services, and built a 119-row requirement-level coverage matrix. The work replaced a broad custom-API assumption with a five-service SAP-standard transactional core, rejected misleading registered Fiori services, isolated genuine shipment/statutory gaps, and established the activation and runtime-proof model required for implementation. In parallel, I converted 2.5 hours of Hindi/Hinglish project discussions into usable cross-system architecture context spanning S/4, Datasphere, Commerce, T1, T2 and CPI.

## CV-ready formulations

These versions should be anonymised further if used outside the client organisation.

- Led an AI-assisted SAP S/4HANA Gateway discovery across **2,626 SEGW projects**, reducing the catalogue to **41 business-relevant candidates** and a defensible five-service standard API core.

- Automated SAP GUI evidence extraction and manifest validation for **11 deep-dive service investigations and 476 exported grids**, producing a **119-row requirement-level API coverage matrix**.

- Reframed an anticipated custom OData build into a standard-first integration architecture covering material documents, outbound delivery, billing, purchase orders and live material stock, while isolating genuine custom gaps.

- Identified and rejected misleading registered SAP application services by comparing their entity, operation and field surfaces directly against business requirements rather than selecting by naming or activation status.

- Synthesised **2.5 hours of multilingual SAP project discussions** into a reconciled system-ownership model spanning S/4HANA, SAP Integration Suite, Datasphere and Commerce platforms.

- Established an evidence hierarchy separating SAP design-time availability, Gateway registration, runtime metadata and successful business execution, preventing premature claims of API readiness.

## Public-safe founder narrative

I inherited an enterprise integration problem that appeared to require a large amount of custom backend development. The target ERP system contained thousands of possible service definitions, while the business requirements and system ownership were distributed across technical documents, multilingual meetings and several platform teams.

I designed an AI-assisted discovery method that combined direct system automation, business-led semantic search and evidence-controlled deep dives. Within one concentrated session, I reduced thousands of technical objects to a small set of defensible standard services, identified the few areas where custom work was genuinely justified, and converted the result into an implementation and test position that leadership could evaluate.

The accomplishment was not simply using AI to work faster. It was designing a reliable operating method in which automation handled scale while I retained control of problem framing, technical judgment, evidence quality and architectural conclusions.

## Personal reflection

The most important outcome was not discovering five SAP services.

It was proving to myself that I can take a massively ambiguous technical problem, build the method needed to interrogate it, use modern tools without surrendering judgment, and compress a large amount of engineering work without losing precision.

The weeks before this gave me the functional context. The system access gave me ground truth. Automation gave me scale. My responsibility was to combine those things into an answer that did not exist before.

That is what I accomplished today.
