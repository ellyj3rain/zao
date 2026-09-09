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
| Current version | `0.1.1.3-pre-alpha` |
| Closed chronology | `A1-A5` |
| Next batch | `A6` |
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

## Maturity

`pre-alpha` throughout: maturity moves on play receipts and no batch
has one. Play is later, one project at a time, when the operator
says.

## Next movement

`A6` is the next batch. Its content determines its tier after it
exists:

| If A6 is | Result |
|---|---|
| patch or hotfix | `0.1.1.4-pre-alpha` |
| kohai | `0.1.2.0-pre-alpha` |
| minor | `0.2.0.0-pre-alpha` |
