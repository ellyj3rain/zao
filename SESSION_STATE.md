| Document | Zombie Awareness Overhaul Session State |
|---|---|
| Version | `0.1.1.2-pre-alpha` |
| Author | ellyj3rain |
| Repository | `SESSION_STATE.md` |
| Status | CANONICAL - where the work actually stands. |

# Session state

**As of** 2026-09-08, `[A4]` close - the repository is published and
CI runs the gate. ZAO was eleven commits on a local `main` with no
remote while SAO and CAO were both public under the same licence, and
`GOVERNANCE.md` already said remotes publish the canonical tree. It is
at `ellyj3rain/zao` now, public, history intact. With it came what the
siblings carry and this did not: `ci-verify` running the diff-hygiene
check and the whole border gate on every pull request and push to
`main`, `codeql-python` over `tools/`, SAO's pull-request template and
CODEOWNERS, a dependabot configuration that groups the two halves of
`codeql-action` so SAO's `[C58]` cannot recur here, and the publishing
convention `NEO.md` did not have - branch, one squashed commit,
squash-merge, `main` protected and refusing a direct push. Border 1
gained the `argv[1]` control mechanism it never had, which is the
identical gap SAO found in its own `[C64]` the same day. What is
deliberately absent is named in `.github/CI-README.md` rather than left
as an oversight. `[A3]` before it.

## Standing

`[A1]` established the governed repository: doc-pack, instruction surface,
version machine, two-border gate, DR-001..DR-009. `[A2]` closed three
operator forks (DR-010..DR-012) and modeled the ground: the engine
contract, the sister audit, findings F-001..F-006; the seam repairs went
back to SAO as a portable prompt and ZAO held. `[A3]` is the operator's
corrections and the sister's answer: the axes framing corrected (engine
fields are actuators, not the axis set), the corpse-side ruled a gap and
repaired over there, and — after SAO's hardening landed (its 1.11.2.0
tip) — two of this repository's own findings falsified and re-derived by
hand (F-007: the character's modData reaches the corpse unconditionally,
stamping the living body suffices; F-008: the corpse knows the name, the
risen body does not), the ratified identity contract adopted (DR-013:
`SAOPersonId` verbatim, the crowd ledger, the identity-bearing predicate
shape), and the sister's verified arming chain recorded
(`ENGINE_CONTRACT.md` §9a). `A4` is the next batch.

No mod code exists, by design of the gate below.

## The gate

**ZAO's mechanics stay closed until the turn has one live receipt** — a
bitten SAO survivor witnessed dying, leaving a named corpse, rising with
`SAOPersonId` intact, and being recognized. The operator is play-testing
SAO 1.11.2.0 now; the receipt is expected from those sessions. Until it
lands, ZAO work is evidence, contracts, and paper only
(`ENGINE_CONTRACT.md` §10.1; DR-013 consequences). The next session
inherits this gate.

## Open items

The interrelation draft for Knox, decay, and mutation awaits operator
ratification behind the gate; nothing of it is inscribed. The design axes
are ZAO's own and new — engine fields are actuators (F-005, as corrected);
inverse/mirror axes are in the operator's direction. The fork ledger keeps
what stays reserved: mutation axes, strain names, rarity, enable defaults,
mod id, publication. Per-outcome player calls (DR-012) land at the batches
that build the outcomes.

## Instruments

Two borders, run by `tools/check.sh`, which the pre-commit hook runs:
doc currency (`tools/doc_currency_test.py`, SAO Border 43's shape) and the
version replay (`tools/version_replay.py`, DR-009). The Lua structural
checker is carried (`tools/lua_check.py`) and joins the gate with the first
Lua.

## The condition

Every batch is OPEN pending play receipts, and play is later — one project
at a time, when the operator says. The idea is the success condition,
entire. The pass continues until the operator ends it.
