# SRC-SID-20260812-01 — E-Way Bill Extension Timing Clarification

**Source:** direct clarification from Siddharth on 12 August 2026  
**Status:** confirmed project business rule; supersedes the timing caveat in `SRC-SID-20260811-11`

- An E-Way Bill becomes eligible for extension only during the eight hours immediately before its current expiry.
- There is no after-expiry eligibility window in this project.
- Each successful extension adds exactly 24 hours of validity.
- The fixed duration is a government-mandated rule for this business. The caller does not choose or send an extension duration.
- API-09 should return the authoritative updated-valid-until timestamp after success.

Contract expression:

```text
CurrentTimestamp >= ValidUpto - 8 hours
AND
CurrentTimestamp < ValidUpto
```

