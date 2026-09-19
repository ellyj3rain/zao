#!/usr/bin/env python3
r"""Border 2 - the version is a machine, and the machine's output is stated.

CAO's model, adopted here at [A1] (DR-009) exactly as SAO adopted it at
its DR-013; the executable shape is SAO's Border 80, carried into this
tree with its constants renamed and nothing else invented.

THE MODEL (CAO's, adopted)
--------------------------
Form `major.minor.kohai.patch-maturity`; hard caps minor 12, kohai 16,
patch 24; a tier movement resets the coordinates beneath it; a movement
at the cap rolls the tier above (twelve minors of capability ARE a
major - that is the odometer, not an honor). Maturity moves on
evidence, never on arithmetic; ZAO is pre-alpha throughout because no
batch has a play receipt.

Tiers: minor = a new player-visible simulation capability or a new
authoring/runtime contract; kohai = a coherent extension, integration,
or structural maturation of an existing capability; patch = an in-place
correction, verification closure, or repair that does not move a
capability boundary.

WHAT IS DERIVED AND WHAT IS INPUT
---------------------------------
The only input is the tier table below: one row per closed batch, with
the classification argument. Names, dates, and threads come from
BATCH_LOG.md - the index owns them, this file never respells them. The
replay derives the coordinate; --write stamps VERSION and renders
VERSION_MAP.md; the border refuses a tree whose VERSION, VERSION_MAP.md
or any mod.info disagree with the machine.

To disagree with the coordinate, disagree with a tier: edit that unit's
row, state the argument in its rationale, run --write. The map and
VERSION follow. Nothing else in the tree may state a version of its own
(Border 1 holds the doc-pack headers to VERSION).
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
BATCH_LOG = ROOT / "BATCH_LOG.md"
VERSION_FILE = ROOT / "VERSION"
VERSION_MAP = ROOT / "VERSION_MAP.md"

SCHEMA = "zao.version-model/1"
MINOR_CAP = 12
KOHAI_CAP = 16
PATCH_CAP = 24
MATURITY_LADDER = ("pre-alpha", "alpha", "beta", "rc")
REPLAY_START = "0.1.0.0-pre-alpha"

# (batch, tier, classification rationale). Chronological, one row per
# closed batch, covering BATCH_LOG.md exactly.
UNITS = [
    ("A1", "initial", "The governed repository itself: doc-pack, instruction surface, ratified genesis direction (DR-001..DR-009); no mod code."),
    ("A2", "kohai", "The verified ground before anything builds on it: forks DR-010..DR-012, the engine contract, the sister audit, findings F-001..F-006; preparation, not a shipped capability."),
    ("A3", "patch", "Corrections across the seam: two findings falsified and re-derived (F-007/F-008), the identity contract adopted (DR-013), the mechanics gate armed - verification closure, no boundary moved."),
    ("A4", "patch", "The repository is published and CI runs the gate: ZAO existed as eleven commits on a local main with no remote, while SAO and CAO were both public under the same licence and this project's own GOVERNANCE said remotes publish the canonical tree. It is at ellyj3rain/zao now, public, with its history intact. Publishing it exposed what it did not carry that its siblings do: ci-verify runs the diff-hygiene check and the whole border gate on every pull request and push to main, codeql-python scans tools/, the pull-request template and CODEOWNERS are SAO's carried across, dependabot groups the two halves of codeql-action so SAO's [C58] cannot recur here, and NEO.md gained the publishing convention it lacked - branch, one squashed commit, squash-merge, main protected and refusing direct pushes. Border 1 gained the argv[1] control mechanism it never had, the identical gap SAO found in its own [C64] the same day, so it can be pointed at a broken tree. CI-README names what is deliberately absent - no gate_reach_test while three checks are named directly in check.sh, and no RECEIPTS.md while there is no play-evidence claim to retire. Repository and tooling only; no Lua, no Java, no engine surface, so patch."),
    ("A5", "patch", "The turned body control surface, and the player own dials: G0 asks for the turn surface established from the installed build with file-and-line evidence, and [A2] and [A3] established most of it - reanimation is a timer on the corpse, the corpse modData rides the turn, the risen body is nameless, DoZombieStats re-rolls the per-body knobs during reanimation, the per-body axes exist in vanilla own vocabulary, and the unloaded crowd is native and opaque. Two pieces were still open and this closes them. F-009: zombie.characters.IsoZombie is driven by target and path - setTarget, getTarget, pathToCharacter, pathToLocationF, setTargetSeenTime, plus setUseless and the three reanimation flags - which is the same shape SAO drives a living shell with, so G1 has a seam to be proven at rather than a mechanism to be invented: whoever sets the target owns the body, and two controllers setting it is the defect the gate exists to catch. F-010: four of the five shipped presets carry an identical ZombieLore block of twenty-nine keys and ten of them - Cognition, Memory, Sight, Hearing, Speed, Strength, Toughness, Reanimate, Mortality, Transmission - are already the player own words for what this project models, so registering a second set beside them would ask a player the same question twice and put this model and the engine actuators into open disagreement, which is [A3] correction made concrete; and SixMonthsLater carries nineteen of the twenty-nine, so a preset is not a guarantee that a key is present and every read has to survive its absence. What the loaded recovery mods expose is reported UNCHECKED with its reason - the Antibodies family is not in the user mods directory and the Workshop directory holds numeric ids this batch did not resolve - so G0 is not closed. The README also points at PROJECTS.md in the sister, which now holds the architecture across the three repositories and names the edge from here to Speakeasy: a turned mind is a cognition with its inputs failing, the same model under a transform rather than a second model, and nothing should be designed there until G2 lands. Verification and documents only, no mod code, so patch."),
    ("A6", "patch", "Antibodies is installed, and G0 closes: [A5] reported the last piece of G0 - what the loaded recovery mods expose - as UNCHECKED on the ground that the Antibodies family was not in the user mods directory, and it is installed, in the Workshop tree under a numeric id where a subscribed mod lives: 2392676812, Antibodies v1.97 by lonegamedev, shipping two builds under mods/lgd_antibodies. The reported reason was wrong and the report was right to exist, because UNCHECKED named a gap somebody could close rather than a fact somebody would have to falsify, and closing it took one directory listing. F-011: there is no API - every module in the B42.13 build is require-scoped so nothing reaches a consumer through a global, and the only globals are AntibodiesServer and seven timed-action hooks; the state is on the character at player getModData Antibodies with the medical file inside it, a class instance with a metatable rehydrated on load and carrying its own migration path across mod versions, readable by anything holding the character and readable only by naming the mod; and there are sixty-seven sandbox options every one prefixed lgd_antibodies_194 where 194 is the mod own options version, so an option read is pinned to a mod version. Three things go to the operator unresolved: reading it names a mod in code against the house discipline that a mod is never named in logic, and DR-005 ruled recovery mods inputs where loaded without anticipating that the only door in is a named one; its mutation_effect, mutation_threshold and mutation_start options already model the pathogen mutating, which DR-008 reserves to the operator, so two models of one thing sit beside each other; and any option read carries the version in its name and nothing publishes the prefix. G0 is closed - F-001 to F-008 for the turn, F-009 for the control surface, F-010 for the player own dials, F-011 for the recovery mods - and no mod code exists, which is what the gate ladder asks for at this point. Verification only, so patch."),
    ("A7", "patch", "A second mod runs behaviour on turned bodies, and publishes a claim API: The Mutants, Workshop 3796669056, PZTheMutants modversion 0.0.1, published 2026-09-07 and installed - 68 Lua files and 19,733 lines running six behaviours on turned bodies. It is the first mod found occupying the seam G1 exists to prove that also publishes a contract for sharing it, so F-012 records it as G0-class evidence arriving after G0 closed, which is what an append-only findings ledger is for. What it publishes: PZTheMutants.API, a global carrying API.VERSION 1 and two read-only functions, so any mod can ask whether a body is already claimed without loading anything; and ForeignOwnership.isClaimed returning claimed, owner and reason, where the reason names which of three detection routes fired - a claim query saying who and how is a different instrument from one saying yes or no, because the second cannot be debugged from a log. What it does that this project should not copy: ForeignOwnership is general in its name and one named mod in its body, a single implementation behind the general entry point with BANDITS_MOD_ID as a constant, so every new claimant needs a branch in somebody else file and the mod shipping second does the work, which is quadratic and fails silently; and identity by persistent outfit id, one packed 32-bit int that is also the body clothing, where setPersistentOutfitID, dressInNamedOutfit and dressInPersistentOutfitID are all public on IsoGameCharacter so any mod re-dressing a body erases its identity with no error. F-012 sets the three available claim channels side by side - animation variable, persistent outfit, character modData - and modData is the only one giving each mod its own key space, which F-007 already established rides the turn by the engine own hand. Two things go to the operator: the named-door question F-011 left open now has a shipped precedent in PZM_ForeignOwnership, where the name is a constant in one dedicated file, presence is a type test on a global, every read is pcall-wrapped and absence returns false rather than failing to load; and whether ZAO publishes a claim API and when, because anything shipping after ZAO will reverse-engineer ZAO the way The Mutants had to reverse-engineer Bandits, and that surface is cheap only while no mod code exists. DR-004 rules exactly one controller per body and names Knox Survivors; there are two claimants now and neither knows about a third, which is the shape of the problem rather than a fact about two mods. No new border: nothing here is behaviour, the tree still has no mod code, and a border asserting facts about a third-party mod would pin this gate to a file outside it that updates on somebody else schedule. Verification only, so patch."),
    ("A8", "patch", "A claim on a body is released at the turn: [A7] read Bandits through The Mutants compatibility shim instead of through Bandits, which is installed and ships a 42.20 build - this project target build exactly. F-013 carries a correction and a mechanism. The correction: [A7] says The Mutants reverse-engineers Bandits because Bandits publishes nothing and publishes no claim API, and Bandits publishes four surfaces - the Bandit animation variable carrying its own comment that it is for other mods, four modData keys IsBandit, isDeadBandit, brainId and zid, the GetBanditClusterData global, and a Bandit shared namespace of some twenty-five read functions including GetTask, HasTask, GetInfection, IsSleeping and IsAim. That is wider than Antibodies in F-011 and wider than The Mutants itself. The true statement is narrower and more useful: there is no single canonical is-this-body-mine query, and the three routes in PZM_ForeignOwnership exist for a timing reason The Mutants own comments state, that Bandits writes its brain during the spawn call while PZTheMutants classifies on a later tick - a marker correct on tick two is useless to a reader on tick one and no amount of publishing fixes it. [A7] stands as written because the ledgers are append-only. The error shape is four for four in one session, an absence asserted from a narrow grep, and the line is in the catalog. The mechanism [A7] did not see: a claim on a body is RELEASED. Bandits has a local function whose own comment is turns bandit into a zombie and it clears the marker, drops the hand items and puts the walk type back, with a second release in a deprovision path that also clears the reanimation flag. So Bandits hands the body back at the moment this project exists to get right - DR-004 seam, done by a third party for its own people, same engine, same build. What this changes about the fork [A7] opened: [A7] treated a claim as a property of a body and it is a property of a body at a TIME, because ownership transfers and the transfer is the turn. So a claim query has to be re-askable rather than cached, and a claim protocol needs a release as much as an assertion - neither surface read so far has one, since The Mutants API cannot say it has let one go and Bandits release is visible only as the absence of a variable that used to be there. Nothing is designed and the fork stays the operator; what moves is that it now has a shape rather than only a question. No new border, no mod code. Verification and correction only, so patch."),
    ("A9", "patch", "The integration posture, and attribution per source: this repository had no CREDITS.md while having read five other mods for evidence across [A6], [A7] and [A8], naming them in findings and decisions with nowhere stating what it takes from any of them - which for every one of them is nothing. The file exists now and two operator rulings that were being applied without being written down are written down. DR-014: this project is the ontology other mods become coherent inside. The Workshop already answers narrow questions well - what a special infected does, how a hostile fights, how an infection course runs, how a companion takes an order - and every answer ships with its own small world-model, its own way of marking a body, its own taxonomy, its own reason a population exists, so four good mods in one load order produce four unrelated ontologies in one county. What is built here is the county those answers can be true inside at once: one identity per person, one owner per body, one causal account of how somebody came to be the way they are. A taxonomy is the cheapest part of a mod and an implementation is the most expensive part - names, categories and a mod own account of why a body is the way it is cost nothing to discard, while working code that makes a body leap a fence, charge in a line, resist a bullet or cry where it sits is months of craft. A capability is renamed, recombined and re-caused freely; what decides which body has it is always this project own account of who that person was. DR-015 at the sharpest case: a hostile is an outcome and a mod that produces hostiles is a compatibility target, because a mod reliably manufacturing hostiles answers a different question and a placed hostile destroys the only measurement there is - the sister DR-037 applied to hostility instead of to houses. What each source actually says is not one thing, and the first draft of CREDITS.md wrote no-licence-stated against five of six entries after searching mod trees for licence files and before opening four of the Workshop pages: ZombieBuddy is MIT with the text shipped in the mod, Antibodies is MIT on its public repository, Bandits states copyright with no reupload without written permission and no authorised posting on Steam except by the author own account, and The Mutants, Knox Survivors and Special Zombies Framework state nothing. Two of six being MIT was not known when [A6] and [A7] were written, and Antibodies being MIT bears on the decision [A6] handed the operator, because a mod under MIT can be read as source rather than named at runtime - which adds an option to that fork rather than deciding it. Fifth instance in one session of an absence asserted from a narrow search; the catalog carries all five. Border 1 gained a row rather than a sibling since CREDITS.md is a root document. Documents and rulings, no mod code, so patch."),
    ("A10", "patch", "The actuators are Java-side: ENGINE_CONTRACT §9 listed one fact as unchecked and named what it decides, whether the per-body axes are driven from Lua or from Java. F-005 found the six fields at [A2] and left the question open because whether Kahlua reaches public FIELDS rather than methods was never established. It was answerable with javap and the answer is Java. IsoZombie declares speedType, strength, cognition, memory, sight and hearing as public mutable ints, and only one of them has an accessor: getSpeedType exists, while getStrength, getCognition, getMemory, getSight and getHearing do not, on IsoZombie or anywhere above it - IsoGameCharacter and IsoMovingObject were both checked and declare none - and no setter exists for any of the six, setSpeedTypeFromWalkType deriving that field from a walk-type string rather than setting it. zombie.Lua.LuaManager Exposer extends Kahlua LuaJavaClassExposer, whose entire public exposure surface is method-shaped. So from Lua a mod can read one of the six, reach none of the other five in either direction, and write none of them at all. Which half carries the finding matters: the exposer having no field-exposing entry point is an ABSENCE and this session has five recorded instances of an absence asserted from a narrow search, so it is not load-bearing and F-014 says so - five actuators with no accessor anywhere in the inheritance chain are unreachable by a method-based binding whatever else that binding does, and the positive test carries it while the negative is corroboration. Any projection from this project axes onto the per-body actuators is therefore Java-side, which is not a preference but the only reachable path, and the runtime that already loads Java for the sister is ZombieBuddy, MIT. It settles nothing about the axes themselves, which remain the operator and open in the fork ledger: this closes an engine question the design was waiting on and answers no design question of its own. No new border - a javap reading is structural evidence rather than behaviour and the tree still has no mod code. Verification only, so patch."),
    ("A11", "patch", "The mutation system defined: ROADMAP had said draft owed against the mutation-axes fork since [A2], and MUTATION.md is the answer - a definition rather than a draft, because the operator defined the system directly and this records what they said. The method was the hard part and three attempts failed first, each differently. A MENU was put to the operator about where mutation attaches to the infection course, when there was nothing to attach it to and the question presumed an architecture nobody had described. Then AUTHORSHIP, a draft of four continuous axes begun unilaterally, which is the opposite error and worse, substituting a design for the operator in a project whose whole rule is that intent is theirs. Then a LOCAL FIX, proposing to separate the two senses of the word decay that DR-001 uses for both of its mechanisms, which is still bottom-up because a colliding term is a part and parts cannot be defined before the whole they belong to. The operator correction names the posture: take what they set, carry it forward far enough that they can see it was understood, map it, and surface the decisions that fall out of THEIR frame, acting on it and looping them in where it makes sense rather than deferring at every step or building past them. The writing was also refused once on its own terms, a map in invented vocabulary being unreadable and said so. What the definition contains: infection is a repeated event and surviving enough produces resistance then immunity, both counts dials; every infection rolls the same odds across a gradient with crossed rarer and carrying its own number, and every infection also carries a rare variable of its own that makes a body sicker faster and takes it PAST death rather than to it; the gradient holds both mutations that give a body something it can do, built from models already held, and mutations that only make a body more of what it was, with most waiting for death and some not. The two ends are opposites in how much of a person is left, appearance being independent of it: crossed looks like a person and is not one, cognition and every capability and every drive intact with humanity burned out by neuroinflammation; afflicted looks like a monster and is a person again, lessened, sometimes catching, unable to be a person among survivors because of what survivors see, unable to become one of the dead, and likelier than anyone to become crossed, which is what it fears most. Capability at both ends comes from what remains of the person, which is DR-002 carried past the turn. Houses decide about their own and can split over it; the afflicted are driven to gather and toward places survivors avoid, and success is never encoded because a shanty town is an outcome or it does not exist, which is the sister DR-037. The crossed organise, act with a person vocabulary of driving and explosives and loudspeakers, ignore the dead by default and use them, and work on the afflicted deliberately - which needs no new machinery, because torment raises fear, fear taxes moodles, and moodles already feed susceptibility in the infection model this project absorbed. Identity decays alongside the physiology, episodically rather than steadily, with which axis it takes varying per body and how often and how fragmented both dials. The player walks the same road. Two consequences named separately: ZAO owns both, everything past infection belonging to the project that owns the pathogen including the ones who came back; and that opens a SECOND seam, because PROJECTS.md lists one crossing between the projects and there is now another running the other way, a person becoming this project while staying inside the sister county in a house holding bonds being argued over. The crossed also need the sister action machinery stripped of what humanity gave it, a larger claim on the sister than anything this project has needed, not designed here. No new border - a definition is not behaviour and the tree still has no mod code, Border 1 gaining a row because MUTATION.md is a root document. Strain names, how many mutations sit on the gradient, every number behind every dial, how an afflicted settlement is held and whether the crossed hold ground the way a house does all remain the operator and stay in the fork ledger. Definition and documents, no mod code, so patch."),
    ("A12", "patch", "The second seam defined: [A11] opened it - a person becoming this project's while staying inside the sister's county - and the operator has ruled on its shape. The ruling principle is their own frame, the project's definition stated plain: three repositories, one project, separation of concerns, each machinery running what it owns. SAO executes the afflicted, because a person again is a person - the four pillars run them, the house argues over them because they never left the county's machinery, and their bonds and records keep their provenance. This project owns the pathogen state on an afflicted body - the susceptibility to crossed, the passive infection, the identity-decay dials - and that state is the boundary the claim surface lives on, so the claim-surface question as put dissolved rather than answered: the concrete shape stays with F-012 until mod code is near, where the ledger already notes it is cheap only while none exists. This project executes the crossed, who came through death as the risen did, exactly one controller running any body. The crossed's vocabulary is a bidirectional goal: the direction is ratified - read the sister's action machinery stripped of what humanity gave it, the turn's pattern extended - and the sister has not mapped driving yet, so what the crossed need from driving, explosives and loudspeakers feeds forward into the sister's mapping of them, a standing goal between the two repositories and never a dependency in either direction. How the crossed hold ground is variable, and the variability is the design: they still enjoy things and have leisure, differently; their shifted needs reshape how they live in a space they have decided is valuable to them; some groups settle and some stay nomadic; and which one a crossed group does is what its drives did, never a placement - DR-037's law applied to them as to every arrangement in the county. MUTATION.md gains the section and loses the ground-holding fork from its not-yet list; the sister's PROJECTS.md moves in the same turn in its own repository. Definition and documents only, no mod code, so patch."),
    ("A13", "patch", "The seam carries the driving map: the same-turn move [A12] owed when the sister's [C82] landed. MUTATION.md's second-seam section had said the sister has not mapped driving yet, and that clause went stale the moment C82 - no player at the wheel - merged in the sister: disassembled method by method off the installed jar, every identity gate along the driving path exists to exclude the blocked local player and none requires one, the doorway being seat 0 via enter(seat, char), the public control fields standing as written, an engine start bounded by the same keys, hotwire, sandbox and condition rules a player faces, and the physics tick holding no driver-identity gate at all - F-067 holds the finding there, and no shipped code exercises the doorway, so the surface is mapped and the live receipt is owed. The canonical paragraph now says so: what the crossed need from driving rides in the record as named consumers of the sister's map, explosives and loudspeakers remain unmapped so the seam still runs two ways in time for them, and neither side invents its half alone - a standing goal between the two repositories, never a dependency in either direction. Reference and documents only, no mod code, so patch."),
    ("A14", "patch", "The invented gate is removed: the rule that ZAO's mechanics stay closed until one watched turn exists was written at [A3] by an assistant, carried into DR-013's consequences and ENGINE_CONTRACT.md 10.1, and presented as the operator's. The operator ruled on 2026-09-11 that they never made it and that it blocks itself - ZAO has no game code, so the watched turn cannot happen inside ZAO yet, and work that waits for it can never start. The rule is removed from the living records; the watched turn stays wanted evidence for the identity handoff; play stays later, when the operator says. Records only, no mod code, so patch."),
    ("A15", "patch", "The remaining gate claims are removed: [A14] took the blocking rule out of the living records and left three sentences behind - the README still said no mod code exists because the gate order asks for it, the engine contract's header still said live receipts close G0 which closed at [A6] on structural evidence, and the session state's retelling of [A6] carried the same no-code claim. The gate ladder does not require the absence of code: G1 is passed on observed behavior, and observing ZAO take a body needs ZAO code. The three sentences now state facts - no mod code exists yet, and ENGINE_CONTRACT.md section 10 lists what remains unverified. The sister's standing table carried the same claim in its ZAO row and moves in the same turn in the sister's repository. Records only, no mod code, so patch."),
    ("A16", "patch", "The operator's mutation rulings are recorded: the operator answered seven questions on the mutation system on 2026-09-11 and this batch carries the rulings into the living records. The mutants mod's forms enter through a source port, with attributes and forms distinct but linked, and a mutant-form body can come back as one of the afflicted (DR-017). The gradient's contents are enumerated from what can be made possible (DR-018). The dial numbers extrapolate from numbers the operator has already suggested (DR-019). Afflicted memory is fractured at the turn and the return, and further loss is not universal (DR-020). Necessity holds an afflicted settlement (DR-021). The rarity fork is split into its two concerns and the strain-names fork is answered in substance by the forms. The assistant's remaining six questions were withdrawn by the caller after the operator ruled they carried ungrounded presuppositions; the seven answers stand. Records only, no mod code, so patch."),
    ("A17", "patch", "The pathogen and the branching graph are integrated: the operator answered six integration questions on 2026-09-11 and this batch carries the rulings into the living records. The pathogen owns the mutation roll and the roll for form performance; the default roll is uniform and sandbox settings may weight it. Crossed is terminal and does not organize around forms. Retained form traits are state rather than new branches. Capability forms and attribute mutations stack. Forms enter Perception as visible facts and change pressure inside the living branching graph. Records and documents only, no mod code, so patch."),
    ("A18", "patch", "The ZAO state producer: tools/state_dump.py emits one pathogen-state row per SAO decision moment, keyed by person id and decision hour. It carries the pathogen facts SAO already records and leaves the ZAO-specific mutation fields null until ZAO has a real state surface to read them from. A tool only, no mod code, so patch."),
    ("A19", "kohai", "The state surface: ZAO_State.lua defines the runtime pathogen state ZAO can honestly produce from SAO facts - terminal state, current form, form performance, decay state, and visible forms. A body with no assigned form is in the none form and its performance is zero. tools/state_dump.py emits the same mapping, and tools/state_dump_test.py is Border 3. First runtime Lua and a coherent new state surface, so kohai."),
    ("A20", "kohai", "The form registry and the pathogen roll: FORMS.md records the six source-port forms, the 10 percent mutation roll, and normalized performance. ZAO_Forms.lua implements the roll, ZAO_State.lua consumes it, and state_dump.py emits the same state. A coherent extension of the mutation state surface, so kohai."),
    ("A21", "patch", "The development loadout: a temporary mod id, a bound key, a state panel for the nearest SAO survivor, and a deploy script. No new game capability beyond the existing state surface, so patch."),
    ("A22", "kohai", "The form overlay: a world-space UI that draws each body's current form and normalized performance, plus the corrected gate that only infected, dead, or turned bodies carry a form. A coherent extension of the state surface into the game, so kohai."),
    ("A23", "kohai", "The turned body is driven: ZAO_Controller claims identity-bearing zombies, writes the ownership mark, and drives each body according to its form. Puker holds range, Skitter flanks, and the remaining forms close on the target. First real turned-body control, so kohai."),
    ("A24", "patch", "The mod id is chosen: ZombieAwareness. Both mod.info files, the deploy path, and the README now use the clean loadout name. Metadata and records only, so patch."),
    ("A25", "patch", "The claim surface is published: ZAO_API exposes owns, formOf, and performanceOf as a read-only Lua query surface. A small public integration contract, so patch."),
    ("A26", "patch", "The defaults are chosen: forms on, 10 percent mutation odds, runtime controller on, world-space overlay on, and the state panel bound to O. Records only, so patch."),
    ("A27", "patch", "The controller check is corrected: ZAO_Controller now reads the actual instanceof result and only drives IsoZombie objects. A correctness repair, so patch."),
    ("A28", "kohai", "The Java bridge is built: ZAO.jar owns the per-body actuators, applies each form's speed, strength, cognition, memory, sight, and hearing, and drives the body through the engine's own target and path methods. A coherent runtime capability, so kohai."),
    ("A29", "minor", "The runtime passes its own dials: every dial DR-019 reserved is declared, defaulted, read and consumed - eighteen new sandbox options after the seven that existed, episodic identity decay (DR-020) in the pathogen's daily advance, recovery read from where it lives, settlements by lingering (DR-021), derived ambient dead (DR-011), all six per-form behaviors, the crossed fear-work, the bridge course events, and the configured Java policy. The whole missing runtime, a new player-visible simulation capability, so minor."),
    ("A30", "patch", "The Sandbox prefix is the engine's lookup, never the title: read from the engine's own disassembled code that the prefix lands at read time inside the option classes and never reaches the player. A verification record, no code change, so patch."),
    ("A31", "patch", "A rebuild of the same source is the same jar: the readiness sweep found the gate's own build step dirtying a clean tree - jar entries stamped with the build's current time, so every check run left a meaning-free jar diff - and the jar stamp is now held to the county's calendar anchor (July 9 1993), making the build deterministic. A build repair, no capability boundary moved, so patch."),
    ("A32", "minor", "The crossed are executed: ZAO_Crossed.lua consumes the four-pillar mind the runtime already built and runs the deliberate half of a crossed body's life - the strips are omissions (no trust gate, no protection, no noise-is-a-debt ceiling), the dead are gathered as a tool on the engine's own world-sound channel, kin share a hunt and cohere, the person's home is held ground where crossed lingering takes the same settlement roll the turned take, and the driving map is called as the rulings named it ([A11]/[A12]/[A13]). Toughness, the one enumerated attribute without a consumer, is consumed. A new player-visible simulation capability, so minor."),
    ("A33", "kohai", "The corpse is laid down: a reverted body whose person the sister has re-adopted (her [C116] return minted them back through her own materialize) is released in the controller's scan - removal, never a kill, the sister's own despawn pair, the claim forgotten with the body, and the county's ground-dead never touched because the gate is her registry and they hold no entry in it. A coherent integration of the sister's adoption with this repo's body ownership; the capability boundary, the return itself, was her minor, so kohai."),
    ("A34", "patch", "Pathogen begin uses a table walk supported by the installed Kahlua VM; Border 5 reproduces the original missing-next failure and verifies durable mutation state. An in-place runtime correction."),
]

TIER_MEANINGS = [
    ("major", "Formal release, project-identity, or supported-compatibility boundary. No unit requires it; the odometer reaches it by cap."),
    ("minor", "A new player-visible simulation capability or a new authoring/runtime contract."),
    ("kohai", "A coherent extension, integration, or structural maturation of an existing capability."),
    ("patch", "An in-place correction, verification closure, or repair that does not move a capability boundary."),
    ("maturity", "`pre-alpha -> alpha -> beta -> rc`; moves on evidence (play receipts), never on arithmetic. Everything here is pre-alpha."),
]


def mod_infos():
    """Every mod.info in the tree, wherever the mod tree puts them. None
    exist before the mod tree ships; each one is covered from the day it
    appears, with no list here to forget to extend."""
    return sorted(ROOT.glob("mod/**/mod.info"))


def parse_version(text):
    m = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)\.(\d+)(?:-([\w.-]+))?", text.strip())
    if not m:
        raise ValueError(f"malformed version {text!r}")
    maturity = m.group(5)
    if maturity and maturity not in MATURITY_LADDER:
        raise ValueError(f"unknown maturity {maturity!r}")
    return [int(m.group(1)), int(m.group(2)), int(m.group(3)), int(m.group(4)), maturity]


def fmt(v):
    major, minor, kohai, patch, maturity = v
    return f"{major}.{minor}.{kohai}.{patch}" + (f"-{maturity}" if maturity else "")


def bump(v, tier):
    major, minor, kohai, patch, maturity = v
    if tier == "major":
        major, minor, kohai, patch = major + 1, 0, 0, 0
    elif tier == "minor":
        if minor == MINOR_CAP:
            major, minor = major + 1, 0
        else:
            minor += 1
        kohai = patch = 0
    elif tier == "kohai":
        if kohai == KOHAI_CAP:
            if minor == MINOR_CAP:
                major, minor = major + 1, 0
            else:
                minor += 1
            kohai = 0
        else:
            kohai += 1
        patch = 0
    elif tier in ("patch", "hotfix"):
        if patch == PATCH_CAP:
            patch = 0
            if kohai == KOHAI_CAP:
                kohai = 0
                if minor == MINOR_CAP:
                    major, minor = major + 1, 0
                else:
                    minor += 1
            else:
                kohai += 1
        else:
            patch += 1
    elif tier == "initial":
        pass
    elif tier.startswith("maturity-"):
        maturity = tier.split("-", 1)[1]
        if maturity not in MATURITY_LADDER:
            raise ValueError(f"unknown maturity tier {tier!r}")
    else:
        raise ValueError(f"unknown tier {tier!r}")
    return [major, minor, kohai, patch, maturity]


ROW = re.compile(
    r"^\| \[([A-Z]\d+)\]\((Batches/[^)]+)\) \| (\d{4}-\d{2}-\d{2}) \| (.*?) \| (.*?) \|$",
    re.M)


def log_rows():
    """Batch id -> (date, name, threads-cell), in log order. The index owns
    the names and dates; this tool never respells them."""
    rows = {}
    for m in ROW.finditer(BATCH_LOG.read_text(encoding="utf-8")):
        rows[m.group(1)] = (m.group(3), m.group(4), m.group(5))
    return rows


def replay():
    v = parse_version(REPLAY_START)
    trace = []
    for batch, tier, rationale in UNITS:
        v = bump(v, tier)
        trace.append((batch, tier, rationale, fmt(v)))
    return trace


def render():
    rows = log_rows()
    trace = replay()
    current = trace[-1][3]
    tip = UNITS[-1][0]
    nxt = f"{tip[0]}{int(tip[1:]) + 1}"
    lines = [
        "# Version map",
        "",
        "The regulatory version replay: the closed batch chronology classified",
        "one unit per batch, the coordinate computed under CAO's caps. The",
        "version is a machine (DR-009): nobody picks the number - to disagree",
        "with the coordinate, disagree with a tier in",
        "[`tools/version_replay.py`](tools/version_replay.py) and run",
        "`python tools/version_replay.py --write`; the map and `VERSION`",
        "follow. Border 2 refuses a tree whose stated versions disagree with",
        "the machine. Names, dates, and threads below come from",
        "[`BATCH_LOG.md`](BATCH_LOG.md), which owns them.",
        "",
        "| Field | Current state |",
        "|---|---|",
        f"| Schema | `{SCHEMA}` (CAO's `cao.version-model/1`, adopted via SAO) |",
        "| Form | `major.minor.kohai.patch-maturity` |",
        f"| Hard caps | minor {MINOR_CAP}; kohai {KOHAI_CAP}; patch {PATCH_CAP} |",
        f"| Replay start | `{REPLAY_START}` |",
        f"| Current version | `{current}` |",
        f"| Closed chronology | `A1-{tip}` |" if tip != "A1" else "| Closed chronology | `A1` |",
        f"| Next batch | `{nxt}` |",
        "| Executable source | [`tools/version_replay.py`](tools/version_replay.py) |",
        "",
        "## Tier meanings",
        "",
        "| Tier | Meaning here |",
        "|---|---|",
    ]
    for tier, meaning in TIER_MEANINGS:
        lines.append(f"| {tier} | {meaning} |")
    lines += [
        "",
        "## Chronological replay",
        "",
        "| Batch | Date | Tier | Resulting version | Name | Classification |",
        "|---|---|---|---|---|---|",
    ]
    for batch, tier, rationale, version in trace:
        date, name, _threads = rows[batch]
        lines.append(f"| `{batch}` | {date} | {tier} | `{version}` | {name} | {rationale} |")
    lines += [
        "",
        "## Maturity",
        "",
        "`pre-alpha` throughout: maturity moves on play receipts and no batch",
        "has one. Play is later, one project at a time, when the operator",
        "says.",
        "",
        "## Next movement",
        "",
        f"`{nxt}` is the next batch. Its content determines its tier after it",
        "exists:",
        "",
        f"| If {nxt} is | Result |",
        "|---|---|",
    ]
    v = parse_version(current)
    lines.append(f"| patch or hotfix | `{fmt(bump(v, 'patch'))}` |")
    lines.append(f"| kohai | `{fmt(bump(v, 'kohai'))}` |")
    lines.append(f"| minor | `{fmt(bump(v, 'minor'))}` |")
    lines.append("")
    return "\n".join(lines)


def validate():
    faults = []
    rows = log_rows()
    unit_ids = [u[0] for u in UNITS]
    if unit_ids != list(rows.keys()):
        missing = [b for b in rows if b not in unit_ids]
        extra = [b for b in unit_ids if b not in rows]
        faults.append(
            "the tier table and BATCH_LOG.md disagree about the closed "
            f"chronology (unclassified: {missing or 'none'}; not in the log: "
            f"{extra or 'none'}; or the order differs)")
    trace = replay()
    current = trace[-1][3]
    stated = VERSION_FILE.read_text(encoding="utf-8").strip()
    if stated != current:
        faults.append(f"VERSION states {stated}; the replay derives {current}")
    if not VERSION_MAP.exists() or VERSION_MAP.read_text(encoding="utf-8") != render():
        faults.append("VERSION_MAP.md is not the machine's rendering - run "
                      "python tools/version_replay.py --write")
    infos = mod_infos()
    for info in infos:
        m = re.search(r"^modversion=(.*)$", info.read_text(encoding="utf-8"), re.M)
        if not m or m.group(1).strip() != current:
            rel = info.relative_to(ROOT).as_posix()
            faults.append(f"{rel} states modversion="
                          f"{m.group(1).strip() if m else 'NOTHING'}; the replay derives {current}")
    return faults, current, len(infos)


def main():
    write = "--write" in sys.argv[1:]
    if write:
        VERSION_FILE.write_text(replay()[-1][3] + "\n", encoding="utf-8")
        VERSION_MAP.write_text(render(), encoding="utf-8")
    faults, current, info_count = validate()
    print("=" * 74)
    print("THE VERSION IS A MACHINE")
    print("=" * 74)
    if faults:
        for f in faults:
            print(f"  FAULT: {f}")
        return 1
    print(f"  2) version replay: {len(UNITS)} closed unit(s) classified; the machine")
    print(f"     derives {current}, and VERSION, the map, and {info_count} mod.info file(s) state it")
    return 0


if __name__ == "__main__":
    sys.exit(main())
