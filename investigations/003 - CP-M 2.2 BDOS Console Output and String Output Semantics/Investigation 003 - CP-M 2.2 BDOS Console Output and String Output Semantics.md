# Investigation 003 - CP/M 2.2 BDOS Console Output and String Output Semantics

Date: 14 August 2026  
Status: evidence report only; no BetterCP/M policy decision or implementation

## 1. Investigation question and scope

This investigation establishes the application-visible behavior of:

- BDOS function 2, Console Output; and
- BDOS function 9, Print String.

It asks which register supplies data, which logical device receives it, how TAB, scroll pause, and printer echo behave, how function 9 finds and terminates a string, whether the terminator is emitted, how output column state crosses calls, and whether either function defines a return value.

Direct Console I/O (function 6), Console Input (1), Buffered Console Input (10), Console Status (11), raw BIOS character interfaces, terminal-specific rendering, and the means by which console input toggles printer echo are outside scope except where necessary to explain an output effect. Generic BDOS ABI propositions remain governed by Compatibility Ledger entries 035-051.

Evidence classes are: **A** documented requirement; **B** DRI CP/M 2.2 implementation behavior; **C** possible de facto dependency; **I** incidental behavior; and **D** unresolved.

## 2. Why the question matters to BetterCP/M

These are the smallest ordinary formatted-output services in CP/M. They are prerequisites for the roadmap's initial console environment, diagnostic programs, command output, error reporting, and many later conformance probes. They also define a clean boundary between portable BDOS behavior (logical console formatting and control) and hardware-specific BIOS output.

Investigating functions 2 and 9 together is narrow but necessary: DRI documents function 9's TAB, scroll, and printer-echo processing by reference to function 2, and its source sends both through the same output machinery.

## 3. Relationship to the current Compatibility Ledger

This investigation depends upon existing accepted propositions:

- 008: the BDOS gateway is at 0005h;
- 035-036: selector in C and function-specific input in DE/E;
- 039-040: normal returns establish A=L and B=H;
- 043: returning BDOS calls restore caller SP; and
- 045-049: no generic register-preservation promise exists.

No ledger entry yet specifies function 2 or function 9 semantics. Entries 039-040 do **not** give a meaningful result to functions whose documented result is “none”; they only constrain whatever values are exposed on normal return.

The System Services architecture §§7.2-7.3 assigns compatibility-visible console semantics to System Services and physical console interaction to Hardware Abstraction. The investigation supplies concrete propositions for that boundary.

## 4. Sources examined

### 4.1 Digital Research documentation

1. Digital Research, **_CP/M 2.0 Interface Guide_**, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, 56 scanned PDF pages, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`.
   - Function 1 and function 2, printed p. 8 / PDF p. 14.
   - Function 9, printed p. 11 / PDF p. 17.
   - System Function Summary, printed p. 46 / PDF p. 52.
2. Digital Research, **_CP/M 2.2 Alteration Guide_**, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`. Section 9 identifies 0005h as the primary BDOS entry and refers to the Interface Guide.

The Interface Guide is explicitly 2.0, not a silently relabelled 2.2 manual. It applies here because the 2.2 Alteration Guide incorporates that interface, the February 1980 2.2 source implements the described functions, and no relevant 2.2 source change was found.

The scan has no useful text layer. Relevant pages were rendered and OCRed for navigation, then the original page images were visually inspected. Exact control characters and the dollar-sign delimiter are taken from visual inspection, not unverified OCR.

### 4.2 Original DRI CP/M 2.2 source

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`:
   - console state/control and output: lines 161-258;
   - `$` string loop: 288-294;
   - function dispatch: 422-470;
   - common return: 2090-2104.
4. `OS3BDOS1.ASM`, the archive's Caldera variant. Its only difference is in buffered console line editing around control-X. Functions 2 and 9 and all shared output routines are otherwise identical, so the variant does not affect these findings.
5. DRI call sites in `OS2CCP.ASM`, `DUMP.ASM`, `XSUB0/1.ASM`, `SUBMIT.PLM`, and `STAT.PLM`. These corroborate normal use of function 2 for individual characters and function 9 for dollar-terminated strings. In particular, `SUBMIT.PLM` explicitly describes printing until the next dollar sign.

### 4.3 Reference environment

The behavioral reference is unchanged from Investigations 001-002:

- z80pack repository commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39, Z80 mode, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`;
- disposable copy of `cpmsim/disks/library/cpm22-1.dsk`, original SHA-256 `bb06534599e7167547563096217d775bcd073464408dbae0927a010604d03443`;
- DRI CP/M 2.2 CCP+BDOS already matched byte-for-byte to z80pack's `srccpm2/cpm.bin`;
- z80pack Z80 CBIOS V1.2.

The CBIOS and its terminal/printer sinks are not DRI distribution devices. Experiments establish DRI BDOS behavior above those sinks; terminal rendering and z80pack file filtering are environment limitations.

## 5. Documented CP/M 2.2 requirements

### 5.1 Function 2 - Console Output

**A:** C=02h selects Console Output and E contains the ASCII character.

**A:** The character is sent to the logical console device. This is a CP/M logical-device operation; no particular UART, terminal, port, or display rendering is promised.

**A:** TAB (09h) is expanded in columns of eight. The output is spaces through the next eight-column tab stop, not a literal TAB byte passed to the console device.

**A:** The formatted output path checks start/stop scrolling (control-S) and printer echo (control-P state). Thus output can pause for console flow control and can be duplicated to the logical list device when printer echo is active.

**A:** Function 2 has no function-specific output result. The Function Summary says “none.” Existing ledger aliases A=L and B=H still apply on normal return, but the values have no function-2 meaning.

**A:** Dollar sign (`$`, 24h) has no delimiter meaning in function 2 and is emitted like another graphic character. The delimiter is specified only for function 9.

### 5.2 Function 9 - Print String

**A:** C=09h selects Print String; DE is the address of the first string byte.

**A:** Bytes are processed sequentially from that address until the first dollar sign (`$`, 24h).

**A:** The terminating dollar sign is not emitted. “Until a `$` is encountered” defines it as the stopping sentinel rather than string data. Consequently an initial `$` represents an empty string, and function 9 cannot itself print a dollar sign from within one call.

**A:** Characters before the terminator go to the logical console. TAB expansion, start/stop scrolling, and printer echo are the same as function 2.

**A:** Function 9 has no function-specific output result. The Function Summary says “none.”

**A:** The interface specifies a sentinel-terminated string, not a count. It gives no maximum length and no alternative terminator. A caller that does not provide an accessible `$` has violated the documented input form; behavior is not defined by the examined documentation.

### 5.3 Shared column state implied by formatted output

**A:** Correct columns-of-eight expansion requires column position to reflect earlier formatted console output, including output from previous function calls. The formatting state is therefore observable across function-2 and function-9 calls. The documentation does not prescribe where or how it is stored.

The documentation is not explicit about every character's effect on that logical column. DRI's precise rules below are classified separately rather than silently promoted.

## 6. Relevant DRI implementation behavior

### 6.1 Shared output path

The DRI source implements function 2 as `tabout` and function 9 as a loop that calls `tabout` for every pre-terminator byte (`OS3BDOS.ASM` 250-258, 288-294, 427-428, 466-470). Both therefore share one `column` byte, one pending console-character byte, and one `listcp` printer-echo flag.

For ordinary output, `conout`:

1. checks pending console input and scroll pause;
2. calls BIOS `CONOUT` with the character in C;
3. if printer echo is active, calls BIOS `LIST` with the same processed character; and
4. updates its private logical column (`OS3BDOS.ASM` 204-238).

This private organization is **B**, not a required BetterCP/M mechanism.

### 6.2 TAB and precise DRI column rules

On TAB, DRI repeatedly sends ASCII space until `(column & 7)==0`. At column 0 this emits eight spaces; at column 5 it emits three (`tabout`, 250-258).

DRI updates column as follows (`conout`, 217-238):

- graphic bytes 20h-7Eh increment it;
- DEL (7Fh) leaves it unchanged;
- backspace (08h) decrements it when nonzero;
- LF (0Ah) resets it to zero when nonzero;
- CR (0Dh) and other controls leave it unchanged;
- decrement never proceeds below zero.

The next-TAB result makes these rules externally observable, but the complete rule set was not found stated explicitly in applicable documentation. It is therefore **B/C, policy pending**, not automatically REQUIRED. CR not resetting the private column is particularly implementation-specific-looking and should be tested against software needs before adoption.

Column arithmetic is 8-bit and wraps after 255 graphic characters. This is source-established **I** absent software-dependency evidence.

### 6.3 Scroll pause

Before each processed output character, DRI checks BIOS console status. If control-S is pending, it consumes it, then blocks for one more character. A following control-C warm-boots; any other resume character is discarded and output continues (`conbrk`, 185-202).

A pending character other than control-S is retained in a one-byte BDOS buffer for a later input service while output proceeds. These exact buffering and control-C details are **B/C** beyond the manual's general documented start/stop-scroll requirement.

### 6.4 Printer echo

DRI's output functions do not interpret a newly typed control-P themselves. Buffered console input toggles the persistent `listcp` flag; functions 2 and 9 check that current state and duplicate every character sent through `conout` to BIOS `LIST`. TAB has already become spaces, so the list device receives expanded spaces rather than TAB.

The documented proposition is that printer echo applies. The `listcp` variable, its exact toggle path, and its lifetime are DRI implementation behavior pending investigation of console input/state.

### 6.5 Terminator scan and returns

Function 9 compares each memory byte with `$` before output, stops at the first match, and increments a 16-bit address otherwise (`print`, 288-294). It performs no count or bounds check. Exact wrap/fault consequences for a missing terminator are not a contract.

Both handlers leave the common `aret` initialized to zero, so DRI returns HL=0000h, A=00h, and B=00h. The manual declares no result. These zeros are **I/NOT GUARANTEED**, while the already accepted A=L and B=H relationships remain required.

## 7. Experimental method and results

### 7.1 Probe and contamination controls

Artifacts are `probes/OUT003.ASM`, `OUT003.COM`, `observed-output.txt`, `printer-echo.txt`, and `README.txt`. The binary SHA-256 is `a776d5577c1341efdb98762053584d3f32ebca2754b25212e3223cc2952bb03b`.

Build/run:

```text
z80asm -fb -oOUT003.COM OUT003.ASM
cpmcp -f ibm-3740 drivea.dsk OUT003.COM 0:OUT003.COM
cpmsim -z -d <disposable-disk-directory>
A>OUT003
```

Each measured sequence is self-framing and performs no diagnostic call between the bytes under test. LF establishes a known DRI logical column before a TAB case. The function-2 TAB case deliberately builds its prefix with function 9, then emits `$` and TAB with function 2; this tests cross-function column state rather than assuming it.

### 7.2 Main output experiment

| Question | Expected | Observed | Interpretation |
|---|---|---|---|
| Does function 2 emit `$`? | Literal `$` | `F2:A$   X` | Yes; `$` then three TAB-expansion spaces. |
| Is column state shared across calls/functions? | Prefix via function 9 affects later function-2 TAB | At column 5, three spaces to column 8 | Yes in DRI reference. |
| Does function 9 expand TAB? | Next eight-column stop | `F9:A    X` | Four spaces from column 4 to 8. |
| Does first `$` terminate without output? | `VISIBLE`, then stop | `F9TERM:VISIBLE:AFTER` | `$HIDDEN` absent; a later call printed `:AFTER`. |
| Does initial `$` mean empty? | Nothing between brackets | `EMPTY:[]` | Yes. |
| Are CR/LF processed before scanning continues? | Line break then later B | `MULTI:A`, next line `B` | Yes; scan continued after CR/LF. |

The displayed terminal result agrees with documentation and source. Terminal placement is not evidence of a particular physical terminal requirement; the discriminating spaces and characters are BDOS-generated.

### 7.3 Printer-echo experiment

Question: when DRI printer echo is enabled through control-P during CCP buffered input, do functions 2 and 9 duplicate their fully processed output to the logical list device?

Method: at the CCP prompt, control-P preceded `OUT003`. z80pack's list-device sink wrote `printer.txt`; the preserved copy is `printer-echo.txt`, SHA-256 `744bcfe863d649516a8575f35161acc6969cc3ab551e7877e591d6f243afcd9f`.

Observed: the probe output appeared in the printer file, including three literal spaces in the function-2 TAB case and four in the function-9 TAB case. The command echo and subsequent prompt were also duplicated while printer echo remained active.

Interpretation: DRI duplicates the formatted stream after TAB expansion. This corroborates the documented printer-echo requirement and the source order.

Environment limitation: z80pack's `prtd_out` deliberately discards CR before writing its host printer file (`simio.c` 1488-1514). The missing CR bytes in `printer-echo.txt` are emulator sink behavior, not BDOS evidence.

### 7.4 Scroll-pause experiment not performed

A timing-dependent injected control-S test was not used. Reliable interpretation would require proving exactly when emulator input became visible relative to each output character; an uncontrolled success or failure would be weaker than the explicit documentation and source. Scroll pause remains a documented requirement, while its exact DRI resume/buffering details are reported from source.

## 8. Compatibility analysis

The portable boundary is stronger than “write bytes.” Functions 2 and 9 are formatted logical-console services: TAB expansion, scrolling control, printer echo, and persistent column effects are visible CP/M behavior. Function 6 exists precisely for unadorned console I/O and must not be used as evidence that these formatted behaviors are optional.

Function 9 is not an ASCIIZ, counted, or length-limited interface. Substituting any of those models would break ordinary CP/M software and strings containing zero bytes before `$`. Conversely, applications must use function 2 or multiple function-9 calls to display `$`.

BetterCP/M need not reproduce DRI's `column`, `kbchar`, or `listcp` variables, its call graph, its 8-bit overflow, or its zero return. It must reproduce accepted observable propositions independently of mechanism.

## 9. Unresolved questions

1. Should the complete DRI logical-column rules for backspace, LF, CR, DEL, other controls, and 8-bit wrap become required, or only the documented next-eight-column TAB behavior?
2. Is DRI's one-byte preservation of non-control-S input during output relied upon by real programs?
3. Is control-C after a control-S pause required to warm-boot, or merely DRI implementation behavior?
4. What state/lifetime rules govern printer-echo toggling across commands, transient returns, warm boots, and disk reset? This belongs with console input/system-state investigation.
5. What exact behavior occurs when function 9 reaches address FFFFh without finding `$`? Documentation makes the input invalid; no compatibility need is established.

## 10. Proposed conformance tests

Each assertion should map to one ledger proposition:

1. Function 2 with E=`A` emits `A` to the logical console.
2. Function 2 with E=`$` emits `$`.
3. At logical column 5, function 2 TAB emits exactly three spaces.
4. Output a prefix through function 9, then TAB through function 2; verify shared column continuity.
5. Function 9 begins at the exact address in DE.
6. Function 9 stops at the first `$` and does not emit it.
7. Function 9 with an initial `$` emits no characters.
8. Function 9 continues scanning after embedded CR/LF until `$`.
9. Function 9 TAB expands to the next eight-column stop.
10. With printer echo enabled, ordinary characters from functions 2 and 9 also reach logical LIST.
11. With printer echo enabled, TAB-generated spaces reach LIST rather than a literal TAB.
12. Queue control-S during a long output under a deterministic input harness; verify output pauses until a resume character.
13. Diagnostic/policy test: exercise backspace, LF, CR, DEL, other controls, and column wrap before TAB; compare DRI rules without initially failing BetterCP/M.
14. Verify only generic ABI aliases on return; do not require DRI's zero for these no-result functions.

## 11. Proposed Compatibility Ledger findings

One row below is one independently testable proposition. No authoritative file was modified.

| Proposition | Evidence class | Proposed disposition |
|---|---|---|
| Function 2 is selected by C=02h. | A | REQUIRED |
| Function 2 takes its character in E. | A | REQUIRED |
| Function 2 sends the character to the logical console device. | A | REQUIRED |
| Function 2 emits `$` as ordinary data. | A + experiment | REQUIRED |
| Function 2 expands TAB to spaces through the next eight-column stop. | A + source + experiment | REQUIRED |
| Formatted logical-console column state persists across function-2 and function-9 calls. | A inference + source + experiment | REQUIRED |
| Function 2 honors start/stop scrolling. | A + source | REQUIRED |
| Function 2 honors active printer echo by copying formatted output to logical LIST. | A + source + experiment | REQUIRED |
| Function 2 defines no function-specific return value. | A | NOT GUARANTEED |
| Function 9 is selected by C=09h. | A | REQUIRED |
| Function 9 starts at the address in DE. | A | REQUIRED |
| Function 9 processes sequential bytes through the first `$`. | A + source + experiment | REQUIRED |
| Function 9 does not emit its terminating `$`. | A + source + experiment | REQUIRED |
| Function 9 applies function-2 TAB expansion. | A + source + experiment | REQUIRED |
| Function 9 honors start/stop scrolling. | A + source | REQUIRED |
| Function 9 honors active printer echo. | A + source + experiment | REQUIRED |
| Function 9 defines no function-specific return value. | A | NOT GUARANTEED |
| DRI's exact backspace/LF/CR/DEL/other-control column rules. | B/C | POLICY PENDING |
| DRI's 8-bit column wrap after 255. | I | NOT REQUIRED |
| DRI's zero return from functions 2 and 9. | I | NOT REQUIRED |
| DRI's private column, pending-key, and printer-echo variables/organization. | I | NOT REQUIRED |
| DRI buffering of a non-control-S key detected during output. | B/C | POLICY PENDING |
| DRI control-C warm boot as the resume character after control-S. | B/C | POLICY PENDING |

## 12. Proposed corrections or reclassifications of existing entries

No existing ledger proposition requires correction, splitting, merging, or reclassification.

Clarification only: entries 039-040 require A=L and B=H on normal return, but do not assign a meaningful value when an individual function documents no result. Proposed no-result entries for functions 2 and 9 make that distinction explicit and prevent DRI's incidental zero from becoming a requirement.

## 13. Implications for later BetterCP/M engineering

Later engineering must keep formatted BDOS output distinct from raw/direct output and from physical console implementation. Some shared logical column and console-control state is externally necessary, but it need not resemble DRI's variables or live in the same component.

Printer echo crosses System Services and Hardware Abstraction: the portable effect is duplication to logical LIST; device assignment and host/file mechanics are platform concerns. Tests must observe logical streams rather than assume z80pack's terminal or printer-file conventions.

Recommended later numbered investigations:

1. **BDOS Console Status and Direct Console I/O semantics** (functions 6 and 11), a small nonblocking/raw-console boundary.
2. **BDOS Console Input and Control-Character State** (function 1, then function 10 separately), including control-P toggle lifetime, control-S handling, echo, and buffered editing.
3. **Logical character-device and IOBYTE semantics** (functions 3-8 plus BIOS mapping), separated from console formatting.
4. **BDOS disk reset, selection, login vector, and current-disk state** before file operations.
