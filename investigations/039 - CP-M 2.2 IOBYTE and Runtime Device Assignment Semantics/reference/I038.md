# Investigation 038 - CP/M 2.2 Character Device Runtime Semantics

Evidence labels: **A** documented behavior, **B** DRI implementation, **I**
controlled observation, and **D** unresolved policy.

## 1. Objective and scope

This investigation consolidates the practical CP/M 2.2 runtime contract for
console, reader, punch and list devices across BDOS, BIOS, IOBYTE assignment,
status, blocking and failures. It identifies residual compatibility boundaries
without repeating established console editing or jump-table work.

## 2. Compatibility standard

Requirements require documentary, source, experimental or demonstrated ecosystem
support. Hardware latency, serial controllers, host terminal behavior and vendor
extensions are not promoted merely because one BIOS exhibits them. Named device
profiles may strengthen the baseline contract.

## 3. Relationship to previous investigations

I003-I006 define BDOS console output, direct I/O/status, console input/echo and
buffered editing. I018 defines Functions 3-5 and 7-8. I020 defines BIOS character
entries. I036 establishes BIOS as a public runtime ABI; I037 confirms selector
coverage. I038 combines those layers and tests their interaction.

## 4. Character-device compatibility boundary

CP/M exposes two observable layers. BDOS console functions may poll, buffer, echo,
edit and format. BIOS functions are raw logical-device calls using A/C and readiness
status. Direct BIOS callers and BDOS Functions 3-5 make reader/punch/list part of
the practical public interface, not private hardware implementation.

Software may rely on documented characters, status meaning, EOF, and IOBYTE
assignment. It may not rely on a particular UART, host stream, timing, queue depth,
printer protocol, parity violation, or absent-device stub unless a profile says so.

## 5. Documentation findings

**A.** BIOS CONST reports whether a console character is ready; CONIN waits if
necessary and returns seven-bit ASCII in A; CONOUT, LIST and PUNCH accept seven-bit
ASCII in C. READER returns seven-bit ASCII in A and uses Control-Z (1Ah) for EOF.
The vector entry LISTST exposes list readiness, but examined prose does not settle
one universal encoding strongly enough to replace the existing policy decision.

BDOS Functions 1/2/6/9/10/11 add console semantics. Functions 3/4/5 map to reader,
punch and list. Functions 7/8 expose the IOBYTE logical-to-physical assignment byte.
No documented character output function returns a portable device-error object.

## 6. Source findings

**B.** OS3BDOS polls CONST, reads CONIN, and maintains a pending console character
for its own Control-C/status handling. Formatted CONOUT expands tabs and manages
column/printer echo; direct Function 6 output jumps to raw BIOS CONOUT. Functions
3-5 dispatch directly to READER/PUNCH/LIST.

BIOS.ASM and CBIOS.ASM differ in device routing and optional-device bodies. Some
entries may be stubs. IOBYTE decoding occurs in configured BIOS logic, not BDOS.
Exact buffers, polling loops and device routines are NOT REQUIRED.

## 7. Console runtime behavior review

Existing required behavior remains: blocking input where specified, echo/editing
where specified, raw Function 6 output/input, Function 11 status, `$`-terminated
Function 9, and bounded Function 10 buffers. CHAR38 and BLOCK38 reconfirmed the
division: console A+TAB became A plus seven spaces, while Function 6 emitted TAB,
`$` and Ctrl-P raw.

Repeated Function 11 in DRI can retain a BIOS character in a BDOS pending slot.
BLOCK38 observed ready twice and later the CCP received Z. Exact queue placement
and interaction with Function 6/FF are DRI behavior, not a new universal buffer ABI.

## 8. Reader behavior review

Function 3 and BIOS READER are distinct from console input. CHAR38 retained console
Z while READER returned C1 without echo, proving separation. Documentation requires
seven-bit data and Control-Z EOF; the deliberately invalid C1 passed through BDOS,
so parity normalization is a BIOS/device responsibility.

Whether an absent reader blocks, returns Control-Z, or follows another declared
profile is NOT GUARANTEED by the baseline beyond eventual documented reader/EOF
behavior. Universal blocking cannot be inferred from a configured stub.

## 9. Punch behavior review

BDOS Function 4 passes E/C data to BIOS PUNCH without console tab expansion,
Control-P interpretation or column updates. CHAR38 captured 41, 09, 10, 80, 09,
51 exactly. The high-bit test is boundary evidence: conforming callers/BIOS must
honor seven-bit ASCII; pass-through of invalid 80 is not a requirement.

There is no portable Function 4 error return or punch-status entry. Blocking,
discarding or host failure behavior for an unavailable punch is profile-specific.

## 10. List-device behavior review

Function 5 passes characters raw to BIOS LIST. It does not toggle printer echo when
given Ctrl-P and does not inherit console tab expansion. LISTST exists for direct
readiness consumers such as documented DESPOOL use.

Exact printer-ready polarity, timeout, spool buffering, line-ending delay, and
failure behavior depend on BIOS/device profile. Applications may poll the declared
LISTST contract but may not demand one timing or queue implementation.

## 11. Device status behavior

CONST is an instantaneous readiness query, not a promise that readiness remains
true until a later call. CONIN may therefore still wait after a prior status check
in a changing environment. STATUS38 transported 00/FF through scripted CONST and
LISTST entries; this validates dispatch and results, not historical LISTST polarity.

Polling loops must tolerate repeated zero and state changes. Busy-wait instruction
count, scheduler yielding, interrupt use, and precise response time are NOT REQUIRED.

## 12. Device assignment interaction

Functions 7 and 8 expose the live IOBYTE. IOBYTE38 set A5, queried A5, and a
BIOS-facing punch handler observed A5 before restoration. Runtime reassignment is
therefore visible. BDOS does not decode fields for Functions 3-5; configured BIOS
routing determines which physical device receives the call.

Software cannot assume assignments remain fixed after it or another component
changes IOBYTE. Supported mappings, aliases and absent physical devices remain
BIOS/profile configuration. Initialization across BOOT/WBOOT follows I020/I035.

## 13. Blocking and timing behavior

Blocking is semantic, not temporal. CONIN and BDOS blocking-input functions wait
until their required character is available. Status and direct nonblocking input
return promptly with their documented no-character value. Output may block until
the configured device accepts data, but no maximum latency is portable.

BLOCK38 observed empty 11/6FF as zero, ready 6FF returning Z then zero, and raw
output. Its synthetic device is deterministic timing test machinery; it does not
define real-time limits. Polling code must not infer CPU frequency or interrupt mode.

## 14. Error and failure behavior

CP/M 2.2 defines no character-device analogue of BDOS disk-error presentation.
Reader EOF is data value 1Ah, not a structured error. Output calls have no standard
failure result. CONST/LISTST report readiness, not a rich failure reason.

Consequently unavailable-device behavior is **NOT GUARANTEED** beyond a declared
profile: an implementation might wait, discard, return EOF, remain not-ready, or
provide an external diagnostic. Silent substitution with console semantics would
be incompatible if it violates the selected logical assignment.

## 15. Software ecosystem findings

The Alteration Guide names PIP as a possible LIST/PUNCH/READER user and DESPOOL as
a LISTST user. DRI BDOS uses BIOS console services. Editors and development tools
depend on BDOS console behavior; transfer utilities use reader/punch conventions;
printing/spooling uses LIST/LISTST; communications tools commonly need raw Function
6 or direct BIOS access.

This supports the standard interfaces and logical-device separation. The local
corpus does not support universal modem signals, printer polarity, serial timing,
or vendor port access. Those are named-platform concerns.

## 16. Experimental results

Five named probes ran from fresh A/B images with scripted input. CHAR38/ERROR38
captured reader/punch/list/console separation and boundary bytes. STATUS38 enumerated
the vector and transported status. IOBYTE38 demonstrated live assignment visibility.
BLOCK38 tested empty/ready polling, DRI pending buffering, undocumented FE, and raw
output. Full results are in `probes/observed-output.txt` and the transcript.

The final `A>Z` reflects the deliberately retained DRI pending character after
BLOCK38 returned; the harness terminated the emulator without executing it. Both
post-run images are byte-identical to their prepared before-images.

## 17. Compatibility conclusions

- **REQUIRED:** documented BDOS and BIOS character entry contracts, logical-device
  separation, seven-bit character/reader EOF conventions, and live IOBYTE access.
- **REQUIRED:** raw Function 6 and raw BIOS calls remain distinct from formatted
  BDOS console output/editing.
- **NOT GUARANTEED:** exact timing, queue depth, pending-buffer internals, parity
  behavior for invalid bytes, absent-device behavior, or output failure reporting.
- **NOT REQUIRED:** DRI private polling loops, a particular UART/printer/terminal,
  exact status instruction values beyond documented/profiled meaning, or stubs.
- **POLICY PENDING:** LISTST encoding and which optional-device profiles BetterCP/M
  elects to guarantee.

## 18. Proposed ledger additions

The authoritative ledger ends at 0605; the next available number is 0606.

### Proposed Compatibility Ledger additions

0606. Character readiness is a polling snapshot

    BIOS CONST and configured LISTST readiness describe device state at the call;
    they do not guarantee that the state remains unchanged until a later I/O call
    or define a portable response-time bound.

    Disposition: NOT GUARANTEED
    Evidence: I038; DEVICE; BIOS; IG; AG
    Conformance: Vary readiness between status and I/O calls and require software
    to tolerate repeated not-ready results without assuming timing.

0607. Optional character-device failure presentation

    CP/M 2.2 defines no universal structured error result or BDOS fatal-error
    presentation for unavailable reader, punch, or list devices beyond documented
    reader EOF and configured readiness behavior.

    Disposition: NOT GUARANTEED
    Evidence: I038; DEVICE; BIOS; BDOS; IG; AG
    Conformance: Declare an optional-device profile; generic applications shall not
    require a particular wait, discard, EOF, or diagnostic policy beyond it.

0608. Character input normalization boundary

    BIOS console and reader input must provide documented seven-bit ASCII, including
    reader Control-Z EOF; BDOS need not mask a high parity bit supplied in violation
    of the BIOS contract.

    Disposition: REQUIRED
    Evidence: I038; DEVICE; BIOS; BDOS; AG
    Conformance: Verify conforming input bytes/EOF at BIOS, and do not require BDOS
    to repair deliberately invalid high-bit input.

## 19. Existing-entry updates

No ledger was modified. Proposed updates:

- console entries from I003-I006: add BLOCK38 consolidation evidence; preserve raw
  versus formatted and pending-buffer boundaries;
- **0436-0448:** add CHAR38/IOBYTE38; retain reader optional-device and active
  routing policy dispositions;
- **0468-0471:** add STATUS38/CHAR38 direct-call corroboration;
- **0472:** retain POLICY PENDING because scripted 00/FF proves transport only;
- **0597:** add BLOCK38 evidence that pending input is BDOS/CCP/BIOS-state dependent;
- **0598-0601:** add I038 practical direct-device evidence without expanding vendor
  extensions into the generic contract.

## 20. Open questions

1. Which LISTST ready/not-ready encoding should each compatibility profile adopt?
2. Which reader/punch/list physical or virtual profiles merit guaranteed absence
   behavior rather than the baseline NOT GUARANTEED classification?
3. Should strict mode implement Function 6 E=FEh exactly as DRI or leave it an
   undocumented extension/profile behavior?
4. A wider application corpus could quantify direct reader/punch/list usage beyond
   documented PIP/DESPOOL examples.

## 21. Conformance implications

Tests must separately exercise BDOS and BIOS layers with deterministic logical
devices. They should vary readiness, inject EOF, capture all bytes including control
characters, change IOBYTE during execution, and ensure console formatting does not
leak into reader/punch/list or raw Function 6 calls.

Timing conformance checks outcomes and blocking/nonblocking class, not milliseconds
or loop counts. Optional-device and LISTST tests must name the selected profile.
Generic conformance must accept hardware implementation freedom while preserving
the standard logical-device ABI.

### Completion audit

The report, five probe sources/binaries, listings, README, output, transcript,
before/after images, scripts, references and hashes are present. All executables
rebuild byte-identically. Both disk images are unchanged by the experiments. The
ledger was read but not modified, and the protected-tree audit found no pre-existing
BetterCP/M content change attributable to I038.

