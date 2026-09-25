# A41 - Shared living execution owner

| Field | Record |
|---|---|
| Batch | `A41` |
| Timestamp | 2026-09-25 12:01 UTC / 05:01 PST |
| Name | Shared living execution owner |
| Status | Closed implementation batch; loaded-world receipt pending |
| Threads | [`T-001`](THREADS.md#t-001), [`T-002`](THREADS.md#t-002) |

## One driver available in every representation state

`ZAO_ExecutionOwner` now holds the registered SAO adapter outside the loaded
client controller. Loaded, dormant and headless execution therefore consult the
same owner for a ZAO-owned living person. `ZAO_Controller` continues to request
registration at startup and tick boundaries, but it no longer defines a second
inline adapter or becomes a dependency for bodyless coordination.

The adapter locates only the retained human shell currently controlled under
the person's stable ZAO token. It asks `ZAO.Driver` for current activity,
capability and generic competing pressure, with a bounded fallback when the
loaded driver surface is unavailable. A missing shell is reported as
unrepresented; it is not converted into a zombie body, death, incapacity,
migration or another representation rule. The separate driving adapter remains
unchanged.

After SAO proves proposal acquisition, the adapter dispatches appraisal from
the person's current pathogen state. Afflicted calls
`ZAO.Afflicted.appraiseMatter`; Crossed calls
`ZAO.Crossed.appraiseMatter`. Both responses name the common `ZAO.Driver`
executor, but each policy continues to own its motives, pressure interpretation,
terms and choice. The generic envelope does not expose terminal state, diet or
predatory truth. Dormant maintenance and threat-response observation are also
available through this same registered owner.

## Evidence and boundary

Updated Borders 11 and 15 execute the shared owner with the sister's C84
coordination module. Border 11 proves the valid retained shell and side-effect-
free `IsoZombie` rejection. Border 15 proves distinct Afflicted provisioning and
Crossed rendezvous appraisal through the shared registration, including a
bodyless deferral and current-state reappraisal. Each retains six source
mutations. SAO's source-bound audit separately runs twenty actual Survivor,
Afflicted and Crossed appraisals and rejects missing registration plus forged
final executor attribution.

This is mechanical headless evidence. No game window was opened. Loaded-world
speech, motion, animation and save/reopen behavior remain unobserved. A41 adds
no physiology, sustenance, predation, mortality, migration, conversion or
spontaneous Afflicted-to-Crossed rule.
