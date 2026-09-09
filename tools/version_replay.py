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
