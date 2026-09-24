#!/usr/bin/env python3
"""Emit one full-namespace ZAO pathogen-state row per SAO v3 decision.

The state comes from the event-driven pathogen state SAO records. If a row
predates that state, the tool says so with the facts SAO already owns and
leaves the mutation fields empty rather than inventing them. Run, county,
person, event and hour remain the exact one-to-one join identity.
"""

from __future__ import annotations

import argparse
import json
import math
import os
from pathlib import Path
import tempfile
from typing import Any


NAMESPACE_FIELDS = ("runId", "county", "personId", "eventId", "hour")


class ContractError(ValueError):
    """An SAO row or output destination cannot preserve the v3 contract."""


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise ContractError(
                    f"{path}:{line_number}: invalid JSON: {error.msg}"
                ) from error
            if not isinstance(row, dict):
                raise ContractError(
                    f"{path}:{line_number}: each row must be a JSON object"
                )
            rows.append(row)
    if not rows:
        raise ContractError(f"{path}: input contains no decision rows")
    return rows


def terminal_state(record: dict[str, Any]) -> str:
    if record.get("turnedDormant"):
        return "turned"
    if record.get("dead"):
        return "dead"
    if record.get("knoxInfected"):
        return "infected"
    return "living"


def decay_state(record: dict[str, Any]) -> str:
    if record.get("turnedDormant"):
        return "dormant"
    if record.get("dead"):
        return "dead"
    if record.get("knoxInfected"):
        return "course"
    return "living"


def event_state(record: dict[str, Any]) -> dict[str, Any] | None:
    for key in ("pathogenState", "zaoPathogen", "pathogen"):
        value = record.get(key)
        if isinstance(value, dict):
            return value
    return None


def namespace_for(row: dict[str, Any]) -> dict[str, Any]:
    if (row.get("schema") != "speakeasy-decision-row"
            or row.get("schemaVersion") != 3):
        raise ContractError("SAO row requires speakeasy-decision-row schema version 3")
    namespace = row.get("namespace")
    if not isinstance(namespace, dict) or set(namespace) != set(NAMESPACE_FIELDS):
        raise ContractError("SAO row namespace must contain exactly the five v3 fields")
    for field in NAMESPACE_FIELDS[:-1]:
        if not isinstance(namespace[field], str) or not namespace[field]:
            raise ContractError(f"SAO row namespace {field} must be a nonempty string")
    hour = namespace["hour"]
    if (not isinstance(hour, (int, float)) or isinstance(hour, bool)
            or not math.isfinite(hour)):
        raise ContractError("SAO row namespace hour must be finite")
    person = row.get("person")
    situation = row.get("situation")
    if (not isinstance(person, dict)
            or person.get("id") != namespace["personId"]):
        raise ContractError("SAO row person differs from namespace")
    if (not isinstance(situation, dict)
            or situation.get("county") != namespace["county"]
            or situation.get("hour") != hour):
        raise ContractError("SAO row situation differs from namespace")
    return {field: namespace[field] for field in NAMESPACE_FIELDS}


def state_for(row: dict[str, Any]) -> dict[str, Any]:
    namespace = namespace_for(row)
    person = row["person"]
    record = person.get("record", {})
    if not isinstance(record, dict) or "id" not in record:
        raise ContractError("SAO row has no person.record.id")
    if record["id"] != namespace["personId"]:
        raise ContractError("SAO person.record.id differs from namespace")

    explicit = event_state(record)
    current_form = explicit.get("currentForm", "none") if explicit else "none"
    form_performance = (
        explicit.get("formPerformance", 0.0) if explicit else 0.0
    )
    attributes = explicit.get("attributeMutations", {}) if explicit else {}
    if not isinstance(attributes, dict):
        attributes = {}
    terminal = explicit.get("terminalState") if explicit else None
    decay = explicit.get("decayState") if explicit else None
    source = explicit.get("source") if explicit else None
    last_event = explicit.get("lastEvent") if explicit else None

    pathogen = {
        "infected": record.get("knoxInfected"),
        "immuneProgress": record.get("immuneProgress"),
        "infectionSpanHours": record.get("infectionSpanHours"),
        "biteDeathAtHours": record.get("biteDeathAtHours"),
        "dead": record.get("dead"),
        "deathCause": record.get("deathCause"),
        "diedAtHours": record.get("diedAtHours"),
        "diedInGroup": record.get("diedInGroup"),
        "turnedDormant": record.get("turnedDormant"),
        "currentForm": current_form,
        "formPerformance": form_performance,
        "attributeMutations": attributes,
        "decayState": decay or decay_state(record),
        "terminalState": terminal or terminal_state(record),
        "source": source or ("event" if explicit else "record"),
        "lastEvent": last_event,
    }

    visible_forms = []
    if current_form != "none":
        attribute_pressure = 0.0
        for performance in attributes.values():
            if isinstance(performance, (int, float)):
                attribute_pressure += float(performance) * 0.10
        attribute_pressure = min(0.40, attribute_pressure)
        knowledge_store = record.get("mutationKnowledge")
        if not isinstance(knowledge_store, dict):
            knowledge_store = {}
        knowledge_entry = knowledge_store.get(current_form)
        if not isinstance(knowledge_entry, dict):
            knowledge_entry = {}
        knowledge = knowledge_entry.get("weight", 0.0)
        adaptation = max(0.50, 1.0 - float(knowledge) * 0.50)
        pressure = (
            (1.0 + form_performance * 0.50 + attribute_pressure)
            * adaptation
            - 1.0
        )
        visible_forms.append(
            {
                "form": current_form,
                "performance": form_performance,
                "source": source or ("event" if explicit else "record"),
                "pressure": pressure,
            }
        )

    return {
        "schema": "zao-decision-state",
        "schemaVersion": 3,
        "namespace": namespace,
        "asOfHour": namespace["hour"],
        "pathogen": pathogen,
        "visibleForms": visible_forms,
    }


def atomic_write(path: Path, states: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary_name = tempfile.mkstemp(
        prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temporary = Path(temporary_name)
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8", newline="\n") as out:
            for state in states:
                out.write(json.dumps(
                    state, ensure_ascii=False, sort_keys=True,
                    separators=(",", ":")))
                out.write("\n")
            out.flush()
            os.fsync(out.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.close(descriptor)
        except OSError:
            pass
        temporary.unlink(missing_ok=True)
        raise


def states_for(rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
    states = []
    unique = set()
    for row in rows:
        state = state_for(row)
        key = tuple(state["namespace"][field] for field in NAMESPACE_FIELDS)
        if key in unique:
            raise ContractError(f"duplicate full namespace: {key!r}")
        unique.add(key)
        states.append(state)
    return states


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Emit ZAO pathogen-state rows from an SAO decision dump."
    )
    parser.add_argument("--sao", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.sao.expanduser().resolve(strict=False) == \
            args.out.expanduser().resolve(strict=False):
        print("REFUSED: output destination must differ from the SAO input")
        return 2
    try:
        rows = read_jsonl(args.sao)
        states = states_for(rows)
        atomic_write(args.out, states)
    except (ContractError, OSError, UnicodeError) as error:
        print(f"REFUSED: {error}")
        return 2
    print(f"wrote {len(states)} ZAO state row(s) to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
