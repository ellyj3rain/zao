#!/usr/bin/env python3
"""A44: reuse SAO's actual orienting and elapsed-owner transaction instruments.

ZAO owns the driver and Maintenance adapter under test. SAO owns the shared
runner and fixtures; this wrapper passes the current ZAO source root and
requires their complete controlled verdicts without copying either runtime.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parent.parent
GAME = Path(os.environ.get(
    'PZ_DIR', r'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid'))
JDK = Path(os.environ.get(
    'JDK_BIN', r'C:\Users\jleyv\Peanut Butter\JetBrains\Java\bin'))

def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sao-root', type=Path, default=Path(os.environ.get(
        'SAO_ROOT', str(ROOT.parent / 'survivor-awareness'))))
    parser.add_argument('--zao-root', type=Path, default=ROOT)
    parser.add_argument('--output', type=Path)
    args = parser.parse_args(argv)
    required = (GAME / 'projectzomboid.jar', JDK / 'javac.exe', JDK / 'java.exe')
    if not all(path.is_file() for path in required):
        print('A44 SKIPPED: installed game and JDK required for living orientation and elapsed ownership')
        return 0
    sao, zao = args.sao_root.resolve(), args.zao_root.resolve()
    runners = {
        'orientation': sao / 'tools/orienting_policy_checks/run.py',
        'elapsed': sao / 'tools/cooking_checks/run_transaction.py',
    }
    for path in runners.values():
        if not path.is_file():
            print('A44 REFUSED: SAO C89 verification input missing: ' + str(path))
            return 1
    receipt = {'status': 'running', 'saoRoot': str(sao),
               'zaoRoot': str(zao), 'proofs': {}}
    with tempfile.TemporaryDirectory(prefix='zao-living-orientation-') as temporary:
        work = Path(temporary)
        for name, path in runners.items():
            output = work / (name + '.json')
            done = subprocess.run(
                [sys.executable, str(path), str(sao), '--zao-root', str(zao),
                 '--output', str(output)], capture_output=True, text=True,
                encoding='utf-8', errors='replace', timeout=150)
            if done.returncode or not output.is_file():
                print('A44 REFUSED: ' + name + ' instrument\n' + done.stdout + done.stderr)
                return 1
            proof = json.loads(output.read_text(encoding='utf-8'))
            if proof.get('status') != 'passed' or not proof.get('controls'):
                print('A44 REFUSED: ' + name + ' lacked a controlled passing receipt')
                return 1
            if name == 'orientation':
                current = [proof['sources']['driver']]
            else:
                current = [
                    {'path': p, 'sha256': value} for p, value in proof['inputs'].items()
                    if Path(p).name in ('ZAO_Maintenance.lua', 'ZAO_ExecutionOwner.lua')
                ]
            expected = 1 if name == 'orientation' else 2
            if len(current) != expected:
                print('A44 REFUSED: current ZAO source inventory missing')
                return 1
            for row in current:
                checked = Path(row['path']).resolve()
                if not checked.is_relative_to(zao) or (
                    hashlib.sha256(checked.read_bytes()).hexdigest() != row['sha256']
                ):
                    print('A44 REFUSED: instrument did not execute exact current ZAO source')
                    return 1
            receipt['proofs'][name] = proof
            print(f"A44 {name}: {proof['cases']} cases, "
                  f"{len(proof['controls'])} named defect controls", flush=True)
        receipt['status'] = 'passed'
        if args.output:
            args.output.parent.mkdir(parents=True, exist_ok=True)
            args.output.write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')
    print('A44 PASS: both living state drivers orient through shared hearing; elapsed replay retains its ZAO owner')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
