# A5 - The turned body's control surface, and the player's own dials

| Field | Record |
| --- | --- |
| Batch | `A5` |
| Date | 2026-09-09 |
| Name | The turned body's control surface, and the player's own dials |
| Status | Closed append-only batch - verification only; no mod code |
| Threads | [`T-002`](THREADS.md#t-002), [`T-001`](THREADS.md#t-001) |

## Record

G0 asks for the turn surface established from the installed build with
file-and-line evidence, and `[A2]` and `[A3]` established most of it:
reanimation is a timer on the corpse (F-001), the corpse's modData
rides the turn (F-002, F-007), the risen body is nameless (F-003,
F-008), `DoZombieStats()` re-rolls the per-body knobs during
reanimation (F-004), the per-body axes exist in vanilla's own
vocabulary (F-005), and the unloaded crowd is native and opaque
(F-006).

Two pieces of G0 were still open. This batch closes them and reports
the third as unchecked rather than leaving it to be discovered.

**The control surface.** `zombie.characters.IsoZombie` is driven by
target and path - `setTarget`, `getTarget`, `pathToCharacter`,
`pathToLocationF`, `setTargetSeenTime`, plus `setUseless` and the three
reanimation flags. That is the same shape SAO drives a living shell
with, which means G1 has a seam to be proven at rather than a
mechanism to be invented: whoever sets the target owns the body, and
two controllers setting it is exactly the defect the gate exists to
catch. F-009.

**The dials.** Four of the five shipped presets carry an identical
`ZombieLore` block of twenty-nine keys, and ten of them - `Cognition`,
`Memory`, `Sight`, `Hearing`, `Speed`, `Strength`, `Toughness`,
`Reanimate`, `Mortality`, `Transmission` - are already the player's own
words for what this project models. Registering a second set beside
them would ask a player the same question twice and put this model and
the engine's actuators into open disagreement, which is `[A3]`'s
correction made concrete.

And `SixMonthsLater` carries nineteen of the twenty-nine. A preset is
not a guarantee that a key is present, so every read has to survive its
absence or that save takes a nil through ten of them. F-010.

**What is unchecked.** What the loaded recovery mods expose. The
Antibodies family is not in the user's mods directory and the Workshop
directory holds numeric ids this batch did not resolve. The finding is
not that they expose nothing; it is that this batch could not see them,
and G0 is not closed until somebody can.

## The three projects

`PROJECTS.md` in `../survivor-awareness` now holds the architecture
across the three repositories - what SAO, ZAO and Speakeasy each own,
and the three seams between them. This repository's README points at
it. The edge it names that was written nowhere before is the one from
here to Speakeasy: a turned mind is a cognition with its inputs
failing, the same model under a transform rather than a second model,
and nothing should be designed there until G2 lands.

## No new border

The gate's structural Lua walk finds nothing while no Lua ships, which
is by design, and Border 1 already reads every root document against
`VERSION`. This batch adds two findings and a pointer; there is no
behaviour to hold, and a border over a `javap` reading would be a
second copy of the reading rather than a check on it.
