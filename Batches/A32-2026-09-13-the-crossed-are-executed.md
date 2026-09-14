# A32 - The crossed are executed

| Field | Record |
| --- | --- |
| Batch | `A32` |
| Date | 2026-09-13 |
| Name | The crossed are executed |
| Status | Closed append-only batch - runtime, from the totality program (operator ruling 2026-09-13) |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

The operator ruled on 2026-09-13 that the biggest oversight in the
runtime was the crossed's consciousness: "I think the biggest oversight
by me was suggesting the crossed don't have consciousness like a
survivor, just certain aspects of them are stripped" - and the sweep
that followed verified what the documents had already ruled
([MUTATION.md], carried by [`A11`], [`A12`], [`A13`]): the crossed
keep cognition and every capability; what is gone is humanity, burned
out by neuroinflammation; they organise, act with a person's
vocabulary, ignore the dead and use them, and work on the afflicted.
The runtime had the four-pillar mind ([A19],
`ZAO_Mind.lua`) and no consumer of it beyond gating stamps: a crossed
body was executed as an engine zombie with afflicted-preferring
targeting ([A29]'s fear-work), its organise, plan, hold ground, and
work together all design and no runtime.

This batch is the consumer. `ZAO_Crossed.lua` runs once per scan from
the controller, between the mind stamps and the form walk, and runs
the deliberate half of a crossed body's life from the mind's own
pillars - with the strips the rulings name implemented as omissions,
never gates: nothing in the pass consults trust for a target, nothing
protects anybody, and the noise-is-a-debt objection a living person
can hold (`SAO.Standing.roadworthy`'s `loudCeiling`) is simply not
passed - the crossed take the loudest runner in the dead group's
yard. What the pass does:

- **Use the dead.** With a target beyond the walk's reach and the
  drives for it (aggression plus initiative, already scaled by the
  episodic identity decay [DR-020] - a decayed mind gathers less for
  free), the body shouts on the engine's own world-sound channel
  (`WorldSoundManager.addSound`, a new `ZAOBridge.noise` verb - the
  same channel zombie hearing consumes) and the county's dead come
  toward it; the ordinary pursuit then carries them where the body
  is going. The horde is pointed, never scripted: the dead follow the
  engine's own attraction, and the body's walk is the walk it was
  already taking.
- **Work together.** A kin body's hunt is shared: the controller
  stamps the hunt's ground as plain coordinates on the hunting body,
  and a kin within the organise radius walks at the same ground. No
  engine object crosses bodies.
- **Organise.** Kin - other crossed bodies whose person died in the
  same group or ran in the same unit, the dead person's own facts -
  drift together when no hunt is on.
- **Hold ground.** The person's own home (`rec.homeX/homeY`, a
  durable record fact the county keeps) is the space they decided was
  valuable; a body with the discipline for it goes home. Where
  crossed bodies linger - home or anywhere - the controller now
  notes their presence on the same lingering roll the turned take
  ([DR-021]: formation is possible, never placed), so a crossed group
  holding a place is the settlement the rulings let emerge, and which
  groups settle and which stay nomadic is what their drives did.
- **The person's vocabulary.** Where the mind retains the drive verb
  and the dead group's yard holds a runner, the pass calls the
  sister's driving map ([`A13`]: the crossed are the named consumer):
  `SAOJavaBridge:driveBegin` with [C115]'s speed cap, the verdict
  honored - `DRIVE_STARTED` and the body takes the wheel and the
  pass ticks the trip, `NOT_A_SHELL` and the body walks, the honest
  fallback the sister's own goers follow. The map takes only her own
  player shells today; her widening is her half of the seam and is
  named in her records as this batch names ours. Until it lands the
  crossed walk, and the decline is logged once per body, never per
  scan.

Two defects the totality sweeps found close with the same batch:

- **Toughness is consumed.** `ZAODomainController.applyAttributes`
  applied Speed, Strength, and Hearing and silently dropped
  Toughness - the one enumerated attribute ([MUTATION.md]) with no
  consumer. Toughness is what it takes to put the body down: the
  health rides the same ±25% band every other attribute rides,
  applied the day the body is claimed, never retroactively.
- **`record.verbs` is the seam's content.** `ZAO_Mind` reads
  `record.verbs or {}`, and the sister's record carries no verbs, so
  the retained-vocabulary list is always empty at runtime. This batch
  consumes the list; the sister's batch stamps it from her own facts.
  Both halves are named; neither invents the other's.

Every figure in the pass is a named judgment on the engine's own
scales, the same law the sister's [B7] cold thresholds follow, and the
play receipts tune them: the shout's radius `8 + aggression × 12`
squares and volume 50; the noise cooldown 6 hours; the organise
radius 15 squares; the drive order range 40 squares and its cooldown
24 hours; the sister's own claim radius 15 for the car's re-find.

## What changed

- `mod/42.20/media/lua/client/ZAO_Crossed.lua` - new. The crossed
  decision pass: noise-gather, shared hunts, kin drift, hold ground,
  the drive order and the drive tick, all from the mind's pillars
  with the strips as omissions.
- `mod/42.20/media/lua/client/ZAO_Controller.lua` - the crossed pass
  is called between the mind stamps and the form walk (where it
  commits, the walk stands down for the scan); the hunt's ground is
  stamped as plain coordinates for kin to share; the settlement
  lingering gate extends to crossed bodies, the same roll, never
  another placement.
- `java/src/com/zao/bridge/ZAOBridge.java` - the `noise` verb:
  `WorldSoundManager.instance.addSound` on the engine's own channel,
  radius and volume set by the caller from the body's drives.
- `java/src/com/zao/engine/ZAODomainController.java` - the Toughness
  branch of `applyAttributes`.

## Verification

- The gate is clean at the new tip, including the Java build against
  the game's own jars (`WorldSoundManager.addSound` verified against
  the shipped `projectzomboid.jar` before the verb was written).
- The jar rebuilt under [A31]'s deterministic stamp and deployed,
  md5-verified repo-tree-to-install.
- The two runtime halves this batch names but cannot build are
  recorded as owed by the sister: the map's widening (`NOT_A_SHELL`)
  and the `record.verbs` stamp. Both are play-receipt-gated together
  with everything else; nothing here closes without the operator's
  receipts.

## Deferred verification

Runtime behavior is the operator's receipt boundary ([A21]'s law): a
mod-load test is a world start, and world starts are the operator's.
The crossed's execution is verified by the gate's structural pass and
awaits the same play receipts every runtime batch awaits.