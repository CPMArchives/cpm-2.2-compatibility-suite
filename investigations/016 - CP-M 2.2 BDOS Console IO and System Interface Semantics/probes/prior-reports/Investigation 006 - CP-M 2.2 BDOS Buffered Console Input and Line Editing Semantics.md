# Investigation 006 - CP/M 2.2 BDOS Buffered Console Input and Line Editing Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger or BetterCP/M implementation modified

## 1. Investigation question and scope

This investigation defines the externally visible contract of BDOS function 10, Read Console Buffer:

1. What buffer does the caller supply, and what count and data does BDOS return?
2. How do CR, LF, and buffer capacity terminate input?
3. Which characters are stored, excluded, echoed, or transformed?
4. What editing effects are assigned to rubout/DEL, Ctrl-C, Ctrl-E, Ctrl-H, Ctrl-J, Ctrl-M, Ctrl-R, Ctrl-U, Ctrl-X, and Ctrl-P?
5. Which exact DRI display sequences are contract, possible de facto behavior, or incidental implementation?

Function 1, functions 2/9, and functions 6/11 were completed in Investigations 003-005. This report uses their accepted formatted-output and printer-echo boundaries without reinvestigating them. General Ctrl-S pause timing and arbitrary pending-key behavior remain out of scope unless directly required to describe function 10.

Evidence classes are **A** documented CP/M 2.2 requirement, **B** DRI implementation behavior, **C** possible de facto dependency, **I** incidental behavior, and **D** unresolved.

## 2. Why this matters to BetterCP/M

Function 10 is CP/M's application-facing line editor. Programs rely on its memory layout and edited result independently of how a console or terminal is implemented. It also owns control behavior that function 1 does not, notably the DRI Ctrl-P printer-echo toggle. Establishing this boundary completes the documented console-input family before investigations move to logical devices or disk state.

The compatibility target is the returned buffer and required logical-device effects, not DRI's private editor organization.

## 3. Relationship to the Compatibility Ledger

This investigation depends on entries 35-43 (BDOS ABI), 59-74 (formatted output and pending state), 75-90 (direct input/status), and 91-105 (function-1 blocking input and echo). In particular:

- entries 61-62 define shared formatted state and TAB expansion;
- entries 65-66 and 102 define active printer echo;
- entries 86-88 and 104 retain pending-input questions; and
- entries 90 and 105 reject private DRI representations as requirements.

No existing entry specifies function 10. Overlap is limited to observing how function-10 editing uses already-established output and printer-echo state.

## 4. Sources examined

### 4.1 Digital Research documentation

1. Digital Research, *CP/M 2.0 Interface Guide*, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`:
   - function 10, printed p. 12 / PDF p. 18;
   - System Function Summary, printed p. 46 / PDF p. 52.
2. Digital Research, *CP/M 2.2 Alteration Guide*, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`. Section 9 identifies 0005h as the primary BDOS entry and incorporates the Interface Guide.

The Interface Guide is explicitly version 2.0. It is applicable here for the bounded reason used in Investigations 002-005: the 2.2 guide incorporates the interface, and the February 1980 2.2 source implements it. The scanned page was rendered and visually inspected, including its buffer diagram, maximum range, and control list.

### 4.2 Original DRI source

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`:
   - console helpers and formatted output, lines 161-285;
   - buffered reader and editing paths, lines 286-421;
   - function 10 dispatch, line 472;
   - common return, lines 2090-2104.
4. `OS3BDOS1.ASM`, the archive's Caldera variant. Its function-10 region differs around Ctrl-X and appears textually damaged or altered. The difference is recorded rather than treated as a second clean specification; conclusions about exact Ctrl-X display bytes rely on `OS3BDOS.ASM` plus the identified DRI binary experiment.
5. DRI distribution BIOS source for logical CONST, CONIN, CONOUT, and LIST boundaries.

### 4.3 Reference environment

- z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39 in Z80 mode, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`;
- disposable copy of `cpmsim/disks/library/cpm22-1.dsk`, original SHA-256 `bb06534599e7167547563096217d775bcd073464408dbae0927a010604d03443`;
- byte-identified DRI CP/M 2.2 CCP+BDOS with z80pack Z80 CBIOS V1.2.

The probe supplies a controlled BIOS model. It establishes DRI BDOS behavior under that model, not emulator keyboard timing or a universal BIOS implementation.

## 5. Documented CP/M 2.2 requirements

### 5.1 Buffer and return form

**A:** C=0Ah selects Read Console Buffer and DE addresses the caller's buffer.

**A:** At DE+0 the caller places the maximum number of characters the buffer can hold. Valid documented values are 1 through 255.

**A:** On return, DE+1 contains `nc`, the number of edited characters accepted. Characters occupy DE+2 through DE+1+`nc`.

**A:** If `nc` is less than the maximum, bytes after the last returned character are uninitialized/unspecified. Software must use the count rather than require a terminator or cleared padding.

Function 10 defines its result in memory, not a function-specific A or HL value. The common A=L/B=H return relationships still apply, but their value has no function-10 meaning.

### 5.2 Termination

**A:** CR/Ctrl-M terminates the line.

**A:** LF/Ctrl-J also terminates the line.

**A:** Reaching the caller's maximum character count terminates the call without requiring a further terminator.

CR and LF are termination controls, not returned data characters. The experiment confirms exclusion. DRI emits a final CR for all three return paths; the manual's line-editing description supports a returned line but does not separately specify every final display byte, so the exact final-CR output is classified B/C below.

### 5.3 Editing controls

The manual explicitly defines:

- **rubout/DEL:** removes and echoes the last character;
- **Ctrl-H:** backspaces one character position;
- **Ctrl-C:** reboots when at the beginning of the line;
- **Ctrl-E:** causes physical end of line;
- **Ctrl-R:** retypes the current line after a new line;
- **Ctrl-U:** removes the current line after a new line;
- **Ctrl-X:** backspaces to the beginning of the current line.

These controls edit or control the input operation and are not returned as ordinary data when their editing action applies.

The manual notes that functions returning the carriage to the leftmost position, such as Ctrl-X, return only to the column where the prompt ended. Thus editing is relative to the starting logical column, not necessarily physical column zero.

### 5.4 Echo and Ctrl-P

Ordinary accepted characters are echoed through formatted console output. Editing feedback is console-visible and uses the current logical column.

The function-10 source and CP/M user-facing convention establish Ctrl-P as the printer-echo toggle in buffered input. Investigation 003 already established the active printer-echo effect. Because the function-10 page's enumerated control list omits Ctrl-P while function 1's page names printer-echo control, this report classifies the exact function-10 toggle as strong B/C rather than silently claiming an explicit function-10-page statement.

## 6. Relevant DRI implementation behavior

DRI records the starting logical column, reads through its `conin` helper, masks input to seven bits, and maintains an edited length and buffer cursor.

Ordinary characters are stored and echoed through `ctlout`. Controls not handled specially can be stored and displayed in caret notation. When the length reaches the maximum, DRI returns immediately.

Backspace removes the last stored character and computes/redraws column position; DEL removes the same character and uses the same visible BS-space-BS correction in the tested binary. At an empty edited line, they wait for another character without underflowing the count.

Ctrl-E emits CR/LF, sets the starting column to zero, and continues the same logical input line. Ctrl-R emits `#`, CR/LF, restores the starting-column indentation, redisplays the retained text, and continues. Ctrl-U similarly starts a new physical line but discards the retained text. Ctrl-X erases back to the starting column using direct BS-space-BS operations, discards the line, and continues.

Ctrl-C is first stored/echoed through the ordinary control path. If it makes the edited length exactly one, DRI warm-boots; otherwise it remains an ordinary stored character. The beginning-of-line reboot condition is documented; the exact caret display and noninitial storage are implementation detail unless software dependency is shown.

Ctrl-P toggles DRI's persistent `listcp` flag and is neither stored nor echoed. Subsequent formatted echo, including the final CR, follows the new state. The private flag and mechanism are not required.

DRI masks every input byte with 7Fh before interpretation/storage. The examined function-10 page describes console characters and ASCII controls but does not explicitly promise parity-bit stripping. This is **B/C, POLICY PENDING**.

DRI's final common result word remains zero for function 10. That is **I/NOT GUARANTEED**.

## 7. Experimental method and results

### 7.1 Probe

Artifacts are `probes/BUF006.ASM`, `BUF006.COM`, `observed-output.txt`, and `README.txt`. The final binary SHA-256 is `566cc4dfda0483c60c4c747ad7084de2da4ef8dfd0666d5db0441b41ab846cf8`.

The probe temporarily redirects BIOS CONST, CONIN, CONOUT, and LIST. CONIN returns a scripted sequence; CONST reports no asynchronously pending byte; CONOUT bytes are captured; LIST and CONIN calls are counted. This is a valid controlled BIOS schedule in which each next input becomes ready when blocking CONIN requests it. It avoids timing-dependent prefetch during formatted echo.

The caller buffer is prefilled with EEh so unwritten bytes remain distinguishable. Each record preserves the maximum, returned count, first eight data bytes, output stream, LIST count, and input-call count. An initial development binary omitted the final count byte from displayed records; it was corrected and rejected as evidence.

### 7.2 Results

| Script | Returned buffer | Significant console bytes | LIST | Interpretation |
|---|---|---|---:|---|
| `ABC CR`, max 8 | count 3, `ABC` | `ABC CR` | 0 | Ordinary storage/echo; CR excluded. |
| `AB LF`, max 8 | count 2, `AB` | `AB CR` | 0 | LF terminates and is excluded; DRI returns display with CR. |
| `CR`, max 8 | count 0 | `CR` | 0 | Empty line. |
| `ABC`, max 3 | count 3, `ABC` | `ABC CR` | 0 | Capacity terminates without another input call. |
| `AB BS C CR` | count 2, `AC` | `AB BS SP BS C CR` | 0 | Backspace removes B. |
| `AB DEL C CR` | count 2, `AC` | same correction stream | 0 | DEL removes B identically here. |
| `A ^E B CR` | count 2, `AB` | `A CR LF B CR` | 0 | Physical line break, logical line continues. |
| `AB ^U C CR` | count 1, `C` | `AB # CR LF SP C CR` | 0 | Prior line discarded after new line. |
| `AB ^X C CR` | count 1, `C` | two BS-space-BS corrections, then `C CR` | 0 | Erased to starting column. |
| `AB ^R C CR` | count 3, `ABC` | `AB # CR LF`, indentation, `AB C CR` | 0 | Retained line redisplayed and continued. |
| `A ^P B CR` | count 2, `AB` | `AB CR` | 2 | Ctrl-P excluded/toggled; B and final CR reached LIST. |

The BIOS CONIN count equaled the number of scripted bytes in every case. Capacity termination used exactly three calls and did not request CR.

### 7.3 Limitations

Ctrl-C warm restart was not invoked because it does not return to the case recorder. Its required beginning-of-line behavior is explicit in the manual and source. Exact behavior of Ctrl-C later in a line is source-established but unprobed.

The harness deliberately reports CONST not ready during output. DRI's possible prefetch into its private pending byte under a different timing schedule remains covered by earlier pending-input policy questions and is not needed to determine the final edited buffer here.

Exact indentation in Ctrl-U/R output depends on the logical starting column. The test establishes relative behavior, not a fixed number of spaces for every caller context.

## 8. Compatibility analysis

The primary portable product of function 10 is a counted edited byte sequence. Treating it as ASCIIZ, storing CR/LF, or waiting for a terminator after the buffer is full would break the documented interface.

Editing effects and exact display bytes must be separated. Removal, retention, line restart, and redisplay are documented behavior. DRI's precise choices of `#`, BS-space-BS sequences, and final CR are observable but are not all spelled out byte-for-byte. They should remain policy-pending unless contemporary/software evidence establishes dependency.

Ctrl-P is likewise split into independently testable propositions: it is excluded from data; it changes printer-echo state in DRI; and subsequent echo follows the new state. These should not be collapsed into an internal `listcp` requirement.

## 9. Unresolved questions

1. Are DRI's exact correction-display sequences (`#`, BS-space-BS, indentation, final CR) relied upon by terminal-oriented software or only human-visible convention?
2. Is seven-bit masking a de facto function-10 requirement?
3. Must a noninitial Ctrl-C be stored and caret-echoed exactly as DRI does?
4. Does a clean second DRI 2.2 source variant resolve the damaged/altered `OS3BDOS1.ASM` Ctrl-X region?
5. How should function 10 interact with a NUL retained by status logic? The DRI zero-sentinel issue remains unresolved.

## 10. Proposed conformance tests

Mandatory tests:

1. Validate maximum/count/data locations independently.
2. Test empty, ordinary, CR-terminated, LF-terminated, and capacity-terminated lines.
3. Verify bytes beyond count are not treated as required output data.
4. Test backspace and DEL removal separately.
5. Test Ctrl-E continuation, Ctrl-R retention/redisplay, Ctrl-U deletion, and Ctrl-X deletion.
6. Verify Ctrl-C at logical line beginning invokes warm restart.
7. Verify Ctrl-J and Ctrl-M are excluded terminators.

Diagnostic/policy tests:

8. Compare exact correction streams, indentation, and final CR.
9. Test Ctrl-P exclusion, state toggle, and subsequent LIST duplication separately.
10. Supply high-bit input bytes and diagnose seven-bit masking.
11. Test noninitial Ctrl-C without making DRI's exact result mandatory.

Must-not-require observations:

12. Do not require DRI private variables, addresses, stack layout, or helper call graph.
13. Do not require DRI's zero common result for this memory-result function.

## 11. Proposed Compatibility Ledger findings

One row is one independently testable proposition. The authoritative ledger was not modified.

| Proposition | Evidence class | Proposed disposition |
|---|---|---|
| Function 10 is selected by C=0Ah and takes the buffer address in DE. | A | REQUIRED |
| DE+0 supplies a maximum in the documented range 1-255. | A | REQUIRED |
| DE+1 receives the edited character count. | A + experiment | REQUIRED |
| Edited characters begin at DE+2. | A + experiment | REQUIRED |
| Bytes beyond the returned count are unspecified. | A + experiment | NOT GUARANTEED |
| CR terminates and is excluded from returned data. | A + source + experiment | REQUIRED |
| LF terminates and is excluded from returned data. | A + source + experiment | REQUIRED |
| Reaching the maximum terminates without another input character. | A + source + experiment | REQUIRED |
| Ordinary accepted characters are stored and echoed. | A + source + experiment | REQUIRED |
| Backspace/Ctrl-H removes the preceding edited character when present. | A + source + experiment | REQUIRED |
| DEL/rubout removes the preceding edited character when present. | A + source + experiment | REQUIRED |
| Ctrl-C at logical line beginning performs warm restart. | A + source | REQUIRED |
| Ctrl-E starts a new physical line while retaining the logical input. | A + source + experiment | REQUIRED |
| Ctrl-R redisplays and retains the current edited line. | A + source + experiment | REQUIRED |
| Ctrl-U discards the current line after beginning a new physical line. | A + source + experiment | REQUIRED |
| Ctrl-X erases to the starting column and discards the current line. | A + source + experiment | REQUIRED |
| Editing that returns left observes the caller's starting logical column. | A + source | REQUIRED |
| Function 10 stores no CR/LF terminator or required NUL after data. | A + experiment | REQUIRED |
| Function 10 has no function-specific register result. | A | NOT GUARANTEED |
| DRI Ctrl-P is excluded from data and toggles printer-echo state. | B/C + experiment | POLICY PENDING |
| Subsequent formatted echo follows the DRI Ctrl-P state change. | B/C + experiment | POLICY PENDING |
| DRI masks function-10 input to seven bits. | B/C | POLICY PENDING |
| DRI exact correction-display bytes and final CR. | B/C + experiment | POLICY PENDING |
| DRI noninitial Ctrl-C storage/caret echo. | B/C | POLICY PENDING |
| DRI private buffered-editor organization. | I | NOT REQUIRED |
| DRI zero common result from function 10. | I | NOT REQUIRED |

Proposed new entries: **26**.

## 12. Proposed corrections or reclassifications

No existing ledger entry should be corrected, split, merged, or reclassified.

Entry 103 remains POLICY PENDING for function-1 Ctrl-P. Investigation 006 shows that DRI assigns the toggle to function 10, sharpening the distinction but not resolving what function 1 must do.

Entries 87, 88, and 104 remain POLICY PENDING. The controlled schedule intentionally avoided asynchronous prefetch and does not settle general pending-byte policy.

## 13. Implications for later BetterCP/M engineering

Later engineering must provide a counted-buffer line editor with the accepted editing effects and formatted logical-device output. It must track the starting logical column sufficiently to implement required correction behavior. This does not require DRI's variables, routine decomposition, or exact byte sequences where policy remains pending.

The maximum byte permits 255 characters, so buffer arithmetic and count handling must not accidentally impose a signed or 127-character limit.

## 14. Recommended later investigations

1. **Formatted Console Pause and Pending-Key Semantics** - deterministic Ctrl-S/resume/Ctrl-C behavior and relationships among entries 63-64, 72-73, 87-88, and 101.
2. **Logical Character Devices and IOBYTE Semantics** - functions 3-8 and BIOS mapping, excluding already completed function-6 behavior except for device selection.
3. **BDOS Disk Reset and Selection State** - functions 13-14, login vector, current disk, and page-zero drive state.
4. **Function-10 De Facto Display Compatibility** - targeted software/contemporary-source evidence for exact correction sequences, seven-bit masking, and noninitial Ctrl-C if implementation decisions require resolution.
