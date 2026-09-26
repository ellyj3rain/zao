# A43 - Native facing and observer exclusion

| Field | Record |
|---|---|
| Batch | `A43` |
| Timestamp | 2026-09-26 04:57 UTC / 21:57 PST |
| Name | Native facing and observer exclusion |
| Status | Closed implementation batch; integrated observer acceptance and publication pending |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## Native form execution

Puker, Wrecker and Leaper windups now call the installed character-facing
method `faceThisObject(IsoObject)`. The former `faceObject` call did not exist
on the native character, and its surrounding protected call hid that failure
from the Lua driver. SAO's isolated C86 run 08 exposed the missing method;
the recorded runs 09 and 10 completed with the repair.

Border 16 binds the actuator to the installed engine through Java reflection
and executes each production form's windup in the installed Kahlua VM.
Restoring the actual invalid method must fail for missing facing even inside
the protected call. The check also verifies that facing continues through
the next windup update.

## Observer participation boundary

The shared `ZAO.Participants.player(index)` lookup retains ordinary engine
players and excludes a slot carrying the exact Boolean
`SAO_ObserverAnchor` marker. Turned target selection, Weeper listeners,
living external-person processing, the inspector and the overlay now use
that lookup. A native host can keep its detached rendering/loading reference
without presenting that reference to these ZAO consumers as a participant.
ZAO's existing living-state policies and execution owners remain authoritative.

The facing repair is an in-place correction. Integrating observer exclusion
across the existing player consumers makes the combined unit a kohai
extension under the version machine; it introduces no new pathogen state
or action family.

## Evidence and remaining work

`tools/check.sh` covers all sixteen borders and structural Lua validation.
The local full-gate transcript is retained under `_scratch/a43-final-gate/`.
Native facing has an installed-engine reflection check, production VM
execution and the original-call mutation control. The participant lookup's
integration is recorded from its actual call sites; Border 16 does not
establish the complete camera and region-residency cycle.

Integrated autonomous viewing, desktop interaction, save/reopen durability,
and the operator's evaluation of behavior remain separate evidence in the
sister simulation workbench. This batch does not ratify a scenario or admit
observations into a training dataset. Source remains pre-alpha, and publication
is coordinated with the final native integration.


## Observer residency extension

Recorded: 2026-09-26 05:35 UTC / 22:35 PST.

This extension supersedes the earlier description of living external-person
processing as a consumer of the filtered player lookup. Actor-facing
`ZAO.Participants.player(index)` still excludes the observer marker.
`ZAO.Participants.residencyCenter()` now returns the raw infrastructure
reference coordinates separately. The Controller's `processExternalPeople`
uses that center to materialize nearby living Afflicted and Crossed and to
hibernate their bodies when the observed region moves away. A participating
player is unnecessary, and the observer remains outside actor targeting and
membership. State policy and execution ownership stay with the existing ZAO
owners.

Border 9 now loads the actual production Controller and Participants in the
installed Kahlua VM with controlled body fixtures. For both Afflicted and
Crossed it checks near-region materialization, far-region hibernation and
preservation of the living state. It separately refuses observer admission
through `player(0)`. Removing residency coordinates is a failing regression
control alongside the existing dead-body and pending-transfer controls.

The expanded Border 9 passes. The original full-gate transcript and inventory
under `_scratch/a43-final-gate/` describe the earlier facing/exclusion tree;
they are not validation receipts for this extension. The full sixteen-border
rerun for the expanded source passes with no skips and exit code zero in
`gate-residency.log`; its SHA-256 is
`92e881ae733a905ed65ca988ea2730c213e5130e8a7361a26cc3e68669444328`.
This record, the README and session state now describe the residency path. The
existing README and A43 DOCX exports are regenerated from their updated sources;
there is no existing session-state DOCX export.

Native workbench run 19 verifies the real engine hook and the separation of
manual panning from region residency. The white engine view is repaired;
transient dark first visits remain under investigation. Native stop/save/reopen
durability, the operator's evaluation of behavior and coordinated publication
remain pending. These observations are unreviewed and create no dataset
ratification or training admission.


## Native save/reopen checkpoint and publication scope

Recorded: 2026-09-26 05:40 UTC / 22:40 PST.

Native workbench run 19 stopped and completed its save with zero player
membership. Same-save attempt 2 has resumed cleanly from game hour 2.659274,
retaining the same 32 people and producing new observation sequence 4. This
supersedes the earlier pending-first-stop status; the reopened attempt's final
stop and the broader body-visibility repair in SAO remain pending. This is a
bounded save/reopen checkpoint, not overall observer or behavioral acceptance.

A43 publication proceeds for its closed facing, participant-exclusion and
living-person residency scope. Its sixteen-border local gate passes with no
skips, and the PR must satisfy the current required forge checks. Outstanding
simulation-workbench verification remains separate. The batch creates no
operator approval, scenario ratification or training admission.


## Native unload ownership and emitter vocals

Recorded: 2026-09-26 06:14 UTC / 23:14 PST.

The external-person Controller now honors SAO.Body.recover(rec) before using a
retained living body. A false recovery result preserves that body's ownership
while withholding driving, position writes and materialization. Border 9 adds
an unresolved-unload/resume case and rejects a fourth control that ignores the
recovery result. The full sixteen-border gate for this extension passed with
no skips and exit code zero in `_scratch/a43-final-gate/gate-unload.log`, whose
SHA-256 is `cd8c9ec9aa5a33f84b79f18535dcd37c5151f9e04185f52386e9140da543aaff`.

Native workbench run 20 exposed another absent body method: the protected
`zombie:playVocals()` call. The installed `ZombieVocalsManager$Slot.playSound`
gets the body's `getVoiceSoundName()` and calls its character emitter's
`playVocals(String)`. ZAO now uses those exact public methods, preserving the
engine-selected vocal name. Border 16 reflects their signatures, exercises the
cue through each production windup and rejects restoration of either invalid
body-level facing or vocal call. It also checks that a held windup does not
restart its cue every tick. The focused border and Lua structure check pass;
publication runs the full gate over the combined tree before the required CI.

These changes extend A43's native actuator and residency repair. The broader
SAO visibility work and overall observer acceptance remain pending. No new
behavioral acceptance, ratified scenario or training admission is claimed.
