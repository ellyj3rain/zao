| Document | Zombie Awareness Overhaul Findings |
|---|---|
| Version | `0.1.1.4-pre-alpha` |
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
