# A18 - The ZAO state producer

| Field | Record |
| --- | --- |
| Batch | `A18` |
| Date | 2026-09-11 |
| Name | The ZAO state producer |
| Status | Closed append-only batch - records and tools; no mod code |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Record

`tools/state_dump.py` emits one ZAO pathogen-state row per SAO decision
moment. The row is keyed by the SAO person id and the decision hour, and it
carries the pathogen facts SAO already records: infection, immune progress,
death, cause, turn, and the terminal state.

The ZAO-specific mutation fields stay null until ZAO has a real state surface
to read them from. No mutation state is invented here.

## What changed

- `tools/state_dump.py` emits the state row.
- `tools/README.md` describes it.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A18]` row.
- `tools/version_replay.py` classifies `[A18]`.

## No new border

A tool only, and one that writes no game state. The doc-currency and version
borders cover it. No mod code, no engine surface.
