| Document | Zombie Awareness Overhaul Credits |
|---|---|
| Version | `0.5.3.0-pre-alpha` |
| Author | ellyj3rain |
| Repository | `CREDITS.md` |
| Status | CANONICAL - attribution and integration status per source. |

# Credits

**Licence.** This mod is GPL-3.0; the full text is in `LICENSE`.
Components below retain their own terms where those are more specific.

Zombie Awareness uses work by other creators. Thanks to all of them.

**What this project is doing with them.** This is not a collection of
ported mods. The Workshop already holds good answers to narrow
questions - what a special infected does, how a hostile fights, how an
infection course runs, how a companion takes orders - and each answer
arrives with its own small world-model attached: its own way of marking
a body, its own taxonomy, its own reason a population exists. Four good
mods running together produce four unrelated ontologies in one county.

What is built here is the county those answers can be true inside at
the same time: one identity per person, one owner per body, one causal
story for how somebody ended up the way they are. Most entries below
therefore take nothing at all. Being listed here is an acknowledgement
of work this project is built to sit with, not a claim that any of it
is present in this tree.

Each entry states its own terms and its own integration status.
Inspection is not use.

---

## ZombieBuddy
Andrey "Zed" Zaikin. https://github.com/zed-0xff/ZombieBuddy - **MIT**,
(c) 2025. Licence text ships in the mod at `mods/ZombieBuddy/LICENSE.txt`.

*Terms:* MIT - use, copy, modify, merge, publish, distribute,
sublicense, with the notice retained. GPL-3.0 compatible.

*Used for:* the Java runtime. A ByteBuddy agent that patches game
classes at runtime, exposes Java to Lua, and loads a mod's own jar from
`media/java/`.

*Status:* in use since `[A28]` - `ZAO.jar` loads through it and the
bridge reaches Lua through its exposer. Also in use in the sister,
which states it as a requirement.

## Antibodies
lonegamedev. https://github.com/lonegamedev/pz_mod_antibodies - **MIT**.
Workshop `2392676812`.

*Terms:* MIT on the public repository. The Workshop page states no
terms; the repository is the governing statement.

*Used for:* nothing taken. Read at `[A6]`; F-011 records what it
exposes.

*How it fits:* an infection course is one of the narrow questions
answered well elsewhere. DR-005 makes its antibody, recovery, cure and
repeat-infection state an input where the mod is loaded, and ZAO runs
its own course where it is not - so a player who has it keeps the
course they already know, expressed through this project's own record
of who the person is.

*Status:* not integrated; read only.

## The Mutants
SiaCatty. Workshop `3796669056`, mod id `PZTheMutants`.

*Terms:* the Workshop page and the mod tree state none - no licence
file, and the description carries no reuse statement. Its own credits
note the sound effects were produced with ElevenLabs, whose terms
travel with them.

*Used for:* the capability shapes, at the behavior level (DR-017). The
six forms' signature acts - what triggers them, their phase
structures, their effects - were studied from the installed mod and
re-implemented from scratch in this project's own code on public
engine APIs at `[A29]`. **No code, media, or sounds are taken**: the
work here is a re-implementation, the names and categories are not
carried across, and the source mod's files appear nowhere in this
tree. Every engine call is this project's own reading of the engine's
public surface, and where the source act is animation-driven this
project states its pathing substitute rather than hiding it
(`[A29]`, Honest limits).

*How it fits:* the valuable part is the engineering - a body that
leaps a fence, charges in a line, resists a bullet, cries where it
sits. Names and categories are not carried across and cost nothing to
drop (DR-014). What a body here does follows from who the person was
and how far the rot has gone, never from a species-level table
(DR-002, DR-008), so the question this project answers is which
capability a particular body ended up with and why - and a worked
implementation of the capability itself is exactly the expensive thing
worth having.

*Status:* **re-implemented, not ported.** The forms enter through the
operator-ratified source port (DR-017): capability shapes re-caused
under this project's own ontology, zero files copied. The author's
work is credited as the origin of the six forms' behavioral design,
and this entry is the precise, entry-by-entry naming the posture
requires.

## Bandits
Slayer (Piotr Pawłowski). Workshop `3268487204`, mod id `Bandits2`.

*Terms, as the author states them:* the work is copyrighted, is not to
be reuploaded without his written permission, and is not authorised for
posting on Steam except by his own account. That is a restriction on
redistribution and reposting. This project redistributes none of it.

*Used for:* nothing taken. Read at `[A8]`; F-013 records its claim
surface and the mechanism it demonstrates - it releases a body at the
turn, which is DR-004's seam done independently.

*How it fits:* the shapes are useful and the production is not. This
project does not want hostiles placed. It wants the conditions under
which somebody becomes one, so that a bandit is something the county
produced. Bandits answers a different question well, and is treated as
a compatibility target - a mod many players run, which should work
alongside this one - and as prior art.

*Status:* not integrated; read only.

## Knox Survivors
.exe. Workshop `3749727604`, mod id `KnoxSurvivors`. Launcher source at
https://github.com/exe-create/KnoxSurvivorsLauncher.

*Terms:* none stated on the Workshop page, and the public launcher
repository declares none.

*Used for:* nothing taken. Read for two things: its entire save state
sits under one namespaced modData key, and it deliberately leaves a
dead member's body for normal cleanup and reanimation rather than
deleting it - a second independent instance of releasing a body at the
turn.

*How it fits:* DR-004 names it as a mod that may be in the load order
without owning the infected. The sister holds its own integration
facts.

*Status:* not integrated; reference-read only.

## Special Zombies Framework
OO. Workshop `3783282009`, mod id `SpecialZombiesB42`.

*Terms:* none stated on the Workshop page.

*Used for:* nothing taken. Audited as the other structural answer to
the problem The Mutants solves - one framework holding registration,
spawning and the shared runtime, with each type shipping as its own mod
on top, and identity carried on server-managed online zombie ids rather
than outfit ids.

*Status:* not integrated; audited only.

---

## On removal

Any author listed here may have their work removed from this project on
request, immediately and without argument. Where an entry says nothing
was taken, there is nothing to remove and the entry itself will be
withdrawn on request.

## Not included

Anything this project does that resembles another mod's work is written
from scratch. A mod read for evidence is named in `FINDINGS.md` with
what was verified against it; being named there or here is not a claim
that its code or assets are present in this tree.
