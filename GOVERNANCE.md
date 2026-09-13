| Document | Zombie Awareness Overhaul Governance |
|---|---|
| Version | `0.2.0.1-pre-alpha` |
| Design authority | ellyj3rain |
| Repository | `GOVERNANCE.md` |
| Status | ACTIVE - operating discipline for this repository. |

# Zombie Awareness Overhaul - governance

Operating discipline for this repository. `NEO.md` is the instruction surface
and states the batch and commit shape; this file states the judgement rules.
`CLAUDE.md` and `AGENTS.md` are autoload shims pointing at `NEO.md`.

The operator (ellyj3rain) is the design authority and the judge of how the
game looks and plays. Code-level verification never settles that question.

`README.md` is the human entry point. The canonical doc-pack is `MEMORY.md`,
`CORE.md`, `ARCHITECTURE.md`, `GOVERNANCE.md`, `DECISION_REGISTRY.md`,
`FINDINGS.md`, `BATCH_LOG.md`, `ROADMAP.md`, `SESSION_STATE.md`, `VERSION`.
Batch records live under `Batches/` in one alphanumeric sequence, ZAO's own,
from `[A1]`. `MEMORY.md` indexes every root document and states which
surfaces are canonical, regulatory, append-only, or historical. This is the
filing model of `../survivor-awareness` and `../colonist-awareness`, adopted
whole; there is no third system.

## Ground rules

- **Verified APIs only.** Ground truth is the installed game: the decompiled
  `projectzomboid.jar` and the shipped `media/lua` + `media/scripts` trees.
  Never assert engine behavior from memory. A statement without a file and
  line behind it is a hypothesis and is labelled one.
- **Tools are verified before their output is trusted.** An analysis script is
  not evidence until its own correctness is checked against a known-bad
  control. Report the corrected figure, and say that it was corrected.
- **The engine's own seams.** Reach past a seam only when none exists, and
  record why in `DECISION_REGISTRY.md`.
- **No omniscience, no oblivion.** Symmetric failures, and death does not
  lift them: a turned body that pathfinds against facts its person never
  held is the same defect as a survivor doing it.
- **Retention is never addition.** Decay only subtracts from the record. A
  capability appearing after the turn that the person did not carry into it
  is a defect, whatever it does for the encounter.
- **Declarations are promises.** Settings copy and in-game text match shipped
  behavior exactly.
- **Concepts are not copy.** Design terminology directs the work; it reaches
  the UI only when supplied or approved as player-facing text. Provisional
  shorthand from ideation (the operator's or anyone's) never ships as a name.
- **Bespoke implementation.** Everything in this tree is written for this
  project. Reference reading of other mods is fine; copying is not. House
  instruments adopted from SAO and CAO state their lineage in their own
  docstrings.
- **Never name a mod in code.** `mod.info` metadata and `CREDITS.md`-class
  documentation are exempt.
- **Local-first.** The project tree is canonical; remotes publish that state.

## Boundaries set by the operator

- **Reserved decisions.** Strain names, rarity, sandbox enable defaults,
  whether the player walks the same mutation axes as NPCs, and naming in
  general. These are asked before they are needed and never authored into
  prose to look finished. The open-fork ledger is in `ROADMAP.md`.
- **The two mechanisms are not merged.** Zombie intelligence and
  decay/mutation are litigated separately (DR-001). Merging two different
  ideas into one mechanic so the spec looks clean is a defect.
- **Play is later, one project at a time, when the operator says.** ZAO and
  SAO are not playtested in the same window. No test requests, no session
  polling, no orbiting the operator's play.
- **Rare is not a reason to stub.** Settlement formation ships whole or not
  at all (DR-006).
- **Recovery mods are never dependencies.** Used where loaded, replaced by
  ZAO's own course where not (DR-005).

## Execution discipline

- **Operator-mediated.** Substantive direction comes from the operator. Where
  a choice is genuinely arbitrary and consequential it is surfaced rather
  than assumed; where a default is obvious it is taken and stated. When the
  operator has left a fork, ask.
- **Every problem in a message is in scope.** Two complaints that look
  similar are usually two defects. Fix the whole population, not the named
  instance; if something is blocked, finish everything else and say plainly
  what was left and why.
- **A representative example is not the design seed.** When the operator
  illustrates a principle with a case, build the principle, not the case.
- **Batches.** One designed seam per batch, nameable in a sentence. Recorded
  in `BATCH_LOG.md` with a record under `Batches/`; threads tag work across
  time in `Batches/THREADS.md`.
- **Versioning.** The coordinate is `tools/version_replay.py`'s output —
  CAO's machine, adopted (DR-009 here; SAO's DR-013). Nobody picks the
  number.
- **Project history and forge history are separate things.** The batch
  records, decision registry, findings ledger, and this doc-pack are the
  portable project history; a forge history publishes the canonical tree and
  carries no project meaning of its own.

## Evidence standard

A finding is admitted to `FINDINGS.md` when it is reproducible from stated
inputs and its verification method is recorded. The analysis discipline in
SAO's `GOVERNANCE.md` — controls that reproduce the real defect, instruments
distinguishing "found nothing" from "cannot see it", hand-checks on fresh
tools, asking the engine rather than memory — binds here in full; its
citations live in SAO's ledgers and are not respelled into this file.
