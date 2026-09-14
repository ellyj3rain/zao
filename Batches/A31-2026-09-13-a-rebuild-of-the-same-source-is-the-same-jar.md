# A31 - A rebuild of the same source is the same jar

| Field | Record |
| --- | --- |
| Batch | `A31` |
| Date | 2026-09-13 |
| Name | A rebuild of the same source is the same jar |
| Status | Closed append-only batch - build reproducibility, from the readiness sweep |
| Threads | [`T-001`](Batches/THREADS.md#t-001) |

## Record

The readiness sweep of 2026-09-13 (Speakeasy RECORD.md 46, the step the
end-state order named after the sandbox revision) ran this repository's
gate at its tip and found the gate itself dirtying the tree it was
checking. Step 4 of `check.sh` rebuilds the Java bridge on every run
whenever the toolchain is present, and `jar.exe` stamps every entry
with the current time - so a rebuild of unchanged source produced a
jar that differed from the committed one only in zip entry timestamps.
The classes were entry-for-entry identical: 32 entries, same names,
same bytes, only the metadata. Every gate run - including the
pre-commit hook, which runs the same gate - left the working tree
modified, and a meaning-free jar diff was one `git add` away from
entering the forge history.

The fix is the jar tool's own `--date` flag, held to a declared
constant in `build_java.py`: every entry in every jar ZAO builds is
stamped `1993-07-09T00:00:00Z`, the county's own calendar anchor - the
day the Knox Event schedule starts, named on the sister's ratified
sandbox surface - so the jar is stamped as of the world it ships into,
and a rebuild of the same source is the same jar.

Verified the way the finding was found: two independent builds from a
clean state produce byte-identical jars (md5 `50540a3b...` both times),
and a second gate run after the first leaves a clean tree clean. The
sister's build carries the same latent non-determinism in her
`build-java.sh` - her jar tool also stamps the current time - but her
gate never builds, so no gate run dirties her tree; it is named in the
sweep record, not fixed here, because nothing she does today produces
the defect this batch closes.

## What changed

- `tools/build_java.py` - the jar invocation gains `--date` held to a
  declared constant (`jar_stamp = "1993-07-09T00:00:00Z"`), with the
  finding and the anchor's provenance in the comment.
- `java/dist/ZAO.jar` and `mod/42.20/media/java/ZAO.jar` - rebuilt
  once under the fixed stamp; this is the one rebuild whose bytes
  differ from the committed jar, and the last.

## Verification

- Two consecutive `build_java.py` runs from clean state: md5
  `50540a3b3ea2518cebfc4ad8c2e95309` both times, `cmp` equal - the
  build is deterministic on this toolchain (JDK 25.0.3, sorted source
  list, fixed manifest, fixed stamp).
- Entry-level comparison against the pre-fix jar: 32 entries, no
  additions, no removals, no content differences - the change is
  metadata only, so the shipped behavior is unchanged.
- Gate clean at the new tip, and the tree stays clean after the gate's
  own rebuild - the defect this batch closes, closed.
- Deployed to the game's mods directory and md5-verified equal
  repo-tree-to-install.