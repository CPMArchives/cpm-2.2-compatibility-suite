# Investigation 016: CP/M 2.2 BDOS Console I/O and System Interface Semantics

Status: Complete  
Date: 2026-08-14

## 1. Objective and method

This investigation establishes externally visible CP/M 2.2 behavior for BDOS
Functions 1, 2, 6, 9, 10, 11, 12, 25, 26, and 32. The request names Function
34 as Compute File Size; the CP/M 2.2 interface assigns Compute File Size to
Function 35 (23h), while Function 34 is Write Random. Function 35 was therefore
tested only for its possible interaction with system/DMA state.

Evidence was kept in four distinct classes:

1. DRI's *CP/M 2.0 Interface Guide* defines the application interface.
2. DRI CP/M 2.2 BDOS source identifies implementation paths and tests to run.
3. Deterministic probes on z80pack CP/M 2.2 establish observed behavior.
4. Compatibility classifications below distinguish interface requirements
   from incidental DRI state and unresolved BetterCP/M choices.

The probe suite reruns the applicable Investigation 003-006 probes and adds
SYS016, BLOCK016, and SCROLL016. Every case starts with a fresh preserved A:/B:
pair. Raw transcripts, disk images, hashes, sources, binaries, and the harness
are under `probes/`. No conclusion below relies on source alone.

## 2. Documentation findings

### Function 1: Console Input

Call with C=1. It waits for a character and returns the character in A. The
documented formatted-console path echoes graphic characters and handles CR,
LF, TAB, and BS; TAB advances to the next tab stop. Console flow control and
printer-echo processing belong to the formatted path. The documentation does
not promise preservation of other registers, an exact BIOS-call sequence, or
that Ctrl-C passed to Function 1 causes a warm restart.

### Function 2: Console Output

Call with C=2 and the character in E. Output uses the formatted console path:
TAB is expanded and console stop/start and printer-echo controls are honored.
No function result is specified. Exact cursor-column bookkeeping and BIOS call
counts are not part of the interface.

### Function 6: Direct Console I/O

Call with C=6. E=FF requests nonblocking input; A is zero when no character is
available and otherwise contains the character. Other documented ASCII values
in E are sent directly. Direct output bypasses echo, TAB expansion, console
flow control, and printer-echo interpretation. E=FE is not a documented mode.

### Function 9: Print String

Call with C=9 and DE pointing to a `$`-terminated string. Bytes before the
first `$` use the same formatted path as Function 2; the terminator is not
emitted. No result or bounds check is specified.

### Function 10: Read Console Buffer

Call with C=10 and DE pointing to a buffer. Byte 0 is the maximum input count,
byte 1 receives the count, and characters begin at byte 2. CR or LF terminates
the line and is excluded from the count. Documented editing includes rubout,
backspace, line deletion/restart, redisplay, and physical-line continuation;
Ctrl-C at the beginning of a line warm starts CP/M. The function has no
specified register result. Exact visual erasure sequences and private editor
state are not promised.

### Function 11: Get Console Status

Call with C=11. The Interface Guide describes zero for no character and FF for
ready. It does not specify whether polling may fetch and retain a character,
nor the exact BIOS polling sequence.

### Functions 12, 25, 26, and 32

- Function 12 returns the version in HL. CP/M 2.2 reports 0022h: H=00 identifies
  CP/M and L encodes major/minor as 22h.
- Function 25 returns the current drive in A, zero-based (A:=0 through P:=15).
- Function 26 takes the DMA address in DE. The selection persists until reset
  or another Set DMA and applies to subsequent disk transfers.
- Function 32 uses E=FF to query the user number in A; other E values select a
  user number modulo 32. No meaningful result is documented for the set form.
- Function 35 takes an unambiguous FCB in DE and writes the 24-bit record count
  into its random-record field. It is not a DMA-transfer operation.

## 3. DRI source findings (implementation evidence)

The reviewed OS3BDOS source has shared `conin`, echo, and formatted-output
paths; a `conbrk` poller; and a private pending-character byte. `conbrk` polls
BIOS CONST, retains ordinary input, consumes Ctrl-S and a resume character, and
contains a Ctrl-C warm-boot path while output is stopped. Function 6 has a
separate direct path. The Function 10 editor masks input to seven bits and
implements its controls internally. Functions 12, 25, 26, and 32 return or
change version, current disk, DMA address, and masked five-bit user state.
Function 35 updates the FCB random-record bytes without transferring DMA data.

These details motivated pending-input, raw-output, editor, flow-control, and
DMA-sentinel tests. They are not compatibility requirements merely because
they occur in DRI source.

## 4. Experimental design and results

Environment: z80pack cpmsim 1.39, CP/M 2.2, Z80 CBIOS 1.2. The harness uses
Expect and never requires manually timed keyboard input. Complete byte-level
results are in `probes/observed-output.txt` and raw `probes/cases/*/console.txt`.

### Input and status

Function 1 demonstrably blocked for one second without input, then returned Q
as 51h. A separate Ctrl-C case returned 03h normally and did not warm boot.
Scripted A, TAB, CR, LF, and BS returned their character codes; graphics and
the documented whitespace controls were echoed. Ctrl-A and Ctrl-P returned
without console echo.

Function 6 input returned zero with no input and 5Ah for scripted Z. Function
11 returned zero with none and **01h**, not FFh, when ready in this DRI build.
Repeated status checks preserved the character, and Function 1 later consumed
it. Thus readiness is required, but the exact nonzero value is not portable on
the combined documentary and experimental evidence. Function 6 did not consume
DRI's private status-pending byte in this probe.

### Output

Function 2 emitted `$` as ordinary data and expanded TAB. Function 9 stopped
at the first `$`, omitted it, handled an empty string, and applied formatted
TAB behavior. Function 6 output passed A, TAB, `$`, Ctrl-P, B as raw bytes.

The scroll probe substituted deterministic BIOS console routines: Ctrl-S then
Q were consumed before Function 2 emitted X (two input calls, one output call,
58h). This proves DRI formatted-output flow-control behavior without timing or
manual input. The Ctrl-C-while-stopped branch was identified in source but was
not independently executed here; its exact compatibility treatment remains a
policy question.

### Buffered input

Function 10 produced the documented maximum/count/data layout. CR and LF
terminated but were not stored. Zero-length input and immediate termination at
the maximum were observed. BS and DEL removed the previous character; Ctrl-E
continued on a new physical line; Ctrl-U and Ctrl-X erased the current line;
Ctrl-R redisplayed it; and Ctrl-P toggled DRI printer echo without entering the
buffer. At line start, Ctrl-C printed `^C`, warm restarted to A>, and the probe
did not return to its post-call marker.

### Identity, drive, user, DMA, and file size

SYS016 observed HL=0022 from Function 12. Function 25 reported 0, 1, 0 across
controlled A:/B:/A: selections. Function 32 queried user 0, selected and
queried user 5, then restored user 0.

Console and identity calls left two complete 128-byte DMA sentinels unchanged.
A subsequent sequential read placed 41h at the alternate address, proving the
Function 26 selection itself also remained current. Function 10 used its DE
line buffer, not DMA. Function 35 reported 000082h records for the controlled
file and did not depend on DMA.

### Disk repeatability

All 13 accepted cases used fresh copies. In every case both post-run disk
images were byte-identical to the corresponding before images. Each case
retains before/after SHA-256 files and directory listings.

## 5. Compatibility conclusions

### REQUIRED

- Implement the documented selector/input/result contracts above.
- Preserve the distinction between formatted Functions 1/2/9/10 and raw
  Function 6 output.
- Function 1 must wait until input is available; Function 6 input must not.
- Function 9 must stop before the first `$`.
- Function 10 must implement the documented buffer layout, termination,
  capacity, editing controls, and line-start Ctrl-C warm start.
- Function 11 must distinguish ready from not ready and must not lose input as
  a consequence of status polling.
- Return 0022h for CP/M 2.2 from Function 12; return zero-based current drive
  from Function 25; implement persistent Set DMA; implement query/set user.
- Console functions must neither depend upon nor overwrite DMA, and must not
  silently change the selected DMA address. Function 10's DE buffer is separate.

### DRI implementation details / NOT REQUIRED

- Exact internal labels, branch layout, private pending-character storage,
  console-column variable, BIOS call counts, and correction byte sequences.
- E=FE behavior for Function 6.
- Register values not documented as results.
- Treating Function 34 as Compute File Size; CP/M 2.2 assigns that function to
  selector 35.
- DRI's internal seven-bit mask, except where a separately adopted application
  compatibility requirement demands the same external result.

### NOT GUARANTEED

- Exact nonzero ready value from Function 11: the guide says FFh, while the
  tested DRI CP/M 2.2 image returned 01h.
- Whether status readiness is implemented by BIOS-only state or a BDOS pending
  byte, and whether Function 6 shares that pending state.
- Any meaningful return from output, buffered-input, Set DMA, or set-user calls.

### POLICY PENDING

- Whether BetterCP/M should reproduce DRI printer-echo toggling on Ctrl-P in
  every formatted input path.
- Whether to reproduce DRI's exact Ctrl-S/Ctrl-Q handling and Ctrl-C warm boot
  while formatted output is stopped, beyond providing compatible flow control.
- Whether to mask all Function 10 input to seven bits.
- Whether BetterCP/M should deliberately return FFh for Function 11 exactly as
  documented, or accept/produce any nonzero true value as observed in DRI.

## 6. Proposed ledger additions (not applied)

The current ledger was not modified. Existing console entries 52-130, current
drive entry 150, DMA entries 208-209, and file-size entries 347-352 already
cover much of this surface. The following concise additions/reconciliations
are proposed after Investigation 015's proposals:

414. **REQUIRED** — BDOS Function 12 returns the CP/M version in HL; a CP/M
     2.2-compatible system returns 0022h.
415. **REQUIRED** — BDOS Function 32 with E=FF returns the current user number
     in A.
416. **REQUIRED** — BDOS Function 32 with E other than FF selects the user
     number modulo 32.
417. **NOT GUARANTEED** — The set form of Function 32 has no meaningful
     application-visible return value.
418. **REQUIRED** — Console Functions 1, 2, 6, 9, 10, and 11 neither use nor
     overwrite the current DMA transfer buffer.
419. **REQUIRED** — Console and identity calls do not change the DMA address
     previously selected by Function 26.
420. **REQUIRED** — Function 10 stores its buffer through the DE address supplied
     for that call; that buffer is not the current DMA buffer by implication.
421. **NOT REQUIRED** — BetterCP/M need not implement DRI's private
     pending-character representation or exact BIOS polling sequence.
422. **NOT REQUIRED** — Function 6 E=FE behavior is outside the documented CP/M
     2.2 direct-console interface.
423. **NOT REQUIRED** — Function 34 is not a Compute File Size alias; Compute
     File Size is Function 35.

## 7. Incomplete and unresolved cases

No required experiment was blocked. The following deliberately narrow cases
remain unresolved policy work, not claimed experimental findings: Ctrl-C as
the resume character after Ctrl-S; exact printer-device effects of Ctrl-P on
real hardware; high-bit Function 10 input; and behavior across alternative
BIOS implementations. These do not invalidate the documented interface tests.

## 8. Artifact and preservation audit

- Investigation directory, report, all seven source probes, seven COM files,
  README, observed output, harness scripts, raw transcripts, preserved disk
  images, and hash records: present.
- All COM files rebuilt byte-identically with z80asm 2.1.
- All 13 case image pairs: unchanged byte-for-byte during their runs.
- Source documents and OS3BDOS source are identified and hashed in
  `probes/source-hashes.sha256`.
- Compatibility Ledger SHA-256 before and after: recorded in
  `probes/ledger-hash.txt` and unchanged.
- No existing BetterCP/M file was modified; only this new Investigation 016
  directory is created at final installation.

## 9. Sources

- Digital Research, *CP/M 2.0 Interface Guide*.
- Digital Research, *CP/M 2.2 Alteration Guide*.
- Digital Research CP/M 2.2 `OS3BDOS.ASM` source.
- Prior BetterCP/M Investigations 003-006 and current compatibility ledger.
- z80pack cpmsim/CP/M 2.2 environment, commit recorded with the probe evidence.
