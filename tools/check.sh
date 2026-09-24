#!/usr/bin/env bash
# [A1] The gate. SAO's check.sh shape, adopted with the borders this
# tree actually has; the count is not a target and grows only when a
# batch pays for a new instrument.
#
#   tools/check.sh            - check the whole tree
#   tools/check.sh --staged   - structural check only what is staged
#
# Exit non-zero on any failure, so the pre-commit hook can refuse.
set -u
cd "$(dirname "$0")/.." || exit 2

PY=python
command -v python >/dev/null 2>&1 || PY=python3

fail=0
note() { printf '[check] %s\n' "$*"; }

# 1. Structural Lua check on the relevant files. No Lua ships yet; the
#    walk finds nothing until the first batch that lands some, and from
#    that day every file is covered with nothing to remember to enable.
if [ "${1:-}" = "--staged" ]; then
    files=$(git diff --cached --name-only --diff-filter=ACM \
            | grep '\.lua$' || true)
else
    files=$(find mod -name '*.lua' 2>/dev/null || true)
fi

# The gate's verdict must not depend on who invoked it (SAO [C1]): the
# staged file list above is the one thing that legitimately needs the
# hook's git environment; everything after runs with it scrubbed.
unset "${!GIT_@}" 2>/dev/null || true

if [ -n "$files" ]; then
    for f in $files; do
        [ -f "$f" ] || continue
        if ! "$PY" tools/lua_check.py "$f"; then
            note "STRUCTURE FAILED: $f"
            fail=1
        fi
    done
else
    note "no Lua files to check"
fi

# 2. Border 1 - doc currency.
if ! "$PY" tools/doc_currency_test.py; then
    note "BORDER 1 REFUSED: doc currency"
    fail=1
fi

# 3. Border 2 - the version is a machine.
if ! "$PY" tools/version_replay.py; then
    note "BORDER 2 REFUSED: version replay"
    fail=1
fi

# 3. Border 3 - state producer mapping and precedence.
if ! "$PY" tools/state_dump_test.py; then
    note "BORDER 3 REFUSED: state dump"
    fail=1
fi

# 4. Build and install the Java bridge. The build reads this machine's
#    JDK and the game's own jars, so on any machine without them - the
#    forge's runner - the border reports SKIPPED rather than passing: a
#    check that cannot run must never look like a check that passed
#    (the sister's [C56] law, stated in her ci-verify.yml). The
#    powershell.exe detour this replaces ran only on Windows and made
#    the forge's own gate refuse on its first CI run; it was also
#    unnecessary, because the build resolves its own root from its
#    __file__ and never rode on the invoking shell's cwd.
if "$PY" tools/build_java.py --can-build; then
    if ! "$PY" tools/build_java.py; then
        note "BORDER 4 REFUSED: Java bridge"
        fail=1
    fi
else
    note "BORDER 4 SKIPPED: Java bridge (no JDK or game jars on this machine)"
fi

# 5. The real engine VM, including the original missing-next control.
if ! "$PY" tools/pathogen_vm_test.py; then
    note "BORDER 5 REFUSED: pathogen VM"
    fail=1
fi

# 6. Native source holding, terminal removal and reload. Keep the exact-source
# receipt beside the local build scratch for the batch evidence record.
if ! "$PY" tools/return_removal_test.py --receipt _scratch/return-removal-last.json; then
    note "BORDER REFUSED: native return ownership"
    fail=1
fi

# 7. Returned afflicted people are critically viable while their actual
# wounds, treatment state, ordinary wound infection, statistics and XP remain.
if ! "$PY" tools/return_health_test.py --receipt _scratch/return-health-last.json; then
    note "BORDER REFUSED: afflicted return physiology"
    fail=1
fi

# 8. Durable pathogen/settlement state reconstructs disposable Lua and Java
# projections, and a same-process world change releases prior-world handles.
if ! "$PY" tools/runtime_reconstruction_test.py; then
    note "BORDER 8 REFUSED: runtime reconstruction"
    fail=1
fi

# 9. A transferred living Crossed shell stays under ZAO; its death returns to
# SAO's county death funnel, and a refused hand-back remains retryable.
if ! "$PY" tools/external_crossed_test.py; then
    note "BORDER 9 REFUSED: external Crossed lifecycle"
    fail=1
fi

# 10. Only an interruptible live action can authorize the first Afflicted to
# Crossed roll; exact receipt replay never rolls or transfers twice.
if ! "$PY" tools/intentional_exposure_test.py; then
    note "BORDER 10 REFUSED: intentional Crossed exposure"
    fail=1
fi

# 11. Crossed retain their living human shell. An identity-bearing IsoZombie
# is rejected before ownership, settlement, persistence, or cognition, while
# the registered ZAO execution owner exposes the real shell to shared work.
if ! "$PY" tools/crossed_ownership_test.py; then
    note "BORDER 11 REFUSED: Crossed execution ownership"
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    note "GATE REFUSED"
else
    note "gate clean"
fi
exit "$fail"
