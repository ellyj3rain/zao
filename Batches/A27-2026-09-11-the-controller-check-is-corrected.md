# A27 - The controller check is corrected

| Field | Record |
| --- | --- |
| Batch | `A27` |
| Date | 2026-09-11 |
| Name | The controller check is corrected |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

`ZAO_Controller.lua` used the success flag from `pcall(instanceof)` as if it
were the result of `instanceof`. Every object therefore passed the zombie
check. The controller now reads the actual result and only drives
`IsoZombie` objects.

## What changed

- `ZAO_Controller.lua` reads the `instanceof` result.
- `ZAO_State.lua` and `tools/README.md` state the current runtime surfaces.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A27]` row.
- `tools/version_replay.py` classifies `[A27]`.

## Verification

The ZAO gate is clean.
