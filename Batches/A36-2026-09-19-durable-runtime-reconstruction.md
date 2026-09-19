# A36 - Durable/runtime reconstruction

| Field | Record |
| --- | --- |
| Batch | `A36` |
| Date | 2026-09-19 |
| Name | Durable/runtime reconstruction |
| Status | Closed implementation batch; loaded-world receipt pending |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Runtime ownership

ZAO now reconstructs its runtime projections from durable world state. Pathogen,
recovery, settlement and source records remain serialized authorities;
controllers, courses, settlement groups, loaded-body ownership and Java maps are
cleared and rebuilt when a new Lua environment or world begins. Course restore
uses durable recovery/body terminal state instead of retaining an object from
the prior world.

This complements SAO C55's graph, cache, pending-corpse and action treatment.
Neither repository serializes callbacks or live controller objects as history.

## Interrupted save generations

Afflicted return spans SAO global records, ZAO global pathogen/source records
and native reanimated-player state. The engine does not commit those surfaces as
one transaction. A36 adds a bounded write-ahead journal containing only return
identities: their SAO record slice, ZAO pathogen/recovery slice and exact source
receipt or explicit absence tombstone. Generation markers bind the global tables,
source record and native body to that journal.

`IsoCell.save` prepares the journal after Lua `OnSave` and before native body
persistence. The payload uses Kahlua's serializer, a format/version header and a
SHA-256 digest; the file is forced and atomically moved into place. On load,
replay occurs after global ModData is available and before native reanimated
players load. It can retain a matching source, replace stale ordinary or native
sources, reconstruct a missing source, retire a removed source or resume a held
source after cancellation. Existing worlds without markers or a journal remain
valid and migrate on their next save. A current marker without its valid journal
refuses rather than guessing.

## Verification

Border 8 verifies the installed engine lifecycle order and compiles the shipped
weave, journal, return-source and body code against the installed game and
ZombieBuddy jars. It executes the complete pairing matrix:

| Native source | Global records | Expected authority |
|---|---|---|
| old | old | prior generation |
| old | new | journaled new generation |
| new | old | journaled new generation |
| new | new | matching new generation |

Additional cases reconstruct a missing reanimated source, replace stale native
owners under old and new globals, discard a retired source, resume a cancelled
held source and replace the journal on repeated saves. Missing and corrupt
current journals reject. Mutation controls remove generation preparation,
replay and source-reconciliation branches and fail.

The runtime reconstruction probe separately creates a fresh Kahlua environment
and a second world and proves controller/course/settlement and Java-map teardown.
The full repository gate is the final batch check. These receipts do not claim a
rendered loaded-world return or repair A32's unreachable and incomplete Crossed
human action system.
