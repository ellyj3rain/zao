| Document | Zombie Awareness Overhaul Engine Contract |
|---|---|
| Version | `0.1.1.0-pre-alpha` |
| Author | ellyj3rain |
| Repository | `ENGINE_CONTRACT.md` |
| Status | CANONICAL, INCOMPLETE - the verified engine mechanics the turned require; nothing here is live-verified. |

# Engine contract — what the turn actually is on Build 42

The verified surface for a mod that owns zombies, from the installed game at
`C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid`
(`projectzomboid.jar`, 2026-08-26 build; `media/` tree). Methods: `javap`
(JetBrains JDK 25.0.3) and `javap -p -c` disassembly against the jar; direct
reads of the shipped Lua. No decompiled source tree exists locally; bytecode
offsets are the citations. Sections marked HAND-CHECKED were re-derived in
this repository's own pass ([A2]), not taken from a sweep's word. Everything
is structurally verified and live-unverified; live receipts are G0's close.

## 1 · The reanimation path (HAND-CHECKED)

`zombie.iso.objects.IsoDeadBody` (final) owns the timer:

- `private float reanimateTime`; `getReanimateTime()/setReanimateTime(float)`;
  `reanimateLater()` = world-age + private `getReanimateDelay()`;
  `reanimateNow()` = world-age now. The gate is inline in `update()`:
  compare `reanimateTime` against `GameTime.getWorldAgeHours()`, then
  `reanimate()`. There is no `shouldReanimate()`; a past-dated
  `reanimateTime` IS the trigger.
- `reanimate()` (public, returns `IsoGameCharacter`), by bytecode offset:
  - 43-47: `new SurvivorDesc()` — **fresh**, not a copy.
  - 56: `setFemale(isFemale())`; 60-74: `setVoicePrefix(desc.getVoicePrefix())`.
    **Nothing else is copied into the new descriptor. No forename, no
    surname** (no `setForename`/`setSurname` call exists in the method).
  - 89: `new IsoZombie(cell, thatFreshDesc, id)`.
  - 132-184: inventory, `HumanVisual.copyFrom`, worn items, attached items.
  - 234-242: `zombie.getModData() ← this.getModData()` via
    `LuaManager.copyTable` — **the corpse's modData is copied onto the
    zombie by the engine itself.**
  - 374: `IsoZombie.DoZombieStats()` — re-rolls per-zombie stats from
    sandbox lore (see §3).
  - 520-540 (player corpses): `setReanimatedPlayer(true)`,
    `getDescriptor().setID(...)`,
    `SharedDescriptors.createPlayerZombieDescriptor(zombie)`,
    `setReanimate(true)`.
  - 643/654: `IsoPlayer.reanimatedCorpse` / `.reanimatedCorpseId` written —
    the player object points at its zombie, not the reverse.

**How a corpse gets a descriptor at all** (HAND-CHECKED): the `IsoDeadBody`
constructor writes `desc` in exactly two branches — `instanceof IsoZombie`
(ctor offset 626) and `instanceof IsoSurvivor` (offset 1019), each via the
`SurvivorDesc` copy-constructor; the only other `desc` write in the class is
a fresh `SurvivorDesc(boolean)` in a separate method (offset 239 there).
`getDescriptor()` is a bare field read with no fallback. **An `IsoPlayer`
corpse — every SAO shell — therefore carries `desc = null`.**

**Contract consequences.**
1. *The name does not survive the turn through the engine.* Any recognition
   chain built on the zombie's descriptor name is structurally dead for
   player-class corpses (see `SAO_SEAM_AUDIT.md` §5).
2. *The modData table is the engine-native identity channel.* Stamp the
   CORPSE's modData and `reanimate()` carries it to the zombie. The corpse
   is NOT auto-populated from the dying character (the class has exactly two
   `copyTable` sites: `reanimate()` and `reanimateAnimal()`) — a mod must
   write the corpse itself. `Events.OnDeadBodySpawn` fires with the body
   (shipped subscriber: `media/lua/client/ISUI/ISWorldObjectContextMenu.lua:2795`)
   and `body:getModData()` is exercised by shipped Lua
   (`media/lua/shared/Definitions/animal/ButcheringUtil.lua:594,602`).

Persistence: `zombie.ReanimatedPlayers` (`addReanimatedPlayersToChunk`,
`save/loadReanimatedPlayers`) keeps reanimated players across chunk load;
the save carries a top-level `reanimated.bin`
(`media/lua/client/OptionScreens/LoadGameScreen.lua:240`). Format Java-side,
UNCHECKED.

Lua reach: `body:reanimateNow()` (shipped:
`DebugUIs/DebugContextMenu.lua:680-688` — its menu also shows the shipped
tree's only player-corpse/zombie-corpse discrimination) and
`zombie:setReanimateTimer(s)` (shipped: `Tutorial/Steps.lua:922,962,1282`).
No Lua global reaches `reanimate()` directly.

## 2 · IsoZombie — the body ZAO drives (javap)

`zombie.characters.IsoZombie` is **final** — no subclass shell; ZAO drives
real zombies or nothing. Constructed `IsoZombie(IsoCell, SurvivorDesc, int)`.

Per-body capability knobs are **public mutable int fields, not setters**:
`speedType, strength, cognition, memory, hearing, sight` (+
`visionRadiusResult`). This is vanilla's own per-body vocabulary — the same
axes the sandbox lore page sets fleet-wide. Constants:
`SPEED_SPRINTER=1/FAST_SHAMBLER=2/SHAMBLER=3/RANDOM=4`;
`HEARING_PINPOINT=1/NORMAL=2/POOR=3/RANDOM=4/NORMAL_OR_POOR=5`;
`VISION_RADIUS_MIN=10/MAX=20`.

Identity: `isReanimatedPlayer()/setReanimatedPlayer`, `isReanimate()/
setReanimate`, `getReanimatedPlayer()`, `getDescriptor()/setDescriptor`
(inherited), `useDescriptor(SharedDescriptors$Descriptor)`, outfit/visual
surface (`dressInNamedOutfit` etc.), `setAsSurvivor()`, `isSkeleton()`.

Target/attack/memory: public `target`, `vectorToTarget`,
`lastTargetSeenX/Y/Z`, `timeSinceSeenFlesh`, `setTargetSeenTime(float)`,
`spotted(IsoMovingObject, boolean)`, aggro list, `eatBodyTarget`/`bodyToEat`,
sound response (`soundAttract`, `RespondToSound`), `Wander()`.

Movement: `pathToCharacter`, `pathToLocationF` (overrides),
`getPathFindBehavior2()`, `setCanWalk`, crawler surface (`setCrawler`,
`isBecomeCrawler`, `crawling` public field), lunge surface.

Doors: `tryThump(IsoGridSquare)`, `thumpFlag` (GENERIC=1 … WOOD=8),
`setThumpCondition`. Door-opening rides `cognition` (§3).

Update: `preupdate()/update()/postupdate()`; states via inherited
`getStateMachine()/changeState(State)/setDefaultState` and typed
`State$Param` slots; `initializeStates()` populates the machine (order
UNCHECKED). Grouping: public `group` field → `ZombieGroup`
(`add/remove/getLeader/size/update`).

Lifecycle: `removeFromWorld()`, `resetForReuse()`, `makeInactive(boolean)`,
`setUseless`, fake-dead surface (`isFakeDead/setFakeDead/wasFakeDead`).

## 3 · DoZombieStats — the re-roll hazard (HAND-CHECKED call site)

`DoZombieStats()` reads `SandboxOptions.instance.lore.<option>.getValue()`
into `cognition`, then `strength` (with `Rand.Next` branches for RANDOM),
then `doorOpeningPercentage` — the sweep's per-field disassembly; the [A2]
hand-check confirmed the call inside `reanimate()` at offset 374. **Any
per-body override written into the §2 fields is destroyed by the next
`DoZombieStats()` — which runs during reanimation itself.** ZAO applies its
coordinates after reanimation and re-applies after any engine re-roll; the
re-roll's other call sites are UNCHECKED and G0 work.

## 4 · The AI states (javap, package zombie.ai.states)

Singleton `State` classes (`instance()`, `enter/execute/exit/animEvent`);
zombie set includes: `ZombieIdleState`, `PathFindState`, `WalkTowardState`,
`LungeState`, `AttackState`, `ThumpState`, `ZombieEatBodyState`,
`ZombieReanimateState` (enter/exit/animEvent only — no execute),
`ZombieTurnAlerted`, `ZombieGetUpState`, `ZombieHitReactionState`,
`ZombieOnGroundState`, fake-dead pair, climb/window/fence set, crawl set.
Typed per-character params exist (`WalkTowardState.IGNORE_OFFSET/IGNORE_TIME`,
`AttackState.SKIP_TEST_DEFENCE`) via `IsoGameCharacter.set(Param, value)`.
Which fields each `execute()` reads: UNCHECKED (targeted disassembly, G0).
Reanimation's animation gate is data-side: `bReanimate` condition in
`media/actiongroups/zombie-crawler/idle/to_reanimate.xml` and
`reanimate/to_idle.xml:5`; the player rig itself carries `reanimateTimer`
(`media/actiongroups/player/onground/to_getup.xml:7`).

## 5 · Population machinery (javap)

- `zombie.VirtualZombieManager.instance` — real-zombie create/remove:
  `createRealZombie(Now/Always)`, `removeZombieFromWorld(IsoZombie)`,
  `addZombiesToMap`, `createEatingZombies(IsoDeadBody, int)`,
  `createHordeFromTo`, reusable pool (`addToReusable/isReused`).
- `zombie.popman.ZombiePopulationManager.instance` — the unloaded-area
  owner, **backed by native `PZPopMan64.dll`**
  (`n_realZombieCount`, `n_spawnHorde`): `virtualizeZombie(IsoZombie)` is
  the real→virtual handoff; chunk add/remove; hordes; sounds; per-chunk
  min/max. **Contract consequence: the engine's virtual crowd is opaque to
  Java and Lua alike. Any body ZAO must keep identity for cannot be
  virtualized into the native pool and recovered; unloaded continuity lives
  in ZAO's own record layer (the sister's dormant machinery is the working
  precedent, `SAO_SEAM_AUDIT.md` §6).**
- `zombie.characters.ZombiesZoneDefinition` (static) + shipped
  `media/lua/shared/NPCs/ZombiesZoneDefinition.lua` (~70 zones, schema
  documented at `:1-20`, `Default` at `:1771`) — outfit/zone identity for
  ambient zombies; the derived-record draw (DR-011) can read the same zone
  vocabulary the engine dresses bodies with.
- `IsoWorld`: `noZombies`, `ForceKillAllZombies()`,
  `survivorDescriptors: HashMap<Integer, SurvivorDesc>`.

## 6 · Sandbox lore — the fleet-wide axes (shipped tree, direct reads)

No `sandbox-options.txt` ships; the schema is Java-side
(`zombie.SandboxOptions`, singleton, options as public final typed objects:
`lore` = `ZombieLore` with 29 fields, `zombieConfig` = population block).
Ground truth for values: preset files
`media/lua/shared/Sandbox/Apocalypse.lua:194-241` (ZombieLore + ZombieConfig
blocks; Apocalypse defaults cited below), labels/enum meanings
`media/lua/shared/Translate/EN/Sandbox.json:446-535` and the `:1027-1056`
tail, canonical ordering `OptionScreens/ServerSettingsScreen.lua:4380-4434`.
Enums are 1-based.

Load-bearing rows (Apocalypse defaults in bold):

| `SandboxVars.ZombieLore.*` | Domain | Default |
|---|---|---|
| `Speed` | 1 Sprinters / 2 Fast Shamblers / 3 Shamblers / 4 Random | **4** |
| `Strength` | 1 Superhuman / 2 Normal / 3 Weak / 4 Random | **2** |
| `Toughness` | 1 Tough / 2 Normal / 3 Fragile / 4 Random | **4** |
| `Transmission` | 1 Blood+Saliva / 2 Saliva / 3 Everyone's Infected / 4 None | **1** |
| `Mortality` | 1 Instant … 5 2-3 Days … 7 Never | **5** |
| `Reanimate` | 1 Instant … 3 0-1 Minutes … 6 1-2 Weeks (no Never) | **3** |
| `Cognition` | 1 Navigate+Use Doors / 2 Navigate / 3 Basic / 4 Random | **3** |
| `Memory` | 1 Long / 2 Normal / 3 Short / 4 None / 5-6 Random forms | **2** |
| `Sight` / `Hearing` | 1 Eagle-Pinpoint … 5 Random Normal-Poor | **5 / 5** |
| `SprinterPercentage` / `DoorOpeningPercentage` | raw % under Random | **0 / 0** |
| `ActiveOnly` | 1 Both / 2 Night / 3 Day | **1** |
| `ThumpNoChasing` / `ThumpOnConstruction` | bool | **false / true** |
| `DisableFakeDead` | 1 World / 2 World+Combat / 3 Never | **1** |

Population block (`ZombieConfig`): `PopulationMultiplier 0.65`, peak day 28,
respawn 0 by default, `RallyGroupSize 20` ± variance 50, separation 15,
radius 3 — **the engine already has a grouping model; ZAO settlement work
composes with it rather than fighting it.** Top-level: `Zombies 4`,
`ZombieRespawn 4 (None)`, `ZombieMigrate true`; multiplier tables live in
`media/lua/shared/defines.lua:66-89` (which contradicts
`EN/Sandbox.json:585-586` on Insane start/peak — the Lua table wins at
runtime, `OptionScreens/SandboxOptions.lua:757-761`).

Custom options for mods: `getSandboxOptions():initSandboxVars()` hook
(`media/lua/shared/Sandbox/SandboxVars.lua:4`), `zombie.sandbox.
CustomSandboxOptions` (surface UNCHECKED), and B42's
`media/lua/client/PZAPI/ModOptions.lua`.

## 7 · Infection — two systems, one flag each (shipped Lua)

Knox infection is character-level: `BodyDamage.IsInfected()/setInfected`,
`isFakeInfected` (the you-don't-know-yet flag), stats
`CharacterStat.ZOMBIE_INFECTION/ZOMBIE_FEVER`
(`DebugUIs/DebugMenu/General/ISStatsAndBody.lua:85-106`);
`BodyDamage.InfectionLevelToZombify = 0.001f`; growth/mortality surface
`getInfectionTime/getInfectionGrowthRate/getInfectionMortalityDuration/
pickMortalityDuration`, `getApparentInfectionLevel()` (javap). Wound
infection is per-part and unrelated: `isInfectedWound()/
get/setWoundInfectionLevel`, doctor-skill visibility gate
(`XpSystem/ISUI/ISHealthPanel.lua:788-807`), sandbox
`WoundInfectionFactor`. Transmission wounds: `SetBitten`, `setScratched`,
laceration (`ISHealthPanel.lua:222-308`). `BodyDamage.Update()` internals
UNCHECKED (targeted disassembly, G0). No infection constants ship in
`media/scripts/` — courses are Java-side, driven by `Mortality`.

## 8 · The epistemological surface — moodles and events (shipped tree)

Moodle ids: 26 in `media/lua/shared/Translate/EN/Moodles.json`, including
the two lore-grade single-level moodles `Dead` ("Deceased") and `Zombie`
("Zombified", desc "Sudden attraction to gunshots, house alarms, and human
flesh") at `:70-71`. Art at `media/ui/Moodles/{32..128}/` — 36 icons per
size; **unclaimed-by-JSON art usable for mutation/recovery states**:
`Mood_Ill`, `Mood_Dizzy`, `Mood_Hungover`, `Mood_Scared`, `Mood_Sleepy`,
`Status_DifficultyBreathing`, `Status_Sedated`, `Status_Wired`,
`Status_VisionImpaired`, `Status_HearingImpaired`,
`Status_MovementRestricted` (verify Java-side binding before claiming one —
several may back `Sick`/`Injured` sub-states). Full `MoodleType` enum is
jar-side, UNCHECKED; naming convention maps `FoodEaten`→`FOOD_EATEN`, so
`ZOMBIE`/`DEAD` are near-certain.

Zombie/death events with shipped subscribers: `OnHitZombie(zombie, wielder,
bodyPart, weapon)` (`Definitions/DamageModelDefinitions.lua:24,69`),
`OnZombieDead(zombie)` (`Tutorial/Steps.lua:840+`), `OnPlayerDeath(player)`,
`OnDeadBodySpawn(body)` (`ISWorldObjectContextMenu.lua:2795-2797`) — the
corpse-stamping hook. **Not found in shipped Lua**: `OnCharacterDeath`,
`OnZombieUpdate`, `OnZombieSpawn`, `OnCreateZombie`; whether they exist
Java-side is UNCHECKED (G0: enumerate `LuaEventManager` from the jar).

## 9 · What Kahlua reaches (javap on LuaManager$GlobalObject)

Globals: `createZombie(x,y,z,SurvivorDesc,int,IsoDirections)` — an
identity-carrying spawn IS Lua-reachable — plus `addZombiesInOutfit`,
`createHordeFromTo/InAreaTo`, `spawnHorde`, `addVirtualZombie`,
`zpopClearZombies`, `getZombieInfo(IsoZombie)`,
`createRandomDeadBody(square,int)`, `getSandboxOptions()`. Instance methods
on held objects are exposed reflectively (no allow-list found in
`LuaManager`); **whether public FIELDS (the §2 knobs) are Lua-reachable is
UNCHECKED and decisive** — if not, per-body control needs a Java component
(SAO ships one; ZombieBuddy is the load path, `SAO_SEAM_AUDIT.md` §7). No
`*Reanimate*` global exists.

## 10 · The G0 ledger — what remains unverified

Everything above is structural. Still owed, each a named gap:

1. LIVE: a dead `IsoPlayer`-class corpse actually reanimates with its
   modData intact (the whole §1 contract, witnessed once in a running game).
2. `LuaManager$Exposer` field exposure (§9) — decides Lua vs Java control.
3. `BodyDamage.Update()` infection→zombify branch (§7).
4. Per-state field reads (§4); `initializeStates()` registration order.
5. All other `DoZombieStats()` call sites (§3).
6. Java-side event registry (§8).
7. `reanimated.bin` format; `ReanimatedPlayers` lifecycle (§1).
8. `CustomSandboxOptions` surface (§6).
9. Exact jar patch number (inferred 42.20-line from `mod/42.20/` and
   structural markers only).
