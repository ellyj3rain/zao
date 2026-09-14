| Document | Zombie Awareness Overhaul Findings |
|---|---|
| Version | `0.3.1.0-pre-alpha` |
| Author | ellyj3rain |
| Repository | `FINDINGS.md` |
| Status | CANONICAL, APPEND-ONLY - verified engine findings from F-001. |

# Findings

Verified engine findings, numbered from F-001. A finding is admitted when it
is reproducible from stated inputs and its verification method is recorded
(`GOVERNANCE.md`, evidence standard).

Left empty by design at `[A1]`; the [A2] modeling pass admitted the first
entries. Structural findings (bytecode, shipped files) are marked so; no
finding below has a live receipt yet. Method note: "hand-checked" means
re-derived in this repository's own [A2] disassembly pass, not carried from
a sweep's report. `ENGINE_CONTRACT.md` holds each finding's full context.

---

## F-001 — Reanimation is a timer on the corpse, and Lua can set it

**Verified** [A2], structural. `IsoDeadBody.update()` compares private
`reanimateTime` against `GameTime.getWorldAgeHours()` and calls
`reanimate()`; `reanimateNow()/reanimateLater()` set the timer; there is no
`shouldReanimate()`. Shipped Lua calls `body:reanimateNow()`
(`DebugContextMenu.lua:680-688`) and `zombie:setReanimateTimer(s)`
(`Tutorial/Steps.lua:922,962,1282`). Method: `javap -p -c` on the installed
jar; shipped-Lua reads.

## F-002 — The corpse's modData rides the turn; nothing fills it for you

*Corrected by F-007 ([A3]): the "nothing fills it" half is false — a third
`copyTable` site fills the corpse from the character unconditionally.*

**Verified** [A2], hand-checked. `IsoDeadBody.reanimate()` copies the
corpse's modData onto the new zombie via `LuaManager.copyTable`
(offsets 234-242: `zombie.getModData() ← this.getModData()`). The class
contains exactly two `copyTable` sites (`reanimate()`, `reanimateAnimal()`),
so the corpse's own modData is NOT populated from the dying character — a
mod stamps the corpse itself (`Events.OnDeadBodySpawn` hands the body;
shipped subscriber `ISWorldObjectContextMenu.lua:2795`). This is ZAO's
identity channel through the turn.

## F-003 — Names do not survive the turn; player corpses carry no descriptor

*Corrected by F-008 ([A3]): the corpse-side half is false — the descriptor
copy is unguarded and player corpses carry the full descriptor. The
zombie-side half (the risen body's fresh, nameless descriptor) stands.*

**Verified** [A2], hand-checked. `reanimate()` constructs a fresh
`SurvivorDesc` copying only gender (offset 56) and voice prefix (60-74) —
no forename/surname call exists in the method. The `IsoDeadBody`
constructor writes `desc` only under `instanceof IsoZombie` (offset 626)
and `instanceof IsoSurvivor` (offset 1019); `getDescriptor()` is a bare
field read. An `IsoPlayer`-class corpse therefore has a null descriptor,
and its zombie a nameless fresh one. Consequence: any turn-recognition
chain built on descriptor names is structurally dead for player-backed
NPCs — including the sister's (`SAO_SEAM_AUDIT.md` §4, reported upstream).

## F-004 — DoZombieStats() re-rolls the per-body knobs, during reanimation

**Verified** [A2], call site hand-checked. `reanimate()` invokes
`IsoZombie.DoZombieStats()` at offset 374; that method reads
`SandboxOptions.instance.lore` values into the public `cognition`,
`strength`, `doorOpeningPercentage` fields (per-field pattern from the [A2]
sweep's disassembly). Any per-body override must land after reanimation and
be re-applied after every engine re-roll; other call sites UNCHECKED
(`ENGINE_CONTRACT.md` §10.5).

## F-005 — The per-body axes already exist, in vanilla's own vocabulary

**Verified** [A2], structural (javap). `IsoZombie` carries public mutable
int fields `speedType, strength, cognition, memory, hearing, sight` —
per-body versions of the same axes the sandbox lore page sets fleet-wide.
`IsoZombie` is final: ZAO drives real zombies, no subclass shell. Whether
Kahlua reaches public FIELDS (vs methods) is UNCHECKED and decides Lua-side
vs Java-side control (`ENGINE_CONTRACT.md` §9).

## F-006 — The unloaded crowd is native and opaque

**Verified** [A2], structural (javap). Unloaded-area zombie population is
owned by `zombie.popman.ZombiePopulationManager` backed by native
`PZPopMan64.dll` (`n_realZombieCount`, `n_spawnHorde`);
`virtualizeZombie(IsoZombie)` hands a real body to the native pool with no
identity-preserving return path visible to Java or Lua. Off-screen
continuity for owned bodies must live in ZAO's record layer, on the
sister's dormant precedent (`SAO_SEAM_AUDIT.md` §6).

## F-007 — The character's modData reaches the corpse by the engine's own hand

**Verified** [A3], hand-checked; supersedes F-002's "nothing fills it"
half after SAO's falsifying pass (SAO F-044..F-047). `IsoDeadBody` has
THREE `copyTable` sites, not two: the `IsoDeadBody(IsoGameCharacter)`
constructor copies the character's modData onto the corpse at offsets
1102-1113 (`this.getModData() ← chr.getModData()`), sitting at the join
point every constructor path reaches — unconditional, every character
class. [A2]'s two-site count was the sweep's, repeated without an
enumeration of my own; this pass enumerated (`grep LuaManager.copyTable`
over the full `javap -p -c` dump: offsets 1110, 242, 159). Consequence:
stamping the LIVING character suffices — the chain character → corpse
(ctor) → risen zombie (`reanimate()` 234-242, F-002's still-true half) is
engine-owned end to end. The corpse's modData also persists while the body
lies there: `IsoObject`'s serialization paths read
`hasModData()/getModData()` (spot-checked in this pass; full offsets in
SAO's receipts).

## F-008 — The corpse knows the name; the risen body does not

**Verified** [A3], hand-checked; supersedes F-003's corpse-side half after
SAO's falsifying pass. In the `IsoDeadBody(IsoGameCharacter)` constructor,
the `instanceof IsoSurvivor` at offset 989 branches `ifeq 1007` — it
guards ONLY the survivor-list removal (995-1006). The descriptor copy at
1007-1019 (`new SurvivorDesc(chr.getDescriptor())` → `desc`) runs for
every non-animal character, `IsoPlayer` included; a player corpse then has
its voice prefix adjusted to Male/FemaleZombie (1035-1064). [A2] inferred
the guard from a truncated context window; the branch target says
otherwise. F-003's zombie-side half STANDS unchanged: `reanimate()` builds
the risen body a fresh descriptor carrying gender and voice prefix only
(offsets 43-74, hand-checked at [A2] and unchanged), and per SAO's pass
`SharedDescriptors.createPlayerZombieDescriptor` opens with
`if (!GameServer.server) return` — a no-op in single player. Net contract:
named-corpse reads are legitimate; the risen body is nameless; identity
through the turn rides modData only (F-007).

## F-009 — The turned body is driven by target and path, the same shape as a living shell

**Verified** [A5] by `javap` against the installed
`projectzomboid.jar`, class `zombie.characters.IsoZombie`. The public
surface a controller would take a body by:

| Declared on `IsoZombie` | What it is |
|---|---|
| `public void update()` | the per-frame drive |
| `public void setTarget(IsoMovingObject)` / `getTarget()` | who it is going for |
| `public void pathToCharacter(IsoGameCharacter)` | send it at a person |
| `public void pathToLocationF(float, float, float)` | send it at a tile |
| `public void setTargetSeenTime(float)` / `getTargetSeenTime()` | how long the target has been in view |
| `public void setUseless(boolean)` / `isUseless()` | the engine's own inert flag |
| `public boolean isReanimate()` / `setReanimate(boolean)` | risen rather than spawned |
| `public boolean isReanimatedPlayer()` / `setReanimatedPlayer(boolean)` | risen from a player |
| `public int getSpeedType()` | which of the lore's speed bands this body is |

That is target-and-path, which is the same shape SAO drives a living
shell with. G1 — one brain per body — therefore has a seam to be proven
at rather than a mechanism to be invented: whoever sets the target owns
the body, and two controllers setting it is the defect the gate exists
to catch.

**What this does not say.** `IsoZombie` declares no modData accessor of
its own; it inherits `IsoGameCharacter`'s, and identity through the turn
is F-007's finding rather than this one. Nothing here establishes that
overriding `update()` is safe or necessary, and nothing here is a claim
about the unloaded crowd, which F-006 reports as native and opaque.

## F-010 — The player already sets twenty-nine zombie dials, and a preset need not carry them all

**Verified** [A5] by reading the shipped
`media/lua/shared/Sandbox/*.lua`. Four of the five presets — Apocalypse,
Extinction, Outbreak, Rising — carry an identical `ZombieLore` block of
**29 keys**:

`ActiveOnly`, `ChanceOfAttachedWeapon`, `Cognition`, `CrawlUnderVehicle`,
`DisableFakeDead`, `DoorOpeningPercentage`, `FenceDamageMultiplier`,
`FenceThumpersRequired`, `Hearing`, `Memory`, `Mortality`,
`PlayerSpawnZombieRemoval`, `Reanimate`, `Sight`, `Speed`,
`SpottedLogic`, `SprinterPercentage`, `Strength`, `ThumpNoChasing`,
`ThumpOnConstruction`, `Toughness`, `Transmission`, `TriggerHouseAlarm`,
`ZombiesArmorFactor`, `ZombiesCrawlersDragDown`, `ZombiesDragDown`,
`ZombiesFallDamage`, `ZombiesFenceLunge`, `ZombiesMaxDefense`.

`SixMonthsLater` carries **19** of them and omits ten:
`ChanceOfAttachedWeapon`, `DoorOpeningPercentage`,
`FenceDamageMultiplier`, `PlayerSpawnZombieRemoval`, `SpottedLogic`,
`SprinterPercentage`, `ZombiesArmorFactor`, `ZombiesCrawlersDragDown`,
`ZombiesFallDamage`, `ZombiesMaxDefense`.

**Two things follow.** `Cognition`, `Memory`, `Sight`, `Hearing`,
`Speed`, `Strength`, `Toughness`, `Reanimate`, `Mortality` and
`Transmission` are already the player's own words for what this project
models. Registering a second set beside them would ask a player to
answer the same question twice and would put ZAO's model and the
engine's actuators into open disagreement — which is [A3]'s correction
made concrete: the engine fields are actuators, not the axis set.

And a preset is not a guarantee that a key is present. Any read of
`SandboxVars.ZombieLore.<key>` has to survive the key being absent, or
a `SixMonthsLater` save takes a nil through ten of them.

## What is UNCHECKED, and why

**What the recovery mods expose.** G0 names it and it is not done. The
Antibodies family is not in the user's `Zomboid/mods` directory, and the
Workshop content directory holds numeric ids that were not resolved to
mod names in this batch. Reported rather than omitted: the finding is
not that they expose nothing, it is that this batch could not see them.

## F-011 — Antibodies exposes no API; its state is a namespaced modData table, and its options are version-pinned

**Verified** [A6] against the installed copy — Workshop `2392676812`,
`Antibodies (v1.97)` by lonegamedev, which ships two builds
(`42.0` and `42.13`) under `mods/lgd_antibodies/`. G0 named this
unchecked at [A5] because the mod was looked for in the user's `mods`
directory and not in the Workshop tree. It is installed.

**There is no API.** Every module in the B42.13 build is
`require`-scoped — `local Antibodies = {} ... return Antibodies` — so
nothing reaches a consumer through a global. The only globals the mod
publishes are `AntibodiesServer` and seven timed-action hook functions
(`ISDisinfect_perform`, `ISGarlicCataplasm_perform` and
`_complete`, the plantain and comfrey pairs). None of them is a read
surface.

**Its state is on the character.**
`Antibodies.getNamespacedModData(player)` returns
`player:getModData().Antibodies`, and the medical file lives at
`.medicalFile` inside it — an `AntibodiesMedicalFile` instance with a
metatable, rehydrated from the save on load and carrying its own
`migrateData` path across mod versions.

So the state is readable by anything holding the character, and it is
readable only by naming the mod.

**Sixty-seven sandbox options**, every one prefixed
`lgd_antibodies_194_`. Two families: general —
`base_growth`, `recovery_effect`, `recovery_threshold`,
`mutation_effect`, `mutation_threshold`, `mutation_start`,
`diagnose_enabled`, `diagnose_skill_needed`,
`doctor_skill_treatment_mod` — and a per-condition weight for each of
fitness, strength, fatigue, endurance, weight, thirst, sickness, food
sickness, temperature, intoxication, hunger, pain and stress.

**The `194` is the mod's own options version.** An option read is
therefore pinned to a mod version, and a consumer reading one is
reading a name that the next release may change.

## Three things this hands the operator, unresolved on purpose

**Reading it names a mod in code.** The house discipline this project
was built to is that a mod is never named in logic — property, not
name. `getModData().Antibodies` is a name. DR-005 says recovery mods
are inputs where loaded and never dependencies, and that ruling did not
anticipate that the only door in is a named one. Whether a named read
behind a presence check is acceptable, or whether a property-shaped
probe has to be invented, is a decision rather than a detail.

**Its mutation axes overlap this project's second mechanism.**
`mutation_effect`, `mutation_threshold` and `mutation_start` are
already a model of the pathogen mutating, and DR-008 reserves
mutation's axes and outcomes to the operator. Two models of the same
thing running beside each other is the state to decide about before
anything is built, not after.

**Version pinning.** Any option read carries `194` in its name. A read
that survives the mod updating needs the prefix discovered rather than
typed, and nothing in the mod publishes it.

**G0's last piece is closed by this.** Every part of the gate's
verification now has evidence: F-001 to F-008 for the turn, F-009 for
the control surface, F-010 for the player's own dials, and this for the
recovery mods.

---

## F-012 — The Mutants publishes a versioned claim API and detects a second mod's bodies by three routes

**Verified** [A7] against the installed copy — Workshop `3796669056`,
`The Mutants` (`PZTheMutants`, `modversion=0.0.1`) by SiaCatty, under
`mods/PZTheMutants/42/`, 68 Lua files and 19,733 lines. Published
2026-09-07. Method: the mod's own source read in place, plus `javap`
signatures from `projectzomboid.jar` for every engine call it makes. No
live receipt; nothing below was observed in a running session.

This is the first mod found that runs behaviour on turned bodies and
publishes a contract for coexisting with other mods that do the same.
It is the surface G1 must be proven against, and it answers part of
what `[A6]` handed the operator.

### It publishes a read-only API with a contract version

`PZTheMutants.API` is a global. `API.VERSION = 1` at
`PZM_PublicAPI.lua:16`, with a comment saying it increments only if the
public contract changes. Two functions:
`API.getMutantType(zombie)` (line 25) and `API.isMutant(zombie)`
(line 42). Both resolve through `zombie:getPersistentOutfitID()`.

The Workshop page tells other modders to call it behind a nil guard —
`if PZTheMutants and PZTheMutants.API and PZTheMutants.API.isMutant(zombie)`
— so the reader names the mod but never requires it, and the mod's
absence is a falsy read.

### Its own compatibility with Bandits is the opposite shape

`PZM_ForeignOwnership.lua` exists because Bandits publishes no such
API. `ForeignOwnership.isClaimed(zombie, outfitName)` (line 123)
returns `claimed, owner, reason`, and there are three detection routes
tried in order, each with its reason named as a string:

| Route | What it reads |
|---|---|
| `runtime-marker` (line 83) | `zombie:getVariableBoolean("Bandit")` |
| `persistent-outfit-source` (line 97) | the outfit's owning mod id, from parsed `clothing.xml` |
| `cluster-spawn-brain` (line 112) | Bandits' own `GetBanditClusterData` global |

The third cross-checks the id against the body's spawn square and sex
before claiming, with a comment saying a non-unique persistent id would
otherwise cause a false claim.

**The name is in the code and the dependency is not.**
`local BANDITS_MOD_ID = "Bandits2"` at line 16 is one constant in one
file whose whole job is foreign ownership. Line 28 is
`if type(GetBanditClusterData) ~= "function" then return false end`,
with the comment at line 27 stating that Bandits is never required
because compatibility must remain optional. Every foreign read is
`pcall`-wrapped. That is DR-005's rule — inputs where loaded, never
dependencies — as working code in another author's tree.

**The file is general and its contents are one mod.**
`ForeignOwnership.isClaimed` has exactly one implementation,
`PZM_isBanditsOwned`. The population is every mod that runs behaviour
on a zombie body, and The Mutants is now a member of that population
which Bandits does not know about. Two mods detecting each other by
hand is quadratic in mods and silent when it fails.

### Three claim channels exist, and all three are publicly writable

Each of these was confirmed against `projectzomboid.jar` rather than
taken from the mod:

| Channel | Read | Write | Shape |
|---|---|---|---|
| animation variable | `getVariableBoolean(String)`, a default method on `IAnimationVariableSource` | `IsoGameCharacter.setVariable(String, boolean)` | one string-keyed map, shared with the engine's animation system |
| persistent outfit | `IsoGameCharacter.getPersistentOutfitID()` | `setPersistentOutfitID(int)`, `dressInNamedOutfit(String)`, `dressInPersistentOutfitID(int)` | one packed 32-bit int |
| character modData | `getModData()` | same | a namespaced table |

Bandits marks bodies on the first, The Mutants identifies bodies on the
second, and F-007 established that ZAO's record crosses on the third.
The first two are single shared slots that any mod can overwrite at any
time; a body re-dressed by another mod stops being a Mutant, and
nothing reports it. Only modData gives each mod its own key space, and
F-007 already showed it riding character to corpse to risen body by the
engine's own hand.

The Mutants documents the persistent outfit id's bit layout at
`PZM_Identity.lua:265-268` — bit 31 gender, bits 30-16 outfit index,
bit 15 the fallen accessory flag, bits 14-0 variant. That layout is
stated by the mod and is **not** re-derived here; it is recorded as a
lead, not as a verified engine fact.

The mod also cannot read the engine's own outfit table. The comment at
`PZM_Identity.lua:41` says Lua cannot query `PersistentOutfits.Data.useSeed`
directly, so `initializeOutfitIndexLookup` reconstructs the index by
calling `getAllOutfits(true)` and `getAllOutfits(false)` and replaying
the insertion order, and bails while keeping old state if any declared
Mutant outfit is absent. `PZM_OutfitPriority.lua` builds the ownership
table by parsing `media/clothing/clothing.xml` out of every loaded mod.

### One vanilla outfit name on the turn path

`nonSeededOutfits` at `PZM_Identity.lua:43` holds a single entry,
`ReanimatedPlayer`, as an outfit whose id carries no seeded variant.
That is a vanilla name on the turn surface and it bears on F-008, where
the risen body was found nameless. It is noted here and not chased.

### What this bears on

**DR-004 names one mod; the population is larger.** The ruling says
Knox Survivors may be in the load order and does not own the infected.
The Mutants is a second member of the same population, shipped, and G1
now has a live case to be proven against rather than a hypothetical.

**The decision `[A6]` handed the operator has a shipped precedent.**
F-011 found that reading Antibodies means naming a mod in code, against
the discipline that a mod is never named in logic, and that DR-005 did
not anticipate a door that is only ever a named one. `PZM_ForeignOwnership`
is a working answer to the same problem: the name is a constant in one
file dedicated to foreign ownership, the presence check is a type test
on a global, every read is `pcall`-wrapped, and absence returns false
rather than failing to load. Whether ZAO adopts that shape is still the
operator's call. What is no longer open is whether anyone has solved it.

**Publishing a claim surface is what stops the next mod guessing.** The
Mutants contains both patterns at once — a versioned API offered
outward so nobody has to reverse-engineer it, and three fallback
heuristics inward because Bandits offered none. A claim query that
answers `claimed, owner, reason` costs one small file and is the
difference between the two.

---

## F-013 — Bandits publishes four surfaces, and releases its claim at the turn

**Verified** [A8] against the installed copy — Workshop `3268487204`,
mod id `Bandits`, shipping a `42.20` build, which is this project's
target build exactly. Read in place. No live receipt.

`[A7]` reached Bandits through The Mutants' compatibility shim rather
than through Bandits itself. Two things come out of reading the source:
one correction to `[A7]`, and one mechanism `[A7]` did not see.

### The correction

`[A7]`'s record and its pull request both say The Mutants had to
reverse-engineer Bandits **because Bandits publishes nothing**, and
that it "publishes no claim API". That is wrong. Bandits publishes four
distinct surfaces:

| Surface | Where |
|---|---|
| `zombie:setVariable("Bandit", true)` | `client/BanditUpdate.lua:199` |
| `getModData()` keys `IsBandit`, `isDeadBandit`, `brainId`, `zid` | throughout |
| `GetBanditClusterData(id)` | `shared/BanditGMD.lua:81` |
| a `Bandit.*` shared namespace, some twenty-five functions | `shared/Bandit.lua:74` onward |

The marker is deliberate and documented in its own comment at
`BanditUpdate.lua:198` — it says the variable determines whether a
zombie is a bandit and can be used by other mods. That namespace
includes `Bandit.GetTask`, `Bandit.HasTask`, `Bandit.GetInfection`,
`Bandit.IsSleeping`, `Bandit.IsAim` and `Bandit.IsForceStationary`,
which is a wider read surface than F-011 found on Antibodies and wider
than The Mutants publishes.

**What is actually true is narrower.** There is no single canonical
is-this-body-mine query, and the three routes in `PZM_ForeignOwnership`
exist for a reason The Mutants states in its own comments: Bandits
writes its brain into the cluster during the same spawn call, while
PZTheMutants waits until a later tick to classify. That is a **timing**
problem, not an absence of surface. A marker that is correct on tick
two is useless to a reader on tick one, and no amount of publishing
fixes it — which is a more useful thing to know than what `[A7]` wrote.

`[A7]` stands as written because the ledgers are append-only. This
entry carries the correction, and `SESSION_STATE.md` carries it too.

### The mechanism `[A7]` did not see

**A claim on a body is released.** `BanditUpdate.lua` has a local
function whose own comment is *turns bandit into a zombie*, and it
clears the marker — `bandit:setVariable("Bandit", false)` at line 244,
alongside dropping the hand items, resetting `setNoTeeth`, and setting
the walk type back. A second release sits at line 2444 in a
deprovision path that also calls `setUseless(false)` and
`setReanim(false)`.

So Bandits hands the body back at exactly the moment ZAO cares about.
Its NPC dies, and it stops owning the corpse.

**That is DR-004's seam, implemented by another mod for its own
people.** DR-004 rules that living people are SAO's until the turn and
the body is ZAO's after it, with never two brains on one corpse. Here
is a third party doing the same handoff, in the same engine, on the
same build, with the release written as an ordinary state change rather
than a protocol.

### What this changes about the claim surface

The fork `[A7]` opened asks whether ZAO publishes a claim query. F-013
says what shape it has to have.

**A claim is not a property of a body; it is a property of a body at a
time.** The Mutants' `API.isMutant(zombie)` reads a persistent outfit
id and is true for as long as the clothing survives. Bandits' marker is
true between its spawn and its death. `[A7]` treated a claim as static
and it is not — ownership of a body transfers, and the transfer is the
turn, which is the one moment this project exists to get right.

So a claim query has to be re-askable rather than cached, and a claim
protocol needs a release as much as it needs an assertion. Neither of
the two published surfaces read so far models release: The Mutants'
API has no way to say *I have let this one go*, and Bandits' release is
visible only as the absence of a variable that used to be there.

Nothing is designed here. The fork stays the operator's.

---

## F-014 — Five of the six per-body actuators are unreachable from Lua, so the axes drive from Java

**Verified** [A10], structural (`javap` against the shipped
`projectzomboid.jar`). Closes the second unchecked item in
`ENGINE_CONTRACT.md` §9, which named it as the fact deciding Lua-side
versus Java-side control.

`IsoZombie` declares six public mutable int fields, which F-005 found:
`speedType`, `strength`, `cognition`, `memory`, `sight`, `hearing`.

**Only one of them has an accessor.** `getSpeedType()` exists.
`getStrength`, `getCognition`, `getMemory`, `getSight` and
`getHearing` do not, on `IsoZombie` or anywhere above it -
`IsoGameCharacter` and `IsoMovingObject` were both checked and declare
none. **No setter exists for any of the six**, including `speedType`;
`setSpeedTypeFromWalkType()` derives that field from a walk-type string
and is not a setter for it.

**Kahlua's exposer publishes methods.**
`zombie.Lua.LuaManager$Exposer` extends
`se.krka.kahlua.integration.expose.LuaJavaClassExposer`, whose entire
public exposure surface is method-shaped - `exposeMethod`,
`exposeGlobalObjectFunction`, `exposeGlobalClassFunction`,
`exposeGlobalFunctions`, `exposeLikeJava` and its recursive form. There
is no field-exposing entry point on it.

So from Lua a mod can read `speedType` through its getter and can reach
none of the other five in either direction, and can write none of the
six at all.

**Consequence.** Any projection from ZAO's axes onto the per-body
actuators is Java-side. That is not a preference and not a
recommendation; it is the only reachable path. The runtime that already
loads Java for the sister is ZombieBuddy, which is MIT.

**Method note.** The exposer's lack of a field entry point is an
absence, and this session has five recorded instances of an absence
asserted from a narrow search. It is not load-bearing here: the
positive test carries the finding on its own, because five actuators
with no accessor anywhere in the inheritance chain are unreachable by a
method-based binding whatever else that binding does. The negative is
recorded as corroboration, not as the evidence.
