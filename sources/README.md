# Source Documents

Primary evidence for this project. Files are prefixed with their source ID so a claim citing `SRC-DOC-20260803-02` can be traced to the file without a lookup.

Registered in `../MEETING_INGEST.md`. Confidence rules in `../README.md §Evidence standard`.

## Originals

| Source ID | File | What it is | Status |
|---|---|---|---|
| `SRC-TECH-001` | `SRC-TECH-001_SAP_ABAP_OData_Technical_Specification.pdf` | Vendor-proposed ABAP/OData specification, v1.0, July 2026. No author, reviewer or approver named | **Assessed, 32 defects logged** — see `../SAP_API_DOSSIER.md` §Part A. Greenfield build instruction, not as-built. Do not implement as written |
| `SRC-DOC-20260803-01` | `SRC-DOC-20260803-01_CNF_Feature_to_SAP_Mapping.docx` | Feature → SAP table / T-code mapping: Login & Authorisation, Common Masters & KDS, Functionalities (MIGO, DI, Invoice, e-Invoice/e-Way, STO), 8 report visibilities, KDS reference index | **Authoritative for client configuration** |
| `SRC-DOC-20260803-02` | `SRC-DOC-20260803-02_CNF_KDS_Catalogue.xlsx` | **The KDS catalogue.** 11 sheets of real code values — SPI↔Sloc (`ZLETSPIMAP`), Plant↔Sloc (`T001L`), Sales area↔plant (`TVKWZ`), ↔sales office (`TVKBZ`), Incoterm↔plant (`ZISP`), Customer group (`T151`), vendor/customer master, Material Groups 1–5 (`TVM1`–`TVM5`), Nielsen indicator, Material freight group (`TMFG`) | **Highest-value document in the project.** This is what Q-021 / V-12 was asking for |
| `SRC-ARCH-20260803-01` | `SRC-ARCH-20260803-01_CNF_Architecture_Options_v1.2.pptx` | Three DSP data-integration options. **Option C selected** (D-014) — note the deck itself presents all three neutrally and does not mark a selection | Authoritative for the topology; selection is relayed |
| `SRC-MTG-20260803-01` | `SRC-MTG-20260803-01_transcript.en.txt` / `.hi.txt` / `.raw.json` | UI/UX design walkthrough. Hindi/Hinglish with English technical code-switching; Sarvam AI transcription (D-008), two passes. Diarized, timestamped | Reconciled in `../meetings/2026-08-03-ui-design-walkthrough.md`. Read the ASR-artifact table there before quoting |

## Not held here

| Source ID | Why |
|---|---|
| `SRC-MTG-20260803-01` audio | `Morecontext.m4a`, 27 MB. Excluded — binary, undiffable, and the transcripts are the usable artifact. Original in `C:\Users\sidmy\Downloads\` |
| `SRC-MTG-20260728-01..04`, `-SUM` | **Lost.** The 28 July recordings (`Chaayos_3/4/6`, `New_Recording_12`, `MEETING-SUMMARY.md`) are no longer present on disk. Every 28 July claim — including approved decisions **D-001 to D-006** — rests permanently on secondhand reconciliation in `../meetings/2026-07-28-design-walkthrough.md`. It cannot be re-adjudicated. Re-confirm those decisions with the business rather than treating the meeting note as primary |
| `SRC-BRD-001` | Business Requirements Document — **never supplied to anyone**. Largest documentary gap in the project |
| `SRC-CPI-001` | CPI interface workbook — **never supplied** |

## `extracted/`

Plain-text extractions of the Office documents, produced locally. An agent can read these directly without parsing OOXML. They are **derived, not primary** — where an extraction and its original disagree, the original wins.

| File | From |
|---|---|
| `SRC-DOC-20260803-01_extracted.txt` | The mapping docx — all five sections, tables flattened |
| `SRC-ARCH-20260803-01_extracted.txt` | The architecture deck — 9 slides incl. Option C detail |
| `KDS_00_Index.txt` … `KDS_10_Material_freight_group.txt` | One file per KDS workbook sheet. Large sheets truncated at 400 rows — go to the xlsx for the full set |

**Extraction caveat:** the KDS sheets were flattened cell-by-cell with column boundaries rendered as ` | `. Merged cells and multi-row headers may misalign. Verified spot-checks: SPI↔Sloc, Customer group, Material groups 1–5, Material freight group. The four 400-row sheets (Plant↔Sloc, Sales area↔plant, ↔sales office, Incoterm↔plant) were sampled, not fully verified.
