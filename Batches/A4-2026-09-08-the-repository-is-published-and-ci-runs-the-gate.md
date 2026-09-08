# A4 - The repository is published and CI runs the gate

| Field | Record |
|---|---|
| Batch | `A4` |
| Date | 2026-09-08 |
| Name | The repository is published and CI runs the gate |
| Status | Closed append-only batch - nothing about the mod changed, so nothing here is owed a play receipt |
| Threads | [`T-001`](THREADS.md#t-001) |

## Record

ZAO existed as eleven commits on a local `main` with no remote. SAO and CAO
are both public on the operator's account under GPL-3.0, ZAO carries the same
licence and the same doc-pack, and `GOVERNANCE.md` already said the tree is
canonical and remotes publish that state. There was no remote to publish it
to.

It is at `ellyj3rain/zao` now, public, with its history intact rather than
squashed into a first commit.

Publishing it exposed what the repository did not carry that its siblings do.

## What changed

**CI.** `.github/workflows/ci-verify.yml` runs the diff-hygiene check and the
whole border gate on every pull request and every push to `main`, which is the
same content the pre-commit hook runs. `.github/workflows/codeql.yml` scans
`tools/` on pull requests, `main`, and a weekly schedule.

The runner has no Project Zomboid installation and never will, so any border
that reads the installed game must report SKIPPED rather than passing. A check
that cannot run must never look like a check that passed.

**The pull-request shape.** `.github/pull_request_template.md` is SAO's,
carried across unchanged. `NEO.md` gained the publishing convention it did not
have: branch, one squashed commit, a filled-in template, squash-merge, delete
the branch. `main` refuses a direct push. Assistance is not authorship, so no
co-author trailers or tool attribution enter the forge history.

**`CODEOWNERS` and `dependabot.yml`.** The dependabot configuration carries
SAO's `[C58]` correction before the same thing can happen here: the two halves
of `codeql-action` are grouped, because they are two dependencies to dependabot
and one action to CodeQL, which refuses a run whose halves report different
versions.

**Border 1 takes a control tree.** `tools/doc_currency_test.py` had `ROOT`
fixed to the tree the file lives in, so it could not be pointed at a broken
tree and its control had never been run. It takes an optional `argv[1]` now.
SAO carried the identical gap and found it the same way, in its own `[C64]`,
the same day.

**What is named as absent rather than left as an oversight.**
`.github/CI-README.md` records two things SAO has that ZAO does not: no
`gate_reach_test.py`, because ZAO has three checks all named directly in
`check.sh` and the border arrives when the count makes it possible to lose one;
and no `RECEIPTS.md`, because ZAO makes no claim about play evidence that needs
retiring and the ledger arrives with the first observation.

## What was measured before it was designed

ZAO's tree was compared against SAO's before anything was written: `tools/`,
the root doc-pack, `.github/`, the licence, and the git remotes. ZAO's
documents were also searched for the blanket play-evidence claim that SAO's
`[C64]` removed from five of its own files the same day. ZAO makes it nowhere,
so that standard is met by absence and no correction was invented to match a
sibling's.

Branch protection was applied after this pull request ran, not before, because
a required status check must have produced its context at least once for the
protection to name it.

## Not in this batch

**Anything the mod does.** No Lua, no Java, no engine surface. The version
moves because the machine says a repository-and-tooling unit moves it, not
because the county changed.

This governed record is the portable project history for this unit.
