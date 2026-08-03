# Brain Map

```mermaid
flowchart LR
    U["C&F user"] --> C["Commerce / portal"]
    C <--> I["CPI / Integration Suite"]
    I <--> G["SAP Gateway / OData V2"]
    G --> A["Thin DPC_EXT"]
    A --> S["ABAP application services"]
    S --> P["Released APIs / BAPIs / queries"]
    P --> H["S/4HANA transactional truth"]

    H --> D["Datasphere replication / models"]
    D --> I
    H --> O["Invoice, delivery, material, shipment and e-document outputs"]
    F["FleetX / external tax services"] <--> I

    K["SD/MM/KDS knowledge"] --> S
    K --> M["Field and source-of-record mapping"]
    M --> I
    R["BRD, meetings and decisions"] --> K
    E["System evidence and tests"] --> K
```

## Operational spine

```mermaid
flowchart TD
    O["Order"] --> DI["Delivery Instruction"]
    DI --> SL["One storage location"]
    SL --> B["One or more batches"]
    B --> T["Transporter, route and freight"]
    T --> X["Shipment details"]
    X --> PGI["PGI"]
    X --> SH["Shipment and shipment cost"]
    X --> INV["SAP billing document"]
    INV --> EI["e-Invoice / IRN"]
    INV --> EW["E-Way Bill"]
    PGI --> DF["Document-flow status"]
    SH --> DF
    INV --> DF
    EI --> DF
    EW --> DF
    EW --> CORR["Part A / Part B correction"]
    EW --> EXT["24-hour extension"]
```

The arrows express the desired business journey, not yet the verified SAP call sequence. PGI, shipment, billing, and e-document ordering/atomicity remain open.

## Knowledge loop

```mermaid
flowchart TD
    SRC["Meeting, BRD, KT or system observation"] --> OBS["Observation"]
    OBS --> CLS["Confidence and source classification"]
    CLS --> TERM["Glossary / KDS"]
    CLS --> SOR["System-of-record matrix"]
    CLS --> WF["Workflow and document chain"]
    TERM --> API["Interface design"]
    SOR --> API
    WF --> API
    API --> TEST["Layered test evidence"]
    TEST --> DEC["Decision or correction"]
    DEC --> TERM
    DEC --> SOR
    DEC --> WF
```

