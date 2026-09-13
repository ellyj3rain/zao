# A21 - The development loadout

| Field | Record |
| --- | --- |
| Batch | `A21` |
| Date | 2026-09-11 |
| Name | The development loadout |
| Status | Closed append-only batch - implementation and records |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

ZAO gains a local development loadout. The temporary mod id is
`ZombieAwarenessDev`; the final id remains the operator's.

The loadout adds:

- a `mod.info` for local loading;
- a bound key, **O**, for the ZAO state panel;
- a state panel that shows the nearest SAO survivor's terminal state, decay
  state, current form, form performance, and visible forms;
- a `tools/deploy.sh` script that installs the development mod to the game's
  mods directory.

## What changed

- `mod/mod.info` and `mod/42.20/mod.info` name the temporary development build.
- `mod/42.20/media/lua/shared/ZAO_Binding.lua` binds **O**.
- `mod/42.20/media/lua/client/ZAO_Inspect.lua` opens the state panel.
- `tools/deploy.sh` installs the development build.
- `README.md` says how to load it.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A21]` row.
- `tools/version_replay.py` classifies `[A21]`.

## No new border

The existing Lua structural border and state-dump border cover the new files.

## Verification

`bash tools/check.sh` is clean.
