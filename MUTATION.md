| Document | Zombie Awareness Overhaul Mutation System |
|---|---|
| Version | `0.2.0.2-pre-alpha` |
| Author | ellyj3rain |
| Repository | `MUTATION.md` |
| Status | CANONICAL - the system as the operator defined it on 2026-09-09. Specifics not yet ratified into `DECISION_REGISTRY.md` are marked. |

# The mutation system

What the pathogen does to a body, and what that body becomes.

This is the operator's definition, recorded as given. Where a number is
mentioned it is a dial rather than a value; almost everything here is
controllable, and the defaults are stated as defaults.

## Infection happens more than once

Catching Knox is a repeated event, not a single one. Fighting one off
does not put a person back where they started.

- Survive a set number of infections and the body becomes **resistant**.
- Survive more and it becomes **immune**.

Both counts are dials.

## What every infection rolls for

Every infection, from a body that has not already mutated, carries the
same odds of producing a mutation. Which mutations are available is a
gradient, and at baseline the odds across it are uniform. The odds are a
dial.

**Crossed carries its own odds** and is rarer than the rest by default.

**And every infection carries a random variable of its own.** Most
infections do not have it. One that does makes the body sicker faster,
and does not stop at death - it carries the body *past* death into the
crossed state.

## The gradient

Two kinds of thing sit on it, reached differently:

- **Mutations that give a body something it can do.** A body that leaps,
  one that charges, one that is hard to put down. These are built from
  the models and animations already held, altered rather than adopted
  whole.
- **Mutations that only make a body more of what it was.** Faster,
  stronger, tougher, sharper hearing. No new capability - the same body
  turned up.

A body that leaps and a body that is merely very fast are both on the
gradient, arrived at by different routes.

**The forms enter through a source port.** The mutants mod's forms and
animations are raw material for this gradient. Attributes and forms are
distinct but linked: a bruiser can look the part and be the part, and
attributes and animations can also be conferred non-physiognomically.
Attribution lands in `CREDITS.md` when source is used, and every ported
capability is re-caused under this project's own ontology (DR-014).

**The contents are enumerated from what is possible.** What sits on the
gradient is enumerated from what can be made possible, using the ported
forms and the suggested concepts as the basis for variety among the
known types and for expanding beyond them.

## Integration with the branching graph

The pathogen owns the mutation roll. The living branching graph does not
choose a form.

- The default roll is uniform across the gradient; sandbox settings may
  weight it.
- The pathogen also owns the roll for form performance.
- Crossed is a terminal pathogen state. A crossed body does not mutate
  further and does not organize around forms. A crossed body may
  instrumentalize or value a unique form in another body.
- Retained form traits are state, not new branches.
- Capability forms and attribute mutations stack.
- A form is a visible fact. It enters Perception and changes pressure
  inside the branching graph.

## Implemented enumeration

The runtime gradient carries two enumerated kinds:

- **Capability forms:** Puker, Husk, Skitter, Wrecker, Leaper, and Weeper.
- **Attribute mutations:** Speed, Strength, Toughness, and Hearing.

A pathogen event can give a body one capability form and one attribute
mutation. Capability forms and attribute mutations therefore stack. A
body without a capability form can still carry an attribute mutation, so
an ordinary turned body can express a partial ability before it embodies
a final form.

The state is event-driven. Infection, death, and turn create it; daily
advancement grows the form, decays human capability, advances passive
decay, and can revert a mutant to afflicted. Reversion is a random event,
with the retained ability inversely related to the performance the body
had reached.

Recovery is an event too. A body that survives keeps the state the pathogen
already changed; survival does not erase the fact that the pathogen acted.

Both kinds are visible facts. A capability form and its attribute mutations
enter Perception together and change pressure inside the living branching
graph.

## Death is not always required

Most mutations wait for the body to die and take effect as it rises.

**Some do not.** A living body can change without dying first, and
whatever produces the crossed is one of those - "past death" means the
body did not stop there, not that it rose afterward.

## The two ends

The gradient runs between two states that are opposites in one specific
way: **how much of a person is left**. Appearance is independent of it,
and the two ends are the two ways appearance and humanity can be
maximally wrong about each other.

### Crossed

Reached by going past death rather than stopping at it.

Keeps cognition. Keeps every capability. Keeps the appearance of a
person - a hollowed face and a wrong skin tone, but a human being to
look at. Every drive intact.

What is gone is humanity, burned out by neuroinflammation. **Not a
zombie and not a human.** A third thing to be afraid of, distinct from
raiders and distinct from the dead.

### Afflicted

Reached by regression - a body that turned or mutated and came back,
arriving short of human.

Lessened capacity. Ghoul-shaped. Sometimes passively infectious to be
near. **And a person again**, which is the whole of the tragedy: they
have their humanity back and cannot express it among survivors, because
of what survivors see.

An afflicted body **cannot become one of the dead**. Its chance of
becoming crossed is **higher than anyone's** by default, and that is a
dial. It is the thing they are most afraid of.

By default the afflicted state is where they stay - the only way out of
it is crossed. That default is controllable.

## Where capability comes from

For both ends, and for everything between: **what remains of the person
decides how capable the thing is.** A capable person makes a capable
crossed and a capable afflicted. Nothing is dealt a competence.

This is DR-002 carried past the turn: the record is the person, and what
survives of it is what the body has to work with.

## The afflicted among the living

**A house decides, and can split over it.** When one of a house's own
becomes afflicted, the people who loved them argue with the people who
are afraid of them. It can go either way and it can break the house.
The sister already has houses that quarrel and divide.

**They are driven to gather.** A cast-out afflicted seeks others like
them, and seeks places survivors will not go - the sewers, the ruins,
the edges. Both drives are real.

**Success is never encoded.** Whether a shanty town actually forms is an
outcome, never a placement. This is DR-037's law in the sister, applied
here: a settlement is what these people did, or it does not exist.

**What holds a settlement together is necessity.** When one forms, the
members stay because they need it, and the mechanics of holding follow
from what they need.

**A returned mutant is one of the afflicted.** A mutant-form body can
come back, and a returned mutant diversifies how the afflicted present
and the capabilities they carry forward.

## The crossed

**They organise**, and that is what makes them the worst thing in the
county. They plan, hold ground, and work together, with nothing
restraining any of it.

**They act with a person's vocabulary.** They drive. They plant
explosives. They use loudspeakers. Mechanically this is the sister's own
survivor machinery with what humanity gave it stripped out - no fear for
others, no loyalty, no restraint.

**The dead do not concern them.** By default they ignore the dead and
hunt the living; this is controllable. In practice they are largely
invisible to the dead and use them: a horde is not a hazard to a crossed
one, it is something to point at somebody else.

**They work on the afflicted.** Deliberately, on the fear of becoming
what they are. This needs no new machinery: it raises fear and taxes
moodles, and moodles already feed susceptibility in the infection model
this project absorbed. Torment makes the thing they dread more likely
through a mechanism that already exists.

## Identity decay

The turning and the return already fracture and disorganize a person's
memory. Not every afflicted body loses more over time.

**Where further loss occurs, which axis it loses varies per body.** Some
forget who they were and keep what they can do. Some remember
everything - the house, the people
who turned them away - and lose the ability to act on any of it.

**And the further decay itself is episodic rather than steady.** How often an
episode happens, and how much it fragments when it does, are both dials.
Beyond them the process is genuinely random.

## The player

The player walks the same road. They can go past death into crossed, and
they can regress into afflicted, and they live with what either means.

## What can be seen

- **Early, it takes a medic.** First Aid reads a body before anything
  shows.
- **Late, anyone can see it.** Past a point it is simply visible.
- **A skilled enough player is shown real chances**, not only symptoms.

## The dials

Everything below is controllable. The defaults are the operator's
(DR-019, ratified 2026-09-11): resistance at **2** survived infections,
immunity at **5**, mutation odds **10%-or-lower** at baseline, crossed
rarity **2.5%** as the per-infection variable, afflicted susceptibility
**5×**, identity decay rare and mild.

| Dial | Default |
|---|---|
| infections survived before resistance | 2 |
| infections survived before immunity | 5 |
| odds of each mutation on the gradient | 10% or lower (0.10), uniform at baseline |
| odds of crossed | 2.5%, the per-infection random variable |
| an afflicted body's susceptibility to crossed | 5× |
| whether an afflicted body can return further than afflicted | no |
| whether the crossed engage the dead | they do not |
| how often an identity-decay episode happens | 1% per advanced day |
| how much it fragments when it does | 0.10 off one or two axes |
| odds a lingering turned group forms a settlement | 2% |

The daily advancement follows the registry's extrapolation rule from the
baseline odds, and each rate is its own dial: growth runs at the
baseline odds (**0.10**), passive decay at a tenth of it (**0.01**),
reversion at a tenth (**0.01**), the outlier correction at a fifth
(**0.02**). Which capability form a mutation lands on is a weighted
roll - uniform at baseline (every form weight **1.0**), weightable per
form in the sandbox.

## Where this lives

**ZAO owns both the crossed and the afflicted.** Everything past
infection belongs to the project that owns the pathogen, including the
ones who came back.

**That opens a second seam between the projects.** `PROJECTS.md` lists
one crossing, the turn. There is now another, running the other way: a
person becomes ZAO's while remaining inside the sister's county - in a
house, holding bonds, being argued over. The sister's machinery for
houses, standing, fear and temperament reaches a body this project owns.

## The second seam, defined

The seam *Where this lives* opened. Ruled on by the operator on
2026-09-09, under one principle of their own framing: three
repositories, one project, and each machinery runs what it owns.

**SAO executes the afflicted.** A person again is a person - the four
pillars run them, the house argues over them because they never left
the county's machinery, and their bonds and records keep their
provenance.

**This project owns the pathogen state on an afflicted body.** The
susceptibility to crossed, the passive infection, the identity-decay
dials - what the pathogen did and still threatens is here, and the
behavior is the sister's to run. The state is the boundary the claim
surface lives on, and its concrete shape stays with F-012 until mod
code is near.

**This project executes the crossed.** They came through death as the
risen did, and exactly one controller runs any body.

**The crossed's vocabulary is a bidirectional goal.** The direction is
ratified: read the sister's action machinery, stripped of what
humanity gave it, copying no files - the turn's pattern extended from
the record to the living vocabulary. The sister has mapped driving:
`[C82]`, at their `F-067`, found no gate on the wheel path that
requires a player - every identity gate exists to exclude the blocked
local player - so the doorway is surface-mapped and its live receipt
is owed, no shipped code exercising it. What the crossed need from
driving rides in the record as named consumers of that map;
explosives and loudspeakers remain unmapped, so the seam still runs
two ways in time for them, and neither side invents its half alone.

**How the crossed hold ground is variable, and the variability is the
design.** They still enjoy things and have leisure, differently. Their
shifted needs reshape how they live in a space they have decided is
valuable to them. Some groups settle; some stay nomadic. Which one a
crossed group does is what its drives did, never a placement - DR-037's
law, applied to them as to every arrangement in the county.

## What is not defined yet

- The names a player sees. The substance is defined by the forms
  themselves; the words are not yet chosen.

The numbers are defined (DR-019 above), and the gradient's contents are
enumerated in the runtime as the six capability forms and four attribute
mutations. What remains open is the second seam's far side: the crossed's
living vocabulary - driving is mapped (`C82`, surface-mapped at the
sister's `F-067`), explosives and loudspeakers are not - and ZAO's half
of that seam is the named consumers in the record, never an invented
implementation.
