# Version map

The regulatory version replay: the closed batch chronology classified
one unit per batch, the coordinate computed under CAO's caps. The
version is a machine (DR-009): nobody picks the number - to disagree
with the coordinate, disagree with a tier in
[`tools/version_replay.py`](tools/version_replay.py) and run
`python tools/version_replay.py --write`; the map and `VERSION`
follow. Border 2 refuses a tree whose stated versions disagree with
the machine. Names, dates, and threads below come from
[`BATCH_LOG.md`](BATCH_LOG.md), which owns them.

| Field | Current state |
|---|---|
| Schema | `zao.version-model/1` (CAO's `cao.version-model/1`, adopted via SAO) |
| Form | `major.minor.kohai.patch-maturity` |
| Hard caps | minor 12; kohai 16; patch 24 |
| Replay start | `0.1.0.0-pre-alpha` |
| Current version | `0.1.1.4-pre-alpha` |
| Closed chronology | `A1-A6` |
| Next batch | `A7` |
| Executable source | [`tools/version_replay.py`](tools/version_replay.py) |

## Tier meanings

| Tier | Meaning here |
|---|---|
| major | Formal release, project-identity, or supported-compatibility boundary. No unit requires it; the odometer reaches it by cap. |
| minor | A new player-visible simulation capability or a new authoring/runtime contract. |
| kohai | A coherent extension, integration, or structural maturation of an existing capability. |
| patch | An in-place correction, verification closure, or repair that does not move a capability boundary. |
| maturity | `pre-alpha -> alpha -> beta -> rc`; moves on evidence (play receipts), never on arithmetic. Everything here is pre-alpha. |

## Chronological replay

| Batch | Date | Tier | Resulting version | Name | Classification |
|---|---|---|---|---|---|
| `A1` | 2026-08-29 | initial | `0.1.0.0-pre-alpha` | Repository and governance surface | The governed repository itself: doc-pack, instruction surface, ratified genesis direction (DR-001..DR-009); no mod code. |
| `A2` | 2026-08-29 | kohai | `0.1.1.0-pre-alpha` | Operator forks closed; the sister and the engine modeled | The verified ground before anything builds on it: forks DR-010..DR-012, the engine contract, the sister audit, findings F-001..F-006; preparation, not a shipped capability. |
| `A3` | 2026-08-29 | patch | `0.1.1.1-pre-alpha` | Corrections across the seam | Corrections across the seam: two findings falsified and re-derived (F-007/F-008), the identity contract adopted (DR-013), the mechanics gate armed - verification closure, no boundary moved. |
| `A4` | 2026-09-08 | patch | `0.1.1.2-pre-alpha` | The repository is published and CI runs the gate | The repository is published and CI runs the gate: ZAO existed as eleven commits on a local main with no remote, while SAO and CAO were both public under the same licence and this project's own GOVERNANCE said remotes publish the canonical tree. It is at ellyj3rain/zao now, public, with its history intact. Publishing it exposed what it did not carry that its siblings do: ci-verify runs the diff-hygiene check and the whole border gate on every pull request and push to main, codeql-python scans tools/, the pull-request template and CODEOWNERS are SAO's carried across, dependabot groups the two halves of codeql-action so SAO's [C58] cannot recur here, and NEO.md gained the publishing convention it lacked - branch, one squashed commit, squash-merge, main protected and refusing direct pushes. Border 1 gained the argv[1] control mechanism it never had, the identical gap SAO found in its own [C64] the same day, so it can be pointed at a broken tree. CI-README names what is deliberately absent - no gate_reach_test while three checks are named directly in check.sh, and no RECEIPTS.md while there is no play-evidence claim to retire. Repository and tooling only; no Lua, no Java, no engine surface, so patch. |
| `A5` | 2026-09-09 | patch | `0.1.1.3-pre-alpha` | The turned body's control surface, and the player's own dials | The turned body control surface, and the player own dials: G0 asks for the turn surface established from the installed build with file-and-line evidence, and [A2] and [A3] established most of it - reanimation is a timer on the corpse, the corpse modData rides the turn, the risen body is nameless, DoZombieStats re-rolls the per-body knobs during reanimation, the per-body axes exist in vanilla own vocabulary, and the unloaded crowd is native and opaque. Two pieces were still open and this closes them. F-009: zombie.characters.IsoZombie is driven by target and path - setTarget, getTarget, pathToCharacter, pathToLocationF, setTargetSeenTime, plus setUseless and the three reanimation flags - which is the same shape SAO drives a living shell with, so G1 has a seam to be proven at rather than a mechanism to be invented: whoever sets the target owns the body, and two controllers setting it is the defect the gate exists to catch. F-010: four of the five shipped presets carry an identical ZombieLore block of twenty-nine keys and ten of them - Cognition, Memory, Sight, Hearing, Speed, Strength, Toughness, Reanimate, Mortality, Transmission - are already the player own words for what this project models, so registering a second set beside them would ask a player the same question twice and put this model and the engine actuators into open disagreement, which is [A3] correction made concrete; and SixMonthsLater carries nineteen of the twenty-nine, so a preset is not a guarantee that a key is present and every read has to survive its absence. What the loaded recovery mods expose is reported UNCHECKED with its reason - the Antibodies family is not in the user mods directory and the Workshop directory holds numeric ids this batch did not resolve - so G0 is not closed. The README also points at PROJECTS.md in the sister, which now holds the architecture across the three repositories and names the edge from here to Speakeasy: a turned mind is a cognition with its inputs failing, the same model under a transform rather than a second model, and nothing should be designed there until G2 lands. Verification and documents only, no mod code, so patch. |
| `A6` | 2026-09-09 | patch | `0.1.1.4-pre-alpha` | Antibodies is installed, and G0 closes | Antibodies is installed, and G0 closes: [A5] reported the last piece of G0 - what the loaded recovery mods expose - as UNCHECKED on the ground that the Antibodies family was not in the user mods directory, and it is installed, in the Workshop tree under a numeric id where a subscribed mod lives: 2392676812, Antibodies v1.97 by lonegamedev, shipping two builds under mods/lgd_antibodies. The reported reason was wrong and the report was right to exist, because UNCHECKED named a gap somebody could close rather than a fact somebody would have to falsify, and closing it took one directory listing. F-011: there is no API - every module in the B42.13 build is require-scoped so nothing reaches a consumer through a global, and the only globals are AntibodiesServer and seven timed-action hooks; the state is on the character at player getModData Antibodies with the medical file inside it, a class instance with a metatable rehydrated on load and carrying its own migration path across mod versions, readable by anything holding the character and readable only by naming the mod; and there are sixty-seven sandbox options every one prefixed lgd_antibodies_194 where 194 is the mod own options version, so an option read is pinned to a mod version. Three things go to the operator unresolved: reading it names a mod in code against the house discipline that a mod is never named in logic, and DR-005 ruled recovery mods inputs where loaded without anticipating that the only door in is a named one; its mutation_effect, mutation_threshold and mutation_start options already model the pathogen mutating, which DR-008 reserves to the operator, so two models of one thing sit beside each other; and any option read carries the version in its name and nothing publishes the prefix. G0 is closed - F-001 to F-008 for the turn, F-009 for the control surface, F-010 for the player own dials, F-011 for the recovery mods - and no mod code exists, which is what the gate ladder asks for at this point. Verification only, so patch. |

## Maturity

`pre-alpha` throughout: maturity moves on play receipts and no batch
has one. Play is later, one project at a time, when the operator
says.

## Next movement

`A7` is the next batch. Its content determines its tier after it
exists:

| If A7 is | Result |
|---|---|
| patch or hotfix | `0.1.1.5-pre-alpha` |
| kohai | `0.1.2.0-pre-alpha` |
| minor | `0.2.0.0-pre-alpha` |
