# A26 - The defaults are chosen

| Field | Record |
| --- | --- |
| Batch | `A26` |
| Date | 2026-09-11 |
| Name | The defaults are chosen |
| Status | Closed append-only batch - records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO's playable defaults are:

- the form roll is on;
- the mutation odds are 10%;
- the runtime controller is on;
- the world-space overlay is on;
- the state panel is bound to **O**.

## What changed

- `DECISION_REGISTRY.md` gains DR-025.
- `ROADMAP.md` closes the enable-defaults fork.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A26]` row.
- `tools/version_replay.py` classifies `[A26]`.

## Verification

The defaults match the shipped code and the ZAO gate is clean.
