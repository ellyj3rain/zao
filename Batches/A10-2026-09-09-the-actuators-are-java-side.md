# A10 - The actuators are Java-side

| Field | Record |
| --- | --- |
| Batch | `A10` |
| Date | 2026-09-09 |
| Name | The actuators are Java-side |
| Status | Closed append-only batch - verification only; no mod code |
| Threads | [`T-002`](THREADS.md#t-002), [`T-001`](THREADS.md#t-001) |

## Record

`ENGINE_CONTRACT.md` §9 listed one fact as unchecked and named what it
decides: whether the per-body axes are driven from Lua or from Java.
F-005 had found the six fields at `[A2]` and left the question open,
because whether Kahlua reaches public FIELDS rather than methods was
never established.

It was answerable with `javap`, and the answer is Java.

## What the check found

`IsoZombie` declares `speedType`, `strength`, `cognition`, `memory`,
`sight` and `hearing` as public mutable ints. **Only one of them has an
accessor.** `getSpeedType()` exists; `getStrength`, `getCognition`,
`getMemory`, `getSight` and `getHearing` do not, on `IsoZombie` or
anywhere above it - `IsoGameCharacter` and `IsoMovingObject` were both
checked and declare none. No setter exists for any of the six.
`setSpeedTypeFromWalkType()` derives that field from a walk-type string
and is not a setter for it.

`zombie.Lua.LuaManager$Exposer` extends Kahlua's
`LuaJavaClassExposer`, whose entire public exposure surface is
method-shaped.

So from Lua a mod can read one of the six and reach none of the other
five in either direction, and can write none of them at all.

## Which half of that carries the finding

The exposer having no field-exposing entry point is an **absence**, and
this session has five recorded instances of an absence asserted from a
narrow search. It is not load-bearing here and F-014 says so: five
actuators with no accessor anywhere in the inheritance chain are
unreachable by a method-based binding whatever else that binding does.
The positive test carries it; the negative is corroboration.

## What this settles, and what it does not

Any projection from this project's axes onto the per-body actuators is
Java-side. That is not a preference and not a recommendation - it is
the only reachable path, and the runtime that already loads Java for
the sister is ZombieBuddy, which is MIT (`CREDITS.md`).

**It settles nothing about the axes themselves.** What they are remains
the operator's, open in `ROADMAP.md`'s fork ledger. This batch closes
an engine question that the design was waiting on and answers no design
question of its own.

## No new border

A `javap` reading is structural evidence, not behaviour, and the tree
still has no mod code. `ENGINE_CONTRACT.md` §9's open list is one
shorter.
