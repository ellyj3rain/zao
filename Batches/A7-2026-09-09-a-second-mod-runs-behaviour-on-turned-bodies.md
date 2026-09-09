# A7 - A second mod runs behaviour on turned bodies, and publishes a claim API

| Field | Record |
| --- | --- |
| Batch | `A7` |
| Date | 2026-09-09 |
| Name | A second mod runs behaviour on turned bodies, and publishes a claim API |
| Status | Closed append-only batch - verification only; no mod code |
| Threads | [`T-002`](THREADS.md#t-002), [`T-001`](THREADS.md#t-001) |

## Record

`The Mutants` (Workshop `3796669056`, `PZTheMutants`, `modversion=0.0.1`)
was published 2026-09-07 and is installed. It runs six behaviours on
turned bodies - 68 Lua files, 19,733 lines - and it is the first mod
found that occupies the seam G1 exists to prove and publishes a
contract for sharing it.

F-012 carries the reading. Nothing under a mod tree changes here,
because there is no mod tree yet; this is G0-class evidence arriving
after G0 closed, which is what an append-only findings ledger is for.

## Why this is worth a batch rather than a note

DR-004 rules that exactly one controller runs any body, and names Knox
Survivors as the mod that may be in the load order without owning the
infected. That ruling is right and its statement is one instance wide.
The Mutants is a second member of the same population, and it arrived
nine days after the ruling was written.

G1 asks for one brain per body **proven by observation**. Until now the
only other claimant named in this tree was Knox Survivors. There are
now two, they detect each other by hand, and neither knows about a
third. That is the shape of the problem rather than a fact about two
mods.

## What it does that this project should copy

`PZTheMutants.API` is a global with `API.VERSION = 1` and two read-only
functions. Any mod can ask whether a body is already claimed, and the
question is answered without loading anything.

`ForeignOwnership.isClaimed(zombie, outfitName)` returns
`claimed, owner, reason`. The reason is a string naming which of three
routes fired. A claim query that says **who** and **how** is a
different instrument from one that says yes or no, because the second
cannot be debugged from a log.

Neither costs much. Both are one small file.

## What it does that this project should not copy

`ForeignOwnership` is general in its name and one named mod in its
body: `local BANDITS_MOD_ID = "Bandits2"`, and a single implementation
behind the general entry point. Every new claimant needs a new branch
in somebody else's file, and the mod that ships second is the mod that
has to do the work. It is quadratic and it fails silently.

Identity by persistent outfit id is the second. The id is one packed
32-bit int that is also the body's clothing, and
`setPersistentOutfitID`, `dressInNamedOutfit` and
`dressInPersistentOutfitID` are all public on `IsoGameCharacter`. Any
mod re-dressing a body erases its identity with no error. F-012 sets
the three available channels side by side; modData is the only one that
gives each mod its own key space, and F-007 already established that it
rides the turn by the engine's own hand.

## What goes to the operator

**The named-door question from `[A6]` has a shipped precedent.** F-011
left it open whether naming a mod in code is acceptable when the only
door in is a named one. `PZM_ForeignOwnership` is a working answer from
another author: the name is a constant in one file dedicated to foreign
ownership, presence is a type test on a global, every read is
`pcall`-wrapped, and absence returns false rather than failing to load.
Whether ZAO adopts that shape is still the operator's call. It is no
longer an open question whether anyone has solved it.

**Whether ZAO publishes a claim API, and when.** The Mutants had to
write three heuristics to find Bandits' bodies because Bandits publishes
nothing. Anything that ships after ZAO will do the same to ZAO unless
ZAO publishes first. This is a design commitment about a public
surface, so it is the operator's, and it is cheap only while no mod
code exists.

## Two ledger gaps this batch found in passing

**`SESSION_STATE.md` named the wrong tip.** Its "As of" block said
`[A4]` while `[A6]` was closed, because `[A5]` and `[A6]` both appended
to Standing without moving the header. Border 1 holds version strings
and does not hold this, so it drifted silently for three batches. It
names `[A7]` now.

**`[A6]`'s three unresolved items were never entered in the fork
ledger.** F-011 handed the operator three decisions - the named door,
the overlapping mutation options, the version-pinned option prefix -
and `ROADMAP.md`'s fork table says it is the standing ledger of what
the operator has reserved or left open, asked before it is needed. None
of the three is in it. This batch entered the fork it produced itself
and did not enter `[A6]`'s, because writing three operator forks from
another batch's prose would be authoring the operator's reservations
rather than recording them. It is reported here so the gap is somebody's
to close deliberately.

## No new border

Nothing here is behaviour, and the tree still has no mod code. Border 1
holds the doc pack and runs unchanged. A border asserting facts about a
third-party mod would pin this tree's gate to a file outside it that
updates on somebody else's schedule, which is the failure `[A6]` already
recorded about version-pinned option names.

The instrument used is worth recording, because it failed first. The
`javap` invoked from the game's own `jre64/bin` does not exist there -
that directory ships a JRE without the tool - and the shell returned an
empty result rather than an error the first time it was read. Two
"no such method" conclusions were drawn from it before the path was
checked. Both were false, and the real signatures contradicted them.
The instrument is `JetBrains/Java/bin/javap`, which is the path
`tools/build-java.sh` in the sister already uses, and a resolving class
was counted before any absence was believed.
