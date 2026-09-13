#!/usr/bin/env bash
# Deploy ZAO to the game's mods directory.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# The mods directory under the user's home, the same spelling SAO's
# own deploy.sh uses. `$HOME` is the Git Bash `/c/Users/...`; the old
# hard-coded `/mnt/c/...` was the WSL spelling and does not exist in
# Git Bash at all, so a deploy from here failed before it copied a
# file - the script only ever worked from the one shell it was
# written in.
DST="$HOME/Zomboid/mods/ZombieAwareness"

if powershell.exe -NoProfile -Command "if (Get-Process ProjectZomboid64,java -EA SilentlyContinue | Where-Object { \$_.Path -like '*ProjectZomboid*' }) { exit 0 } else { exit 1 }" 2>/dev/null; then
    echo "REFUSED: the game is running. Close it first."
    exit 1
fi

rm -rf "$DST"
cp -r "$ROOT/mod" "$DST"

echo "deployed to $DST"
find "$DST" -type f | sed "s|$DST|  .|"
