# A30 - The Sandbox prefix is the engine's lookup, never the title

| Field | Record |
| --- | --- |
| Batch | `A30` |
| Date | 2026-09-12 |
| Name | The Sandbox prefix is the engine's lookup, never the title |
| Status | Closed append-only batch - verification record, no code change |
| Threads | [`T-002`](Batches/THREADS.md#t-002) |

## Record

The operator clarified (2026-09-12): "to be clear, the configuration for
zao in sandbox does not literally need to be prefixed my sandbox in the
title." Read against `[A29]`'s translation work, the question underneath
was whether the `Sandbox_` prefix on the keys in
`Translate/EN/Sandbox.json` puts the word "Sandbox" in front of the
player - and whether that file is the live mechanism at all.

This batch answers it from the engine's own code, disassembled from the
installed `projectzomboid.jar` - not assumed from the vanilla file's
shape:

- **The option names and tooltips.** `CustomSandboxOptions` parses
  `sandbox-options.txt` and hands each option's raw `translation` field
  to `SandboxOptions.newCustomOption`, which calls `setTranslation`
  verbatim - no prefixing at parse time. The prefix is applied at READ
  time, inside the option classes themselves:
  `SandboxOptions$BooleanSandboxOption.getTranslatedName()` calls
  `Translator.getText(...)` on the string built from the bootstrap
  constant `Sandbox_` - that is, `getText("Sandbox_" ..
  translation)` - and `getTooltip()` uses `Sandbox__tooltip`:
  `getTextOrNull("Sandbox_" .. translation .. "_tooltip")`. Verified in
  the bytecode's BootstrapMethods section; the same shape holds in the
  Integer, Double, Enum, and String option classes.
- **The page title.** `ServerSettingsScreen.lua` (engine file, lines
  5135-5149) creates a page for every custom option whose `page` field
  is set, naming it with the RAW page id - `ZombieAwareness` - and then
  transforms it once: `page.name = page.title or getText("Sandbox_" ..
  page.name)`. The sandbox screen (`SandboxOptions.lua:543`) adds that
  translated name to the page list.
- **The resolution, end to end.** ZAO's `page = ZombieAwareness` looks
  up `Sandbox_ZombieAwareness`; its
  `translation = ZombieAwareness_Enable` looks up
  `Sandbox_ZombieAwareness_Enable` and
  `Sandbox_ZombieAwareness_Enable_tooltip`. Every one of those keys
  exists in `[A29]`'s `Sandbox.json`. The player sees the VALUES: the
  page listed as "~ Zombie Awareness" and each dial labeled with its
  own name and tooltip. No "Sandbox" word is displayed anywhere.

So the ruling is satisfied by construction, and `[A29]`'s shape is
verified live rather than assumed: the `Sandbox_` prefix on the JSON
keys is the ENGINE's lookup convention - the vanilla file proves the
same ("Sandbox_ZombieLore" displays as "Zombie Lore") - and the title
the player reads is the mod's own words. The sister's page
(`Sandbox_SurvivorAwareness` → "~ Survivor Awareness") rides the same
engine law with no action of its own.

One honest note on what is inert: `Translate/EN/UI_EN.txt` still
carries the seven pre-`[A29]` option names (`ZombieAwareness_Enable`
and siblings, unprefixed). Those keys sit on the FALLBACK path only -
the engine reads them solely when an option has no `translation` field,
and every option here has one. Nothing else in the mod reads them. They
stay in place as the fallback they are, named here as inert so nobody
mistakes them for the menu's mechanism again.

No code changed in this batch. It is a verification record: the
question the operator's clarification raised is answered from the
engine, and the answer is that the built thing was already right.

## What changed

- Nothing in `mod/` or `java/`. The engine contract in this record is
  the deliverable: the `Sandbox_` prefix is a lookup key convention
  applied by `getTranslatedName()`/`getTooltip()` and
  `ServerSettingsScreen.lua` at read time, never displayed.

## Verification

Deferred to the end pass by the operator's standing order: no gate,
build, deploy, or test runs until the feature work across the three
repositories is finished; verification runs once, at the end. The
bytecode disassembly above is itself evidence read from the installed
jar, not a test run.