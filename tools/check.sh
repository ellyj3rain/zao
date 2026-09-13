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
# The Windows path of the repo root, for the one step that needs
# PowerShell. `pwd -W` is the Git Bash spelling; `wslpath` is the WSL
# one. Either shell runs this gate, and neither has the other's tool,
# so the two are tried in order and the build's location never rides
# on whichever shell happened to invoke the gate - a launch that
# inherited the right cwd by accident worked, but the error it
# printed on every run was the gate betting on that accident.
WINROOT="$(pwd -W 2>/dev/null || true)"
if [ -z "$WINROOT" ]; then
    WINROOT="$(wslpath -w "$(pwd)" 2>/dev/null || true)"
fi

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

# 4. Build and install the Java bridge.
if ! powershell.exe -NoProfile -Command "Set-Location -LiteralPath '$WINROOT'; python tools\\build_java.py; exit \$LASTEXITCODE"; then
    note "BORDER 4 REFUSED: Java bridge"
    fail=1
fi

if [ "$fail" -ne 0 ]; then
    note "GATE REFUSED"
else
    note "gate clean"
fi
exit "$fail"
