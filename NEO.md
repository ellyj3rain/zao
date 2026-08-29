| Document | Zombie Awareness Overhaul - instruction surface |
|---|---|
| Author | ellyj3rain |
| Repository | `NEO.md` |
| Status | CANONICAL - the first file any model in this repository reads. |

# Instruction surface

`CLAUDE.md` and `AGENTS.md` are autoload shims that point here.

Host identity is a vantage, not authority. The operator (ellyj3rain) is the
design authority and the judge of how the game looks and plays. Code-level
verification never settles that question.

Read `CORE.md` for identity and composition, `ARCHITECTURE.md` for the
ratified shape, `GOVERNANCE.md` for operating discipline, and
`SESSION_STATE.md` for where the work stands.

## What this repository is

A Project Zomboid Build 42 add-on beside Survivor Awareness Overhaul
(`../survivor-awareness`). It owns the turned: what remains of a person's
mind after zombification and how it rots, and — separately — what the
pathogen does to bodies and what anyone is permitted to know about it.
Living people are SAO's until the turn.

## Operating conventions

- **One alphanumeric batch sequence.** Work lands in numbered batches with a
  record under `Batches/`. The catalog is ZAO's own, from `[A1]`, thin; the
  tip is `BATCH_LOG.md`'s last row. A batch is one designed seam nameable in
  a sentence, not a chat turn.
- **Batch shape.** A batch is a coherent development unit, closed when the
  work is done, not when a message ends. Closing a batch means the record, the
  `BATCH_LOG.md` row, and the `SESSION_STATE.md` advance, in that order, plus
  the version machine's restamp — and, once instruments exist for the class
  the batch touched, a border and a control that flips its verdict.
- **Commit shape.** `[A#] source: ...` for implementation, `[A#] reference: ...`
  for records and documents, `[A#] governance: ...` for closings and process,
  `[REPO] ...` for repository mechanics. One batch is one logical unit and
  lands in few commits, not a stream of them. Assistance is not authorship:
  no co-author trailers or tool attribution anywhere in the forge history.
- **Append-only ledgers.** `DECISION_REGISTRY.md`, `FINDINGS.md`, and closed
  batch records are extended, never rewritten.
- **The version is a machine.** `tools/version_replay.py` computes the
  coordinate from the classified batch chronology (CAO's model, adopted here
  as it was at SAO's DR-013). Nobody picks the number; to disagree with the
  coordinate, disagree with a tier in the table.
- **Verified APIs only.** Ground truth is the installed game
  (`projectzomboid.jar`, the shipped `media/lua` and `media/scripts` trees).
  Never assert engine behavior from memory; an unsupported statement is a
  hypothesis and is labelled one.
- **Verify the tool before trusting its output.** An analysis script is not
  evidence until its own correctness is established against a known-bad
  control.
- **The gate.** `tools/check.sh` runs every border; the pre-commit hook runs
  it. Run it before every commit and read the whole verdict, including the
  exit code.
- **Names come from the operator or from surfaces that already exist** — SAO,
  CAO, vanilla, and the Workshop mods this project hooks. No new dialect, no
  provisional concept names promoted into spec. Strain names, rarity, enable
  defaults, and whether the player walks the NPC mutation axes are the
  operator's calls: ask, never author them into prose.
- **Operator-mediated.** Arbitrary consequential choices are surfaced.
  Obvious defaults are taken and stated. When the operator has left a fork,
  ask; never merge two ideas into one mechanic so the spec looks clean.
- **Say what is not known.** An honest gap is worth more than a confident
  guess, and a guess presented as a finding is a defect.

## Laws

1. No omniscience, no oblivion. A walker that pathfinds against facts its
   person never held is as wrong as a survivor doing it.
2. The mind that rots is the record. Whatever remains after the turn is the
   person's own record decaying — never a new species brain, never a second
   planner.
3. Zombification is not one outcome.
4. One brain per body. Living people are SAO's until the turn; the turned
   body is ZAO's while ZAO is on, vanilla's when it is off.
5. Rare is not stubbed. A mechanic kept rare on purpose is still built whole.
