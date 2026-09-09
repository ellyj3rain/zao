# A6 - Antibodies is installed, and G0 closes

| Field | Record |
| --- | --- |
| Batch | `A6` |
| Date | 2026-09-09 |
| Name | Antibodies is installed, and G0 closes |
| Status | Closed append-only batch - verification only; no mod code |
| Threads | [`T-002`](THREADS.md#t-002), [`T-001`](THREADS.md#t-001) |

## Record

`[A5]` reported the last piece of G0 - what the loaded recovery mods
expose - as UNCHECKED, on the ground that the Antibodies family was not
in the user's `mods` directory. It is installed. It is in the Workshop
tree, under a numeric id, which is where a subscribed mod lives:
`2392676812`, `Antibodies (v1.97)` by lonegamedev, shipping two builds
under `mods/lgd_antibodies/`.

The reported reason was wrong and the report was right to exist:
UNCHECKED said "this batch could not see them" rather than "they expose
nothing", so it named a gap somebody could close instead of a fact
somebody would have to falsify. It took one directory listing.

## What it exposes

**No API.** Every module in the B42.13 build is `require`-scoped, so
nothing reaches a consumer through a global. The only globals are
`AntibodiesServer` and seven timed-action hooks.

**State on the character.** `player:getModData().Antibodies`, with the
medical file at `.medicalFile` - a class instance with a metatable,
rehydrated on load and carrying its own migration path across mod
versions. Readable by anything holding the character, and readable only
by naming the mod.

**Sixty-seven sandbox options**, every one prefixed
`lgd_antibodies_194_`, where `194` is the mod's own options version.

F-011 holds the detail.

## Three things for the operator, left open on purpose

**Reading it names a mod in code.** The house discipline is that a mod
is never named in logic - property, not name. `getModData().Antibodies`
is a name. DR-005 ruled recovery mods inputs where loaded and never
dependencies, and did not anticipate that the only door in is a named
one. Whether a named read behind a presence check is acceptable, or
whether something property-shaped has to be found, is a decision.

**Its mutation axes overlap the second mechanism.**
`mutation_effect`, `mutation_threshold` and `mutation_start` already
model the pathogen mutating, and DR-008 reserves mutation's axes and
outcomes to the operator. Two models of one thing beside each other is
a state to decide about before anything is built.

**Version pinning.** Every option name carries `194`. A read that
survives the mod updating needs the prefix discovered rather than
typed, and nothing publishes it.

## G0

Closed. Every piece has evidence: F-001 to F-008 for the turn, F-009
for the control surface, F-010 for the player's own dials, F-011 for
the recovery mods. No mod code exists, which is what the gate ladder
asks for at this point.

## No new border

Nothing here is behaviour. Border 1 reads every root document against
`VERSION`; a border over a directory listing and a set of option names
would be a second copy of the reading rather than a check on it.
