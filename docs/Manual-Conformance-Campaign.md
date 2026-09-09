# Running a Complete Manual Conformance Campaign

This is a recipe for a **complete manual conformance campaign** against one CP/M 2.2 implementation. It follows the suite's recommended ordering and deliberately postpones destructive, nonreturning, and fault-injection tests until the ordinary returning tests have been exhausted.

# Phase 0 — Before Starting

Use a **working copy** of the runtime disk, never your master copy.

For the maintained Montezuma distribution, keep available:

- `Conformance Suite.dmk` — runtime/test disk

- a disposable blank formatted disk for SCRATCH operations

- `BIOSTEST OFF Scratch.dmk` — specifically for BIOSTEST 0453

- a way to restore/snapshot the CP/M system

- preferably, a complete terminal transcript

The source disk is **not required** merely to run the suite.

Record before beginning:

- compatibility-suite release/version, build identifier, or Git commit

- runtime-disk filename and SHA-256 hash

- SYSINFO version, if SYSINFO will be used

- machine/emulator and version

- CP/M version

- BIOS/version

- CPU configuration

- disk formats

- any claimed compatibility profiles

- initial drive and USER number

If practical, run `SYSINFO` and save its output as part of the campaign record.

Some procedures preserve evidence in files across invocations or restarts. Do
not delete unexplained test-created files until the owning procedure has been
identified and completed or deliberately reset. In particular, do not treat a
working test disk as disposable merely because a transient program has
returned to the CCP.

Record every snapshot, restoration, and fixture-media recreation event in the
campaign transcript, including which disk or system state was restored. Later
observations are only auditable if their relationship to the current media
state is clear.

---

# Phase 1 — Inventory the Suite

Start from a freshly booted system with the runtime disk accessible.

There are twelve test executables:

```text
FILETEST

RANDTEST

DIRTEST

CONSTEST

BDOSTEST

ENTRYTST

CCPTEST

DISKTEST

BIOSTEST

ERRTEST

ECOTEST

CPUTEST
```

`SCRATCH` is a fixture-preparation utility, not a test.

`RANDTEST` was split from `FILETEST` for program-size reasons. That historical
implementation detail does not change how a campaign is run: the operator has
twelve separate test executables to inventory, run, and account for.

For **each** of the twelve test programs, first run:

```text
TOOL /HELP

TOOL /INFO

TOOL /LIST

TOOL /GROUP:LIST
```

Thus, for example:

```text
FILETEST /HELP

FILETEST /INFO

FILETEST /LIST

FILETEST /GROUP:LIST
```

Repeat for all twelve programs.

Save the output. `/LIST` is particularly important because it is the authority for which executable owns each numbered test, and `/GROUP:LIST` identifies the procedures available in that version.

Do not assume ledger-number order is execution order.

---

# Phase 2 — Run Every SAFE Set

Now run the non-destructive returning tests.

Run:

```text
FILETEST /SAFE

RANDTEST /SAFE

DIRTEST /SAFE

CONSTEST /SAFE

BDOSTEST /SAFE

ENTRYTST /SAFE

CCPTEST /SAFE

DISKTEST /SAFE

BIOSTEST /SAFE

ERRTEST /SAFE

ECOTEST /SAFE

CPUTEST /SAFE
```

`/SAFE` establishes the low-risk baseline. `/ALL` then executes everything the
harness can safely determine automatically and exposes the remaining manual
procedures. Running `/ALL` later is therefore not a substitute for beginning
with `/SAFE` and investigating its failures.

## Stop Here if Something Fails

Do **not** simply continue through a pile of failures.

For any failed item, rerun the individual test:

```text
TOOL /NNNN
```

and, where supported/useful:

```text
TOOL /NNNN:REPORT
```

For example:

```text
FILETEST /0171:REPORT
```

Determine whether you have:

- a genuine candidate-system failure;

- an incorrect fixture;

- an operator/setup problem; or

- a suite/harness error.

Only after the SAFE results are understood should you continue.

---

# Phase 3 — Run ALL on Every Executable

Now run each executable's complete automatically executable set and obtain its
full status report:

```text
FILETEST /ALL

RANDTEST /ALL

DIRTEST /ALL

CONSTEST /ALL

BDOSTEST /ALL

ENTRYTST /ALL

CCPTEST /ALL

DISKTEST /ALL

BIOSTEST /ALL

ERRTEST /ALL

ECOTEST /ALL

CPUTEST /ALL
```

This is an important distinction:

**`/ALL` does not perform every dangerous test.**

It runs returning checks and permitted observations and identifies procedures that remain unperformed.

Consequently, a correct `/ALL` report can contain many `-` / NOT RUN entries.

Those now become the checklist for the remainder of the campaign.

---

# Phase 4 — Perform the Ordinary Manual/Interactive Tests

For each executable, inspect its manual inventory:

```text
TOOL /GROUP:MANUAL
```

Select each outstanding procedure individually:

```text
TOOL /NNNN
```

The program prints the required setup, action, expected result, failure condition, and recovery procedure.

Follow those instructions **literally**.

This matters particularly for CONSTEST. If it tells you to type a particular editing sequence, an equivalent final string is not sufficient evidence—the keystrokes themselves may be under test.

For console tests, record both:

```text
OBSERVED

EXPECTED
```

and your response.

Do the ordinary returning interactive procedures before the terminal/nonreturning procedures described below.

---

# Phase 5 — ENTRYTST Operand Tests

ENTRYTST has tests that require exact CCP command lines.

In particular, run the prescribed commands including:

```text
ENTRYTST /0012 SECOND.BIN

ENTRYTST /0014 A:AB*.C?M

ENTRYTST /0015 mixed.txt

ENTRYTST /0020 mixed Case
```

Do not substitute other filenames, spelling, capitalization, or operands: the command line itself is test input.

ENTRYTST also creates `ENT40.$$$` during Function 40 testing. Normally it cleans this up.

If a run is interrupted and `ENT40.$$$` remains, inspect what happened before removing it or restore the test disk from your working master.

Record any such restoration in the campaign transcript.

Leave ENTRYTST's terminal tests `0026`, `0027`, and `0595` until the terminal-test phase.

---

# Phase 6 — DIRTEST USER Test

DIRTEST 0567 requires a specific CCP/BDOS USER-state experiment.

Run:

```text
USER 1

DIRTEST /0567

USER 0
```

The distributed runtime layout deliberately includes `DIRTEST.COM` in USER 1.

Make certain you return to USER 0 afterward.

---

# Phase 7 — Prepare CROSS Media

Now prepare a disposable secondary disk for the cross-drive FILETEST and DIRTEST procedures.

At the CP/M prompt:

```text
SCRATCH /CROSS
```

SCRATCH will ask which configured drive, B through P, is to be destroyed.

Choose your disposable disk.

It displays the drive and requires a second:

```text
Y
```

confirmation.

**Everything on that disk is expendable.**

`SCRATCH /CROSS` creates the required:

```text
BTBFILE.DAT
```

fixture.

Now return to the outstanding FILETEST and DIRTEST cross-drive `/NNNN` procedures and run them individually. When asked for the secondary drive, specify the drive you just prepared.

Do not assume that it must be B:.

---

# Phase 8 — Prepare BLANK Media

Some procedures require a genuinely blank expendable disk.

Prepare one with:

```text
SCRATCH /BLANK
```

Again select the disposable B–P drive and confirm destruction.

This erases all USER areas and verifies that the formatted disk is empty.

Use this fixture for the outstanding procedures explicitly asking for blank media, including the appropriate BDOSTEST media-change work and BIOSTEST direct-I/O work.

Restore/recreate it whenever an earlier procedure has changed the state required by a later one.

Record each restoration or recreation, and identify the procedure after which
it occurred, in the campaign transcript.

---

# Phase 9 — DISKTEST Destructive Media

DISKTEST's allocation/full-disk procedures require their own specially prepared state.

Start with disposable media and run:

```text
SCRATCH /DISK
```

Select the expendable drive and confirm.

This creates the controlled files and fills the data area as required by DISKTEST.

Now run the outstanding destructive DISKTEST items individually:

```text
DISKTEST /NNNN
```

Follow each printed procedure exactly, particularly where disk replacement or media recognition is involved.

Never point these procedures at the runtime suite disk.

---

# Phase 10 — CCPTEST Command-Level Procedures

Now work through:

```text
CCPTEST /GROUP:MANUAL
```

and execute each outstanding CCP procedure individually.

These can involve such CCP operations as:

```text
DIR

ERA

REN

SAVE

TYPE

USER
```

drive changes, unknown commands, transient lookup, deliberately malformed/truncated COM files, command-line boundaries, and recovery.

Use expendable filenames and begin the more invasive loader/recovery tests from a snapshot or otherwise restorable state.

Some tests involve behavior occurring **before CCPTEST begins or after it terminates**, so the evidence is the external command transcript rather than something CCPTEST can determine internally.

SUBMIT/XSUB tests require those facilities actually to be installed. Their absence means `-` / NOT RUN, not `F` / FAIL.

---

# Phase 11 — ECOTEST Resident-Command Procedures

Run:

```text
ECOTEST /GROUP:MANUAL
```

and perform its outstanding command-level procedures individually.

These include behaviors involving such things as:

```text
SAVE

TYPE
```

and other surrounding CP/M environment behavior.

Capture the CCP transcript.

Do not turn directory presentation/order or other NOT GUARANTEED behavior into a conformance failure.

---

# Phase 12 — CONSTEST External-Device Tests

Now configure any real external logical devices available on the candidate system.

CONSTEST can test:

- READER

- PUNCH

- LIST

- IOBYTE routing

The provider must be **distinguishable** from ordinary console I/O. Routing LIST straight back to an indistinguishable console does not establish that the LIST path worked independently.

Record the IOBYTE/device assignments before changing them.

Run the corresponding individual CONSTEST procedures.

Then restore the original assignments.

If the machine has no suitable provider, those tests remain `-` / NOT RUN. That is not a CP/M failure.

---

# Phase 13 — BIOSTEST Special OFF Disk: 0453

BIOSTEST 0453 needs something more specific than merely a blank disk.

Use:

```text
BIOSTEST OFF Scratch.dmk
```

or equivalent expendable media.

The **BIOS/emulator drive configuration** must identify that drive as a system format having a DPB with nonzero `OFF`.

The contents of the image do not establish this.

Before running the test, verify the selected drive with:

```text
SYSINFO /DPB
```

using the appropriate drive selection supported by SYSINFO, and confirm:

```text
OFF != 0
```

Then run:

```text
BIOSTEST /0453
```

and follow its printed procedure.

---

# Phase 14 — BIOSTEST Direct Write/Write-Protect: 0457

Use blank expendable media.

Run:

```text
BIOSTEST /0457
```

The procedure first performs a controlled 128-byte:

**write → read → compare**

against the scratch disk.

BIOSTEST then asks you to enable **actual write protection**.

Do so only when instructed.

It then attempts one direct BIOS WRITE.

When prompted, restore the disk to writable state.

BIOSTEST checks recovery and cleans up its temporary file.

If you cannot provide real write protection, quit the physical-fault portion as instructed. Do **not** manufacture a successful result.

---

# Phase 15 — BIOSTEST READER Test: 0471

This is a retained **two-run** experiment.

The first run requires an ordinary functioning READER provider.

On the tested Montezuma system, the documented example is:

```text
STAT RDR:=PTR:

BIOSTEST /0471
```

When READER waits:

```text
Y
```

then supply uppercase:

```text
R
```

BIOSTEST records the evidence in:

```text
BTRDR.DAT
```

and returns.

The second stage requires a **different, independently configured READER provider which immediately returns Ctrl-Z/EOF**.

Run:

```text
BIOSTEST /0471
```

again with that provider.

If no such provider exists, choose the procedure's quit option and leave that
stage `-` / NOT RUN.

On the validated Montezuma setup, `UR1:` and `UR2:` block and therefore are **not** suitable immediate-EOF providers.

Do not delete:

```text
BTRDR.DAT
```

between stages.

Delete it only when intentionally resetting 0471 evidence.

---

# Phase 16 — RANDTEST Terminal Read-Only Tests: 0368/0369

These are special because on DRI CP/M the tested BDOS operation can abandon RANDTEST and enter the resident error path.

Run the selected test against the controlled read-only:

```text
BTRO.DAT
```

fixture.

For each of:

```text
RANDTEST /0368

RANDTEST /0369
```

the external observer must establish all four facts:

1. The operation reaches the expected `File R/O` terminal outcome.

2. Acknowledging it returns to a usable CCP.

3. The complete fixture disk is byte-identical before and after.

4. `BTRO.DAT` still exists and remains read-only.

A typical DRI message is:

```text
Bdos Err On B: File R/O
```

RANDTEST cannot subsequently print `P` / PASS because CP/M has abandoned the transient program.

Therefore **the external evidence is the verdict**.

A normal return, successful write, changed disk, missing fixture, failure to recover, or an unaccepted different outcome is not `P` / PASS.

---

# Phase 17 — Other Read-Only Delete/Rename Terminal Cases

DIRTEST has protected Delete/Rename procedures which may similarly enter a resident terminal-error path.

For each selected procedure:

1. capture the resident error;

2. acknowledge it;

3. verify recovery to CCP;

4. verify that the protected fixture was not changed.

Again, the transient cannot necessarily report after CP/M abandons it.

---

# Phase 18 — ENTRYTST Terminal Tests

Now run the tests deliberately postponed earlier.

## 0026 — BDOS Function 0 Termination

```text
ENTRYTST /0026
```

The expected successful terminal result is recovery to a usable CCP.

## 0027 — RET Termination

```text
ENTRYTST /0027
```

Again verify successful CCP recovery.

## 0595 — WBOOT

```text
ENTRYTST /0595
```

This invokes WBOOT and cannot report afterward.

Judge the resulting reconstructed CP/M/CCP environment according to the printed procedure.

---

# Phase 19 — BIOSTEST BOOT/WBOOT Tests

BIOSTEST's BOOT/WBOOT tests are also nonreturning.

Select the outstanding BOOT procedures individually and follow the printed stages exactly.

BIOSTEST retains cross-restart evidence in:

```text
BTBOOT.DAT
```

A subsequent invocation uses that evidence to judge the reconstructed environment.

**Do not delete `BTBOOT.DAT` between stages.**

Delete it only when intentionally resetting the boot evidence and starting those procedures again.

---

# Phase 20 — ERRTEST Physical-Error Campaign

Do this near the very end.

First understand the crucial requirement:

**A fake return value is not a physical-error test.**

The fault must occur **after the requested operation reaches the candidate BIOS**.

Suitable providers can include:

- controlled faulty media;

- an emulator's disk-fault mechanism;

- a guarded BIOS shim with evidence that the real candidate path was reached.

Run:

```text
ERRTEST /LIST

ERRTEST /GROUP:LIST

ERRTEST /GROUP:MANUAL
```

and work through the outstanding physical/fault/recovery procedures individually.

For Ignore/Abort cases, capture:

- fault injected;

- resident diagnostic;

- operator response;

- resulting disk/file state;

- recovery or non-recovery;

- CCP usability afterward.

Use restorable media.

A procedure for which you cannot provide the required physical fault remains `-` / NOT RUN.

It does not fail merely because your emulator or hardware cannot provide the experiment.

---

# Phase 21 — Named Profiles

Now review profile-class items.

These appear with class:

```text
X
```

or `PROFILE`.

Only judge them as requirements if the candidate **claims that named profile**.

Examples include strict DRI presentation/behavior, declared command-tail capacity, unavailable-drive behavior, and DRI ecology behavior.

For an unclaimed profile, do not turn nonparticipation into either `P` / PASS or `F` / FAIL.

Run the applicable:

```text
TOOL /GROUP:PROFILE
```

where provided, plus any individual procedures required by the claimed profiles.

---

# Phase 22 — NOT GUARANTEED Observations

Review the `N` / `NOT GUARANTEED` entries.

Where the suite can observe them, record the result.

They may characterize such things as implementation-specific state, presentation, ordering, or unspecified processor behavior.

These are:

```text
O / OBSERVED
```

not conformance passes or failures.

Do not use a difference from DRI CP/M as a failure unless the ledger actually makes it REQUIRED or the candidate claims the relevant profile.

---

# Phase 23 — Final ALL Pass

Once all manual, destructive, terminal, provider, and profile procedures possible on the system have been performed, run all twelve `/ALL` reports again:

```text
FILETEST /ALL

RANDTEST /ALL

DIRTEST /ALL

CONSTEST /ALL

BDOSTEST /ALL

ENTRYTST /ALL

CCPTEST /ALL

DISKTEST /ALL

BIOSTEST /ALL

ERRTEST /ALL

ECOTEST /ALL

CPUTEST /ALL
```

This final run is especially useful where test executables retain evidence across earlier procedures.

Do **not** expect every row necessarily to say `P` / PASS.

---

# Phase 24 — Interpret the Final Results Correctly

There are four basic status outcomes:

| Status | Meaning |
|---|---|
| `P` / PASS | Test executed and matched its oracle |
| `F` / FAIL | Test executed and produced contrary evidence |
| `-` / NOT RUN | No valid verdict was obtained |
| `O` / OBSERVED | Informational behavior was recorded |

And four classes:

| Class | Meaning |
|---|---|
| `R` | REQUIRED CP/M compatibility behavior |
| `N` | NOT GUARANTEED |
| `X` | Named PROFILE |
| `S` | OUT OF SCOPE |

The important rule is:

> **`-` / NOT RUN is not `F` / FAIL—but it is never `P` / PASS.**

Likewise:

> **An observation differing from DRI CP/M is not automatically a compatibility failure.**

---

# Completion Criterion

Call the manual campaign **complete** when all **627 ledger items** can be accounted for across the twelve test executables and every one has a defensible disposition:

- `P` / PASS

- `F` / FAIL

- `O` / OBSERVED

- `-` / NOT RUN

- **PROFILE — not claimed**

- **OUT OF SCOPE**

Completion does **not** mean all 627 items say `P` / PASS.

The suite distinguishes between:

1. assigned ledger items;

2. items represented by this suite version;

3. procedures actually executed with valid fixtures/providers;

4. required `P` / PASS and `F` / FAIL results, `O` / OBSERVED items, and
   `-` / NOT RUN items.

That distinction must be preserved in the final report.

---

# Recommended Execution Order

For an actual manual campaign, use the phases above in order:

1. Establish the candidate machine and preserve restorable media.

2. Inventory the suite.

3. Run every `/SAFE` set.

4. Investigate all SAFE failures before proceeding.

5. Run every `/ALL` set.

6. Complete ordinary manual/interactive procedures.

7. Perform exact ENTRYTST operand tests.

8. Perform the DIRTEST USER test.

9. Prepare and use CROSS media.

10. Prepare and use BLANK media.

11. Prepare and use DISKTEST destructive media.

12. Complete CCPTEST command-level procedures.

13. Complete ECOTEST command-level procedures.

14. Complete external-device CONSTEST procedures.

15. Perform BIOSTEST 0453 with a nonzero-`OFF` disk configuration.

16. Perform BIOSTEST 0457 write-protect testing.

17. Perform BIOSTEST 0471 READER-provider testing.

18. Perform RANDTEST terminal read-only procedures.

19. Perform DIRTEST terminal read-only procedures.

20. Perform ENTRYTST nonreturning termination/WBOOT procedures.

21. Perform BIOSTEST BOOT/WBOOT procedures.

22. Perform ERRTEST physical-error procedures.

23. Evaluate claimed profiles.

24. Record NOT GUARANTEED observations.

25. Run the final `/ALL` reports.

26. Account for every ledger item and prepare the final campaign result.

When actually running the suite interactively, proceed **one small step at a time**: run the next test or preparation step, record its output/evidence, resolve anything unexpected, and only then continue.

---

# Preserved Campaign Artifacts

A completed campaign should preserve enough material for another reviewer to
reconstruct what was tested, under which conditions, and why every disposition
was assigned. Keep at least:

- candidate-system identification, including machine or emulator, CP/M, BIOS,
  CPU, disk formats, initial drive and USER number, and claimed profiles;

- compatibility-suite release/version, build identifier or Git commit, runtime
  disk filename and SHA-256 hash, and the SYSINFO version if used;

- the complete terminal transcript and saved `SYSINFO` output;

- all twelve `/LIST` and `/GROUP:LIST` inventories from the tested suite build;

- the final `/ALL` report from each of the twelve test executables;

- external evidence for terminal and nonreturning procedures, including the
  observed resident messages, recovery behavior, and before/after media checks;

- records of every snapshot, restoration, and CROSS, BLANK, DISK, or other
  fixture-media recreation event;

- retained evidence files needed to substantiate multi-stage procedures, or a
  byte-for-byte archival copy of the media containing them;

- every `-` / NOT RUN item and its reason, plus the disposition of each claimed
  or unclaimed profile item; and

- the final accounting of `P` / PASS, `F` / FAIL, `O` / OBSERVED, `-` / NOT RUN,
  PROFILE not claimed, and OUT OF SCOPE results.

Preserve hashes for disk images and other binary evidence wherever practical.
The artifact set, rather than any single summary number, is the auditable record
of the campaign.
