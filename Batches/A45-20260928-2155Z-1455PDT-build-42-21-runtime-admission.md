# A45 - Build 42.21 runtime admission

| Field | Record |
|---|---|
| Batch | `A45` |
| Timestamp | 2026-09-28 21:55 UTC / 14:55 PDT |
| Name | Build 42.21 runtime admission |
| Status | Closed; full gate and loaded-cohort verification passed |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Runtime admission

Both shipped `mod.info` descriptors now admit Build 42.21 while retaining
Build 42.20 as the minimum. A full SAO living-world study requested
`ZombieAwareness` on the installed 42.21 engine, but the engine omitted ZAO
from its saved load order because the prior descriptor ended at 42.20. This
batch corrects that cohort boundary.

The corrected declaration exposed a second compatibility defect. Build 42.21
removed `ZombiePopulationManager.beginSaveRealZombies()` and moved current-body
selection into `packRealZombies(List)`. ZAO's return-source weave still targeted
the deleted 42.20 selector. It now accepts either exact engine topology. The
42.21 path checkpoints current held sources, copies the engine-supplied list,
excludes only sources whose checkpoint identity matches, and gives that copy to
the native packer. The 42.20 begin-save and cell selectors remain guarded.
ZAO behavior, person state, planning and action families do not change.

## Verification

The version machine and document border bind both descriptors to the derived
ZAO version. The native return-source probe executes the installed 42.21
`packRealZombies(List)` method with one held and one ordinary body, then checks
that only the ordinary persistent id is packed. Named controls remove the
packed-list selector, the cell-save checkpoint, and the ordinary held-source
exclusion independently. The full sixteen-border repository gate passes. The
same full living-world cohort that exposed the omission preserved
`ZombieAwareness` in its saved mod list on Build 42.21 and completed with exit
code zero and an empty runtime-error scan. Its exact report, observation and
log hashes are retained by SAO C98's loaded receipt.

No scenario or dataset rule is admitted by this compatibility correction.

## Version

This is an in-place runtime admission correction and therefore a patch unit.
