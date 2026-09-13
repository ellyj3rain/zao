# A22 - The form overlay

| Field | Record |
| --- | --- |
| Batch | `A22` |
| Date | 2026-09-11 |
| Name | The form overlay |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO now shows the pathogen state in the world. `ZAO_Overlay.lua` draws the
current form and its normalized performance above every nearby SAO body that
carries a form.

The form roll is corrected to match the mutation system: a body carries a
form only when the pathogen has already acted on it — infected, dead, or
turned. Healthy survivors no longer receive a form.

## What changed

- `mod/42.20/media/lua/client/ZAO_Overlay.lua` draws the form overlay.
- `ZAO_Forms.lua` gates the roll on infection, death, or turn.
- `state_dump.py` and `state_dump_test.py` mirror that gate.
- `FORMS.md` states the gate.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A22]` row.
- `tools/version_replay.py` classifies `[A22]`.

## Verification

`bash tools/check.sh` is clean.
