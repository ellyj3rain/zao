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
| Current version | `0.1.1.2-pre-alpha` |
| Closed chronology | `A1-A4` |
| Next batch | `A5` |
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

## Maturity

`pre-alpha` throughout: maturity moves on play receipts and no batch
has one. Play is later, one project at a time, when the operator
says.

## Next movement

`A5` is the next batch. Its content determines its tier after it
exists:

| If A5 is | Result |
|---|---|
| patch or hotfix | `0.1.1.3-pre-alpha` |
| kohai | `0.1.2.0-pre-alpha` |
| minor | `0.2.0.0-pre-alpha` |
