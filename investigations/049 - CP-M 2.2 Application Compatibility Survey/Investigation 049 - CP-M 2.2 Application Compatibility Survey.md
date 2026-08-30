# Investigation 049 - CP/M 2.2 Application Compatibility Survey

## 1. Objective and scope

This investigation asks whether ordinary CP/M 2.2 application software exposes compatibility requirements absent from the ledger through Investigation 048. It covers application startup, console and terminal use, file persistence, capacity failure, multi-file runtime behavior, and normal termination. It does not implement BetterCP/M, modify the ledger, or treat an application's private format or presentation as an operating-system contract.

The principal result is conservative. MicroPro WordStar 3.00, Microsoft BASIC-80 running Wumpus, and Adventure A02 all operated through the already established CP/M surface. WordStar's full-disk path reinforced the requirement that logical storage failure be visible to the caller, but its `E12` wording and recovery UI are application behavior. No new independently testable OS proposition was established.

Spreadsheet, database, communications, and packaged business-application executables were not adequately available in the local evidence corpus. Those categories remain incomplete; no behavior is inferred from filenames, reputation, or source reconstruction.

## 2. Compatibility standard

Evidence is separated as follows: **A** is documented CP/M interface behavior; **B** is DRI implementation behavior; **I** is controlled observation of preserved software; **D** is an unresolved BetterCP/M policy choice. A repeated use of a documented interface strengthens it. A vendor diagnostic, private file format, terminal sequence, or isolated byte pattern does not become an OS requirement merely because an application exhibits it.

Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Any future ledger evidence update from this report must use exactly `I049 APPLICATION ECOSYSTEM COMPATIBILITY subsystem IG AG`.

## 3. Relationship to previous investigations

Investigation 041 separated public gateways from literal BDOS/BIOS targets and fixed resident addresses. Investigation 042 screened common software and left databases, communications, games, and full-screen terminal behavior open. Investigation 047 exercised standard utilities. Investigation 048 exercised development toolchains. Investigation 049 adds full WordStar edit/save behavior, an interpreter-hosted game, a larger multi-file game, and an application-visible disk-capacity failure.

The current ledger already covers 0100h COM loading, page-zero gateways and memory ceiling, CCP command preparation, console calls, FCB/DMA file operations, 128-byte records, drive and user state, write/allocation failures, and WBOOT/normal termination. I049 tests whether applications require more than those propositions; within the executed corpus they do not.

## 4. Application category coverage

| Category | Representative evidence | Coverage and result |
|---|---|---|
| Word processor | MicroPro WordStar 3.00 | Startup, full-screen terminal output, document creation, save, CCP DIR/TYPE verification, and full-disk save failure performed (**I**). |
| Spreadsheet | None adequate locally | Not executed; no spreadsheet-specific claim (**D**). |
| Database | None adequate locally | Not executed; no database-specific claim (**D**). |
| Communications | None adequate locally | Not executed; no serial/modem-specific claim (**D**). |
| Business application | None adequate locally | Not executed; no business-package-specific claim (**D**). |
| Games | Wumpus under Microsoft BASIC-80; Adventure A02 | Interpreter and native multi-file application startup, deterministic input, and clean return performed (**I**). |
| Other historically significant | Microsoft BASIC-80 runtime | Command-tail program selection, source loading, console interruption, and `SYSTEM` return performed (**I**). |

The untested categories are real gaps in acceptance-corpus coverage, not evidence of missing CP/M semantics.

## 5. Documentation findings

The CP/M interface documentation (**A**, as reviewed in I001-I048) defines application-visible mechanisms rather than application categories: transient loading at 0100h; page-zero WBOOT/BDOS gateways and entry objects; console and character-device calls; FCB/DMA file operations; 128-byte logical records; drive/user state; and documented function results. It does not promise WordStar screen layouts, BASIC runtime behavior, Adventure data formats, a universal terminal escape language, modem registers, printer formatting, or vendor error text.

Documentation therefore supports the distinction seen experimentally: the OS must supply the documented service result, while the application decides how to present it. The Interface and Alteration Guides leave the acceptance set of third-party products, terminal profiles, and machine-specific direct-I/O programs unspecified.

## 6. Source findings

DRI source conclusions inherited from I041/I042/I047/I048 (**B**) supplied test targets but no new private interface: public calls pass through 0005h; CCP prepares the transient environment; BDOS mediates ordinary file and console work; direct BIOS/device access has profile-specific consequences.

Preserved third-party artifacts were screened as ecosystem evidence (**I**), not DRI evidence. `WS.COM`, `MBASIC.COM`, and `AD.COM` each contain literal `CALL 0005h` byte patterns; they also contain `JP 0000h` and/or 0006h memory-ceiling patterns. No screened file contains literal `JP 0005h`. The exact offsets are in `probes/source-analysis.txt`. As in I042, a literal match may be embedded data and is only a lead. Successful execution through CP/M corroborates public-interface use but does not prove every match is executed.

WUMP.BAS uses BASIC console statements and runtime-managed execution; it contains no direct CP/M implementation address. Adventure's preserved distribution separates a 39,680-byte COM transient from a 63,616-byte message file and multiple data files. These are evidence of multi-file use and adequate transient space, not public application file formats.

## 7. System interface usage

All three tested applications were found and loaded by the CCP on a non-system drive, ran in the configured 56K CP/M 2.2 environment, and returned to that drive's prompt. WordStar and Adventure exercised sizeable transient/runtime images; BASIC loaded a source program and maintained an interactive interpreter environment.

The observed paths reinforce the **REQUIRED** COM/CCP entry environment, public 0005h BDOS gateway, documented console calls, file services, current-drive behavior, memory ceiling, and termination paths. Nothing observed requires a literal BDOS target, fixed CCP/BDOS/BIOS base, private resident layout, or direct controller access; those remain **NOT GUARANTEED** under the existing ledger.

No direct BIOS call, direct device port, or raw disk access was proved by these runs. Absence of proof in three programs is not a guarantee that other historical applications avoid such access.

## 8. Storage assumptions

WordStar created `APP49.TXT`, wrote two known lines, closed it, and returned to CP/M. `DIR` found the file and `TYPE` reproduced the text. The extracted 128-byte record contained CR/LF between lines and 1Ah padding. The record padding is compatible application/file content; it does not require BDOS to synthesize a vendor's EOF convention beyond the existing record-transfer contract.

On the unmodified nearly full distribution disk, WordStar began its save and displayed `ERROR E12: DISK FULL`. The after-image differed, so the test does not claim atomicity, rollback, or a valid partial file. The **REQUIRED** compatibility surface is the established logical write/allocation result and coherent subsequent documented operations. Exact allocation choices, directory slot, partial-write layout, application diagnostic, and recovery UI are **NOT REQUIRED** or **NOT GUARANTEED** as already classified.

Adventure opened a large message file and several data files from the same user/drive and completed a no-save session without changing its disk. Wumpus likewise left its disk unchanged. These observations reinforce ordinary filename lookup, multi-file reads, current-drive/user visibility, and normal close/termination behavior; they do not establish file locking, databases, backup protocols, or crash recovery.

## 9. User interface assumptions

WordStar emitted cursor-addressed control sequences and presented a terminal-specific full-screen interface. BetterCP/M's generic CP/M contract must transport the configured console bytes and provide the documented console/BIOS device semantics. It need not translate every historical terminal language or reproduce WordStar's screen. Which terminal emulations are advertised is a machine/distribution profile decision (**POLICY PENDING**), and behavior outside an advertised profile is **NOT GUARANTEED**.

Wumpus and Adventure used line-oriented console input and output. Control-C interrupted BASIC at a program line and returned to BASIC's prompt; `SYSTEM` returned to CP/M. This is evidence for the tested Microsoft runtime layered over the configured console, not a general requirement that BDOS independently provide BASIC's `Break in 680` presentation.

Printer, list-device output, modem/reader/punch paths, function-key mappings, and non-ASCII display attributes were not exercised. WordStar's banner identified a CP/M list-output driver, but identification is not a device-operation test.

## 10. Undocumented convention analysis

1. **Public, repeated convention:** loading at 0100h, CALL 0005h, 0006h memory sizing, page-zero restart, command processing, FCB/DMA storage, console I/O, and return to CCP are already **REQUIRED**; I049 strengthens their ecosystem evidence.
2. **Application convention:** WordStar document bytes, 1Ah padding, overlay/message filenames, command keys, `E12`, and Adventure's message/database division are **NOT REQUIRED** OS behavior.
3. **Profile convention:** cursor-addressing sequences, printer selection, modem ports, memory-mapped video, and machine-specific direct I/O are **NOT GUARANTEED** unless a declared machine/terminal/device profile promises them.
4. **Screening leads:** literal vector/address byte patterns are not requirements without control-flow or execution corroboration.
5. **No ecosystem-wide inference:** three executed products cannot settle spreadsheet, database, communications, or business-application dependencies. Those acceptance choices remain **POLICY PENDING**.

No repeated undocumented behavior in the executed matrix justified a new de facto baseline requirement.

## 11. Experimental results

All runs used disposable copies and scripted input; no manually typed application input is part of the preserved result.

| Test | Matrix class | Purpose and procedure | Observed behavior | Compatibility conclusion |
|---|---|---|---|---|
| T01 WordStar startup | Normal/device | Boot, select B:, execute WS | Release 3.00 menu and cursor controls displayed | Existing transient/console contracts sufficient; exact terminal stream profile-specific |
| T02 WordStar save | Normal/file | Create APP49.TXT, type two lines, ^KX, DIR, TYPE | File persisted; known lines returned; repeated after-image hash identical | Existing create/write/close/search/read contracts sufficient |
| T03 WordStar full disk | Boundary/failure | Restore full disk; create and save FULL49.TXT | Visible `ERROR E12: DISK FULL`; image changed | Logical failure visibility REQUIRED; diagnostic and partial state not OS requirements |
| T04 Wumpus | Normal/unusual runtime | `MBASIC WUMP`, decline help, reach move prompt, ^C, SYSTEM | Interactive state printed; BASIC break; B> restored; disk unchanged | Console/runtime/termination contracts sufficient |
| T05 Adventure | Boundary-sized/normal | Run 39,680-byte AD.COM with 63,616-byte message and data files; seed 123; quit | Initial location printed; clean STOP and B>; disk unchanged | TPA, multi-file read, console, termination contracts sufficient |
| T06 vector screen | Unusual/static | Scan three COM files for exact CP/M instruction patterns | CALL 0005h in all; public restart/ceiling leads; no JP 0005h | Corroborative lead only; no private target requirement |

Raw console streams, after-images, extracted text, hashes, and procedures are preserved under `probes/`. Incomplete cases are explicit in sections 4, 9, and 15.

## 12. Compatibility conclusions

**REQUIRED:** The public application surface already represented in the ledger: COM lookup/loading and entry environment; page-zero WBOOT and BDOS gateways; configured memory ceiling; documented console behavior; current drive/user semantics; FCB/DMA file operations and 128-byte records; documented logical failure results; and valid application termination/recovery paths. I049 strengthens this evidence but does not duplicate the propositions.

**NOT GUARANTEED:** Literal resident addresses or private targets; unadvertised terminal sequences and physical devices; exact allocation, directory placement, residual bytes, or partial image after failure; behavior of untested application categories; and unperformed printer/modem/raw-device paths.

**NOT REQUIRED:** WordStar's exact screen, commands, document encoding, filenames, `E12` diagnostic, and partial-save policy; BASIC's banner, random/game state, and break wording; Adventure's private data/message format, text, score, and seed prompt; emulator timing and banners.

**POLICY PENDING:** The third-party release-acceptance corpus; advertised terminal/printer/communications profiles; and whether specific applications or machine-bound software are distribution claims rather than strict baseline claims.

## 13. Proposed ledger additions

None. Every supported operating-system proposition is already independently represented. Adding application-named duplicates would weaken the ledger's one-proposition rule. The evidence is better applied as strengthening updates using `I049 APPLICATION ECOSYSTEM COMPATIBILITY subsystem IG AG`.

## 14. Existing-entry updates

No ledger file was modified. At the next authorized ledger-integration step, consider adding `I049 APPLICATION ECOSYSTEM COMPATIBILITY subsystem IG AG` to:

- **0001, 0008, 0011-0017, 0023-0024:** third-party COM entry, public gateway, default entry objects, and DMA/command environment corroboration.
- **0059-0060 and the established console-input entries:** WordStar, BASIC, and Adventure console-path corroboration without requiring vendor presentation.
- **0220, 0250-0281 and related sequential-read/write/Make/Close entries:** WordStar create/save and Adventure multi-file-read corroboration.
- **0246-0249, 0269-0273, 0512-0517, and related logical-failure boundaries:** WordStar full-disk presentation as application consumption of an existing failure result; retain all post-failure NOT GUARANTEED limits.
- **0486-0502, 0534, 0591, 0619, and 0622:** non-system-drive lookup/loading, transient handoff, application ownership, public-versus-private gateway boundary, and writable executable TPA evidence.

Exact entry selection should be verified against the then-current authoritative ledger; no disposition change is proposed.

## 15. Open questions

1. Which rights-cleared spreadsheet, database, communications, and business packages form the reproducible acceptance corpus? (**D**)
2. Which terminal profiles should BetterCP/M advertise, and should a WordStar-configured terminal run be a strict-profile acceptance test? (**D**)
3. Which printer, reader/punch, modem, or direct-port applications belong to machine profiles rather than the generic CP/M contract? (**D**)
4. Do representative databases expose locking, damaged-index recovery, unusual extent, or multi-user assumptions beyond the existing ledger? No database experiment was performed. (**D**)
5. Should future application testing vary TPA size, disk geometry/capacity, user area, read-only state, and injected physical errors for each accepted product? (**D**)
6. WordStar print output, Adventure save/recovery, corrupted private data, and alternate terminal configurations remain unperformed; no claim is made for them.

## 16. Conformance implications

A BetterCP/M application-acceptance suite should restore known disks, run application-level workflows with scripted console input, verify externally visible files and return paths, and compare hashes. It should test at least one full-screen terminal application, one interpreter/runtime workload, one large multi-file application, and one controlled logical-storage failure. Product diagnostics and private formats should be checked only when the product/profile claims them, not promoted into the baseline OS ABI.

### Completion audit

- Investigation directory and report: staged and verified.
- Preserved harnesses, raw transcripts, extracted files, before/after disk fixtures, source screen, inventories, and hashes: present.
- WordStar success repeat: byte-identical after-image on two independent restored runs.
- Wumpus and Adventure no-save tests: application disks byte-identical before/after.
- Incomplete categories and unperformed paths: explicitly identified; no evidence claimed from them.
- Authoritative ledger before hash: `a1119d87b2a2723cec18cb983aeda3987381bca5cd6f67ac4e3d15397e380301`.
- Ledger modification: none; final hash verified separately in `probes/ledger-sha256-after.txt`.
- Existing BetterCP/M files outside the new I049 directory: protected by before/after inventory audit.
- ZIP archive: none created.

Artifact-level SHA-256 values are recorded in `SHA256SUMS.txt`; source-input hashes and absolute provenance are recorded under `hashes/`.
