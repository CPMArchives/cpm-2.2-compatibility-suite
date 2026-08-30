# CP/M 2.2 Compatibility Suite interface standard

This document defines the user-visible command and reporting interface for
CP/M 2.2 compatibility utilities. New utilities must follow it, and existing
utilities should be brought into conformance when they are next revised.

The standard has three goals:

1. The same selector always has the same meaning in every utility.
2. A user can understand what happened without consulting source code.
3. Help remains usable on an ordinary 80-column, 24-line CP/M terminal.

In the examples below, `TOOL` stands for the utility name.

## Standard selectors

Every utility implements these selectors:

```text
TOOL /NNNN          Run or explain one four-digit ledger item
TOOL /SAFE          Run the returning, automatically judged REQUIRED subset
TOOL /ALL           Run all returning automated checks and observations
TOOL /LIST          List ledger item numbers and short descriptions
TOOL /INFO          Show version, coverage, and classification totals
TOOL /H             Show the command summary
TOOL /H:RESULTS     Explain result and classification terminology
TOOL /H:PROFILES    Explain the utility's named profiles and special equipment
```

Selectors are case-insensitive. Unknown selectors and unknown help topics must
produce a short error followed by the command needed to obtain help. They must
not silently fall back to `/H` or run another selector.

`/LIST` and `/INFO` are deliberately distinct:

- `/LIST` is the user-facing catalog. It lists each assigned ledger number and
  a concise description of that item. It does not run tests.
- `/INFO` reports utility identity and totals: version, implemented coverage,
  REQUIRED and diagnostic counts, profiles, optional rows, and outside-scope
  rows as applicable. It does not enumerate the ledger.

`/GROUP:name`, `/FN:n`, `/CASE:id`, and similar selectors are optional and
utility-specific. Keep them only when they select a useful, coherent subset.
They must be documented on that utility's `/H` screen. They do not replace the
standard selectors.

`/REPORT` is the preferred common modifier for complete evidence:

```text
TOOL /NNNN /REPORT
TOOL /SAFE /REPORT
TOOL /ALL /REPORT
```

The compact form is intended for an operator at a terminal. `/REPORT` supplies
the complete expected result, observed evidence, prerequisites, and contextual
identifiers needed for review or captured logs. A utility that does not yet
support `/REPORT` should not advertise it.

## Help organization and terminal limits

`/H` is a command summary, not the entire manual. It contains the utility name
and version, the supported command forms, and a short description of each. The
definitions of results, classes, profiles, and report fields belong on the
topic screens rather than at the bottom of `/H`.

The minimum topic set is:

- `/H:RESULTS` — `STATUS`, `CLASS`, `OBSERVED`, summary counts, and `/REPORT`.
- `/H:PROFILES` — every named compatibility profile used by the utility and
  any special equipment, routing, capture, or fixture requirements.

Each help screen must fit independently within 80 columns by 24 lines,
including its heading and blank lines. No line may wrap on an 80-column
terminal. Returning to the CCP prompt must not push the first help line off the
screen. If a future help topic genuinely needs more than one screen, paginate
it with an explicit `Press any key for more` pause; never allow inaccessible
text to scroll past automatically.

`/LIST` and `/REPORT` may be longer than one screen because they are requested
listings rather than quick-reference help. Their individual lines must still
fit within 80 columns.

## Compact result table

The standard compact table is:

```text
ITEM  S  C  OBSERVED
----  -  -  ----------------------------------------------------------
```

Use one physical terminal line per row. Shorten the observed text rather than
allowing a row to wrap. Detailed wording belongs in `/NNNN /REPORT` or in the
selected item's explanatory procedure.

### STATUS: the outcome

`STATUS` answers only whether the check ran and matched its oracle:

- `PASS` — the check completed and the observed result matched.
- `FAIL` — the check completed and the observed result did not match.
- `UNTESTED` — the check was not executed, could not be completed, or still
  requires an operator judgment.

Do not use `MANUAL`, `OBSERV`, `PROFILE`, or `OUT SCOPE` as statuses. A
NOT-GUARANTEED diagnostic can still have `PASS` or `FAIL` status; its class,
not its status, says that it has no conformance effect.

### CLASS: applicability and conformance effect

`CLASS` describes what the ledger item means:

- `REQUIRED` — a baseline CP/M requirement.
- `NOT GUAR.` — an informational or characterization check. Its PASS or FAIL
  result has no baseline conformance effect.
- `PROFILE` — required only when the named optional compatibility profile is
  claimed.
- `OPTIONAL` — an optional behavior not selected for the current run, where the
  utility's ledger uses that category.
- `OUT SCOPE` — the catalog item cannot be executed or judged by this utility.

Manual execution is a workflow, not a status or a class. A manual REQUIRED item
therefore remains `UNTESTED  REQUIRED` until it is actually performed and
judged.

### OBSERVED: evidence or the next action

For a completed check, `OBSERVED` contains concise, meaningful evidence. It
must describe the actual result, not merely repeat the normative ledger title.

For an unperformed selected/manual check, `OBSERVED` contains the exact command
the operator should run, for example:

```text
0026  UNTESTED  REQUIRED      Run: ENTRYTST /0026
0013  UNTESTED  REQUIRED      Run: CCPTEST /0013 B:ALPHA.TXT
```

For a `PROFILE` row, `OBSERVED` must name the profile being claimed as well as
the command still required. Do not write only `that profile` or `profile
required`.

For `OUT SCOPE`, say that the utility cannot execute or judge the item. Do not
present it as a failed or incomplete conformance test.

## Individually selected and manual checks

Running `TOOL /ALL` does not interactively perform disruptive, terminal,
hardware-dependent, or operator-judged procedures. It lists each such row as
`UNTESTED` and gives the exact `/NNNN` command in `OBSERVED`.

Running `TOOL /NNNN` for such a row must provide useful instructions, not just
repeat the row title. The explanation identifies:

1. what behavior is being tested;
2. prerequisites, fixtures, profile, or equipment;
3. the exact command or physical action to perform;
4. the expected successful behavior;
5. the observable failure behavior; and
6. whether the utility judges the result automatically or the operator must
   compare `OBSERVED` with `EXPECTED`.

Before any selected check uses a dedicated scratch disk, it must identify the
required SCRATCH profile and ask for the configured drive containing it:

```text
This test requires a prepared scratch disk.
To prepare one, quit now, then run SCRATCH /profile.
Enter its configured drive letter, or Q to quit (B-P or Q):
```

A valid configured drive from B through P proceeds. `Q` returns without disk
I/O. Any other key repeats the prompt. The utility must not access a candidate
scratch drive before the operator selects it.

Automate everything the utility can safely observe. Do not label a test manual
merely because its implementation is inconvenient. Conversely, do not claim a
PASS after a warm boot, cold boot, BDOS termination call, or other event that
prevents the utility from regaining control. In those cases, tell the operator
exactly what successful recovery looks like, such as return to the CCP with a
usable prompt.

If a separately selected check accepts an operand, the selected form should
consume and verify it directly. `/ALL` should display the complete command that
supplies that operand.

## Profiles and equipment

A profile is a named compatibility claim beyond the baseline CP/M requirement,
not a generic synonym for configuration. Examples include strict DRI command
behavior, exact DRI diagnostic presentation, declared command-tail capacity,
or a declared unavailable-drive setup.

`/H:PROFILES` must list the exact names understood by that utility and briefly
state what each claims. If the utility defines no profiles, say so explicitly.
The same screen may identify special equipment needed by selected checks, such
as printer capture, IOBYTE routing, reader/punch devices, scratch media, or an
external utility.

A profile check must not silently pass when its profile is not claimed. Report
it as `UNTESTED  PROFILE`, name the profile in `OBSERVED`, and let `/NNNN`
explain how to perform or declare the check.

## Aggregate summaries

Every executed selection ends with a summary using the same meanings:

```text
Summary: N pass, N fail, N error, N observations
```

`pass` and `fail` count executed checks. `observations` identifies completed
NOT-GUARANTEED diagnostics and does not turn them into baseline conformance
claims. `error` is reserved for a test-harness or execution failure, not a
conformance mismatch. `UNTESTED`, `PROFILE`, `OPTIONAL`, and `OUT SCOPE` rows
are not silently counted as passes.

Where supported, the compact summary points to `/REPORT` for detail and `/H`
for commands.

## Implementation and release checklist

Before publishing a utility or a revised disk image:

1. Assemble the source with zero errors.
2. Verify every standard selector and every advertised utility-specific
   selector on the target CP/M system.
3. Verify `/H`, `/H:RESULTS`, and `/H:PROFILES` independently fit 80x24 and
   contain no line longer than 80 characters.
4. Verify every compact result and `/LIST` entry occupies one 80-column line.
5. Confirm `/LIST` includes every assigned ledger row exactly once and `/INFO`
   reports matching totals.
6. Exercise portable utilities in Intel 8080 and Z80 modes. Clearly identify a
   utility that intentionally requires Z80 instructions; do not claim 8080
   compatibility for it.
7. Test all automated PASS/FAIL paths that can be reproduced safely, including
   required operands and manual-selector guidance.
8. Run `suite/build.sh`; confirm all current sources assemble, checksum and
   size manifests are refreshed, and the matching source/COM revision appears
   under `suite/archive/dev-versions`.
9. Run `suite/release.sh` with the maintained project directory. Confirm it
   updates `Conformance Suite.dmk`, regenerates `Conformance Suite Source.dmk`,
   publishes the source/build/archive/tooling set, and verifies exact copies.
10. Record the two image checksums printed by the release command. Unmount and
    remount updated images before emulator testing so cached media are not used.
