# Investigation 042 - CP/M 2.2 Common Software Compatibility Assumptions

## 1. Objective and scope

This investigation identifies operating-system assumptions made by practical CP/M 2.2 software beyond a reading of individual API descriptions. It examines DRI tools and independent-vendor development/editor software, source, executable patterns, and controlled reference-system execution. It does not port individual packages or infer requirements from software that was not available and tested.

The main result is conservative: the observed ecosystem overwhelmingly reinforces documented CP/M interfaces - 0100h COM loading, CCP command preparation, page zero, CALL 0005h, FCB/DMA file services, 128-byte records, and warm restart. One previously deferred ecosystem mechanism merits new ledger propositions: the DRI CCP/SUBMIT command stream and XSUB's delivery of submitted lines through BDOS Function 10.

## 2. Compatibility standard

Evidence classes are:

- **A**: documented behavior in the CP/M 2.0 Interface Guide (IG) or CP/M 2.2 Alteration Guide (AG).
- **B**: DRI implementation/source behavior or preserved vendor executable evidence.
- **I**: controlled observation in the z80pack CP/M 2.2 environment.
- **D**: unresolved BetterCP/M policy.

Repeated independent use strengthens an existing requirement; it does not convert an implementation accident into an interface. A literal executable byte pattern is a screening lead because it may be data. It becomes dependency evidence only when corroborated by source, documentation, or execution. Findings are classified REQUIRED, NOT GUARANTEED, NOT REQUIRED, or POLICY PENDING.

## 3. Relationship to previous investigations

I034 defines memory, page zero, system boundaries, and the TPA. I036 defines BIOS availability and hardware abstraction. I037 consolidates the BDOS service set. I040 defines configured disk geometry and direct-structure responsibility. I041 distinguishes public direct-access interfaces from private targets.

I021 established ordinary CCP acquisition/parsing but explicitly left SUBMIT acquisition untested and for later work. I042 closes the narrow successful-stream portion of that gap. It does not replace the earlier detailed semantics or reopen their dispositions.

## 4. Software ecosystem categories

| Category | Preserved evidence | Execution coverage | Result |
|---|---|---|---|
| Assemblers | DRI ASM/MAC/RMAC source or binaries; Microsoft M80; SLR Z80ASM | Full ASM fixture; controlled startup of the others | Standard TPA, page zero, BDOS/file interfaces reinforced. |
| Compilers | `SPEED.C` sample only; no compiler with adequate provenance | Not tested | No compiler-specific claim. |
| Editors | DRI ED source/binary; MicroPro WordMaster | Full ED create/close; WM startup | Console/file/text conventions reinforced; terminal-specific editing untested. |
| Database | None adequate | Not tested | No database-specific claim. |
| Communications | None adequate | Not tested | No serial/modem/device-specific claim. |
| Disk utilities | PIP, STAT, DUMP, SDIR; SYSGEN source | Full file workflow; SDIR startup; SYSGEN source only | FCB/DMA/search/record and configured-disk contracts reinforced. |
| System utilities | DDT, SID, ZSID, SUBMIT, XSUB | DDT restart; SUBMIT/XSUB full stream; debugger startups | Page-zero/restart and batch interposition are practical dependencies. |
| Linkers/development | Microsoft L80; SLR SLRNK | Controlled startup | Standard loader/console environment reinforced; link semantics untested. |
| Games/applications | None adequate | Not tested | No game/application-specific claim. |

The untested categories are explicit coverage gaps, not evidence of absence.

## 5. Documentation findings

The Interface Guide describes relocatable CP/M organization, standard BOOT=0000h and TBASE=0100h, the principal FDOS gateway at BOOT+0005h, its operand as the configured high-memory boundary, CCP loading of `command.COM`, default FCB preparation, and the function-number/information-address interface (**A**).

The Alteration Guide assigns page-zero fields, documents programmed restart, the 0005h JMP and ceiling convention, default FCB and command/DMA areas, and the configured BIOS vector (**A**). These published conventions explain most recurring software assumptions without invoking an undocumented ABI.

CP/M text tools use CR/LF and 1Ah logical end-of-text conventions, but BDOS file records remain byte-oriented. The OS requirement is correct byte preservation and the already established resident-command semantics, not global interpretation of 1Ah by all file functions.

Neither manual makes vendor terminal control sequences, exact utility diagnostics, temporary filenames, private debugger state, or fixed resident addresses universal.

## 6. Source findings

The DRI ASM modules call 0005h, use the default FCB at 005Ch, set DMA, and read the word at 0006h to size workspace. DUMP likewise uses 0005h and the default FCB. ED uses the external maximum at 0006h, default FCB/buffer, buffered console behavior, and documented file functions. STAT uses 0006h as a memory bound, 005Ch/0080h, directory search, DPB-related functions, alternate DMA, and file size (**B**).

SUBMIT reads the CCP-prepared default FCB, forces type SUB, uppercases source, performs parameter/control-character substitution, writes counted command records in reverse order to `A:$$$.SUB`, closes it, and invokes WBOOT. OS2CCP, when submission is active, reopens that file, reads the last remaining record, copies its counted command into the CCP buffer, decrements/updates the file, and deletes it on exhaustion or cancellation (**B**).

XSUB saves and redirects the WBOOT/BDOS gateway operands, chains the real BDOS, tracks Function 26 DMA changes, intercepts Function 10 calls, supplies the next `A:$$$.SUB` record as buffered input, and restores the saved path when the stream disappears (**B**). This is historically significant shipped-software use of the flat-memory/interposition class established by I041; it does not make the private BDOS target a general ABI.

SYSGEN directly derives BIOS entries for system generation, while ordinary application tools primarily use BDOS. Direct BIOS assumptions therefore remain specialized and configured, not ecosystem-wide permission to hard-code hardware or vector addresses.

## 7. Software dependency findings

### Repeated, well-supported dependencies

- COM origin and entry at 0100h; CCP lookup and explicit-drive command dispatch (**A**, **B**, **I**).
- Valid 0000h WBOOT and 0005h BDOS gateways; CALL 0005h service convention (**A**, **B**, **I**).
- Default FCBs, command tail/default DMA, uppercase filename parsing, and FCB drive codes (**A**, **B**, **I**).
- The word at 0006h as the configured usable-memory ceiling. DRI ASM/ED/STAT and literal patterns in Microsoft M80/L80 and MicroPro WM independently reinforce this documented convention (**A**, **B**).
- 128-byte records, alternate DMA, directory search, sequential I/O, close persistence, and explicit-drive FCB behavior (**A**, **B**, **I**).
- Programmed restart and public page-zero visibility for debuggers/system tools (**A**, **B**, **I**).

### Supported ecosystem mechanisms

- CCP consumption of `A:$$$.SUB` generated by standard SUBMIT across transient completions (**B**, **I**).
- XSUB interposition sufficient to supply a queued submitted line to a transient's Function 10 call without console input (**B**, **I**).
- CR/LF with 1Ah text termination/padding in the DRI editor/assembler workflow (**B**, **I**), without changing binary BDOS semantics.

### Unsupported or overbroad assumptions

- A universal private BDOS/CCP/BIOS address, private entry point, stack, or serialization layout.
- A universal terminal type, screen size, escape sequence set, modem port, or device timing.
- One raw disk geometry or direct-sector layout.
- Exact DRI utility wording, backup/temp-file naming, empty artifact behavior, or directory order.
- That startup success proves every feature of an application.

## 8. Undocumented convention analysis

The investigation distinguishes four kinds of convention:

1. **Documented and repeated.** CALL 0005h, 0006h ceiling, 0100h, FCBs, page zero, and WBOOT are already REQUIRED. Ecosystem prevalence strengthens evidence but does not need duplicate entries.
2. **De facto data convention.** CR/LF and 1Ah are important to CP/M text tools. The OS must preserve them and its supplied TYPE/CCP tools must follow their established behavior; BDOS must not treat every 1Ah byte as file EOF.
3. **DRI ecosystem protocol.** `A:$$$.SUB` plus XSUB is not merely an internal algorithm: separately supplied DRI transients and CCP cooperate through observable files, gateway interposition, and Function 10. Strict compatibility should execute this standard workflow.
4. **Incidental implementation behavior.** Empty `EDIT42.BAK`/`NOFILE.$$$`, exact banners, literal handler addresses, and emulator diagnostics lack a general dependency case and are NOT REQUIRED or NOT GUARANTEED.

Independent-vendor binaries reinforce the documented common denominator. They do not establish a second undocumented universal interface.

## 9. Representative software testing

The full deterministic workflow executed DRI ASM and LOAD to create and run HELLO42, PIP/STAT/DUMP to copy and inspect it, ED to create a text file, missing-file failures, DDT page-zero inspection and G0 restart, and SUBMIT/XSUB with an actual Function-10 consumer. The batch fixture ended with a unique HELLO42 marker so completion was not inferred from timing.

Isolated sessions started Microsoft M80/L80, MicroPro WordMaster, SLR Z80ASM/SLRNK, and DRI MAC/RMAC/SDIR/SID/ZSID. Their own prompts/banners prove CCP lookup/loading and initial runtime viability. They do not prove untested compilation, linking, screen editing, debugging, or file-format features.

The 19-file executable screen found literal CALL 0005h in 17, JP 0000h in 10, loads from 0006h in 12, and loads from 0001h in 3 (**B**). Source and execution corroborate the principal patterns; unmatched programs are not presumed to avoid CP/M services.

Compiler, database, communications, and game packages were not tested because adequate local software/fixtures were absent. No evidence is claimed for them.

## 10. Experimental results

| Matrix class | Test | Principal observation | Evidence |
|---|---|---|---|
| Documented API | ASM/LOAD/HELLO42 | 0100h-0113h image ran and returned | I |
| Documented API | PIP/STAT/DUMP | Explicit-drive copy, two records, exact bytes | I |
| Documented API | ED | Created/closed CRLF text padded with 1Ah | I |
| Failure | ASM/PIP missing input | Reported failure and returned to CCP | I |
| Direct system | DDT D0,7 and G0 | Public vectors visible; WBOOT restored prompt | I |
| Common ecosystem | SUBMIT RUN42 | Automatic command execution across transients | I |
| Unusual/historical | XSUB + IN42 | Function 10 received `BATCH42` from submission | I |
| Independent software | Ten isolated startups | Microsoft/MicroPro/SLR/DRI interfaces reached | I |
| Executable analysis | 19 COM pattern screen | Common gateway/ceiling patterns identified | B |

The complete purpose, procedure, observation, and conclusion for each case is in `probes/observed-output.txt`. Startup and full-workflow transcripts, inputs, output disk images, sources, and executable hashes are preserved.

Drive images changed only in disposable copies. Expected changes include assembler/listing/COM output, PIP copies, ED output, DRI temporary entries, and creation/consumption of `A:$$$.SUB`. No original z80pack image was modified.

## 11. Compatibility conclusions

**REQUIRED**

- All documented interfaces reinforced in section 7: 0100h lifecycle, page-zero objects, CALL 0005h, configured memory ceiling, CCP/FCB/tail environment, file/DMA/record semantics, and WBOOT.
- Strict-profile execution of the standard DRI SUBMIT command stream across transient completion.
- Strict-profile ability for standard XSUB to interpose the documented gateways and supply a submitted line through Function 10 while chaining ordinary BDOS operations.
- Byte-transparent storage of CR/LF, 1Ah, and arbitrary data; existing text-tool/resident-command interpretations remain as separately specified.

**NOT GUARANTEED**

- Private system addresses/entries or exact reserved-memory contents.
- Direct BIOS behavior beyond the configured documented vector contract.
- Terminal/device-specific behavior not declared by the platform profile.
- Utility-specific temporary/backup artifacts, exact wording, and directory placement.
- Compatibility of software or features not executed or otherwise evidenced.

**NOT REQUIRED**

- Reproduction of DRI source algorithms, private stacks/tables, exact utility implementations, vendor banners, and emulator shutdown diagnostics.
- Global operating-system interpretation of 1Ah as EOF for binary BDOS reads.

**POLICY PENDING (D)**

- Whether non-strict profiles may disable gateway interposition or SUBMIT/XSUB support while declaring a reduced compatibility class.
- Which additional third-party application suites define the acceptance corpus for compilers, databases, communications, games, and full-screen terminal behavior.

## 12. Proposed ledger additions

The authoritative ledger ends at 0619. Two independently testable ecosystem propositions are proposed and were not applied.

### 0620. DRI submitted-command stream

    In a strict CP/M 2.2 compatibility profile, after standard SUBMIT creates
    A:$$$.SUB and invokes warm restart, the CCP automatically acquires and
    executes its counted command records across transient completions until the
    stream is exhausted, then removes the active submission file and resumes
    console command acquisition.

    Disposition: REQUIRED
    Evidence: I042 SOFTWARE ECOSYSTEM COMPATIBILITY subsystem IG AG; SUBMIT;
              CCP; RUN42
    Conformance: submit a deterministic multi-command file ending in a unique
                 transient marker; verify ordered execution across returns,
                 exhaustion cleanup, and subsequent console prompt.

### 0621. XSUB buffered-input compatibility

    A strict CP/M 2.2 compatibility profile permits the standard DRI XSUB
    utility to interpose the page-zero WBOOT/BDOS gateways, chain ordinary BDOS
    calls, and satisfy a transient's BDOS Function 10 request from the next
    A:$$$.SUB command record without console input.

    Disposition: REQUIRED
    Evidence: I042 SOFTWARE ECOSYSTEM COMPATIBILITY subsystem IG AG; XSUB;
              IN42; RUN42; I041
    Conformance: activate XSUB from a submission, run a transient that calls
                 Function 10, place a known following record in the stream, and
                 verify the counted buffer and continued command execution.

## 13. Existing-entry updates

- **0001-0005:** add I042 assembler/editor/debugger and independent-vendor evidence for 0100h, WBOOT, and 0006h ceiling; no wording change.
- **0011-0024:** add ASM/ED/PIP/STAT workflow evidence for CCP-supplied FCB/tail/DMA state; avoid duplicating I023.
- **0042-0044 and I027 call entries:** add the 19-executable screen plus source corroboration for CALL 0005h; preserve non-preservation limits.
- **CCP entries from I021-I023/I028:** add RUN42 for command execution across transient returns. Do not fold the new submission protocol into ordinary interactive parsing.
- **BDOS file/DMA/search entries:** add the representative DRI workflow only as ecosystem strengthening; no disposition change.
- **0461-0474, 0598-0600, and 0617:** retain direct BIOS as a configured specialist interface; no evidence supports broader hard-coded access.
- **0591 and 0619:** add XSUB/IN42 as concrete shipped-software interposition evidence while preserving the private-target NOT GUARANTEED distinction.
- **TYPE/text entry 0556:** add ED/ASM/DUMP corroboration for CRLF/1Ah text convention; BDOS remains binary-transparent.

No existing disposition required correction. The ledger was not modified.

## 14. Open questions

1. Which compiler/runtime suites should form the next deterministic acceptance corpus, and do they add assumptions beyond 0100h, CALL 0005h, FCBs, and 0006h workspace sizing? (**D**)
2. Which database packages depend on locking, direct directory access, unusual extent handling, or exact error presentation? (**D**)
3. Which communications programs bypass BIOS for hardware ports, and should those dependencies belong only to machine-specific profiles? (**D**)
4. Which games/applications depend on CPU undocumented instructions, video memory, timing, or terminal escape sequences rather than CP/M itself? (**D**)
5. What are the exact SUBMIT cancellation/error rules for console break, malformed command, user changes, read-only media, and damaged `$$$.SUB`? These were not tested and are not included in 0620.
6. Should strict conformance require the supplied DRI XSUB binary specifically, or only equivalent observable interposition behavior? (**D**)

## 15. Conformance implications

Conformance should use a tiered corpus. The base tier verifies documented probes. The ecosystem tier executes real DRI tool workflows plus independent-vendor startup and selected functional fixtures. Machine profiles separately declare terminal, character-device, disk-format, CPU-extension, and hardware assumptions.

Tests must distinguish a tool's own behavior from OS behavior. They should require output/state only when the dependency is independently evidenced, preserve binary file semantics, vary configured memory/drive placement, and reject hard-coded reference addresses. Startup is a smoke test, not full application certification.

A strict batch test should create a disposable submission, exercise both CCP command acquisition and XSUB Function-10 injection, verify cleanup and restoration by observable continued operation, and never rely on manual input. Failure/cancellation variants remain future work.

### Completion audit

- Investigation directory, report, sources, representative executables, fixtures, transcripts, and images: verified present.
- IN42 rebuild byte-identical: verified in `probes/rebuild-verification.txt`.
- Controlled runs reproducible from fresh restored images: verified.
- Original z80pack images: not modified; only disposable case images changed as expected.
- Authoritative ledger: unchanged; before/after SHA-256 recorded.
- Existing BetterCP/M substantive files: checked against the pre-investigation manifest. One top-level I041 prompt disappeared externally and one Finder `.DS_Store` changed independently; Investigation 042 did not write either. The exception and hashes are recorded in `probes/protected-files-audit.txt`.
- Unsupported software categories and unresolved policy questions: explicitly identified.
- Proposed entries 0620-0621: report only, not applied.
- Artifact hashes: `SHA256SUMS.txt`.

### Evidence sources

- Digital Research, *CP/M 2.0 Interface Guide*.
- Digital Research, *CP/M 2.2 Alteration Guide*.
- DRI sources preserved under `reference/`: ASM modules, ED, PIP, STAT, SUBMIT, XSUB, CCP, DUMP, and SYSGEN.
- Preserved executables and vendor banners listed in `reference/software-inventory.txt`.
- Investigations 034, 036, 037, 040, and 041.
- Controlled z80pack observations under `probes/`.
