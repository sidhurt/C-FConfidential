# SE38/SE24 editor setting — baseline to restore

Captured 2026-09-15, QS4/700, user QNOVATE8, before any change.
Dialog: SE38 editor -> Utilities -> Settings... -> tab "ABAP Editor" -> tab "Editor".

| Field | Label | State BEFORE change |
|---|---|---|
| `SEUCUSTOM-ABAPCNTRL` | Source Code-Based Editor | **selected (TRUE)** |
| `*SEUCUSTOM-PCMODE` | Text-Based Editor | false |
| `RSTXP-TDENHALL` | Display All (enhancements) | **selected (TRUE)** |
| `RSTXP-TDENHACT` | Display activated only | false |
| `RSTXP-TDNOENH` | Do Not Display Any | false |
| `CLS_SETTINGS-EDITOR_DISP_PERR` | Also display package errors | false |
| `SEWB_SLIN_CHECK-USE_WB_CHECKLIST` | Display extended program check messages | false |
| `G_DISPLAY_EDITOR_ERROR_MARKER` | Flag error messages in source code-based editor | false |

**Restore action:** select `SEUCUSTOM-ABAPCNTRL` ("Source Code-Based Editor"). Change nothing else.

Only `SEUCUSTOM-ABAPCNTRL` / `*SEUCUSTOM-PCMODE` is touched by this investigation.
Note `RSTXP-TDENHALL` is already "Display All", so captured source includes enhancement implementations inline.
