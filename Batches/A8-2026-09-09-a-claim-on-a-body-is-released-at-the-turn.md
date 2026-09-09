# A8 - A claim on a body is released at the turn

| Field | Record |
| --- | --- |
| Batch | `A8` |
| Date | 2026-09-09 |
| Name | A claim on a body is released at the turn |
| Status | Closed append-only batch - verification only; no mod code |
| Threads | [`T-002`](THREADS.md#t-002), [`T-001`](THREADS.md#t-001) |

## Record

`[A7]` read Bandits through The Mutants' compatibility shim instead of
through Bandits. Bandits is installed, ships a `42.20` build - this
project's target build exactly - and reading it produces one correction
and one mechanism.

F-013 carries both.

## The correction

`[A7]` says The Mutants reverse-engineers Bandits **because Bandits
publishes nothing**, and that it publishes no claim API. Bandits
publishes four surfaces: the `Bandit` animation variable, carrying its
own comment saying it is for other mods; four modData keys; the
`GetBanditClusterData` global; and a `Bandit.*` shared namespace of
some twenty-five read functions. That is wider than Antibodies (F-011)
and wider than The Mutants itself.

The true statement is narrower and more useful. There is no single
canonical is-this-body-mine query, and The Mutants' three routes exist
for a **timing** reason its own comments state: Bandits writes its
brain during the spawn call while PZTheMutants classifies on a later
tick. A marker correct on tick two is useless to a reader on tick one,
and publishing more surface does not fix that.

`[A7]` stands as written; the ledgers are append-only.

**How the error happened**, because the shape is now four for four in
one session. `[A7]` searched one spelling, found what it was looking
for in one file, and wrote a claim about everything else in the tree.
Every one of today's corrections is that: an absence asserted from a
narrow grep. Before writing that something publishes nothing,
enumerate what it publishes. The line is in the catalog.

## The mechanism

A claim on a body is **released**. Bandits has a local function whose
own comment is *turns bandit into a zombie*; it clears the marker and
puts the body back to an ordinary walk type. A second release sits in
a deprovision path that also clears the reanimation flag.

So Bandits hands the body back at the moment ZAO exists to get right.
Its NPC dies and it stops owning the corpse - DR-004's seam, done by a
third party for its own people, in the same engine on the same build.

## What this changes about the fork `[A7]` opened

`[A7]` treated a claim as a property of a body. It is a property of a
body **at a time**. The Mutants' `isMutant` is true while the clothing
survives; Bandits' marker is true between spawn and death. Ownership
transfers, and the transfer is the turn.

Two consequences for whatever the operator decides:

- A claim query has to be re-askable rather than cached.
- A claim protocol needs a release as much as an assertion. Neither
  surface read so far has one. The Mutants' API cannot say *I have let
  this one go*, and Bandits' release is visible only as the absence of
  a variable that used to be there.

Nothing is designed here and the fork stays the operator's. What moves
is that the fork now has a shape rather than only a question.

## No new border

Same reason as `[A7]`: nothing here is behaviour, the tree has no mod
code, and a border asserting facts about a third-party mod would pin
this gate to a file that updates on somebody else's schedule.
