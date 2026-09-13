#!/usr/bin/env python3
"""Border: the state producer's mappings are correct and precedence is explicit.

The producer reads the state the pathogen recorded. That is the whole
law of this border, held from both sides:

  * A record that carries the event-driven state (the `pathogenState`
    SAO's inspect rows write, built by `ZAO.State.of`) passes its
    fields through - current form, performance, source - and the
    visible-forms list is emitted with the pressure chain computed
    on top of them.
  * A record with NO recorded state leaves the mutation fields empty
    - form `none`, performance zero, no visible forms - however
    infected, dead or turned it is. That is [A18]'s law ("no
    mutation state is invented here") and [A22]'s gate (a body
    carries a form only when the pathogen has already acted on it),
    and it is what the runtime state surface holds too
    (`ZAO_State.lua`: "never rolls a form and never derives one from
    a person id or clock"). The first draft of this border expected
    a form derived for a bare record; that derivation is gone, and
    the control below is here so it cannot return unnoticed.
  * Terminal and decay precedence are explicit when two facts are
    present, and a recorded terminal state (`crossed`, `afflicted`)
    outranks the record's own facts, mirroring `State.terminalOf`.

Real input shapes are pinned, not just synthetic ones: SAO's inspect
row writes `mutationKnowledge` as the adaptation DESCRIBE string, so
the knowledge term must treat a string as no structured weight rather
than crash or read through it.
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import state_dump


def check(name, actual, expected):
    if actual != expected:
        print(f"  FAULT: {name}: {actual!r} != {expected!r}")
        return 1
    return 0


def main():
    failures = 0

    samples = [
        ({"turnedDormant": True}, "turned", "dormant"),
        ({"dead": True}, "dead", "dead"),
        ({"knoxInfected": True}, "infected", "course"),
        ({}, "living", "living"),
    ]

    for record, terminal, decay in samples:
        failures += check(
            f"terminal({record})",
            state_dump.terminal_state(record),
            terminal,
        )
        failures += check(
            f"decay({record})",
            state_dump.decay_state(record),
            decay,
        )

    # Controls: precedence must be explicit when two facts are present.
    failures += check(
        "terminal(turned overrides dead)",
        state_dump.terminal_state({"turnedDormant": True, "dead": True}),
        "turned",
    )
    failures += check(
        "terminal(dead overrides infected)",
        state_dump.terminal_state({"dead": True, "knoxInfected": True}),
        "dead",
    )

    # The base record: every pathogen fact present, so nothing below
    # fails for lack of the facts - only for how they are read.
    def base_record():
        return {
            "person": {
                "record": {
                    "id": "sao-44",
                    "knoxInfected": True,
                    "immuneProgress": 0,
                    "infectionSpanHours": 62.66,
                    "biteDeathAtHours": 1670.66,
                    "dead": True,
                    "deathCause": "zombie",
                    "diedAtHours": 1680,
                    "diedInGroup": "company-sao-42",
                    "turnedDormant": True,
                },
            },
            "situation": {"hour": 888},
        }

    # A recorded state passes through, and the pressure chain is
    # computed on top of it. Minimal case: no attributes, no
    # structured knowledge - adaptation floor is 1.0, attribute
    # pressure 0.0, so pressure is the performance's own half.
    row = base_record()
    row["person"]["record"]["pathogenState"] = {
        "currentForm": "Wrecker",
        "formPerformance": 0.06,
    }
    state = state_dump.state_for(row)
    pathogen = state["pathogen"]
    failures += check("currentForm", pathogen["currentForm"], "Wrecker")
    failures += check("formPerformance", pathogen["formPerformance"], 0.06)
    failures += check("source", pathogen["source"], "event")
    failures += check(
        "visibleForms",
        state["visibleForms"],
        [{
            "form": "Wrecker",
            "performance": 0.06,
            "source": "event",
            "pressure": 0.030000000000000027,
        }],
    )

    # The full pressure chain: five attribute mutations at 2.0 each
    # would sum 1.0 and are capped at 0.40, and structured mutation
    # knowledge at weight 0.6 halves toward the 0.50 adaptation floor.
    row = base_record()
    row["person"]["record"]["pathogenState"] = {
        "currentForm": "Wrecker",
        "formPerformance": 0.06,
        "attributeMutations": {
            "grip": 2.0, "reach": 2.0, "lunge": 2.0, "hide": 2.0,
            "shriek": 2.0,
        },
    }
    row["person"]["record"]["mutationKnowledge"] = {
        "Wrecker": {"weight": 0.6},
    }
    state = state_dump.state_for(row)
    failures += check(
        "pressure(attribute cap and knowledge adaptation)",
        state["visibleForms"][0]["pressure"],
        0.001000000000000112,
    )

    # The shape SAO's inspect row actually writes: mutationKnowledge
    # is the adaptation DESCRIBE string, not a table. A string is no
    # structured weight - the term reads as zero, nothing crashes.
    row = base_record()
    row["person"]["record"]["pathogenState"] = {
        "currentForm": "Wrecker",
        "formPerformance": 0.06,
    }
    row["person"]["record"]["mutationKnowledge"] = (
        "Wrecker weight 0.6 grip 1.5"
    )
    state = state_dump.state_for(row)
    failures += check(
        "pressure(knowledge described as a string)",
        state["visibleForms"][0]["pressure"],
        0.030000000000000027,
    )

    # A recorded terminal state outranks the record's own facts,
    # mirroring `State.terminalOf`: "crossed" and "afflicted" are the
    # pathogen's own verdicts and are not re-derived from the record.
    row = base_record()
    row["person"]["record"]["pathogenState"] = {
        "terminalState": "crossed",
        "decayState": "gone",
    }
    state = state_dump.state_for(row)
    failures += check(
        "terminal(recorded crossed outranks turned)",
        state["pathogen"]["terminalState"],
        "crossed",
    )
    failures += check(
        "decay(recorded state outranks the record's facts)",
        state["pathogen"]["decayState"],
        "gone",
    )

    # THE NO-INVENTION CONTROL. Every pathogen fact is present -
    # infected, dead, turned - and no state was recorded. The form is
    # none, the performance zero, no forms are visible, and the
    # fields say where they came from: the record, not an event.
    row = base_record()
    state = state_dump.state_for(row)
    pathogen = state["pathogen"]
    failures += check(
        "currentForm(no recorded state, however acted-on)",
        pathogen["currentForm"],
        "none",
    )
    failures += check(
        "formPerformance(no recorded state)",
        pathogen["formPerformance"],
        0.0,
    )
    failures += check(
        "visibleForms(no recorded state)",
        state["visibleForms"],
        [],
    )
    failures += check(
        "source(no recorded state)",
        pathogen["source"],
        "record",
    )
    failures += check(
        "terminalState(still the record's own facts)",
        pathogen["terminalState"],
        "turned",
    )
    failures += check(
        "decayState(still the record's own facts)",
        pathogen["decayState"],
        "dormant",
    )

    print("=" * 74)
    print("STATE DUMP")
    print("=" * 74)
    if failures:
        print(f"  FAULT: {failures} check(s) failed")
        return 1
    print("  state mapping, precedence, the recorded-state gate, and")
    print("  the pressure chain: correct")
    return 0


if __name__ == "__main__":
    sys.exit(main())