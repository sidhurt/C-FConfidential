# Meeting audio → transcript

How client meeting recordings become the `sources/SRC-MTG-*_transcript.*` files.

## The pipeline

Two Sarvam batch jobs run over the same audio — `transcribe` (Hindi/Hinglish, as
spoken) and `translate` (English). Neither pass is trustworthy alone. Cross-read
them: each catches the other's errors, and where they disagree on a technical term
the `hi` pass is usually right.

```powershell
# name the audio without spaces first - it is uploaded under its own file name
.\run-sarvam.ps1 -Mode transcribe -AudioPath 'C:\...\SRC-MTG-20260831-01.m4a' -OutDir '.\out'
.\run-sarvam.ps1 -Mode translate  -AudioPath 'C:\...\SRC-MTG-20260831-01.m4a' -OutDir '.\out'

.\format-transcript.ps1 -RawJson '.\out\transcribe\raw.json' -OutTxt '..\..\sources\SRC-MTG-20260831-01_transcript.hi.txt'
.\format-transcript.ps1 -RawJson '.\out\translate\raw.json'  -OutTxt '..\..\sources\SRC-MTG-20260831-01_transcript.en.txt'
```

Then copy `transcribe\raw.json` to `sources\SRC-MTG-*_transcript.raw.json` and
`translate\raw.json` to `sources\SRC-MTG-*_transcript.raw.en.json`, and add the
row to `MEETING_INGEST.md`.

`format-transcript.ps1` emits `[MM:SS] S<n>: text` (`[HH:MM:SS]` past an hour) from
the diarized entries, UTF-8 with BOM, matching every existing transcript in `sources/`.

## Constraints

This machine has no ffmpeg and no real Python — the `python` on PATH is the
Microsoft Store stub and it hangs. Chunking is therefore impossible; the batch API
is used because it accepts whole files up to about two hours. A 35-minute file
takes roughly five minutes per job, and the two jobs can run in parallel.

## What not to commit

The API key, the presigned Azure blob URLs, and the audio itself. `.gitignore`
keeps audio out; the transcripts under `sources/` are the committed record.

## Known ASR artifacts

Sarvam garbles the same proper nouns every time. Treat these as transcription
noise, not as evidence:

| Heard as | Actually |
|---|---|
| "app", "recipe", "SST" | SAP |
| "high bridge", "IBPS", "IBIS", "hybrid" | Hybris |
| "DSP", "VSP", "SDP" | Datasphere |
| "Meecom", "Migo", "MeeGo", "Ligo", "minor" | MIGO |
| "bapi goods movement under square" | `BAPI_GOODSMVT_CREATE` |
| "test directory", "tax directory" | SE37 test data directory |

Diarization is reliable for turn boundaries. Speaker **identity** is never stated —
`S0`, `S1`, `S2` are anonymous. Names spoken in a meeting are not mapped to speaker
IDs, so confirm attribution with Siddharth before weighting any claim by who said it.
