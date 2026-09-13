#!/usr/bin/env python3
"""Emit one ZAO pathogen-state row per SAO decision moment.

The state comes from the event-driven pathogen state SAO records. If a row
predates that state, the tool says so with the facts SAO already owns and
leaves the mutation fields empty rather than inventing them.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path
from typing import Any


def read_jsonl(path: Path) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    with path.open("r", encoding="utf-8") as handle:
        for line_number, line in enumerate(handle, 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError as error:
                raise SystemExit(
                    f"{path}:{line_number}: invalid JSON: {error.msg}"
                ) from error
            if not isinstance(row, dict):
                raise SystemExit(
                    f"{path}:{line_number}: each row must be a JSON object"
                )
            rows.append(row)
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


def state_for(row: dict[str, Any]) -> dict[str, Any]:
    person = row.get("person", {})
    record = person.get("record", {})
    situation = row.get("situation", {})
    if not isinstance(record, dict) or "id" not in record:
        raise SystemExit("SAO row has no person.record.id")
    if "hour" not in situation:
        raise SystemExit(f"SAO row {record['id']} has no situation.hour")

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
        "id": record["id"],
        "hour": situation["hour"],
        "pathogen": pathogen,
        "visibleForms": visible_forms,
    }


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Emit ZAO pathogen-state rows from an SAO decision dump."
    )
    parser.add_argument("--sao", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    rows = read_jsonl(args.sao)
    unique: dict[tuple[str, Any], dict[str, Any]] = {}
    with args.out.open("w", encoding="utf-8", newline="\n") as out:
        for row in rows:
            state = state_for(row)
            key = (state["id"], state["hour"])
            if key in unique:
                continue
            unique[key] = state
            out.write(json.dumps(state, ensure_ascii=False, separators=(",", ":")))
            out.write("\n")
    print(f"wrote {len(unique)} ZAO state row(s) to {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
