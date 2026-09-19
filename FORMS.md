| Document | ZAO Form Registry |
|---|---|
| Version | `0.3.1.1-pre-alpha` |
| Author | ellyj3rain |
| Repository | `FORMS.md` |
| Status | CANONICAL - the source-port forms and their state contract. |

# Form registry

The six source-port forms are internal candidate names, not player-facing
copy. They are the shapes the pathogen can roll when a turned body takes a
form.

| Form | Candidate meaning |
|---|---|
| Puker | a body that projects material at range |
| Husk | a body whose remaining mass is harder to stop |
| Skitter | a body that moves low and fast |
| Wrecker | a body built to break barriers |
| Leaper | a body that closes distance in one movement |
| Weeper | a body that leaves a hazardous trace |

## The roll

The pathogen owns the form roll. A body carries a form only when the pathogen
has already acted on it: infected, dead, or turned. A turned body has a 10
percent chance of taking one of these forms. The roll is uniform across the
six candidates by default, and the odds are a sandbox dial.

## Performance

Form performance is a normalized state value between 0 and 1. It is not a
gameplay number and it is not a skill. Later work converts this value into
the engine’s own actuator numbers.

## Visibility

A form is a visible fact. When a body carries a form, the state surface emits
that form and its normalized performance to Perception. Perception decides
what a living person can actually see.

## Movement

The form also drives the body. `ZAO_Controller.lua` claims the turned body
and moves it according to its form: Puker holds range, Skitter flanks, and the
remaining forms close on the target.

## What is not settled

- The player-facing names
- The animation and actuator mapping for each form
- The exact in-game numbers behind normalized performance
- The sandbox’s exact default weights
