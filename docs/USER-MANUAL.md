# CP/M 2.2 Compatibility Suite User's Manual

## 1. Introduction

The CP/M 2.2 Compatibility Suite is a collection of eleven logical CP/M 2.2
test utilities, delivered as twelve transient programs, for examining the behavior presented to applications. It is
intended for system implementers, emulator authors, maintainers, and experienced
operators who need more than a simple “boots CP/M” test.

The suite asks narrow, independently reportable questions. Does a particular
call return the required code? Does a directory search place its result in the
selected DMA buffer? Does a warm boot reconstruct a usable command environment?
Does a BIOS routine preserve the public state required by its caller? Each
question is tied to one numbered entry in the compatibility ledger.

The utilities do not award a single universal “CP/M compatible” badge. Some
behaviors are baseline requirements, some are optional named profiles, some are
useful observations for which CP/M makes no guarantee, and some cannot be
judged by a transient program at all. The reports preserve those distinctions.

The suite is written for the Intel 8080 instruction set and is suitable for
8080 and Z80 CP/M 2.2 environments. It deliberately avoids treating private
addresses, undocumented residue, emulator-specific facilities, or one vendor's
presentation choices as universal requirements.

### 1.1 The compatibility ledger

The ledger is the suite's frozen catalog of 627 propositions, numbered `0001`
through `0627`. A ledger number is a stable reference to one question; it is
not a sequence in which the tests must run and it is not a severity ranking.

Each ledger entry is assigned to exactly one of the eleven utilities:

| Utility | Assigned items | General area |
| --- | ---: | --- |
| `FILETEST` and `RANDTEST` | 142 | FCB file operations and record I/O |
| `CONSTEST` | 87 | Console and character-device behavior |
| `BDOSTEST` | 86 | BDOS gateway, results, and system state |
| `DIRTEST` | 72 | Directory operations, searches, and user areas |
| `ENTRYTST` | 59 | Transient entry environment and page zero |
| `CCPTEST` | 59 | Command acquisition, parsing, loading, and dispatch |
| `BIOSTEST` | 46 | Public BIOS jump table and BIOS services |
| `ERRTEST` | 43 | Logical, physical, fatal, and recovery outcomes |
| `DISKTEST` | 20 | Disk state, allocation, and protection |
| `ECOTEST` | 8 | Resident-command and operating-environment behavior |
| `CPUTEST` | 5 | Minimum processor semantics and declared CPU profile |
| **Total** | **627** | |

The ledger is broader than the set of tests that can run automatically. An
assigned item may require special media, an external fault provider, a named
profile, an operator judgment, or observation across a restart. It may also be
outside the reach of a transient utility. Presence in the ledger means the
question is represented and reportable; it does not mean that `/ALL` can or
should force the experiment.

### 1.2 Design principles

The suite follows several conservative rules:

- Every item retains its own identity and disposition.
- A shared setup or probe may serve several items, but one successful result is
  not silently copied into unrelated verdicts.
- Safe returning checks are automated where possible.
- Destructive, interactive, nonreturning, and hardware-dependent procedures
  require explicit selection and suitable fixtures.
- Missing equipment or an unperformed procedure never becomes a pass.
- Temporary files use reserved names and returning paths restore borrowed DMA,
  drive, user, and device state where the public contract permits restoration.
- Tests rely on public CP/M interfaces. Private implementation details are
  either observations, named profile requirements, or outside scope.

### 1.3 Native build toolchain

Microsoft M80 and L80 formed the conventional CP/M assembly toolchain, and
many surviving CP/M assembly projects assume that pair. The suite instead uses
ZSM4 followed by Digital Research LINK for its maintained native build. ZSM4
is a CP/M-hosted, GPL-licensed macro assembler with familiar M80-style source
and standard relocatable output; LINK converts that output into a `.COM` file.
This provides a redistributable, reproducible source disk without making the
Microsoft assembler a prerequisite, while retaining the standard CP/M linker.
The source disk also includes the CRUNCH 2.4 compressor and UNCR, so edited
native sources can be recompressed as well as expanded. Their embedded notice
permits reproduction for non-profit use only; see
`../THIRD-PARTY-NOTICES.md`.

ZSM4 requires a Z80-compatible processor to perform the build. That does not
change the target baseline: the suite sources use the Intel 8080 instruction
subset, and the resulting utilities run on both Intel 8080 and Z80 CP/M 2.2
systems. The maintained binaries have been rebuilt with ZSM4 and LINK and
checked against the tested ZSM4 builds.

## 2. Distribution and preparation

The authoritative distribution consists of ordinary host files: executables,
assembly sources, controlled fixtures, documentation, manifests, and checksums.
Transfer them to media appropriate for the target system using the operator's
usual CP/M tools. The files may be divided among several disks, provided that
each utility can reach the fixtures required by the selected test. Preserve the
names, contents, attributes, user areas, and same-drive or cross-drive
relationships identified by the distribution documentation and file manifest.

Keep an untouched copy of the distributed files and any working media. Use
copies or snapshots when running a procedure involving writes, protection,
media replacement, full directories, full disks, physical errors, or restart
recovery.

Do not remove or rename the `BT...` and `BDS...` files merely because they look
temporary. Some are controlled inputs, and `BDSA.TMP` and `BDSB.TMP` are a
matched directory-search pair. Files created dynamically by a test are cleaned
up by the normal returning path, but an interrupted run may require a fresh
copy of the affected distribution files.

### 2.1 SCRATCH media preparer

`SCRATCH.COM` is a safety and fixture utility, not a twelfth ledger owner. It
prepares expendable media for procedures that must not use ordinary utility or
fixture media:

```text
SCRATCH /LIST
SCRATCH /DISK
SCRATCH /CROSS
SCRATCH /BLANK
SCRATCH /H
SCRATCH /HELP
SCRATCH /INFO
SCRATCH /VER
```

- `/DISK` creates the controlled full-data-area layout used by `DISKTEST`.
- `/CROSS` creates `BTBFILE.DAT` for cross-drive `FILETEST` and `DIRTEST` work.
- `/BLANK` erases all user areas and verifies an empty formatted disk.

SCRATCH accepts only configured drives B through P, displays the selected drive,
and requires a second `Y` confirmation. It never selects A. Everything on the
chosen disk is expendable. `/H` and `/HELP` are synonyms; `/VER` and `/VERSION`
print the utility name and version. SCRATCH's help screen emphasizes that it
requires a blank, formatted image and destroys all content on the selected
medium.

### 2.2 Capturing a run

For serious validation, capture the complete terminal session and record:

- utility version;
- CP/M and BIOS identity;
- emulator or hardware configuration;
- claimed profiles;
- disk formats and fixture preparation;
- special device routing or fault provider;
- commands entered and operator responses;
- resulting report and recovery state.

A screenshot is useful, but a complete text transcript is better for long
lists and multi-stage procedures.

## 3. Common command interface

The eleven ledger-owning utilities share the following command forms. A tool
may omit a form only when it has no meaningful operation for it.

```text
TOOL /NNNN[:REPORT] Run, explain, or report one ledger item
TOOL /ALL           Run checks and report all items
TOOL /SAFE          Run checks requiring no destructive media
TOOL /LIST          List ledger items by useful group
TOOL /GROUP:LIST    List all available groupings
TOOL /GROUP:name    Run a named group; use /GROUP:LIST to discover names
TOOL /H, /HELP      Show concise command help
TOOL /INFO          Show build information
TOOL /VER, /VERSION Show the utility name and version
```

Selectors are case-insensitive but otherwise exact; abbreviations are rejected.
Unless an item's printed operator procedure explicitly calls for operands,
give the utility exactly one selector. `/NNNN` means the literal four-digit
ledger number, including leading zeroes. `/NNNN:REPORT`, where the selected
utility supports detailed evidence, requests the expanded report for that
item. It is one selector; `/NNNN /REPORT` is not an alternative spelling.

A selected automatic item runs immediately. A selected manual, profile,
destructive, or nonreturning item prints its setup, action, expected result,
failure indication, and recovery instructions.

`/SAFE` is the recommended first command. `/ALL` does not mean “perform every
dangerous act.” It runs every returning check and permitted observation in that
utility, then reports unperformed procedures honestly.

`/LIST` organizes the utility's assigned ledger items into useful functional
groups. Every group displayed there can be selected with `/GROUP:name`.
`/GROUP:LIST` gives the available names and brief descriptions without
overloading the main help screen. Three group names have common meanings:

- `/GROUP:REQUIRED` runs returning REQUIRED items in its scope and lists any
  required procedures that cannot safely run there.
- `/GROUP:OBSERVATION` runs NOT GUARANTEED observation items.
- `/GROUP:MANUAL` lists manual items for the operator's convenience; it does
  not execute them.

Utilities may add functional or orthogonal groups such as `MEDIA`, `RECOVERY`,
or `PROFILE`. Some also retain selectors such as `FILETEST /FN:15`. Use
`/GROUP:LIST` as the authority for the selected utility.

Examples of expanded item reports are:

```text
FILETEST /0171:REPORT
DIRTEST /0567:REPORT
CONSTEST /0051:REPORT
```

### 3.1 Reading the result table

A full-width report uses columns similar to:

```text
ITEM  STATUS    CLASS         OBSERVED
----  --------  ------------  --------------------------------
```

Some compact reports use one-character status and class columns:

```text
ITEM  S  C  OBSERVED
----  -  -  --------------------------------
```

The compact keys are:

| Column | Character | Meaning |
| --- | --- | --- |
| Status | `P` | Pass |
| Status | `F` | Fail |
| Status | `-` | Not run or not completed |
| Status | `O` | Observation recorded |
| Class | `R` | Required |
| Class | `N` | Not guaranteed |
| Class | `X` | Named profile |
| Class | `S` | Out of scope |

### 3.2 Status: what happened

`PASS` means the check ran to completion and the observed result matched its
oracle. It does not mean that every item in the utility ran, nor does a pass on
a NOT GUARANTEED observation create a baseline requirement.

`FAIL` means the check ran, obtained judgeable evidence, and that evidence did
not match. A failure is a candidate-system conformance result, not a test
harness crash.

`NOT RUN`, or `-` in a compact table, means no verdict was obtained. Common
reasons include a missing provider, a procedure not selected, an unavailable
profile, required operator action, or a terminal event after which the program
cannot report for itself. Untested is not failed, but it is never passed.

`OBSERVED`, or `O`, records behavior for a NOT GUARANTEED item. It is useful for
characterizing systems and comparing implementations, but has no baseline
conformance effect.

An `error` in a summary is reserved for a failure of the test mechanism or
fixture, not an ordinary mismatch between expected and observed behavior.

After an aggregate report with one or more failures, the utility prints a
compact `Failed items:` line containing every failed four-digit selector. This
line is omitted when there are no failures. It preserves the actionable result
after a long table scrolls off screen; rerun any listed selector with `/NNNN`
or `/NNNN:REPORT` for its evidence and explanation.

### 3.3 Class: what the item means

`REQUIRED` (`R`) is part of the generic baseline. A completed required check
may pass or fail. A manual required check remains untested until performed.

`NOT GUARANTEED` (`N`) is an informational proposition. The program may record
register residue, ordering, persistence after an ignored error, or another
implementation-dependent fact. It must not be used to reject a baseline
implementation.

`PROFILE` (`X`) is required only when the named optional compatibility profile
is claimed. Examples include strict DRI command behavior or exact diagnostic
presentation. If the profile is not claimed, the correct result is untested,
not pass or fail.

`OPTIONAL` represents behavior that is neither a baseline requirement nor an
active named profile in the current run.

`OUT OF SCOPE` (`S`) means the item cannot be executed or judged by that
utility. It commonly concerns private internals or behavior requiring an
observer outside the transient. Out of scope is a classification, not a failure.

### 3.4 The OBSERVED field

For a completed test, `OBSERVED` gives concise evidence: return codes, state
transitions, a comparison result, or another meaningful signature. For an
unperformed item, it gives the next command or required provider. For a named
profile, it should name the profile as well as the required action.

### 3.5 Recommended run order

1. Make working copies or snapshots of all media.
2. Run each utility's `/HELP`, `/INFO`, `/LIST`, and `/GROUP:LIST`.
3. Run `/SAFE` for each utility.
4. Review failures before proceeding; do not bury them in later experiments.
5. Run `/ALL` to add observations and inventory procedures still untested.
6. Prepare SCRATCH profiles and special devices only for selected `/NNNN`
   procedures.
7. Perform terminal, boot, physical-error, and recovery procedures last, with
   transcript capture and a known restoration point.

The numeric ledger order is not a required execution order. Utilities may run
checks in a safer order or an order which preserves fixtures and state.

## 4. FILETEST

### 4.1 Purpose

`FILETEST` and its companion `RANDTEST` jointly own 142 ledger items concerning FCB interpretation, Open, Close,
Make, sequential and random I/O, file size, random-record fields, partial final
records, extent boundaries, explicit drives, and related lifecycle behavior.
It is the largest logical utility because file semantics contain many related
but independently reportable boundary cases. It is split into two executables
so both load below the `C400h` BDOS boundary used by common 48K CP/M systems:
`FILETEST` contains the 93 FCB, Open, sequential-read, and sequential-write
items; `RANDTEST` contains the 49 random-I/O, protection, and lifecycle items.

The `/LIST` output of the two programs divides the catalog into `FCBOPEN`,
`READ`, `WRITE`, `RANDOM`, and `LIFECYCLE`; each applicable group is runnable
through `/GROUP:name`. The narrower legacy
workflow groups `OPEN`, `SEQREAD`, and `CLOSE` remain available and are listed
by `FILETEST /GROUP:LIST`. The orthogonal selectors `/FN:15`, `/FN:16`, and
`/FN:20` select cards using those BDOS functions. They are also accepted as
`/GROUP:FN:15`, `/GROUP:FN:16`, and `/GROUP:FN:20`, respectively. Invoke an
item through the executable whose `/LIST` contains it. `/NNNN:REPORT` is particularly
valuable here because compact rows cannot show every FCB and DMA detail.

### 4.2 Fixtures and notable procedures

The normal runtime disk contains controlled `BT...DAT` fixtures. Their names,
sizes, record contents, partial-record padding, attributes, and extent layout
are part of the test setup. Do not edit them between runs.

Cross-drive items require a secondary disk prepared with `SCRATCH /CROSS`.
When prompted, supply the configured drive containing `BTBFILE.DAT`; do not
assume a fixed drive letter. FILETEST reports these items as not-run, rather
than failed, when the required cross-drive fixture is unavailable.

Items `0368` and `0369` exercise sequential and random writes against the
read-only `BTRO.DAT` fixture. On a DRI-style system the call may enter the
resident `File R/O` path and never return to RANDTEST. An external observer
must verify the expected message, acknowledge it, confirm return to a usable
CCP prompt, and prove the fixture disk is unchanged and `BTRO.DAT` remains
read-only. RANDTEST cannot print its own in-process pass after being abandoned.

Tests involving a full disk, allocation refusal, or other special media must
use the named expendable fixture. Never substitute the suite runtime disk.

## 5. DIRTEST

### 5.1 Purpose

`DIRTEST` owns 72 items covering Search First and Search Next, wildcard
matching, returned DMA slots, Delete, Rename, attributes, extents, directory
lifetime, explicit drives, and user-area visibility.

Its functional groups are `SEARCH`, `ENUMERATION`, `DELETE`, `RENAME`,
`ATTRIBUTES`, and `USERS`.

### 5.2 Fixtures and notable procedures

Directory search returns a slot number from zero through three. DIRTEST uses
that result to find the selected 32-byte entry within the active DMA. This is
why some observations refer to a slot rather than a fixed address or ordering.

Search order and exact physical directory layout are generally not guaranteed.
Do not treat a different but complete enumeration order as failure unless the
selected item explicitly supplies an ordering oracle.

Cross-drive items use media prepared by `SCRATCH /CROSS`. Multi-extent tests
derive their fixture requirements from the active DPB rather than assuming a
particular disk geometry.

Item `0567` checks agreement between CCP `USER` state and BDOS user state. Run
it as instructed:

```text
USER 1
DIRTEST /0567
USER 0
```

The supplied runtime layout places a copy of `DIRTEST.COM` in user area 1 for
this purpose. Restore the original user afterward.

Read-only Delete or Rename cases may enter a resident terminal error path.
Treat them like other terminal outcomes: capture the message and recovery,
then verify that the protected fixture was not changed.

## 6. CONSTEST

### 6.1 Purpose

`CONSTEST` owns 87 items concerning console input and output, string output,
direct console I/O, console status, buffered input, line editing, tabulation,
control characters, logical printer echo, IOBYTE routing, and reader, punch,
and list behavior.

Its functional groups are `INPUT`, `FORMATTED`, `DIRECT`, `BUFFERED`, and
`DEVICES`.

### 6.2 Interactive evidence

Many console properties cannot be judged by the same output routine being
tested. CONSTEST therefore prints labeled `OBSERVED` and `EXPECTED` material
and asks the operator to confirm the comparison. Capture the entire exchange,
including the response.

Buffered-input and line-editing cases require exact keystrokes. Follow the
selected item's recipe rather than entering an equivalent final line; the edit
sequence itself may be the subject of the test.

Device-routing cases require declared, separately observable devices. Configure
IOBYTE assignments before the run, record them, and restore them afterward.
Do not claim a READER, PUNCH, or LIST result when the logical device is routed
back to the console or to an indistinguishable sink.

An absent reader or alternative device is not a failure of CP/M. The related
procedure remains untested until a suitable provider is configured. Exact DRI
console presentation belongs to its named profile rather than the baseline.

## 7. BDOSTEST

### 7.1 Purpose

`BDOSTEST` owns 86 items covering the public gateway at `0005h`, selector and
argument carriers, byte and word result aliases, returning-call stack balance,
disk reset and selection state, login vectors, DMA persistence, user number,
directory search transfer, and public ALV/DPB access.

Its functional groups are `GATEWAY`, `CONTRACT`, `IDENTITY`, `STATE`, `DRIVE`,
and `DIRECTORY`.

### 7.2 Fixtures and notable procedures

`BDSA.TMP` and `BDSB.TMP` are generated copies of the current BDOSTEST image
with alternate names. They form a known two-file set for wildcard, Search Next,
DMA-slot, restart, and enumeration checks. Both files must be present.

The program temporarily changes drives, user areas, or DMA for individual
checks and restores them on returning paths. Nevertheless, record the initial
drive and user, and verify them after any interrupted run.

The media-change item requires a blank expendable disk prepared with
`SCRATCH /BLANK`. Unavailable-drive presentation requires the named
`UNAVAILABLE-DRIVE` profile. Invalid-drive and private-internal behavior must
not be generalized from one BIOS.

Register preservation and exact returned addresses are diagnostic evidence
unless a ledger item states a public requirement. A different address or
unspecified register value is not automatically a failure.

## 8. ENTRYTST

### 8.1 Purpose

`ENTRYTST` owns 59 items describing the environment presented when a transient
program begins: load origin, TPA boundaries, page-zero vectors, IOBYTE, default
FCBs, command tail, default DMA, entry stack, complete-image loading, and
selected public BIOS/disk structures visible to the application.

Its functional groups are `ENTRY`, `TERMINATION`, `LOADER`, `BIOS`,
`FUNCTION40`, and `DEVICES`.

### 8.2 Operand-sensitive and terminal procedures

Several items must be invoked with exact operands, for example:

```text
ENTRYTST /0012 SECOND.BIN
ENTRYTST /0014 A:AB*.C?M
ENTRYTST /0015 mixed.txt
ENTRYTST /0020 mixed Case
```

These commands examine the CCP-built FCBs or command tail. Typing a different
operand changes the test input.

Items `0026` and `0027` test termination by BDOS Function 0 and by restoring
the original entry stack and executing `RET`. Item `0595` invokes WBOOT. Each
is terminal from the transient's point of view. Success is return to a usable
CCP prompt; the program cannot print a verdict after relinquishing control.

Function 40 items create reserved `ENT40.$$$`, verify zero-filled sparse holes,
restore DMA, and delete the file. A leftover copy indicates an interrupted
run; use a fresh disk or remove only that reserved work file after inspection.

The direct-structure item follows the current public BIOS jump table and active
DPH/DPB. It is read-only and does not assume fixed BIOS addresses.

## 9. CCPTEST

### 9.1 Purpose

`CCPTEST` owns 59 items covering command acquisition, editing and case
handling, built-in command recognition, default FCB construction, transient
lookup, loading, dispatch, termination, command errors, submit facilities, and
recovery to the command prompt.

Its functional groups are `ENTRY`, `COMMAND`, `FILES`, `LOADER`, `MEMORY`, and
`SUBMIT`.

### 9.2 Operator procedures and profiles

Many CCP behaviors occur before a transient starts or after it exits, so they
must be judged from the command prompt. A selected item prints exact commands
and success/failure criteria. Typical procedures exercise `DIR`, `ERA`, `REN`,
`SAVE`, `TYPE`, `USER`, drive changes, unknown commands, current-drive lookup,
and loading of deliberately prepared images.

Use harmless operands and expendable files. Procedures involving truncated or
invalid COM images, maximum command lines, or recovery behavior should begin
from a restorable snapshot.

Named profiles include strict DRI command behavior and diagnostic presentation,
declared command-tail capacity, and DRI ecology behavior. Do not mark these
items failed merely because the implementation does not claim the profile.

SUBMIT and XSUB checks require those facilities to be installed and configured.
If they are absent, record the procedure as unavailable/untested.

## 10. DISKTEST

### 10.1 Purpose

`DISKTEST` owns 20 items covering disk reset, read-only vectors, allocation
state, disk-full behavior, release and reuse of blocks, media replacement, and
returning protection checks.

Its functional groups are `STATE`, `ALLOC`, and `PROTECT`.

Additional selectors include:

```text
DISKTEST /FN:13
DISKTEST /FN:28
DISKTEST /FN:29
DISKTEST /GROUP:ALLOC
DISKTEST /GROUP:PROTECT
```

### 10.2 Destructive fixture

The allocation and full-disk procedures require a disk prepared with:

```text
SCRATCH /DISK
```

That profile creates controlled files and fills the data area. DISKTEST asks
for the configured drive; it does not require a fixed `D:`. Confirm the drive
carefully. The selected disk is expendable and must not contain useful data.

Media-replacement tests may require removing or replacing a disk after state
has been established. Follow the selected item's order exactly, and make sure
the replacement is actually recognized before continuing. Retain before/after
copies when allocation reuse or protection is the evidence.

`/SAFE` excludes destructive procedures. Run it before preparing full media.

## 11. BIOSTEST

### 11.1 Purpose

`BIOSTEST` owns 46 items covering the standard BIOS jump table, BOOT and WBOOT,
character I/O entry points, LIST/PUNCH/READER behavior, disk selection and
track/sector/DMA calls, sector translation, public DPH/DPB relationships, and
controlled direct disk I/O.

Its functional groups are `BOOT`, `CHARACTER`, `DEVICES`, `DISK`,
`ALLOCATION`, and `PROCESSOR`.

### 11.2 Addressing and boot evidence

BIOS addresses are discovered from the active public vectors and jump table.
No fixed BIOS base is portable. Address relationships may be required while
the numeric addresses themselves remain observations.

BOOT and WBOOT are nonreturning. Their selectors use a retained evidence card,
`BTBOOT.DAT`, so a later invocation can judge the reconstructed environment.
Follow the printed stages exactly. Delete `BTBOOT.DAT` only when deliberately
resetting that evidence.

### 11.3 Direct disk and device procedures

Direct-write tests require blank expendable media and explicit operator
consent. Item `0457` writes, reads, and compares a controlled record, then asks
the operator to enable write protection for one direct BIOS write. Restore the
medium to writable when prompted so recovery and cleanup can be checked.

Item `0453` requires expendable media configured with a system format whose DPB
has nonzero `OFF`. Confirm the active DPB before running the item; the media's
contents do not by themselves select the format used by the BIOS.

Character-device checks require real, distinguishable providers. Item `0471`
is a retained two-run READER procedure: one stage verifies an ordinary reader
character and the other requires a separately configured immediate-EOF
provider. A blocking or absent provider leaves the procedure untested.

## 12. ERRTEST

### 12.1 Purpose

`ERRTEST` owns 43 items distinguishing returning logical refusals, physical
disk errors handled by resident code, fatal/abort paths, ignored-error
observations, exact diagnostic profiles, and recovery after the transient has
been abandoned.

### 12.2 Logical versus physical failure

A logical refusal returns through BDOS and can be judged automatically.
ERRTEST's returning checks cover sequential EOF, random read EOF, random-write
range refusal, a missing-file Make/Close/Rename/Delete lifecycle, and a
meta-check that all controlled logical failures returned without resident
intervention.

A physical error is different. It must be injected after the requested
operation reaches the candidate BIOS. A stub that simply returns a chosen
value to ERRTEST proves only the stub. Suitable providers include controlled
media faults, emulator faults, or a guarded BIOS shim with evidence that the
candidate path was reached.

Ignore and Abort procedures require operator choices and often cannot return
to the transient. Use restorable media and capture the resident output and CCP
recovery. Persistence and DMA after an ignored physical error are explicitly
NOT GUARANTEED unless a named profile says otherwise.

`/LIST` groups the 43 items by equipment and workflow: automatic checks,
special media, physical/BIOS faults, interactive abort/recovery, profiles,
non-guaranteed observations, and documentary exclusions. A normal `/ALL`
result therefore contains many `-` rows; that is expected until providers are
performed.

## 13. ECOTEST

### 13.1 Purpose

`ECOTEST` owns eight items concerning the surrounding operating environment:
missing-file behavior, failed-operation FCB state, resident command semantics,
directory presentation, read-only interpretation, SAVE, TYPE, and recovery
after ordinary resident-command use.

Its returning functional group is `AUTOMATIC`; the universal groups inventory
the remaining observation and manual procedures.

### 13.2 Resident-command transcripts

The automatic missing-file check can be judged inside the transient. Resident
commands such as SAVE and TYPE require an external transcript because ECOTEST
cannot observe their whole command-level presentation from within itself.

Follow each selected item's setup and use disposable names. Restore any file
or command environment changed by the procedure. Directory order and exact
layout, general failed-operation FCB residue, and read-only attribute behavior
beyond the public contract are observations rather than baseline failures.

## 14. CPUTEST

### 14.1 Purpose

`CPUTEST` owns five items. It establishes the minimum Intel 8080-compatible
execution baseline, checks the declared processor-profile semantics used by
the suite, records undocumented processor behavior without depending on it,
and excludes Z80 extensions and hardware timing/interrupt topology from the
generic CP/M claim.

Its functional groups are `AUTOMATIC` and `EXCLUSIONS`.

### 14.2 Interpreting its scope

Passing CPUTEST means the instruction and flag behavior exercised by the suite
agrees with its declared baseline. It does not certify every CPU instruction,
cycle count, wait-state arrangement, interrupt mode, or daisy-chain design.

Undocumented behavior is NOT GUARANTEED. Z80-only facilities may be important
to a particular machine profile, but they are outside the generic 8080 CP/M
baseline and are not required merely because the suite also runs on a Z80.

## 15. Completing and reporting a validation

A useful final report should separate at least four totals:

1. assigned ledger items;
2. items represented or implemented by the utility version used;
3. procedures actually executed with valid fixtures and providers; and
4. resulting required passes, required failures, observations, and untested
   items.

Do not collapse OUT OF SCOPE, unclaimed profiles, missing equipment, and
unperformed destructive procedures into passes. Likewise, do not describe a
NOT GUARANTEED observation as a conformance failure.

Preserve the runtime and source hashes, captured transcripts, media before/after
hashes where available, profile declarations, and operator notes with the report.
That evidence makes the result reproducible and allows a later suite revision
to distinguish a changed test from a changed implementation.

## Appendix A. Quick reference

```text
TOOL /NNNN[:REPORT] Run, explain, or report one ledger item
TOOL /ALL           Run checks and report all items
TOOL /SAFE          Run checks requiring no destructive media
TOOL /LIST          List ledger items by useful group
TOOL /GROUP:LIST    List all available groupings
TOOL /GROUP:name    Run the named grouping
TOOL /H, /HELP      Concise command summary
TOOL /INFO          Build and coverage information
TOOL /VER, /VERSION Utility name and version
```

```text
P / PASS       Check ran and matched
F / FAIL       Check ran and did not match
- / NOT RUN    No verdict was obtained
O / OBSERVED   Informational observation recorded

R / REQUIRED       Generic baseline requirement
N / NOT GUAR.      Informational; no baseline conformance effect
X / PROFILE        Required only for the named claimed profile
S / OUT SCOPE      Not executable or judgeable by this utility
```

When in doubt, stop before changing media and run the selected item's `/NNNN`
form. Its current on-disk instructions are the final authority for the exact
fixture and procedure implemented by that utility version. Use
`/NNNN:REPORT` when the full evidence record is needed.
