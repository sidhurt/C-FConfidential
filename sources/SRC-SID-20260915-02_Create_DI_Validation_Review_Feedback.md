# Create DI validation review feedback

**Source ID:** `SRC-SID-20260915-02`  
**Date:** 2026-09-15  
**Source type:** Stakeholder feedback relayed directly by Siddharth  
**Evidence boundary:** This records what Siddharth received. The original email/message was not supplied as a controlled artifact, so it is authoritative as a report of the review but not independent proof of the reviewers' identity, approval authority or final sign-off.

## Feedback received

The reviewers responded to the ten-point Create DI validation list with these clarifications and requests:

1. They asked whether the depot single-storage-location rule and the storage-location/SPI compatibility rule were duplicates.
2. They stated that validation points 4–6—the route, wheeler/load-capacity and freight-scale checks—should apply only to Primary Plant deliveries.
3. They requested further discussion before implementing point 10, the Primary Plant SPI rule.
4. They requested proof that the validations execute for interface/API input and not only during manual delivery transactions.
5. They requested a wider search across user exits, screen exits, BAdIs, and implicit/explicit enhancement points.

## Technical reconciliation

- **Verified from captured source:** the two storage-location rules are separate. One limits the number of distinct storage locations in a depot delivery; the other validates the selected storage-location/SPI pair against `ZLETSPIMAP`.
- **Verified from captured source:** the freight-scale rule contains an explicit Primary Plant classification test. The route-configuration and first-item maximum-load rules do not visibly contain the same direct classification test.
- **Unknown:** points 4 and 5 may be restricted indirectly by configuration. Read the applicable plant/material/route entries before changing the code.
- **Unknown:** point 10's intended business behavior—reject caller-supplied SPI, overwrite it, or validate it—has not been approved.
- **Unknown:** execution of every unrestricted validation on the actual OData path remains unproven.

## Consequence

Do not present the ten-point list as finally approved. Treat points 4–6 as a Primary-Plant-only requirement reported by Siddharth, point 10 as an open business definition, and API equivalence as a runtime certification task.
