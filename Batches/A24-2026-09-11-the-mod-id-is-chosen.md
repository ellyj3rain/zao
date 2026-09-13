# A24 - The mod id is chosen

| Field | Record |
| --- | --- |
| Batch | `A24` |
| Date | 2026-09-11 |
| Name | The mod id is chosen |
| Status | Closed append-only batch - records and mod metadata |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

The stable mod id is `ZombieAwareness`.

This closes the reserved mod-id fork. The mod's loadout name is now
**Zombie Awareness Overhaul**, and the development suffix is gone.

## What changed

- `mod/mod.info` and `mod/42.20/mod.info` use `id=ZombieAwareness`.
- `tools/deploy.sh` installs to `Zomboid/mods/ZombieAwareness`.
- `README.md` names the clean loadout.
- `DECISION_REGISTRY.md` gains DR-023.
- `ROADMAP.md` closes the mod-id fork.
- `SESSION_STATE.md` advances to this batch.
- `BATCH_LOG.md` gains the `[A24]` row.
- `tools/version_replay.py` classifies `[A24]`.

## Verification

The mod metadata is consistent across both `mod.info` files, and the ZAO gate
is clean.
