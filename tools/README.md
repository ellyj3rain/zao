# Tools

`state_dump.py` emits one ZAO pathogen-state row per SAO decision moment,
keyed by the SAO person id and the decision hour. The state is derived only
from facts SAO already records. A body with no assigned form is in the
"none" form, and its performance is zero.

`ZAO_State.lua` is the runtime state surface. It exposes the same mapping:
terminal state, current form, form performance, decay state, and visible
forms. `state_dump_test.py` is the border that checks the mapping and its
precedence.

`ZAO_Controller.lua` claims identity-bearing zombies and drives each body
according to its form. `ZAO_API.lua` publishes the read-only claim surface:
`ZAO.owns`, `ZAO.formOf`, and `ZAO.performanceOf`.

`build_java.py` compiles the Java bridge, packages `ZAO.jar`, and installs it
into the mod tree. `make_art.py` generates the icon and poster.

`pathogen_vm_test.py` runs pathogen state transitions in the installed game's
Kahlua VM and requires the original missing-`next` implementation to fail.
It reports a skip when the engine or JDK is absent.
