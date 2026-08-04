# Project Brain

The mental model. For current state, open questions and register navigation, read `HANDOVER_AI.md` — this file is how to *think* about the project, not a status report.

**Last reconciled:** 2026-08-03

## One-sentence model

The C&F Agent Interface is a new operational portal over Shree Cement's existing SAP dispatch processes: a Spartacus storefront presents the journey, Commerce Cloud serves most reads, SAP Integration Suite moves messages, S/4HANA validates and creates the authoritative business documents, Datasphere supplies analytical and replicated data, and DigiGST handles statutory e-documents.

## The operational spine

```text
Sales Order / STO
  → Delivery ("DI")                    the central operational object
  → one storage location → 1..n batches
  → transporter · route · freight
  → PGI · shipment · shipment cost · billing
  → e-Invoice (IRN) · E-Way Bill
  → document status · download
  → correction · extension
```

Peripheral to the spine: inbound goods receipt (MIGO), warehouse-to-warehouse transfer (STO), reports.

**Everything the SAP team builds hangs off this chain.** When a requirement arrives, the first question is always: which station does it touch, and does it read or write?

## The central thesis

> **A BAPI will not repair a semantically wrong payload.**

This is the most important sentence in the repository and it has survived every piece of evidence since.

The failure mode this guards against is specific: a technically correct API call, with correct syntax and a valid signature, carrying a business value that means the wrong thing. It posts successfully. Nothing errors. The defect surfaces weeks later in production, as wrong stock in the wrong place or an invoice a customer disputes.

Client senior stakeholders raised exactly this in the 28 July walkthrough, pushing back on the work being scoped as "field mapping and BAPI posting". They were right.

**What has changed since:** the semantic gap is now substantially closed. The KDS catalogue (`sources/`) decodes the client's actual configuration — material groups, customer groups, storage locations, special procurement indicators, org structure. The thesis stands, but the team is no longer working blind against it.

## How to think about the four systems

Not "SAP plus some other things". Four systems that each genuinely own something:

| System | Owns | Do not ask it for |
|---|---|---|
| **S/4HANA** | Creating and posting business documents. Business validity, locking, document numbers, duplicate prevention | Portal display data. Under Option C most reads are served elsewhere |
| **Commerce Cloud** | The user journey; portal masters (depot, geography, material alias, Incoterms, storage location); and — under Option C — serving orders, deliveries and invoices live from T1 | Business validity. Commerce must never decide what SAP will accept |
| **Datasphere** | Analytical, consolidated and replicated data — MRN, STO list, stock ageing, vehicle and transporter masters | Transactional decisions. A batch allocation cannot be made from a 15-minute-old snapshot |
| **Integration Suite (CPI)** | Message movement, routing, transformation, transport retry, correlation | Business rules. CPI must not become the hidden home of SAP logic |

The recurring mistake to guard against: **conflating "created in" with "read from".** S/4 creates the delivery; the portal reads it from Commerce T1. Both statements are true and they imply different work.

## The domains, and what the brain must answer for each

| Domain | Questions that must have answers before building |
|---|---|
| Order | Predecessor type (SO or STO), credit status, open quantity, source plant |
| Delivery (DI) | Creation API per predecessor, editable fields and cutoff, storage-location immutability |
| Stock | Unrestricted vs availability-check, batch grain, eligibility, allocation ranking |
| Batch | Determination ownership, FIFO rule, reset behaviour on quantity change |
| Freight | Route, rate, Incoterm treatment (FTP/FTB/EX), pre-document estimate feasibility |
| Shipment | Document model, where vehicle and driver belong, LR/GR mapping |
| PGI | Trigger, movement type, material document, reversal policy |
| Billing | Billing type, ODN vs billing document number, accounting consequence |
| E-documents | IRN lifecycle and cancellation window, E-Way Part A/B, extension ownership |
| Receipt | Reference model, partial receipt, MRN ownership |
| Master / KDS | Code meanings, derivations, system of record, valid combinations |

## What makes an interface implementation-ready

An API is ready to build only when the brain can answer all ten:

1. What business outcome is required?
2. Which SAP document or process represents it?
3. Which fields are input, derived, and output?
4. What does each code mean — and which system owns it?
5. Which released API, BAPI, query or existing custom object is correct?
6. What statuses and exceptions are valid?
7. What does the caller send, retry and correlate?
8. How does SAP prevent duplicates and log the request?
9. Is this a real-time SAP read, or is it served from Commerce or Datasphere?
10. How is success proven — in SAP, and downstream?

Question 9 is new, and it is the one Option C forces. Several things assumed to be SAP APIs are not.

## Evidence model

Every claim carries: source ID, confidence, owner, environment, and validation date. Confidence labels are in `README.md §Evidence standard`.

The discipline that makes this work: **every new document either confirms something, contradicts something, or opens a question.** Never merely "adds information". A document that changes no register has not been read properly.

Two rules learned the hard way:

- **Record conflicts rather than resolving them by preference.** C-8 (pickup code) and C-10 (sales org vs company code) are live because the sources genuinely disagree.
- **Remove superseded beliefs rather than annotating them.** Three assumptions in this project were confidently wrong — SPI as shipping point, brand/grade as classification characteristics, SAP Document Compliance as the statutory framework. They are gone from the current documents, not footnoted, so nobody reasons from them again.

## The standing risk

The project's original risk was semantic — a technical team mapping fields whose meaning nobody knew. That has largely been mitigated.

The current risk is different: **unowned work at system boundaries.** Option C reads deliveries and invoices from Commerce T1, but they are created in S/4, and nothing specifies what pushes them across. Nobody assigned it because it falls between three teams. Unassigned SAP-side work drifts to the ABAP developer by default, unnamed and unfunded.

The countermeasure is the same as the standing rule in `ROLE_BOUNDARIES.md`: collaborate across every boundary, but name ownership out loud rather than absorbing it silently.
