# Executable suite implementation status

## Suite-wide to-do

- One-character status and class conversion is complete for all eleven ledger
  utilities. The shared row is `ITEM  S  C  OBSERVED`, with P/F/-/O status
  and R/N/S/X class keys.
- Period-style source commentary is complete for all utilities. BIOSTEST dev28
  established the voice; DISKTEST dev36 already carried its modifier notes;
  ECOTEST dev2, CPUTEST dev2, FILETEST dev28, CONSTEST dev13, DIRTEST dev13,
  CCPTEST dev15, SCRATCH dev4, BDOSTEST dev10, ENTRYTST dev10, and ERRTEST dev8
  have received the corresponding programmer-commentary pass.
- Functional `/LIST` grouping is complete for all eleven ledger utilities;
  group counts and totals reconcile with each assigned catalog.
- Aggregate reports with one or more failures now append a compact
  `Failed items:` selector list in every ledger utility. Clean reports omit
  the line. This preserves rerunnable selectors after long tables scroll.
- `/GROUP:name` selection is complete. Every utility supplies `/GROUP:LIST`,
  universal REQUIRED, OBSERVATION, and MANUAL views where applicable, and its
  own functional groups with safety behavior documented in the interface
  standard and user's manual.
- Fully validate every utility, including all provider-assisted, interactive,
  nonreturning, special-media, profile, restart, and recovery procedures; keep
  catalog coverage distinct from procedures actually executed and evidenced.
- The suite documentation and user's manual are complete, covering
  installation, profiles, fixtures, selectors, result interpretation, test
  order, recovery, and platform-specific operator procedures.

## ERRTEST

Dev1 establishes the complete 43-row catalog, standard selectors, compact
one-character report, and individually selectable procedures. Physical,
nonreturning, profile, and damaged-media rows name their required provider and
remain honestly untested until the complete oracle runs. The source explains
the distinction between returning logical refusals, resident physical-error
intervention, and abort paths, and reserves retained continuation evidence for
the latter two groups. No absent fault fixture is converted into a PASS.
The target bring-up corrected the private-stack exit: ERRTEST now pushes a
zero return address after changing SP, so every returning selector warm-starts
through page zero. The regression requires a fresh CCP prompt after each
command rather than accepting the prompt embedded in command echo.

Dev2 added the one-character status and class keys to `/INFO`.

Dev3 moves the class key to `/LIST`, where the compact letters actually
appear. `/INFO` returns to build and coverage information only; the result
table retains its own status and class legends.

Dev4 implements the first 23 assigned items, ERR-001 through ERR-023. The
first 22 are individually selected physical-fault, resident-handler, profile,
Ignore/Abort, and post-Ignore procedures; `/ALL` does not manufacture their
providers and therefore reports `-` until the operator performs them. ERR-023
(`0404`) is automatic: it opens the shipped one-record fixture, requires a
successful sequential read followed by the exact logical EOF result 01h,
closes the FCB, and restores DMA to 0080h. `/INFO` distinguishes implemented
coverage from procedures executed in the current invocation: 23 items are
implemented and 20 remain.

Dev5 makes the aggregate arithmetically complete. The summary now includes
the 30 not-run rows alongside pass, fail, error, and observed counts, so its
categories total all 43 displayed catalog items.

Dev6 implements the remaining 20 items, ERR-024 through ERR-043. Returning
oracles now cover random-read success/EOF (`0406`), random-write success and
the 10000h range result (`0407`), missing Open followed by a complete
Make/Close/Rename/Delete lifecycle (`0408`), and the cross-check that all
controlled logical failures returned without resident intervention (`0582`).
The remaining profile, full-media, resident, abort, and damaged-directory
items have selected provider procedures and remain `-` until performed with
their declared fixture. Coverage is complete at 43 items; aggregate execution
on the standard fixture reports five passes, twelve observations, and 26
not-run procedures.

Dev7 organizes `/LIST` by execution character: automatic return checks,
special-media procedures, physical/BIOS faults, interactive Abort/recovery,
profile procedures, non-guaranteed observations, and documentary exclusions.
The seven displayed counts sum to the authoritative 43-item ERRTEST catalog.

Dev8 completes the period-style programmer commentary pass. It documents the
fresh-FCB discipline, reserved temporary names, random-record range trick,
rename/delete cleanup, DMA restoration, and the 0582 meta-oracle which proves
that controlled logical failures returned without resident intervention.

Dev10 brings ERRTEST into the finalized command-line interface. Exact,
case-insensitive parsing supports `/H` and `/HELP`, `/VER` and `/VERSION`,
canonical `/NNNN:REPORT`, grouped `/LIST`, and `/GROUP:LIST`. Its functional
groups are AUTOMATIC, MEDIA, PHYSICAL, INTERACTIVE, PROFILE, OBSERVATION, and
EXCLUSIONS; their counts reconcile to all 43 items. Universal REQUIRED and
OBSERVATION selectors report their full memberships, while `/GROUP:MANUAL`
lists the 23 provider-dependent procedures without executing them. The full
command matrix passes in Intel 8080 and Z80 modes.

## ECOTEST

Dev1 implements all eight assigned ecology rows with the standard selectors,
one-character status/class report, and grouped `/LIST`. Item `0513` is a safe
returning oracle: missing Open must return FFh, while the shipped one-record
fixture must return sequential success 00h followed by EOF 01h. Items `0515`,
`0571`, and `0573` are explicit NOT GUARANTEED observations. The four REQUIRED
resident-command rows (`0569`, `0575`, `0577`, and `0579`) provide complete
CCP-level setup, action, success, failure, and restoration cards and remain
not-run until their outside transcript is captured; substituting direct BDOS
calls would not test the resident commands. Standard aggregate execution is
one pass, three observations, and four not-run procedures.

Dev4 brings ECOTEST into the finalized command-line interface. Exact,
case-insensitive parsing supports `/H` and `/HELP`, `/VER` and `/VERSION`,
canonical `/NNNN:REPORT`, grouped `/LIST`, and `/GROUP:LIST`. Functional
groups are AUTOMATIC, MANUAL, and OBSERVATION; universal REQUIRED and
OBSERVATION selectors report their complete memberships. `/GROUP:MANUAL`
lists the four CCP procedures without pretending to execute them. Malformed
prefixes and the retired two-token report form are rejected. The complete
command matrix passes in Intel 8080 and Z80 modes.

## CPUTEST

Dev5 brings CPUTEST into the finalized command-line interface. Exact parsing now supports /H and /HELP, /VER and /VERSION, canonical /NNNN:REPORT, grouped /LIST, /GROUP:LIST, universal REQUIRED/OBSERVATION/MANUAL groups, and the AUTOMATIC/OBSERVATION/EXCLUSIONS functional groups. Malformed prefixes and the retired two-token report form are rejected. The full command matrix passes in Intel 8080 and Z80 modes.

Dev1 implements all five assigned processor rows with the standard selectors,
one-character report, and grouped `/LIST`. Item `0623` checks the portable
binary floor through register transfer, ALU, memory, stack, and CALL/RET
signatures. Item `0624` separately checks declared 8080 flag semantics: carry
into ADC, carry preservation across INR, and packed-decimal DAA. Both pass in
the regression's Intel 8080 and Z80 execution modes. Item `0626` is the
NOT GUARANTEED observation. Z80 extensions (`0625`) and processor timing and
interrupt topology (`0627`) remain documentary exclusions from the generic
CP/M claim. The aggregate reports two passes, one observation, and two
out-of-scope rows as not-run.

## BIOSTEST

Dev32 exposes the exact operands used by controlled item `0426`: the DPB
AL0/AL1 reservation mask and the first two live allocation-vector bytes. This
turns a generic oracle failure into actionable evidence without relaxing the
empty-disk requirement or changing the conformance decision.

Dev31 appends a compact `Failed items:` line after any aggregate report with
one or more failures. This preserves the selectors after a long `/ALL` listing
scrolls off screen, so each failed row can be rerun directly with `/NNNN` or
`/NNNN:REPORT`. A deliberately incorrect controlled CONIN byte identified
`0469` in the regression.

Dev30 brings BIOSTEST into the finalized command-line interface. Exact,
case-insensitive parsing supports `/H` and `/HELP`, `/VER` and `/VERSION`,
canonical `/NNNN:REPORT`, grouped `/LIST`, and `/GROUP:LIST`. Functional
groups are ALLOCATION, DEVICES, DISK, BOOT, CHARACTER, and PROCESSOR; their
counts reconcile to all 46 items. Universal REQUIRED and OBSERVATION groups
show their complete class memberships, while `/GROUP:MANUAL` lists 27
provider-dependent procedures without executing them. Safe interface
validation runs only the five returning checks and passes under Intel 8080
and Z80 modes; scratch-media, device, fault, and boot campaigns remain
explicit operator-controlled work.

Dev1 establishes the standard suite interface and catalogs the first 23 of 46
assigned BIOSTEST rows: `0423` through `0451` in assignment order. It gives
honest OUTSIDE SCOPE and NOT GUARANTEED observations and leaves REQUIRED and
OPTIONAL procedures UNTESTED until their complete controlled-media or device
oracles are implemented. No bring-up row fabricates a PASS from a pointer or
call smoke test.

Dev2 adds the remaining 23 assigned rows, `0452` through `0473` plus `0622`,
so all 46 BIOSTEST catalog entries are now discoverable and individually
selectable. Required direct-BIOS, boot, device-provider, and controlled-media
procedures remain UNTESTED until their full oracles are implemented.

Dev3 adds five safe returning probes: coherent Function 7/8 IOBYTE access with
restoration (`0443`), current-drive public DPH validation (`0451`), the
seventeen-entry BIOS jump-vector structure (`0461`), page-zero-only BIOS-base
discovery (`0463`), and writable/executable self-modifying code at two TPA
locations (`0622`). Aggregate PASS/FAIL counters are computed from results.
Every remaining terminal, scratch-disk, optional-profile, or device-assisted
row supplies setup, action, success, failure, and restoration guidance when
selected; aggregates leave those procedures honestly UNTESTED.

Dev4 makes the Function 7/8 IOBYTE probe preserve its original value, expected
value, and result in memory across BDOS calls. Dev3 incorrectly assumed that
BDOS preserved working registers; on systems that clobbered them, the restore
could write a corrupt IOBYTE and make the console appear to lock. Dev4 also
documents that page zero points to WBOOT, so SELDSK is WBOOT plus 24 bytes.

Dev5 implements seven controlled-disk oracles (`0424`-`0427` and
`0431`-`0433`). `/ALL` and those individual selectors request a different
configured drive prepared by `SCRATCH /BLANK`, require explicit confirmation,
and then validate the Function 27 pointer, DPB-derived ALV extent and bit
mapping, AL0/AL1 directory reservations, a one-record allocation/release
lifecycle, two complete public DPB layouts, permitted DPB sharing, and a
guarded live DPB modification. The harness restores the modified field, DMA,
user area, and original drive and deletes its sole `BTBIO.TMP` fixture. `/SAFE`
remains non-destructive at five returning probes. A completed controlled run
reports 12 passes, zero failures or errors, 11 observations, and 23 remaining
scope/provider/profile procedures.

Dev6 adds a guarded trace layer for the public SELDSK-through-SECTRAN BIOS
jump vectors. It verifies writable JMP operands before interposition, preserves
each original target, uses fixed CALL/JMP trampolines so BIOS arguments remain
unchanged, and restores all vectors before reporting. A two-record lifecycle
now gives complete returning oracles for stateful setup (`0449`), configured
and absent SELDSK results when an absent drive exists (`0450`), the
SECTRAN-to-SETSEC chain (`0454`), application/directory DMA selection (`0456`),
and WRITE type codes 0/1/2 (`0458`). Track-boundary item `0453` and injected
failure item `0457` remain UNTESTED until their additional fixtures exist.
The common controlled aggregate is 17 passes, zero failures or errors, 11
observations, and 18 remaining procedures.

Dev7 adds six character-device returning oracles. A guarded logical-boundary
trace verifies BDOS Function 4 graphic/control-byte dispatch to PUNCH (`0439`),
fixed READER/PUNCH/LIST dispatch under three IOBYTE values (`0445`), and DMA
selection plus two sentinel regions across Functions 3/4/5/7/8 (`0448`). One
operator-supplied uppercase `K` verifies real BIOS CONST empty/ready/ready/empty
transitions without consumption (`0468`) and the corresponding zero-parity
CONIN byte (`0469`). A raw direct TAB versus formatted BDOS Function 2 TAB
comparison completes the layering oracle (`0473`). All patched JMP operands,
IOBYTE, DMA selection, and transient bytes are restored before reporting.
Direct LIST/PUNCH capture (`0470`) and READER normal/absent-provider behavior
(`0471`) remain UNTESTED because simulating those providers inside BIOSTEST
would test the harness rather than the candidate BIOS. With both controlled
groups selected, the aggregate is 23 passes, zero failures or errors, 11
observations, and 12 remaining procedures.

Dev8 implements the three nonreturning boot contracts as recoverable two-stage
tests. Selectors `0464`, `0465`, and `0466` write a closed one-record
`BTBOOT.DAT` evidence record before transferring to the real BOOT or WBOOT
entry. Rerunning the same selector after CCP resumes validates the public
gateways and BDOS environment; `0465` also verifies the requested drive, while
`0466` first damages only the opcodes at 0000h and 0005h and then requires
WBOOT to reconstruct both original gateways. The cold-BOOT verifier requires
operator confirmation that the first resumed prompt was `A>`, the one CCP-entry
fact a later transient cannot recover. Completed evidence is tied to the saved
gateway layout and is included in subsequent `/ALL` summaries. Delete
`BTBOOT.DAT` to reset it. With disk, character, and all three boot groups
complete, the aggregate is 26 passes, zero failures or errors, 11 observations,
and nine remaining procedures.

Dev9 adds an explicit successful-boot completion notice explaining that
`BTBOOT.DAT` is intentionally retained for subsequent `/ALL` reporting and
that `ERA BTBOOT.DAT` resets the boot tests after final evidence is captured.

Dev10 adds the complete recommended order to `/H` and every boot-test start
prompt: run `0465` twice, `0466` twice, and `0464` twice (selecting B: after
the cold boot resumes at A:), then run `/ALL` and erase `BTBOOT.DAT`.

Dev11 simplifies that instruction into one numbered sequence using the same
wording in `/H` and at every boot-test start prompt.

Dev12 completes required track-mapping item `0453`. During the guarded disk
trace, BIOSTEST derives the expected SETTRK value from the selected drive's
public DPB, decodes each sequential record's allocation block, and writes far
enough to cross an adjacent track boundary on media whose DPB has a nonzero
`OFF`. It requires every observed SETTRK value to equal the calculated logical
track plus `OFF`; a mismatch reports both 16-bit values. The temporary file,
BIOS vectors, DMA selection, drive, and user area are restored before results
are reported. The full dev12 aggregate passes under z80pack in both Z80 and
Intel 8080 modes with 27 passes, zero failures or errors, 11 observations, and
eight remaining scope/provider/profile procedures.

Dev13 corrects individual-selector routing so a disk-only selector such as
`/0453` no longer falls through to the controlled character-device prompt. It
also distributes a blank expendable 880K Montezuma image specifically for
`0453` and states the missing configuration prerequisite explicitly: the
emulator drive must use a matching system-format DPB whose `OFF` is nonzero.
The operator can verify that prerequisite with SYSINFO before running
`SCRATCH /BLANK` and BIOSTEST.

Dev14 makes the operator prerequisite unambiguous in the controlled-test
prompt: item `0453` requires a freshly formatted SYSTEM disk with nonzero
`OFF`. `SCRATCH /BLANK` is described only as a way to clear previously used
media, not as a formatter or a prerequisite after a fresh SYSTEM format.

Dev15 implements required logical-sector transfer item `0457` without
fabricating the physical-failure result. Using the current guarded BIOS disk
state on the expendable temporary file, it writes one known 128-byte pattern,
reads exactly one logical sector back, and compares all bytes. It then asks
the operator to make the scratch disk write-protected and requires the
candidate BIOS WRITE entry to return nonzero; after the operator restores
writability, a second zero-status write confirms recovery before normal file
cleanup. Choosing Q at the fault prompt leaves the row honestly UNTESTED.
With the provider completed successfully, the aggregate becomes 28 passes,
zero failures or errors, 11 observations, and seven remaining
scope/provider/profile procedures.

Dev16 prints the protected and post-restoration BIOS WRITE status bytes before
judging `0457`. This distinguishes a write-protect mechanism that the running
BIOS did not observe from a mechanism that remained active after the operator
restored writability.

Dev17 uses WRITE type 1 for the successful, protected, and recovery operations
in the direct `0457` oracle. A normal type-0 write may remain only in a BIOS
blocking/deblocking buffer and therefore return zero without touching
write-protected media; directory-class type 1 requires the physical transfer
to occur immediately.

Dev18 completes the two remaining required character-device procedures. Item
`0470` calls CONOUT, LIST, and PUNCH directly with one graphic and one control
byte apiece and captures each C byte at the guarded logical BIOS boundary,
without imposing BDOS formatting or requiring physical output hardware. Item
`0471` calls the saved candidate READER entry in two explicitly independent
provider stages: an assigned reader must return uppercase `R` in A, and an
absent/unassigned reader must return Ctrl-Z immediately. The operator may use
Q at either provider prompt to leave `0471` honestly UNTESTED. The automatic
`0470` path and the `0471` skip path pass regression under z80pack's strict
Intel 8080 mode; the complete `0471` PASS remains a target-provider test.
With both procedures completed, the aggregate becomes 30 passes, zero
failures or errors, 11 observations, and five remaining out-of-scope or
optional-profile procedures.

Dev19 makes the unavoidable blocking behavior of `0471` explicit before each
candidate READER call. CP/M exposes no READER-ready vector or portable timeout:
the normal-stage `R` must already be queued on the external reader device, not
typed at the console, and the absent configuration must be known to return
Ctrl-Z immediately. Either stage can be skipped with Q before the call.

Dev20 corrects the configuration sequence for Montezuma Micro CP/M. The two
READER states cannot be selected while a transient is running, so `0471` is
now retained across two invocations. Stage one runs after `STAT RDR:=PTR:`,
accepts uppercase R, writes `BTRDR.DAT`, and returns to the CCP. Stage two runs
after `STAT RDR:=UR1:` or `UR2:`, requires the shipped null reader to return
Ctrl-Z immediately, and retains the completed PASS for later `/ALL` runs.
Deleting `BTRDR.DAT` resets the reader evidence.

Dev21 corrects the stage-two instructions after direct target testing showed
that both Montezuma `UR1:` and `UR2:` assignments block despite their nominal
user-reader/null-device role. `STAT` and its logical-device assignment syntax
are CP/M/IOBYTE conventions, but every named physical driver is supplied by
the target BIOS. BIOSTEST now requires an independently verified immediate
Ctrl-Z provider and explicitly directs Montezuma users to choose Q when none
is available, leaving `0471` honestly UNTESTED rather than risking a hang.

## DISKTEST

Version: `0.1.0-dev39`

All 20 assigned rows are represented: seventeen REQUIRED, one NOT GUARANTEED,
and two OUTSIDE SCOPE. Seven returning disk-state and read-only-vector checks
run automatically in `/SAFE`; `/ALL` adds the thirteen selected or metadata
rows without silently performing destructive operations. Every selected
destructive, disk-full, or terminal-outcome row prints its required fixture,
action, expected evidence, failure criteria, and restoration step.

DISKTEST follows `INTERFACE-STANDARD.md`, including `/LIST`, `/INFO`, `/H`,
`/H:RESULTS`, and `/H:PROFILES`. Its 8080-compatible executable and numeric
selectors pass the regression under CP/M 2.2 in both Intel 8080 and Z80 modes.
IBM 3740 and Montezuma Micro packages each provide a utility disk plus a
dedicated restorable D: disk for capacity and write-protection work.

Dev2 replaces static-screen tail jumps into BDOS Function 9 with conventional
CALL/RET paths. This preserves a normal caller return address for Montezuma
Micro BDOS while retaining the same output and 8080-compatible instruction set.
Dev3 emits strings through BDOS Function 2 one character at a time, preserving
the cursor around each call and avoiding target-specific Function 9 scanning.

Dev39 brings DISKTEST into the finalized suite command interface. Exact
single-token parsing supports `/NNNN`, `/NNNN:REPORT`, `/ALL`, `/SAFE`,
grouped `/LIST`, `/GROUP:LIST`, `/H` and `/HELP`, `/INFO`, and `/VER` and
`/VERSION`; the useful legacy `/FN:13`, `/FN:28`, and `/FN:29` selectors remain
orthogonal. Functional membership reconciles the catalog as 1 STATE, 7 ALLOC,
and 12 PROTECT items. Universal REQUIRED, OBSERVATION, and list-only MANUAL
groups are available, and `/ALL` now shows all six terminal manual rows and
both OUTSIDE SCOPE rows. On independently prepared full scratch disks,
`/ALL` returned eleven passes and one observation with zero failures or errors
under both Z80 and Intel 8080 modes; the complete selector and malformed-input
matrix also passed in both modes.

## CCPTEST

Version: `0.1.0-dev18`

All 59 assigned catalog rows are represented: forty-one REQUIRED, ten NOT
GUARANTEED diagnostics, four named PROFILE rows, and four OUTSIDE SCOPE rows.
Every separately run row prints a concrete command or setup and an explicit
success criterion. The final batch adds loader, transient lookup, DMA,
resident-command, user-area, SUBMIT, and XSUB coverage. `/SAFE` and `/ALL`
are validated under CP/M 2.2 in both Intel 8080 and Z80 processor modes.

Dev2 replaces the circular executable-identity procedure with a two-program
dispatch comparison. It also gives the strict DRI diagnostic-profile case its
literal expected `NOEXIST?` display, prompt-return check, and failure criteria.

Dev3 automates item 0492. Executing CCPTEST's known image at transient address
0100h is itself the required executable-identity evidence, so the utility now
reports PASS or FAIL directly without asking the operator to compare programs.

Dev4 automates items 0010 and 0013. The first checks the page-zero gateway,
scratch/FCB boundary, and command-entry layout. The second directly validates
FCB2 after `CCPTEST /0013 B:ALPHA.TXT`, including drive number and padded 8.3
name; neither case requires a debugger or copied helper program.

Dev5 makes selected item 0013 report semantic evidence after execution. A
passing row now states that FCB2 contained drive 2 and `ALPHA.TXT`; the compact
aggregate row continues to show the exact selector required to run the case.

Dev6 unifies the user-facing aggregate presentation. Both selector-driven
automatic checks and operator-verified procedures now appear as `MANUAL`, with
the exact command in `OBSERVED`. Their internal distinction remains only so a
selected case can either compute PASS/FAIL or explain what the user must judge.

Dev7 expands the diagnostic status label from `OBS` to `OBSERV`.

Dev8 corrects the status model: `STATUS` now contains only `PASS`, `FAIL`, or
`UNTESTED`. NOT GUARANTEED diagnostics use `UNTESTED / NOT GUAR.` and place
their recorded evidence solely in `OBSERVED`.

Dev9 separates `STATUS` from `CLASS` and documents the full contract on `/H`.
NOT GUARANTEED observations now report PASS/FAIL for successful/failed
collection while remaining explicitly nonconforming. Separately run checks are
UNTESTED in aggregates, retain their REQUIRED or PROFILE class, and put their
exact invocation in `OBSERVED`; `MANUAL` is no longer used as a class.

Dev10 clarifies `/H`: PROFILE means an optional named compatibility claim
(for example, strict DRI behavior), while OUT SCOPE means CCPTEST cannot
execute or judge that catalog item, so it remains UNTESTED without PASS/FAIL.

Dev11 names each applicable profile directly in aggregate `OBSERVED` output.
The help screen explains the convention instead of embedding a fixed profile
catalog; selected `/NNNN` output defines that row's claim and expected result.

Dev18 brings CCPTEST into the suite command-line contract. It uses exact,
case-insensitive single-selector parsing; supports `/HELP`, `/VER`, `/VERSION`,
and `/NNNN:REPORT`; rejects prefixes, extra tokens, and the retired
`/NNNN /REPORT` form; and groups `/LIST` into ENTRY, COMMAND, LOADER, MEMORY,
FILES, and SUBMIT. Every displayed functional group is runnable through
`/GROUP:name`; REQUIRED and OBSERVATION provide universal class views, while
MANUAL lists its 34 selected/operator procedures without executing them.
The complete non-destructive command matrix preserves the established `/SAFE`
12-pass and `/ALL` 21-pass/9-observation results under both Intel 8080 and Z80
processor modes.

## ENTRYTST

Version: `0.1.0-dev15`

Dev10 completes the period-style programmer commentary pass. It explains the
saved entry stack, nonreturning cards, A5h loader and DMA witnesses, Function
40 sparse-file sandbox, cleanup roads, and read-only traversal of the public
BIOS/DPH/DPB/SECTRAN chain.

All 59 assigned catalog rows are represented. Twenty-five REQUIRED probes run
in `/SAFE`; three CCP-entry cases use prescribed selectors, and ten terminal
or hardware-dependent REQUIRED rows remain manual. The strict-profile FCB2
case is selector-driven. `/ALL` additionally reports sixteen NOT GUARANTEED
observations. Four rows are outside executable
scope. The regression runs under z80pack CP/M 2.2 in both Intel 8080 and Z80
processor modes, and matching IBM 3740 and Montezuma Micro 200K media are
generated from the same executable.

Dev3 makes every individually selected manual row actionable. Each now prints
the required setup, action, and expected result; item 0012 also exposes the
actual second default-FCB name/type field for direct comparison. Aggregate
reports retain their compact one-row representation.
Separately-run cases report `UNTESTED` with their actual class until their
procedures are performed and judged. `OBSERVED` supplies the command to run.

Dev4 converts item 0617 to a safe automated probe. ENTRYTST now acts as the
direct-structure caller: it locates SELDSK and SECTRAN through the public BIOS
jump table, follows the active DPH to its DPB, compares that pointer with BDOS
Function 31, validates core DPB fields, and exercises sector translation
without changing disk data or the selected drive.

Dev5 automates Function 40 selector/input, zero-fill, and result-family cases
with a reserved scratch file and verified cleanup. It also automates DPB block
mask/limit coherence and logical-structure traversal. Items 0014, 0015, and
0020 now return PASS/FAIL with their displayed operands; profile item 0012
likewise judges its second default FCB rather than merely printing it.

Dev6 makes item 0026 directly runnable. `/ALL` points to `ENTRYTST /0026`;
the selected case explains that a usable returned CCP prompt is success, waits
for confirmation, and then invokes BDOS Function 0 itself.

Dev7 adds the same guided terminal flow for entry RET and WBOOT. Every other
manual selector now names its prerequisites, exact operator actions, success
and failure criteria, unavailable condition, and required state restoration.

Dev13 brings ENTRYTST into the finalized suite command interface. Exact
single-token parsing supports `/NNNN`, `/NNNN:REPORT`, `/ALL`, `/SAFE`,
grouped `/LIST`, `/GROUP:LIST`, `/H` and `/HELP`, `/INFO`, and `/VER` and
`/VERSION`. Functional membership reconciles all 59 items as 22 ENTRY,
6 TERMINATION, 10 LOADER, 8 BIOS, 4 FUNCTION40, and 9 DEVICES rows. Universal
REQUIRED and OBSERVATION groups run their returning members, while MANUAL
lists all fourteen manual, selected, and profile procedures without invoking
them. The complete returning matrix passes under both Z80 and Intel 8080
modes: `/SAFE` reports 25 passes, and `/ALL` reports 41 passes including
sixteen observations, with zero failures or errors.

Dev15 corrects the ZSM4/LINK load layout. Relocatable source no longer applies
`ORG 0100h` before LINK establishes the standard transient origin; this removes
the extra 256-byte gap that made ENTRYTST report false failures for its own
0100h load-address probes. The corrected build again returns 25 passes for
`/SAFE` and 41 passes, zero failures, and 16 observations for `/ALL`.

## BDOSTEST

Version: `1.0.0-dev10`

Dev10 adds the period-style programmer commentary pass. It documents the
table dispatcher, painted-DMA witnesses, 0..3 directory-slot conversion,
paired Search Next fixtures, disposable-file lifecycle, state restoration,
and the separation of automatic, profile, manual, optional, and outside-scope
cards. Executable statements are unchanged apart from embedded version text.

Dev13 brings BDOSTEST into the finalized command-line interface. Exact,
case-insensitive parsing supports `/H` and `/HELP`, `/VER` and `/VERSION`,
canonical `/NNNN:REPORT`, grouped `/LIST`, and `/GROUP:LIST`. Functional
groups are GATEWAY, DRIVE, DIRECTORY, IDENTITY, STATE, and CONTRACT; their
counts reconcile to all 86 items. Universal REQUIRED and OBSERVATION groups
select by catalog class, while `/GROUP:MANUAL` lists four manual/profile
procedures without executing them. The complete fixture reports 56 passes
under `/SAFE` and 70 passes plus 14 observations under `/ALL` in both Intel
8080 and Z80 modes.

All 86 assigned catalog rows are represented. The first fifteen REQUIRED
probes cover the public BDOS call
convention, byte and word results, documented aliases, selector range, caller
stack restoration, and Functions 13 and 14 disk-state behavior. Six NOT
GUARANTEED rows record register and Function-13 return observations without
affecting conformance. Items `0034`, `0044`, `0050`, and `0131` are explicit
OUTSIDE SCOPE metadata rows.

The returning `/SAFE` aggregate reports 56 passes and zero failures or errors,
plus three manual REQUIRED rows and one manual profile row; `/ALL` reports the
same passes plus fourteen observations. The regression passes
under z80pack CP/M 2.2 in both Intel 8080 and Z80 processor modes. Probes
restore the caller's current drive. The DMA-restoration case uses Search First
as its observer and leaves no file behind. IBM 3740 and Montezuma Micro 200K
runtime media are generated from the same executable.

Dev5 adds the second 25 assigned rows. It covers Function 14 drive numbering,
current-drive and login-vector state, default and explicit FCB drive selection,
and Search First result, DMA-transfer, slot, layout, and user-number behavior.
Media-change and unavailable-drive presentation remain explicit manual rows so
aggregate execution cannot damage media or block for console input. Returning
aggregates pass 34 automated REQUIRED probes with zero failures in Z80 and
Intel 8080 modes.

Dev6 adds assigned rows 51 through 75. It covers wildcard and default-drive
searches, Search Next continuation and DMA behavior, restart and enumeration
semantics, version and user-number calls, console/identity DMA isolation, and
observable system-state independence. Structured errors remain optional;
buffered input and BIOS-owned resource checks are explicit manual rows. The
automated aggregate passes in both z80pack Z80 and Intel 8080 modes.

Dev7 completes the final eleven rows. It adds ALV/DPB pointer observations,
Function 37 optional-profile and Function 39 outside-scope metadata, selector
boundary and common gateway/carrier/result checks, general register and stack
rules, and invalid-parameter portability metadata. BDOSTEST now has no catalog
representation backlog.

Dev4 regenerated both fixture families from the same verified executable and
uses compact status, disposition, and observation text so table rows also fit
the narrower usable display area observed under trs80gp. Diagnostic values are
included directly in their table rows rather than printed on separate lines.

## CONSTEST

Version: `0.1.0-dev18`

All 80 executable CONSTEST items are implemented, and all 87 assigned catalog
rows are represented. They cover BDOS Functions 2 and 9 character and string sources,
dollar-sign termination and non-emission, empty strings, ordinary embedded
control characters, formatted TAB output, shared formatted-output state,
eight-column TAB expansion, scrolling control, logical-printer echo,
unspecified return diagnostics, and the DRI logical-column profile.
Because a console-output routine cannot serve as its own observer, these
interactive probes display separately labeled `OBSERVED` and `EXPECTED`
evidence and require a
single-keystroke operator confirmation before recording PASS or FAIL.

Catalog items `0051`, `0074`, `0089`, `0090`, `0105`, `0130`, and `0421` are OUTSIDE SCOPE. They are selectable and
appear in aggregate output with `STATUS UNTESTED` and `DISPOSITION OUT OF SCOPE`,
but invoke no probe and affect no counters. CONSTEST therefore has no remaining
implementation or representation backlog. Aggregates execute
the directly observable REQUIRED cases, report NOT GUARANTEED observations,
and show asynchronous, printer, line-editor-profile, and character-device
cases as explicit manual rows. Scrolling control, printer
echo, and DRI-profile behavior run through their individual selectors.
The complete automatable regression passed under z80pack CP/M 2.2 in both
Intel 8080 and Z80 processor modes. The CRLF source copy, prefixed with M80's
syntax-only `.Z80` directive, assembled without fatal errors under M80 and
linked under L80; the emitted program still uses only the Intel 8080 subset.
Under Montezuma Micro CP/M in trs80gp, the `/ALL` returning aggregate reports
11 passes, zero failures, zero errors, and two NOT GUARANTEED observations.
Individually selected profile items `0069`, `0070`, and `0071` also pass,
establishing that this target matches the tested DRI logical-column profile:
the shared column transitions match, LF resets the logical column, and CR
preserves it. Manual printer-echo validation remains separate because it
requires inspection of the emulator's logical-printer output.

Dev10 adds catalog items 0103 through 0122. It covers DRI Function 1 control
handling and retained input plus the Function 10 buffer contract, boundary
sizes, count and data placement, termination, editing, warm restart, and
physical-line behavior. Interactive cases show labeled observed and expected
evidence; item 0117 correctly returns to the CCP on success. Item 0105 is
represented explicitly as OUTSIDE SCOPE. The returning aggregate regression
passes under z80pack CP/M 2.2 in both Intel 8080 and Z80 processor modes.
Operator testing under Montezuma Micro CP/M in trs80gp has now covered every
implemented selector through `0122`. All applicable conformance probes pass,
including the terminal warm-restart behavior of `0117`. The previously noted
exceptions are classifications rather than target conformance failures:
NOT GUARANTEED items remain observations, OUTSIDE SCOPE items remain untested,
logical-printer cases remain untested without inspectable printer capture, and
`0116` remains untested because the current MacBook/trs80gp input path has not
provided an unambiguous ASCII DEL character.

Dev11 completes the remaining fifteen catalog rows: `0123` through `0130`,
`0421`, and `0436`, `0438`, `0440`, `0442`, `0444`, `0446`. It adds the final
Function-10 storage, return, DRI editor, printer-state, masking, correction,
and Ctrl-C probes; Function 3 Reader and Function 5 List probes; and Function
7 IOBYTE query, encoding, and routing probes. Items `0130` and `0421` are
explicitly OUTSIDE SCOPE. Device- and presentation-dependent probes are manual
by construction and require a named provider or inspectable external capture.

Dev16 brings CONSTEST into the suite command-line contract. Exact,
case-insensitive parsing accepts one selector; `/HELP`, `/VER`, `/VERSION`,
and `/NNNN:REPORT` are supported, while prefixes, extra tokens, `/VERBOSE`,
and `/NNNN /REPORT` are rejected. `/LIST` groups all 87 rows into FORMATTED,
DIRECT, INPUT, BUFFERED, and DEVICES, with matching `/GROUP:name` selectors.
Universal REQUIRED and OBSERVATION views run their returning probes; MANUAL
lists all 62 interactive/provider procedures without executing them. The full
noninteractive command matrix passes under Intel 8080 and Z80 modes, retaining
the established 15-pass, 3-observation aggregate result.

Dev18 separates the paired Function 6 operator decisions. Item `0081` now asks
only whether `E=FF` returned immediately without blocking; item `0082` asks
only whether the no-key return was exactly `A=00`. Each prompt states precisely
when to answer Y or N, while the superseded strings remain commented in source
as patch history.

## DIRTEST

Version: `0.1.0-dev13`

All 67 executable DIRTEST catalog items are implemented. Dev5 includes
`0361` through `0367`, `0370`, `0371`, and `0541`, covering Function 30
set/clear, multi-extent and result behavior, Open/Make indicator handling,
read-only Delete/Rename protection, and the post-RET diagnostic boundary.
It now also includes `0542` through `0549`, `0559`, and `0560`, covering
extent-visible enumeration, search lifetime and intervening queries, case and
ordering diagnostics, invalid-drive ambiguity, and user-state identity.
The 0542/0543 oracle is DPB-aware: it creates `(EXM+1)*128+1` records so the
fixture necessarily occupies at least two physical directory entries on the
selected disk. This avoids treating the IBM 3740 `EXM=0` layout as a portable
assumption; the same executable adapts to Montezuma Micro `EXM=1` and other
conforming CP/M 2.2 disk parameter blocks.
Dev6 adds `0561` through `0567`, completing user-area isolation, current-user
ownership and namespace scoping, complete-directory-search behavior, and CCP
USER integration. The returning aggregate `/SAFE` reports 49 required passes;
`/ALL` reports those 49 passes and fifteen observations. Terminal REQUIRED
items `0370` and `0371` and CCP integration item `0567` appear as manual rows
in aggregates. The first two require the conforming CP/M 2.2 outcome
`Bdos Err On B: File R/O`; `0567` is run after the CCP command `USER 1` and
requires BDOS Function 32 to report user 1. Every returning
individual selector, `/SAFE`, and `/ALL` was validated
under z80pack in both Z80 and Intel 8080 modes with zero failures or errors.

Dev8 corrects the selected 0567 workflow. Invoking it from user 0 now reports
UNTESTED with the exact `USER 1` procedure instead of falsely reporting FAIL.
Both maintained B: images contain DIRTEST.COM in user 0 and user 1, so the
operator can run the check after changing user areas. Only a run that begins in
user 1 is judged PASS or FAIL.
The Rename coverage includes the Function 23 FCB convention, identity and
same-drive behavior, a 129-record multi-extent file, return values, missing
sources, immediate identity transition, data preservation, and user isolation.
Mutating cases create reserved fixtures and remove them before exit.
Five additional DIRTEST catalog entries are OUTSIDE SCOPE and are deliberately
not runnable.

Dev13 brings DIRTEST into the finalized suite command interface. Its exact
single-token parser supports `/NNNN`, `/NNNN:REPORT`, `/ALL`, `/SAFE`, grouped
`/LIST`, `/GROUP:LIST`, universal REQUIRED, OBSERVATION, and list-only MANUAL
groups, `/H` and `/HELP`, `/INFO`, and `/VER` and `/VERSION`. Functional groups
reconcile the complete catalog as 11 SEARCH, 11 DELETE, 18 RENAME,
14 ATTRIBUTES, 9 ENUMERATION, and 9 USERS items. `/ALL` now includes the five
OUTSIDE SCOPE rows instead of omitting them. On a fixture-complete disposable
IBM 3740 layout, `/SAFE` and REQUIRED returned 49 passes; `/ALL` returned
64 passes, fifteen observations, three manual rows, and five OUTSIDE SCOPE
rows with zero failures or errors under both Z80 and Intel 8080 modes.

The emitted executable uses the Intel 8080 instruction subset. A CRLF `.Z80`
source copy also assembled without fatal errors under CP/M M80 and linked to
DIRTEST.COM under L80. Dedicated IBM 3740 and Montezuma Micro runtime images
are generated without a CP/M-native build disk.

## FILETEST

Version: `0.1.0-dev26`

Implemented end to end:

- All 23 FILETEST propositions classified NOT GUARANTEED: `0163`, `0182`,
  `0183`, `0225`, `0233`, `0238`, `0240`, `0244`, `0245`, `0256`, `0257`,
  `0265`, `0270`, `0277`, `0280`, `0281`, `0325`, `0334`, `0352`, `0372`,
  `0388`, `0552`, and `0554`.
  They emit `RESULT OBSERVATION`, a separate observation count, and
  `CONFORMANCE_EFFECT NONE`; they never emit or increment PASS.

- Ledgers `0170`, `0172`, `0174`, `0176`, `0178`, `0180`, `0253`, `0553`,
  `0555`, `0556`, and `0557`, completing every REQUIRED FILETEST proposition.
  Directory-full and failed-growth cases use a dedicated restorable D fixture.
- Ledgers `0156` through `0162`, `0164`, `0166`, and `0168`, covering the
  sequential and random FCB boundaries, drive/name/type fields, read-only
  attribute bit, EX/S2/allocation fields, and the Function 15 call contract.
- Ledger `0165`, case `BDOS-FILE-001-P0165`, oracle `OR-0165` 1.0.0.
- Ledger `0169`, case `BDOS-FILE-001-P0169`, oracle `OR-0169` 1.0.0.
- Ledger `0171`, case `BDOS-FILE-001-P0171`, oracle `OR-0171` 1.0.0.
- Ledgers `0167`, `0173`, `0175`, `0177`, and `0179`, with their frozen case
  IDs and oracle versions.
- Ledgers `0181`, `0219`, `0220`, `0221`, and `0222`, with their frozen case
  IDs and oracle versions.
- Ledgers `0223` through `0232`, covering guarded and alternate DMA, full
  records, sequential progression, the 128-record extent boundary and EOF.
- Ledgers `0233` through `0240` and `0242`, covering portable EOF-result variation,
  empty/partial/boundary files, repeated EOF, diagnostic failed-read DMA and
  FCB observations, working-FCB mutation, boundary EOF coherence, and an
  explicit-drive marked sequential read that preserves the default drive.
- Ledgers `0243`, `0248` through `0252`, `0254`, and `0259` through `0261`,
  covering read-only readability and the first controlled Make/sequential-write
  slice. Mutating cases use and remove the reserved `BTTEMP.DAT` name.
- Ledgers `0262`, `0263`, `0264`, `0266` through `0269`, and `0271` through
  `0273`, covering write results, persisted full-DMA records, CR/RC changes,
  overwrite, allocation, and automatic write-side extent transition.
- Ledgers `0274`, `0278`, `0279`, and `0317` through `0323`, covering the
  maximum sequential-write boundary, explicit-drive Make/write, Close metadata
  persistence, random-field encoding, random/sequential distinction, and
  Function 36 state conversion.
- Ledgers `0324`, `0326` through `0333`, and `0335`, covering Function 36
  no-I/O behavior, random-read convention/destination/success/position,
  repeated-position behavior, unwritten/missing/overflow errors, and the first
  Function 34 random-write persistence case.
- Ledgers `0336` through `0345`, covering random-write transfer, return,
  allocation, holes, virtual length, working fields, non-advancing random and
  sequential state, Close persistence, and extent-range failure.
- Ledgers `0346` through `0351`, `0368`, `0369`, `0550`, and `0551`, covering
  exact allocation-full status, Function 35 sizing, sparse virtual size,
  read-only protection attributes, special directory search, and Make/Open.
- All 132 implemented `/NNNN` and full frozen `/CASE` forms; `/GROUP:OPEN`,
  `/GROUP:SEQREAD`, `/GROUP:CLOSE`, `/FN:15`, `/FN:16`, `/FN:20`, `/SAFE`,
  and `/LIST`.
- Uppercase-normalized CP/M command-tail parsing.
- Regular console report records and requested-scope summary.
- Eight-byte guards before and after the 36-byte FCB.
- Separate `PASS`, `FAIL C002`, and guard-corruption `ERROR E005` evaluators.
- 8080-compatible executable code.

Validated on z80pack CP/M 2.2 in Z80 and Intel 8080 CPU modes. The conforming
negative fixture produced `PASS`; deliberately adding `BTMISS.DAT` produced
`FAIL C002` with observed result `00h`.

The dev15 required-layout batch passes under z80pack in both Z80 and Intel
8080 modes. All ten numeric selectors and all ten frozen case-ID selectors
reported PASS with no FAIL, BLOCKED, ERROR, unknown selector, or BDOS terminal
error. The complete existing regression also remained clean, and `/SAFE`
retained its intentionally unchanged 33-case read-only scope.

The dev16 final-required batch passes under z80pack in both Z80 and Intel 8080
modes. All eleven numeric selectors, all eleven frozen case-ID selectors, and
the complete prior regression reported zero FAIL and zero ERROR. The REQUIRED
FILETEST backlog is complete; remaining catalog entries are NOT GUARANTEED or
OUTSIDE SCOPE.

The dev17 diagnostic expansion passes its framework regression under z80pack
in both Z80 and Intel 8080 modes. Each profile ran all 19 numeric selectors and
all 19 frozen case-ID selectors, producing 38 `RESULT OBSERVATION` records,
zero FAIL/ERROR/unknown-selector records, and an unchanged `/SAFE` result of
`33 PASS`. The complete conformance regression also remained clean.

Dev18 makes the normal console presentation a compact aligned table with one
row per case and one summary. `/VERBOSE` and `/REPORT` retain the complete
structured dev17 evidence format for explanation, capture, and automation.
The result calculations and `/SAFE` membership are unchanged.

Dev19 places the FILETEST title on its own line so the `ITEM`, `RESULT`, `V1`,
and `V2` headings align exactly with their data columns. `/SAFE` was verified
at `33 pass, 0 fail, 0 error` in both z80pack CPU modes.

Dev20 uses the remaining 80-column width for a `DETAIL` column derived from
each case's frozen expectation. Descriptions are limited to the display width
and end in `...` when abbreviated. `/SAFE` remains 33/0/0 in both CPU modes.

Dev21 replaces the static `DETAIL` text with an `OBSERVED` column containing
the probe's actual `OBS1` and `OBS2` evidence bytes. Compact summaries point to
`/REPORT` and the new `/H` help selector. Help explains selection, detailed
reporting, result classes, and the numbered ledger as the normative authority.

Dev22 adds `/ALL` and completes selector discovery in `/H`. At that revision,
the implementation reported 112 normally returning cases and 19 diagnostics,
while explicitly excluding terminal-outcome items 0368 and 0369. Those counts
were corrected by the dev25 frozen-catalog audit described below. Dev22's
recorded result was `112 pass, 0 fail, 0 error, 19 observation` in both
Z80 and Intel 8080 profiles. Help enumerates `/GROUP:OPEN`,
`/GROUP:SEQREAD`, `/GROUP:CLOSE`, and the `/FN:15|16|20` selectors.

Dev23 removes the opaque `OBS1` and `OBS2` presentation introduced in dev21.
Compact rows now label actual evidence by meaning. Cases with richer retained
evidence use dedicated formatting (including Open/RC, three-read CR progress,
current/explicit drive Open results, and FCB guard status); remaining rows use
an operation-family label for prerequisite and resulting state. Failure and
guard-corruption rows do not claim successful observations.

Dev24 adds a `DISPOSITION` column beside `STATUS` in the compact table.
`STATUS` remains the runtime verdict (`PASS`, `FAIL`, `ERROR`, or
`OBSERVATION`); `DISPOSITION` reports the catalog rule (`REQUIRED` or
`NOT GUARANTEED` for currently executable FILETEST cases). OUTSIDE SCOPE
catalog entries do not execute and therefore do not produce result rows.
`/ALL` was revalidated at 112 pass, 0 fail, 0 error, and 19 observations in
both Intel 8080 and Z80 z80pack profiles.

Dev25 reconciles FILETEST with the frozen catalog dispositions. Items `0225`,
`0233`, `0238`, and `0240` now produce non-conformance diagnostic observations
rather than PASS, and OUTSIDE SCOPE item `0241` is no longer selectable or
executed. The resulting catalog totals are 109 REQUIRED, 23 NOT GUARANTEED,
and 10 OUTSIDE SCOPE: 132 executable cases out of 142. Since REQUIRED terminal
items `0368` and `0369` remain excluded from returning aggregates, the current
`/ALL` reference result is `107 pass, 0 fail, 0 error, 23 observation`; the
current `/SAFE` result is `28 pass, 0 fail, 0 error, 0 observation`. Both were
validated under z80pack in Intel 8080 and Z80 modes.

Ledger 0169 passes in both z80pack CPU modes: the current-drive and explicit-C
fixtures open successfully and BDOS Function 25 reports that the current drive
remains B. The multi-case reporter supports `/GROUP:OPEN`, `/FN:15`, and
`/SAFE`; each selector records its normalized requested scope, expands to
0169 and 0171, emits two independent case records, and calculates one summary.
The dev3 two-case aggregate baseline reported `2 PASS` under both z80pack CPU
modes and remains covered by the expanded dev4 regression runs.

Ledger 0165 passes under both z80pack CPU modes. Open of the one-record
`BTONE.DAT` fixture succeeds and returns `RC=01` at FCB byte 15, within the
documented inclusive range 0-128. Dev4 aggregate selectors expand to 0165,
0169, and 0171 and reported `3 PASS` in both modes at dev4.

The dev5 five-case batch also passes under both z80pack CPU modes. Ledger 0167
verifies three marked sequential reads and CR progression 1,2,3. Ledger 0173
verifies successful Open before access; 0175 verifies deterministic wildcard
activation of `BTWILD1.DAT`; 0177 verifies Close of an activated unchanged
FCB; and 0179 verifies a successful marked read without Close. The complete
`/SAFE` and `/FN:15` selections report `8 PASS`; `/GROUP:OPEN` reports 5,
`/GROUP:SEQREAD` 2, `/GROUP:CLOSE` 1, and `/FN:20` 3.

The same dev5 batch passes under Montezuma Micro CP/M in trs80gp. Retained
screen evidence shows individual PASS results for 0167, 0173, 0175, 0177 and
0179, followed by `/SAFE` with `SUMMARY 8 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`.

The dev6 five-case batch passes under both z80pack CPU modes. It covers failed
Close of a dirty missing-name FCB, DE-selected activated-FCB reads, recorded
Open prerequisites, three distinct sequential markers, and exact 128-byte
one-record content. `/SAFE` intentionally excludes temporary-state case 0181
and reports `12 PASS`; `/GROUP:CLOSE` and `/FN:16` include 0181 and report two
passing Close cases. The regression also exposed and corrected the aggregate
formatter so counts from 10 through 99 print as decimal.

The same dev6 batch passes under Montezuma Micro CP/M in trs80gp. Retained
screens show individual PASS results for 0181, 0219, 0220, 0221 and 0222, plus
`/SAFE` with `SUMMARY 12 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`.

The dev7 ten-case batch passes under z80pack in both Z80 and Intel 8080 modes.
It verifies 16-byte DMA guards, alternate DMA isolation from 0080h, full-record
transfer semantics, consecutive record and CR progression, the 128th-record
FCB state, records 127/128 across an extent transition, new-extent EX/CR/RC
coherence, and controlled EOF. The complete `/SAFE` selection reports
`22 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`; temporary-state case 0181 remains
available separately and through the Close selectors.

The dev7 batch also passes under Montezuma Micro CP/M in trs80gp. The retained
`/SAFE` screenshot shows `SUMMARY 22 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`, and the
operator reports that each individual selector from 0223 through 0232 also
completed with zero FAIL, BLOCKED or ERROR results.

The dev8 ten-case batch passes under z80pack in both Z80 and Intel 8080 modes.
Every numeric and frozen case-ID selector was exercised, followed by all group,
function and `/SAFE` aggregates. The complete safe selection reports
`32 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`; temporary-state case 0181 remains
available separately and through the Close selectors.

Dev9 standardizes unavailable logical-printer handling for items 0065, 0066,
0079, and 0102. Each probe now offers `U` before touching Ctrl-P and reports
`UNTESTED / REQUIRED / Logical printer unavailable; not tested` without
incrementing pass, fail, error, or observation counts.

The dev8 batch also passes under Montezuma Micro CP/M in trs80gp. The retained
`/SAFE` screenshot shows `SUMMARY 32 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`, and the
operator reports that each individual selector from 0233 through 0242 passed.

The dev9 ten-case batch passes under z80pack in both Z80 and Intel 8080 modes.
Every new numeric and frozen case-ID selector passed. The read-only 0243 case
extends `/SAFE` to `33 PASS`; the nine Make/write cases are kept out of `/SAFE`
and independently clean up their reserved temporary file before returning.

The dev9 batch also passes under Montezuma Micro CP/M in trs80gp. The operator
reports that all ten individual selectors passed with no FAIL, BLOCKED or ERROR
results. The retained `/SAFE` screenshot confirms the expected read-only scope:
`33 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`.

The dev14 ten-case batch passes under z80pack in both Z80 and Intel 8080 modes.
The eight normally returning cases pass for every numeric and frozen case-ID
selector with no FAIL, BLOCKED, ERROR, unknown selector, or leaked
`BTTEMP.DAT`. The allocation-full probe fills and restores the scratch disk and
observes exact code 02h. Ledgers 0368 and 0369 are instead validated as terminal
outcomes: for both numeric and frozen selectors, the external provider observed
the exact `Bdos Err On B: File R/O` diagnostic, acknowledged it, recovered the
CCP prompt, and confirmed that the complete protected-fixture disk hash was
unchanged. FILETEST no longer fabricates an in-process PASS from the read-only
attribute alone.

The dev13 ten-case batch (0336-0345) passes under z80pack in both Z80 and Intel
8080 modes. It covers Function 34 transfer and success, allocation, holes and
virtual length, working/random/sequential state, Close persistence, and
out-of-range failure. Every numeric and frozen case-ID selector passes, guards
remain intact, and the reserved temporary file is absent after the run.

The dev13 batch also passes under Montezuma Micro CP/M in trs80gp. The operator
reports all ten individual selectors and the aggregate run passed.

The dev12 ten-case batch passes under z80pack in both Z80 and Intel 8080 modes.
Every new numeric and frozen case-ID selector passes, and the Function 34 case
persists and rereads a complete marked DMA record before cleanup.

The dev12 batch also passes under Montezuma Micro CP/M in trs80gp. The operator
reports that all ten individual selectors passed with no FAIL, BLOCKED or ERROR
results, and `/SAFE` retained its intended read-only scope at `33 PASS`. The
same Montezuma environment assembled and linked `FILETEST` from the C-drive
self-hosting kit without error, validating the CP/M-native M80/L80 build path.

The dev11 ten-case batch passes under z80pack in both Z80 and Intel 8080 modes.
The regression corrected an initially overstrict 0320 assumption: random I/O
may alter sequential working fields; the normative check is that the random
field selects the requested record despite a distinct starting CR. Every new
numeric and frozen case-ID selector passes, and temporary files are removed.

The dev11 batch also passes under Montezuma Micro CP/M in trs80gp. The operator
reports all ten individual selectors passed without FAIL, BLOCKED or ERROR.
The retained `/SAFE` screenshot confirms the unchanged read-only regression at
`33 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`.

The maintained native toolchain is now ZSM4 plus Digital Research LINK. All
thirteen current transient programs assemble with zero ZSM4 errors and link
successfully. The logical FILETEST utility is split at the common 48K CP/M
`C400h` BDOS boundary: FILETEST contains its 93 FCB/Open/sequential items, and
RANDTEST contains its 49 random-I/O/protection/lifecycle items. The resulting programs passed
command-output smoke checks in z80pack and operator testing under Montezuma
Micro CP/M in trs80gp. The source disk includes ZSM4, LINK, UNCR, and a uniform
`BUILD.SUB` recipe.

The earlier CP/M-native self-hosting validation used a separate Montezuma
Micro 40-track DS/DD 400K DATA disk, leaving C dedicated to the explicit-drive
fixture. That private validation disk contained M80 3.44, L80 3.44, a
CRLF-formatted `FILETEST.MAC` with M80 `.Z80` mode selected, and `BUILD.SUB`.
A disposable CP/M 2.2 run assembled with no fatal errors, linked successfully,
and ran the generated `FILETEST /LIST`. Those third-party tools are not part
of the public distribution.

The dev10 ten-case batch passes under z80pack in both Z80 and Intel 8080 modes.
Every numeric and frozen case-ID selector passed, including repeated 129-record
extent-transition writes. The post-run fixture check confirms `BTTEMP.DAT` is
absent. These temporary-file cases remain outside `/SAFE`.

The dev10 batch also passes under Montezuma Micro CP/M in trs80gp. The operator
reports all ten individual selectors passed without FAIL, BLOCKED or ERROR.
The retained `/SAFE` screenshot confirms the unchanged read-only regression at
`33 PASS, 0 FAIL, 0 BLOCKED, 0 ERROR`.

Ledgers 0165, 0169, and 0171 pass under Montezuma Micro CP/M in trs80gp.
For 0165, the retained evidence records Open return `03` and FCB byte 15
`RC=01`. For 0169, it records current-drive and explicit-drive Open returns
`00`, drive `01` before and after, and intact guards. The dev4 `/GROUP:OPEN`
run contains all three independent case records and `SUMMARY 3 PASS, 0 FAIL,
0 BLOCKED, 0 ERROR`. Earlier two-case `/GROUP:OPEN`, `/FN:15`, and `/SAFE`
runs, plus the individual `/0169` and `/0171` runs, remain retained as
regression evidence.

The z80pack fixture package follows the portable-media contract: the candidate
CP/M remains on A:, FILETEST/configuration/primary fixtures are on a
nonbootable B:, and the distinct-drive fixture is on a nonbootable C:. This
focused B/C package was regenerated and FILETEST was run from B: successfully
under both z80pack Z80 and Intel 8080 CPU modes. Runtime transcripts are stored
with the generated fixture package.

Native 200K SS/DD DATA-format DMK media are also generated for Montezuma Micro
CP/M on the TRS-80 Model 4/4P. Their CP/M directories, attributes, absent
fixture, DMK sector structure and CRCs pass host-side validation. The generated
B image was mounted in trs80gp with logical B configured as Montezuma Standard
DATA (40T, SS, DD, 200K); Montezuma Micro CP/M successfully ran `FILETEST
/0171` and reported `PASS`. The retained screenshot records the complete case
and summary output.

All REQUIRED and NOT GUARANTEED entries in the logical FILETEST family, now
implemented by FILETEST and RANDTEST, are complete. The remaining ten family
entries are cataloged as OUTSIDE SCOPE and do not receive executable probes or
fabricated results.
