# Investigation 048 - CP/M 2.2 Development Toolchain Compatibility Survey

## 1. Objective and scope

This investigation determines whether CP/M 2.2 development tools expose operating-system compatibility requirements not already represented by Investigations 001-047. It reviews primary manuals, preserved DRI source, and a comparative executable corpus, then performs deterministic absolute assembly, macro assembly, relocatable assembly, linking, loading, debugging, file-error, multi-record, and batch-build tests.

The result is conservative: development tools strongly exercise the existing CCP, page-zero, BDOS, FCB/DMA, 128-byte-record, memory-ceiling, COM-loading, transient-lifecycle, and SUBMIT contracts. REL/IRL/HEX/SYM/PRN formats and compiler runtime ABIs belong to tools, not the CP/M operating-system interface. No new independently testable ledger proposition is justified.

## 2. Compatibility standard

Evidence classes are:

- **A** - documented behavior in primary Digital Research manuals.
- **B** - DRI source, documented DRI implementation, or preserved executable evidence.
- **I** - controlled observation on z80pack CP/M 2.2.
- **D** - unresolved BetterCP/M policy.

Repeated toolchain use strengthens a public requirement but does not promote every tool algorithm, intermediate format, or vendor runtime to an OS ABI. Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Any ledger evidence update must use `I048 DEVELOPMENT TOOLCHAIN COMPATIBILITY subsystem IG AG`.

## 3. Relationship to previous investigations

I034 defines the TPA, page zero, configured memory ceiling, and system-owned boundary. I041 distinguishes public gateway data from private call targets and implementation state. I042 supplies broader assembler/linker/debugger startup and executable-pattern evidence. I047 executes standard DRI utilities, including ASM, LOAD, and DDT, and concludes that their dependencies are already ledgered.

I048 adds actual macro and relocatable workflows: MAC expansion, RMAC REL generation, LINK external resolution, multi-record COM generation, DDT/SID breakpoint execution, undefined-symbol recovery, and a SUBMIT-driven rebuild. It does not reopen the detailed underlying semantics established earlier.

## 4. Toolchain coverage

| Category | Tools/evidence | I048 execution | Result |
|---|---|---|---|
| Absolute assembler | DRI ASM source/COM | ABS48 to HEX | fully exercised |
| Macro assembler | DRI MAC manual/COM | macro expansion to HEX | fully exercised |
| Relocating macro assembler | DRI RMAC manual/COM | four sources to REL | fully exercised |
| Linker | DRI LINK manual/COM | two-module external link, large link, undefined external | fully exercised |
| Loader | DRI LOAD source/COM | two HEX files to COM | fully exercised |
| Debuggers | DDT source/COM; SID/ZSID binaries | DDT and SID load/display/breakpoint/G0; ZSID prior startup only | representative functional coverage |
| Libraries | LIB/LIB80 binaries; LINK manual | IRL/REL behavior documented; not run | explicit gap |
| Comparative assemblers/linkers | M80/L80, Z80ASM/SLRNK binaries | preserved and screened; I042 startup only | no feature claim |
| Compilers | LINK manual PL/I-80 workflow; SPEED.C/COM | generated COM runtime only; no compiler available | compilation incomplete and explicitly bounded |
| Batch workflow | SUBMIT plus RMAC/LINK | byte-identical BATCH48 build | fully exercised |

The prompt requires deterministic assembly, linking, loading, debugging, file handling, and boundary tests; all were performed. A compiler executable with adequate provenance was not locally available, so compiler execution is not claimed.

## 5. Documentation findings

The MAC manual documents `MAC filename`, an assumed ASM source, and HEX, PRN, and SYM outputs. It describes approximately 12K for MAC itself and an approximately 20K minimum CP/M configuration, with additional memory becoming symbol-table space (**A**). It documents macro expansion as a language/tool facility, not an operating-system service.

The LINK-80 guide documents Microsoft-format REL inputs from RMAC, PL/I-80, or other translators; indexed IRL libraries from LIB; PUBLIC/EXTRN resolution; COM/SYM output; a normal 0100h load address; and LINK use of as many as eight default-disk temporary files (**A**). It warns that non-0100h COM load addresses do not execute normally under standard CP/M and that temporary files can remain after abnormal termination.

The same guide documents RMAC producing PRN, SYM, and binary REL files and assigning CSEG, DSEG, COMMON, PUBLIC, and EXTRN values at link time (**A**). Existing ASM, DDT, Features and Facilities, Interface Guide, and Alteration Guide evidence from earlier investigations supplies the absolute-loader, debugger, page-zero, and BDOS context.

## 6. Source findings

DRI ASM source calls the public 0005h gateway, uses default FCB/DMA conventions, and derives workspace from the word at 0006h. LOAD.PLM uses 005Ch/0080h, sequentially reads HEX, and performs Delete/Make/Write/Close for COM output. DDT source consumes public page-zero WBOOT/BDOS state and uses debugger-owned patching, with special handling around code executing inside BDOS (**B**).

These sources reinforce configured memory, public gateway, file, DMA, execution, and writable-TPA propositions. They do not require DRI's internal module boundaries, stack layouts, buffers, diagnostic paths, or literal target addresses. Complete DRI source for the tested LINK/MAC/RMAC binaries was not available; their manuals and controlled execution are used without inventing source claims.

The preserved executable screen found recurring 0005h/0000h/0006h byte patterns across DRI and third-party tools. Those patterns are treated only as corroboration where documentation, source, or behavior independently establishes their meaning.

## 7. System interface usage

The observed workflows depend on existing **REQUIRED** interfaces:

- CCP lookup, explicit-drive command dispatch, command tails, and transient return;
- 0100h TPA loading and contiguous multi-record COM images;
- public WBOOT at 0000h, BDOS gateway at 0005h, and configured ceiling at 0006h;
- selector/parameter/result BDOS calling conventions;
- FCB parsing, directory search, sequential record I/O, Make, Close, and Function 26 DMA selection;
- writable/executable application memory for debugger breakpoints;
- coherent recovery to the CCP after normal tool-level errors.

The normal tested tool paths used BDOS rather than a hard-coded BIOS or controller. SPEED.COM directly accesses z80pack clock ports; that is a declared machine-specific dependency, **NOT GUARANTEED** by CP/M. Private BDOS targets, debugger patches, and literal resident addresses remain outside the general application ABI.

## 8. Workflow assumptions

Three workflows were verified (**I**): ASM/MAC produce HEX for LOAD; RMAC produces REL modules for LINK; and SUBMIT can drive RMAC/LINK/execution across transient completions. Source, intermediate, listing, symbol, and executable files coexist on an explicit B: drive while commands run from A:.

LINK's documented default-disk temporary-file behavior means a tool may need working directory space even when named inputs/outputs use another drive (**A**). The successful and undefined-symbol runs left no XX*/YY*.$$$ files, while the undefined-symbol run did leave BADOUT.COM/SYM (**I**). BetterCP/M must supply the established file semantics; it need not prescribe a tool's temporary names, cleanup after abnormal termination, or validity of partial outputs.

The batch build regenerated the same 128-byte COM bytes as the interactive build. This independently strengthens entry 0620 but adds no separate batch-build proposition.

## 9. Executable generation findings

ABS48 and MACRO48 loaded as one-record COM files beginning at 0100h. DEV48 linked two REL modules, resolved `MSGOUT` to 0104h, and produced code at 0100h-0116h. BIG48 produced 013Eh bytes at 0100h-023Dh, occupied three 128-byte records, loaded contiguously, executed, and returned (**I**).

This demonstrates composition of already-required record transfer, close persistence, loader placement, application memory, BDOS readiness, and termination behavior. CP/M does not interpret REL, HEX, SYM, PRN, IRL, PUBLIC, EXTRN, library indexes, or compiler runtime records. Those are development-tool file formats and are **NOT REQUIRED** BetterCP/M kernel/BDOS behavior. BetterCP/M must preserve their bytes through ordinary files.

The LINK manual's PL/I-80 example shows that compiler-generated REL modules and runtime libraries can target the same linker and CP/M COM environment (**A**). Without a compiler run, no compiler-specific calling convention or runtime dependency is promoted.

## 10. Undocumented convention analysis

The evidence separates four convention classes:

1. **Documented OS conventions:** 0100h, page zero, CALL 0005h, 0006h, FCB/DMA, records, WBOOT, and COM execution are REQUIRED.
2. **Published toolchain conventions:** HEX/REL/IRL/SYM/PRN, macro syntax, external-symbol resolution, libraries, and linker switches must be implemented by those tools, not by CP/M.
3. **Historically significant ecosystem composition:** standard tools must be able to store and consume those files using public CP/M services; SUBMIT-driven builds depend on entry 0620.
4. **Incidental/vendor behavior:** exact maps, prompts, diagnostics, partial output, temporary names, internal buffers, runtime ABI, and private patches are NOT REQUIRED or NOT GUARANTEED as OS behavior.

No evidence supports a universal compiler ABI, assembler object format, linker algorithm, debugger implementation, or hardware port map.

## 11. Experimental results

`probes/run048.sh` restores fresh images and uses no manually typed input. Detailed purpose, procedure, observation, and conclusion for every case appear in `probes/observed-output.txt`; the complete transcript is `probes/transcripts/toolchain-survey.txt`.

| Test | Principal observation | Conclusion |
|---|---|---|
| ASM/LOAD | 0100h-0111h, one record, ABS48 OK | existing absolute workflow sufficient (REQUIRED) |
| MAC/LOAD | macro expanded; one record; MACRO48 OK | public OS services sufficient; macro format tool-owned |
| RMAC/LINK | two REL modules; MSGOUT resolved; TOOL48 OK | existing file/memory/execution contracts sufficient |
| BIG48 | 013Eh code; three records; BIG48 OK | record-boundary and contiguous-load requirements confirmed |
| Undefined external | ABSENT diagnosed; returned to A>; BADOUT outputs remained | recovery REQUIRED; partial output NOT GUARANTEED |
| DDT | display, breakpoint 0103h, G0 | page zero and writable/executable TPA confirmed |
| SID | independent display/breakpoint/G0 | same public lifecycle confirmed |
| SUBMIT build | ordered rebuild; BATCH48 byte-identical to DEV48 | entry 0620 strengthened |
| Temporary audit | no LINK or SUBMIT $$$ file remained | successful cleanup observed, not a universal OS rule |
| SPEED runtime | compiler-generated COM ran and used profile-specific ports | runtime smoke only; compiler behavior untested |

Three fresh-image runs completed. Runs two and three produced byte-identical after-images. Runs one and two produced identical semantic transcripts after removal of emulator-only shutdown address/timing. No evidence is claimed for an unperformed compiler, librarian, overlay, M80/L80, Z80ASM/SLRNK, or ZSID feature workflow.

## 12. Compatibility conclusions

**REQUIRED:** Preserve the already-ledgered public CP/M environment exercised by development tools: CCP command execution, 0100h COM load, public page-zero gateways/ceiling, BDOS conventions, FCB/DMA/128-byte file operations, coherent multi-record creation/close/reload, writable/executable TPA, logical-error recovery, and strict-profile submitted-command processing.

**NOT GUARANTEED:** Compiler/runtime ABI; private BDOS or debugger targets; exact available tool workspace beyond the configured TPA contract; hardware ports; partial linker outputs; abnormal temporary-file cleanup; padding contents; and behavior of untested tools/options.

**NOT REQUIRED:** Reimplementing ASM, MAC, RMAC, LINK, LOAD, LIB, DDT, SID, compiler libraries, their source algorithms, intermediate formats, diagnostics, symbol maps, temporary names, or modern toolchain abstractions inside BetterCP/M.

**POLICY PENDING:** Which preserved third-party compiler/linker/library families form the release acceptance corpus; which machine-specific compiled programs belong to platform profiles; and whether bundled tool compatibility is a strict-profile or distribution-level claim.

## 13. Proposed ledger additions

None.

The survey found no OS proposition absent from the ledger. "REL linking works" and "a compiler runs" would conflate tool implementation/file formats with the CP/M interface and would not be appropriate ledger propositions. The independently testable underlying requirements already exist.

Future evidence incorporation should use `I048 DEVELOPMENT TOOLCHAIN COMPATIBILITY subsystem IG AG` on existing propositions rather than create umbrella duplicates. The Compatibility Ledger was not modified.

## 14. Existing-entry updates

Recommended evidence-only updates, not applied:

- **0001-0005 and configured-memory entries:** add ASM/MAC/RMAC/LINK/LOAD/DDT/SID evidence for 0100h, WBOOT, 0005h, 0006h, and TPA availability.
- **CCP/load/entry/lifecycle entries:** add explicit-drive tool invocation, generated COM handoff, normal returns, and debugger G0 evidence.
- **BDOS FCB/DMA/sequential/create/close entries:** add HEX/REL/COM/SYM/PRN generation and the three-record BIG48 workflow.
- **ordinary logical-error/recovery entries:** add LINK undefined-symbol recovery while explicitly excluding validation of BADOUT contents.
- **0619:** add debugger/tool corroboration without weakening the private-target NOT GUARANTEED rule.
- **0620:** add BUILD48 as an independent standard batch development workflow.
- **0622:** add DDT/SID breakpoint execution as writable/executable TPA corroboration.

No disposition or wording correction is recommended. The duplicate 0248-0277 block identified by I046 remains a separate ledger-maintenance issue.

## 15. Open questions

1. Which preserved CP/M compiler and runtime package should be acquired for a deterministic compile-link-run study? (**D**)
2. Should LIB/IRL extraction, indexed search, and library ordering receive a focused tool-format investigation, or only an acceptance test? (**D**)
3. Which M80/L80 and Z80ASM/SLRNK workflows are historically important enough to add to conformance without mistaking vendor syntax for OS behavior? (**D**)
4. Should overlay generation/loading be studied as an application/runtime topic rather than an OS requirement? (**D**)
5. Which debugger interactions with BDOS calls, symbols, and self-modifying code merit expanded acceptance coverage? (**D**)
6. How should machine-specific direct-I/O dependencies in compiler-generated software be declared in BetterCP/M platform profiles? (**D**)

Compiler execution and librarian/overlay workflows remain explicitly unperformed. They did not prevent completion of the prompt's required experimental matrix, and no claims replace them.

## 16. Conformance implications

A strict development-tool acceptance suite should restore known media, assemble/load an absolute fixture, expand a macro, generate and link multiple REL modules, resolve an external, create and run a COM spanning several records, recover from an undefined symbol without corrupting the command environment, inspect/break/restart in two debuggers, and repeat the build under SUBMIT. It should compare generated bytes where deterministic and vary drive/memory placement to reject hard-coded reference addresses.

Conformance must assert OS-visible outcomes, not specific REL/HEX syntax, maps, diagnostics, temporary names, or tool algorithms. Compiler, library, overlay, and hardware-specific tests should be separately labelled corpus/profile tests until evidence justifies a baseline requirement.

### Completion audit

- Investigation directory, 16-section report, probes, manuals, rendered pages, sources, software, transcripts, and images: verified present.
- Required deterministic assembly, linking, loading, debugging, file-handling, error, batch, and boundary tests: completed.
- Three fresh-image runs: completed; repeatable semantic transcript and byte-identical second/third after-images verified.
- Direct and submitted linked COM output: byte-identical.
- All recorded artifact hashes: verified.
- Protected pre-existing BetterCP/M files: unchanged.
- Authoritative ledger: unchanged at SHA-256 `f6ccc204328608d8377a1f1652cb8b4309f2e2329a4e347c5625976e45f08dc2`.
- Previous investigations and implementation files: not modified.
- No Compatibility Ledger modification, BetterCP/M implementation, or ZIP archive was created.

