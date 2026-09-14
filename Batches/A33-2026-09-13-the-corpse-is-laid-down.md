# A33 - The corpse is laid down

| Field | Record |
| --- | --- |
| Batch | `A33` |
| Date | 2026-09-13 |
| Name | The corpse is laid down |
| Status | Closed append-only batch - runtime, the sister's `[C116]` return completed on this side |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

The operator ruled the afflicted just as important as the crossed, and
the sister's `[C116]` built her half: a person whose pathogen state
says afflicted is minted back where their risen corpse stands,
through the same materialize every awakening uses - the return is a
fact-reading, the pathogen licensed the reversion and the adoption
followed the state. Her batch named this side's half as `[A33]` owed,
mirroring the way `[A32]` named hers: ZAO owns the turned body, and
until this batch the risen corpse stayed - driven, stamped, and
lingered over by this controller - while its person stood in the
county again beside it. Two bodies for one person, both records
honest about the doubling and neither closing it.

This batch closes it. In the controller's scan, for a body whose
state says afflicted and whose person the sister's registry holds
again (`SAO.Body.get(personId)` - the minted returnee, registered
through her whole identity chain), the corpse is laid down:

- **The release is a fact-reading, not a decision** - the same law
  the return follows. Nothing here judges whether the person deserves
  their body back; the pathogen licensed the reversion, the sister's
  adoption minted the return, and this reads both facts and acts on
  them.
- **Removal, never a kill.** The laying-down is the sister's own
  despawn pair (`removeFromWorld`/`removeFromSquare`, her F-008
  idiom), and her law that removal is NOT death holds here exactly as
  it held in her Absorb (F-051): the person's death already ran its
  funnel - beliefs, voice, company, everything the death dropped stays
  dropped - and no death event fires on the release. The corpse goes
  into the ground it rose from; nothing is re-killed, nothing is
  resurrected, and the store keeps the afflicted state the live body
  still reads for its marks.
- **Her law "never removeFromWorld a corpse" holds on her side.** That
  is her controller's rule about her own people's bodies; this is the
  turned body this repo owns, and it is released only because its
  person stands in the county as themselves. The county's ground-dead
  - the corpses nobody returned to - are never touched: they have no
  sister registry entry, so the gate never fires for them.
- **The claim is forgotten with the body.** `controlled[personId]`
  clears, so the sister's next adoption sweep finds no corpse to mint
  against - there is nothing left to adopt; the person is already
  back. A reverted body whose person the sister has NOT re-adopted
  (her mod absent, her mint refused, her return not yet run) stays
  exactly as it was: driven with its residue, the honest state of a
  body waiting for a county that has not taken it back.

No dial gates the release, by the same law the sister's adoption is
ungated: the return is the pathogen's own fact, and the county does
not vote on it. The controller's own dials govern the scan as a whole
- with the controller or the mind turned off, the county keeps both
bodies, and both records stay honest about that too.

## What changed

- `mod/42.20/media/lua/client/ZAO_Controller.lua` - the release in the
  scan, between the state read and the driving block (a released body
  is never stamped, noted, settled or driven again); the file header
  names the laying-down.

## Verification

- Every surface used was verified against the installed jar before a
  line was written, the same law `[A32]`/`[C116]` follow:
  `IsoObject.removeFromWorld()`/`removeFromSquare()` (both on the
  common chain the IsoZombie inherits), and the sister's
  `SAO.Body.get` (registered by her materialize at
  `SAO_Body.lua`, the `[C8]` identity chain).
- The gate is clean at the new tip; the version machine derives
  0.3.1.0-pre-alpha (kohai - a coherent integration of the sister's
  adoption with this repo's body ownership; the capability boundary,
  the return itself, was the sister's minor `[C116]`).

## Deferred verification

Runtime behavior is the operator's receipt boundary ([A21]'s law): a
mod-load test is a world start, and world starts are the operator's.
The laying-down is verified by the gate's structural pass and awaits
the same play receipts the return itself awaits - one person coming
back, one corpse going down, watched in an ordinary county.

## Next

The afflicted among the living is the sister's next batch (her C117:
the house argument over a returned member, the cast-out and the
gather, the standing reaction) - her standing machinery, her batch to
build. On this side nothing is owed against `[A33]`; the pathogen's
own course continues its rulings in `[MUTATION.md]`'s order.