#!/usr/bin/env python3
r"""Border 1 - the doc-pack states one version, and the index knows the root.

SAO's Border 43, carried into this tree at [A1]: that border was paid
for by twelve headers drifting a hundred and eleven batches stale and
by an index that claimed completeness over five unclassified files. The
lesson arrives here before the drift can.

WHAT THIS HOLDS
---------------
  1. Every root `.md` with a `Version` cell states exactly the string in
     `VERSION`.
  2. No document except `BATCH_LOG.md` claims a batch tip in that cell.
     A clause saying `authored at [A1]` is PROVENANCE and is allowed -
     it records when a thing was written, which does not go stale.
  3. `MEMORY.md` classifies every file at the repository root, because
     it says it does.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
VERSION_FILE = ROOT / "VERSION"
MEMORY = ROOT / "MEMORY.md"


def sayable(text):
    """Quoted repository content, folded to ASCII so a fault reads the
    same on any console and through any capture (SAO [B43]: a border's
    stdout encoding follows the locale, and a piped non-UTF-8 byte turns
    the finding into mojibake)."""
    return text.encode("ascii", "replace").decode("ascii")


VERSION_ROW = re.compile(r"^\|\s*Version\s*\|\s*(.+?)\s*\|\s*$", re.M)
# A currency claim names a batch and says it is where things stand.
TIP_CLAIM = re.compile(r"(tip|next|closes at|era)\b", re.I)
PROVENANCE = re.compile(r"authored at\s*`\[[A-Z]\d+\]`", re.I)
# BATCH_LOG is where the tip lives.
TIP_OWNER = "BATCH_LOG.md"


def main():
    faults = []
    print("=" * 74)
    print("WHAT THE DOC-PACK SAYS ABOUT ITSELF")
    print("=" * 74)

    declared = VERSION_FILE.read_text(encoding="utf-8").strip()
    print(f"  VERSION: {declared}")

    headed = 0
    for path in sorted(ROOT.glob("*.md")):
        src = path.read_text(encoding="utf-8", errors="ignore")
        m = VERSION_ROW.search(src)
        if not m:
            continue
        headed += 1
        cell = m.group(1)
        # Strip a provenance clause before judging what is left.
        rest = PROVENANCE.sub("", cell)
        stated = re.search(r"`([^`]+)`", rest)
        if not stated:
            faults.append(
                f"{path.name} has a Version cell with no version in it: "
                f"{sayable(cell)!r}")
        elif stated.group(1) != declared:
            faults.append(
                f"{path.name} states `{stated.group(1)}` and VERSION says "
                f"`{declared}` - it is CANONICAL by MEMORY.md's own "
                'vocabulary, "current truth, edit in place when superseded"')
        if path.name != TIP_OWNER and TIP_CLAIM.search(rest):
            faults.append(
                f"{path.name}'s Version cell claims a batch position: "
                f"{sayable(cell)!r}. The tip lives in {TIP_OWNER} and "
                "nowhere else")

    print(f"  root documents with a Version cell: {headed}")
    if headed == 0:
        faults.append(
            "no root document has a Version cell - this border is reading "
            "for a header shape the doc-pack no longer uses")

    # 3. The index's own completeness claim.
    mem = MEMORY.read_text(encoding="utf-8", errors="ignore")
    classified = set(re.findall(r"\|\s*`([A-Za-z_0-9.]+)`\s*\|", mem))
    classified |= set(re.findall(r"\[([A-Za-z_0-9]+\.md)\]", mem))
    present = {p.name for p in ROOT.iterdir()
               if p.is_file() and not p.name.startswith(".")}
    missing = sorted(present - classified)
    print(f"  root files: {len(present)}   unclassified: {len(missing)}")
    for name in missing:
        faults.append(
            f"`{name}` sits at the repository root and MEMORY.md does not "
            'classify it, while MEMORY.md says "Nothing at the root is '
            'unclassified"')

    print()
    print("VERDICT:")
    if faults:
        for f in faults:
            print(f"  FAULT: {f}")
        return 1
    print("  1) doc currency: every header states VERSION and nothing "
          "else, the tip lives")
    print("     in one file, and the index classifies the whole root")
    return 0


if __name__ == "__main__":
    sys.exit(main())
