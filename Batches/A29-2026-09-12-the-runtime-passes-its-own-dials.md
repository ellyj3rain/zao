# A29 - The runtime passes its own dials

| Field | Record |
| --- | --- |
| Batch | `A29` |
| Date | 2026-09-12 |
| Name | The runtime passes its own dials |
| Status | Open batch - implementation and records; the end pass ran the gate clean on 2026-09-13, play receipts remain |
| Threads | [`T-001`](Batches/THREADS.md#t-001), [`T-002`](Batches/THREADS.md#t-002) |

## Record

The mutation system's runtime is whole. Every dial DR-019 reserved is
declared, defaulted to the operator's numbers, read by the policy, and
consumed where the system's own definition says it acts. The feature
work this batch ships:

**The dials.** Eighteen new sandbox options after the seven that
existed: crossed odds (2.5%), afflicted susceptibility (5×), growth
rate (0.10), passive decay rate (0.01), reversion odds (0.01), outlier
effect (0.02), identity-decay odds (0.01) and depth (0.10), resistance
(2) and immunity (5) infections, crossed-engage-dead (false),
settlement odds (2%), and one weight per capability form (1.0). The
four advancement rates default by the registry's extrapolation rule from
the baseline odds. Every option carries its name and tooltip in the
sandbox menu (Border 16's shape, the sister's C105 format), the seven
existing options included.

**Episodic identity decay (DR-020).** The per-tick decay is gone from
both sides - the Lua controller no longer calls it, the function no
longer exists, and the Java afflicted controller no longer takes a slice
per drive. Identity loss happens only in the pathogen's daily advance:
rare episodes that take depth from one or two of seven axes, the axis
genuinely random per body. The surviving fraction of each axis is
carried in the pathogen state, persists with it, and multiplies the
mind's disposition through the state surface - so an afflicted body's
loss shows in what the sister's machinery drives it to do, never in a
second planner.

**Recovery read from where it lives.** The old recovery reads compared
containers to true and read keys the antibodies mod never writes. Now
recovery is read from the sister's own record (infections survived,
current course cleared), and the lawful boundary is enforced: a
recovery moves only an infected body back to afflicted. Survival never
resurrects a dead or turned body. The Java course seeds from the body's
own exported facts and never re-fires what the pathogen's event boundary
already fired.

**Settlements that form (DR-006, DR-021).** Nothing is placed. The
controller notes where turned bodies actually stand, per place, per day;
when at least three have shared a place across two consecutive days,
the rare roll happens, and the group that forms joins the members who
lingered there. Necessity is reckoned from what the members need - the
sister's own pressure surface, never a set number - once per day for
every active group, and what was reckoned persists with the group. The
placement-shaped auto-join is gone; membership is a formation event or a
restored one.

**The county's own dead (DR-011).** A body the sister never ran gets
one derived pathogen record, minted once from where it stands and
persisted with the body. From there the same pathogen governs it: forms,
advancement, reversion, settlement. The mechanism covers the whole
county and yields to `SAOPersonId` wherever the sister's claim exists.

**The per-form capabilities.** `ZAO_Behaviors.lua` gives each form its
signature act, re-implemented in this project's own code on public
engine APIs (A9's posture; attribution in `CREDITS.md`), every engine
call wrapped, every duration and effect scaled by the form's
performance. Puker closes to range, commits windup-release-recovery,
and lands the puke: dirt on the victim's body parts plus a three-hour
hazard that pulses world sound at the victim in fading stages, drawing
the dead to them. Skitter drops to a crawl and turns hard while it
rushes. Wrecker warns locked on its target, charges a straight line,
breaks what it hits - doors outright, fences bent then smashed,
everything else flattened by a force past resistance - and the crash
deals heavy body-part damage with the guaranteed knockdown. Leaper
winds up and commits a straight leap that staggers what it catches.
Weeper sits dormant against a wall, is not harmed by the hit that wakes
it, does not take the crit while active, and cries panic into every
living body near enough to hear. Husk is the one that does not go down:
the strength its stat block already carries plus the health to stand
under fire. Where the source mod's act is animation-driven and this
project owns no clips, the committed phase uses the engine's own
pathing as the movement substitute, and that substitution is stated
here rather than hidden.

**The crossed, working.** A crossed body's target selection prefers
the afflicted - the fear-work needs no new machinery, it raises fear
through the pressure chain that already feeds susceptibility - and the
dead are ignored unless the operator's dial says otherwise. The
CrossedEngageDead dial is declared, defaulted to false, and honored
where the target is chosen.

**The bridge carries the dials and the course.** The Lua policy pushes
its whole reading across once, before the first bridge use; the Java
policy holds the configured values, every controller built after that
reads the same dials. The course is one shared object per person:
the pathogen's event boundary on the Lua side fires the course events -
infect, survive, pass-death - by person id, and the controller that
drives the body reads the same course, so an event and a drive never
see two courses.

## The per-outcome player-side answers (DR-012)

Per DR-012, each outcome this batch builds carries its player-side
answer here, NPC-only by default:

- **The dials**: player-facing by design - every option is the player's
  own words in the sandbox menu, name and tooltip.
- **Identity decay**: NPC-only. The player's own identity is not run by
  the four pillars and nothing here touches the player mechanically.
  The player sees a neighbor's loss through the sister's behavior.
- **Settlements**: NPC-only. The player encounters a formed group as a
  world fact, never as a UI assertion.
- **The derived dead**: NPC-only. The player meets them as the county's
  ordinary dead, some of which now carry a form.
- **The per-form capabilities**: player-facing where the player is the
  target, and every one closes its loop through an engine surface the
  player already reads - the puke's dirt shows on the body and worn
  clothing and its attraction visibly draws the dead; the Weeper's cry
  raises the player's own panic moodle; the Wrecker's crash deals
  body-part damage and the knockdown; the Leaper's pounce staggers. No
  player-facing outcome in this batch is left unclosed.
- **The crossed's fear-work**: the player is a target like any living
  body. The fear path is the sister's own pressure chain; no new
  machinery, no player-side surface owed.

## The second seam's named consumers

The crossed's vocabulary stays the ratified two-way deferral
(`MUTATION.md`, The second seam, defined). ZAO's half is naming the
consumers in the record: **the crossed's driving** is the named
consumer of the sister's `C82` doorway map - seat 0, the public control
fields standing as written, an engine start bounded by the same keys,
hotwire, sandbox and condition rules a player faces - and its live
receipt is owed on the sister's side before any shipped code here
exercises it. **Explosives and loudspeakers remain unmapped** on the
sister's side and are implemented nowhere in this project. Neither
side invents its half alone.

## What changed

- `mod/42.20/media/sandbox-options.txt` - eighteen new options.
- `mod/42.20/media/lua/shared/Translate/EN/Sandbox.json` - names and
  tooltips for all twenty-five options.
- `mod/42.20/media/lua/shared/ZAO_Sandbox.lua` - full policy read,
  derived advancement rates, form weights, `pushToBridge`.
- `mod/42.20/media/lua/shared/ZAO_Forms.lua` - weighted capability
  roll (DR-022).
- `mod/42.20/media/lua/shared/ZAO_Pathogen.lua` - episodic identity
  decay; course events at the event boundary.
- `mod/42.20/media/lua/shared/ZAO_State.lua`,
  `ZAO_StateStore.lua` - identity axes persist; settlements persist
  with place and necessity.
- `mod/42.20/media/lua/shared/ZAO_Mind.lua` - per-axis survival; the
  steady decay function is removed.
- `mod/42.20/media/lua/shared/ZAO_Recovery.lua` - record-shaped read.
- `mod/42.20/media/lua/shared/ZAO_Settlement.lua` - formation by
  lingering; necessity reckoned from needs.
- `mod/42.20/media/lua/client/ZAO_Behaviors.lua` - the per-form
  capability module, new.
- `mod/42.20/media/lua/client/ZAO_Controller.lua` - the rewire: lawful
  recovery, derived ambient records, settlement presence and reckoning,
  crossed target preference, behavior dispatch, bridge configure.
- `java/src/com/zao/engine/ZAOSandboxPolicy.java` - the two threshold
  fields and the configured holder.
- `java/src/com/zao/engine/ZAOControllerStore.java` - the shared
  per-person course; configured policy.
- `java/src/com/zao/bridge/ZAOBridge.java` - `configure`,
  `courseInfect`, `courseSurvive`, `coursePassDeath`.
- `java/src/com/zao/engine/ZAORecoveryReader.java` - reads the body's
  own exported recovery keys.
- `java/src/com/zao/engine/ZAODomainController.java` - the recovery seed
  records facts without re-firing course events.
- `java/src/com/zao/engine/ZAOAfflictedController.java` - the per-drive
  decay is removed.
- `MUTATION.md` - the dial table carries the operator's numbers; the
  open list closes what the numbers resolved.

## Honest limits, stated

- The committed movement phases use pathing, not the source mod's
  animation-driven displacement - this project owns no clips.
- Husk's hidden head-armor item is not ported: it needs a clothing
  model and a body-locations registration this project does not own.
  The substitute is the health to stand under fire, stated as the
  substance of the form.
- The puke's cosmetic dirt is applied through the engine's visual
  surface and left to the engine's own washing; the timed fade of the
  source mod is not re-implemented. The functional hazard - the
  world-sound attraction - is real, staged, and bounded by the three
  world-age hours.
- The Wrecker's destruction pass is a best-effort walk over the
  collided square's objects - door, fence, thumpable - with the plain
  thump as the fallback, every probe wrapped. The face-aware candidate
  ordering of the source mod is simplified to the collided face.

## Verification

Deferred to the end pass by the operator's standing order: no gate,
build, deploy, or test runs until the feature work across the three
repositories is finished; verification runs once, at the end.

END PASS, 2026-09-13: the gate ran and is clean - the structural
walk, doc currency, version replay (the machine derives
0.2.0.1-pre-alpha), the state-dump border, and the Java bridge
build, which rebuilt ZAO.jar and installed it into the mod tree.
Both the source tree and the deployed install at
`~/Zomboid/mods/ZombieAwareness` carry that jar. What the gate
cannot establish is the runtime feel of the dials themselves; the
play receipts remain owed, with the rest of the era's, until the
operator drives a session on this build.