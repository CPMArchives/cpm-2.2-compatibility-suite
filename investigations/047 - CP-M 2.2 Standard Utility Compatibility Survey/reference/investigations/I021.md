# Investigation 021 - CP/M 2.2 CCP Command Acquisition, Parsing, and Dispatch Semantics

Date: 15 August 2026  
Status: Complete with limitations recorded in section 18  
Ledger baseline: `02 Compatibility Ledger - Investigation 020.txt`, SHA-256 `e204f30943280ac181d844e3a48c83dd02d1d9918f5aecbee3b2d494faf5cdea`

## 1. Objective and scope

This investigation defines the common DRI CP/M 2.2 CCP path from prompt and buffered console input through normalization, filename-like parsing, built-in recognition, and the boundary into a built-in routine or transient lookup. It does not specify the complete semantics of DIR/ERA/TYPE/SAVE/REN/USER or the complete transient loader.

## 2. Method and evidence classification

- **A - documentation:** DRI *An Introduction to CP/M Features and Facilities*, CP/M 2.0 Interface Guide, and CP/M 2.2 Alteration Guide.
- **B - implementation:** original DRI CP/M 2.2 `OS2CCP.ASM` and relevant `OS3BDOS.ASM` paths.
- **I - observation:** deterministic z80pack command corpus, transient-entry probe, precedence marker, and invalid-drive run.
- **D - policy:** exact presentation and DRI-specific parser details not clearly promised by documentation.

Documentation, source, and observation are reported separately. Source was used to select cases, not as a substitute for experiment.

## 3. Documentation findings

The Features and Facilities guide says CCP reads/interprets console commands, prompts with the logged drive followed by `>`, initially selects A, and distinguishes built-in commands from transients. It documents built-ins ERA, DIR, REN, SAVE, and TYPE; the examined February 1980 CCP source additionally includes USER.

The guide documents `drive:` switching, ordinary filename rules, lower-to-uppercase processing for file/drive names, and transient invocation by primary name. If no built-in is found, CCP searches for `name.COM`. A drive-prefixed transient such as `B:STAT` is loaded temporarily from that drive, then processing returns to the prior logged drive.

The guide attributes command-line editing to the CCP environment, while Investigations 006/016 and source show the actual line editor is BDOS Function 10 beneath CCP. It says command lines can generally be up to 255 characters; the examined CP/M 2.2 CCP sets its Function-10 maximum byte to 127. That documentary/source discrepancy is not silently resolved.

## 4. DRI CCP source findings

### Entry and command loop

CCP has an entry that may execute a preloaded command and another that clears it. Cold/warm entry selects user/drive from C, calls BDOS Function 13, and selects the drive. Ordinary command/error return resets CCP's private stack, emits CR/LF, current drive letter and `>`, then reads another line. A transient that returns normally is restored to the saved user/drive and re-enters the same prompt loop.

Initialization/reset is not performed before every command. It is performed on CCP start; the ordinary loop queries current drive and preserves command-environment user/drive state.

### Acquisition and normalization

`readcom` calls BDOS Function 10 with a buffer whose maximum byte is 127 and count byte follows it. BDOS supplies editing/CR termination. CCP then traverses exactly the counted characters, translates ASCII `a`-`z` to uppercase in place, writes NUL immediately after them, and resets its scan pointer.

SPACE is the only character skipped by `deblank`. TAB (09h) is below SPACE and therefore reaches generic `comerr`; it is not interchangeable whitespace.

### Filename-like lexical parser

`fillfcb` parses into an internal FCB-like object. It optionally recognizes a drive only when the first input character is followed immediately by colon. It then takes at most eight name and three type characters, expands `*` to remaining `?`, pads with spaces, zeros three following fields, and saves the scan position. Source delimiters are NUL, control bytes, SPACE, `=`, `_`, `.`, `:`, `;`, `<`, and `>`.

Overlong name/type components are truncated internally while the scan advances to a delimiter. Exact internal addresses/registers are not compatibility requirements.

### Built-in recognition

The six source-table names are exactly `DIR`, `ERA`, `TYPE`, `SAVE`, `REN`, `USER`. Comparison uses the first four name bytes and requires the fifth FCB name byte to be blank, so abbreviations and longer prefixes do not match. The type field is not part of built-in recognition. If a command-level drive prefix was recognized, built-in lookup is skipped and the transient path is selected.

### Dispatch boundaries

The first FCB parse occurs before built-in classification. A successful built-in dispatch reparses its own operands. The transient path requires a blank command type, supplies `COM`, opens/loads the file, and only after successful load constructs the two default FCBs and counted tail. Thus the full transient entry environment is not generally built for resident commands.

## 5. Command-loop and prompt findings

Cold start, WBOOT, error recovery, empty input, built-in completion, failed lookup, and normal transient RET all converge on the DRI prompt loop. The prompt semantically identifies current drive and readiness. The guide explicitly documents drive letter plus `>`; exact CR/LF placement, casing, absence of user display, and spacing remain presentation details beyond that semantic content.

DRI does not display the user number in its prompt. USER changes namespace but not prompt text. Whether BetterCP/M offers an enhanced prompt outside strict mode is future design, not decided here.

## 6. Command acquisition findings

CCP uses Function 10 rather than its own editor. The maximum byte is 127 in this source/reference CCP; CR terminates input and is not part of the counted command. CCP uppercases counted letters and appends NUL. The observed 127-X line was accepted and then parsed/reported. The behavior of a 128th graphic byte was not forced because Function-10 editing behavior was already investigated and the manual/source limits conflict.

## 7. Lexical parsing and normalization findings

- CR, one SPACE, and multiple SPACEs are empty commands.
- TAB-only and SPACE/TAB/SPACE are errors, not empty commands.
- Leading and inter-token SPACEs are skipped as required by each parser call.
- All counted lowercase ASCII letters are uppercased before token parsing; typed echo remains as entered.
- The command name uses CP/M's 8.3 FCB parser, but transient invocation requires a blank type because CCP supplies COM itself.
- An explicit type on a non-built-in command is rejected. A built-in may be recognized despite a type because recognition ignores the type field.
- The transient tail begins at the first SPACE or NUL after the command token; it preserves the number of separator spaces after uppercasing.

Punctuation is delimiter-specific, not generic whitespace. Malformed delimiters can yield empty commands, generic errors, or later transient lookup depending on their position.

## 8. Drive-prefix and drive-only findings

`X:` alone is the empty-name form with a selected drive and therefore changes the persistent logged drive. The following prompt changes immediately. Page-zero 0004h is updated by CCP's saved command environment as established in I001/I007.

`X:NAME` is not a built-in invocation. It enters the transient path, temporarily selects X, attempts X:NAME.COM, then resets to the prior drive after execution/failure. The B:DIR marker experiment demonstrated this directly.

An unavailable Q: reached BDOS Select fatal presentation and warm restart; there is no normal CCP error result. Exact fatal text is governed by I015 policy. A colon not immediately following a leading letter is not a valid drive prefix.

## 9. Resident-command recognition and precedence

The DRI CP/M 2.2 set is DIR, ERA, TYPE, SAVE, REN, USER. Recognition is exact after uppercase conversion; DI and DIRX did not match. Resident recognition precedes transient lookup when no command-level drive prefix exists.

Controlled DIR.COM/TYPE.COM/SAVE.COM markers established precedence without changing reference disks. `DIR` and `DIR.COM` selected resident DIR; `TYPE.COM` selected resident TYPE then failed operand validation. MARK21 never ran in those A-drive cases. Conversely `B:DIR` bypassed built-in recognition and executed B:DIR.COM. User-area changes do not alter the recognition table; the built-in still wins before lookup.

## 10. Resident/transient dispatch boundary

At built-in dispatch, the command token has been uppercased and parsed once; operands remain in the internal line and each built-in reparses what it needs. Default transient FCBs/tail are not a required resident-dispatch product.

At transient boundary, CCP has an uppercase primary command name and resolved optional source drive, has rejected a nonblank command type, and is ready to supply COM/open. Detailed search/load behavior is deferred. Only after successful load does it parse two operands, copy default FCB data to 005Ch, and construct the tail at 0080h.

## 11. Generic syntax and error findings

`comerr` emits CR/LF, prints bytes from the offending token until SPACE/NUL, adds `?`, CR/LF, cancels SUBMIT if active, and restarts the loop. Missing transient and many malformed names share this presentation. Observed examples were `DI?`, `DIRX?`, `NOEXIST?`, `FOO.TXT?`, `AA:?`, `FOO:BAR?`, and `FOO;BAR?`.

`:FOO` resulted in an empty command because colon delimited an empty first name without selecting a drive. Exact DRI error echo/punctuation is conventional source behavior; documentation establishes that invalid commands are rejected, not necessarily byte-exact formatting.

## 12. Experimental design

The Expect harness submitted 28 source-chosen command lines, including empty/SPACE/TAB, case, leading/multiple SPACE, drive-only/prefixed, built-in exact/prefix/suffix/type, malformed delimiters, two PARSE21 invocations, and a 127-byte boundary. A separate fresh process tested unavailable Q: and supplied the fatal handler's response deterministically.

Fresh preserved IBM-3740 images received only PARSE21 and harmless MARK21 aliases. Before/fixture/after images and hashes are preserved. Fixture and after hashes match, proving the command matrix made no disk changes after installation.

## 13. Experimental results

Raw transcripts and normalized observations are in `probes/`. Principal results are:

1. SPACE is skippable; TAB is not.
2. ASCII case normalization occurs after echo and before dispatch.
3. Drive-only selection persists; drive-prefixed transient selection is temporary.
4. Built-ins win over same-name COM files without a command drive prefix.
5. Explicit `.COM` does not provide a general escape to transient dispatch.
6. Built-in matching is exact, not abbreviated/prefix-based.
7. Missing/malformed common paths converge on token-plus-question-mark DRI presentation.
8. Transient-entry FCB/tail state reflects uppercase, wildcard, drive, and literal separator processing.

## 14. Relationship to Investigation 001 transient-entry findings

I021 supplies direct source-path explanation and two new controlled entry observations. Proposed updates:

- 0012 second default FCB: stronger evidence only; remain POLICY PENDING because explicit user-interface documentation is still absent.
- 0013 drive-prefix parsing: upgrade to REQUIRED for CCP-created transient default FCB behavior; documented drive-prefixed file references plus source/experiment now align.
- 0014 wildcard expansion: upgrade to REQUIRED; user documentation defines `*` abbreviation and I021 observes resulting wildcard FCB.
- 0015 case/padding: upgrade to REQUIRED for CCP processing; documentation explicitly promises lowercase translation and FCB format requires padding.
- 0016 unopened control fields: stronger evidence only; remain POLICY PENDING for exact DRI initialization beyond fields needed by documented FCB use.
- 0019 leading tail blank: stronger evidence only; remain POLICY PENDING because source/experiment establish DRI behavior but user documentation does not specify transient-tail byte form.
- 0020 uppercase command tail: stronger evidence only; remain POLICY PENDING. Documentation promises lowercase translation for processed file/drive names, while source/experiment show DRI uppercases the entire counted line before tail construction; the broader tail-byte promise is not explicit.
- 0021 NUL after tail: stronger evidence only; remain POLICY PENDING because it is source/experiment-visible but not an application-interface promise.

## 15. Compatibility conclusions

Required baseline includes semantic drive prompt, Function-10 acquisition, case-insensitive ASCII command processing, SPACE handling distinct from TAB, drive-only and temporary drive-prefixed transient forms, the six DRI 2.2 built-in names, exact recognition/precedence, primary-name transient syntax with implicit COM, and normal return to the prompt loop.

Exact CCP addresses, buffers, table layout, register allocation, echo punctuation, call count/order, stale bytes, and z80pack terminal behavior are not required. Exact error/prompt presentation beyond documented semantics remains policy-sensitive.

## 16. Proposed Compatibility Ledger additions (not applied)

### 0475. CCP semantic prompt

The command environment prompts with the currently logged drive letter followed by `>` to identify the drive and readiness for another command.

Disposition: REQUIRED  
Evidence: I021; DRI Features and Facilities section 2; CCP; experiment.  
Conformance: Switch drives and verify the semantic prompt changes accordingly.

### 0476. CCP prompt presentation freedom

Exact preceding CR/LF, spacing, and additional user/session decoration are not baseline requirements beyond preserving the documented drive/readiness information in strict compatibility presentation.

Disposition: POLICY PENDING  
Evidence: I021; documentation silence beyond drive-plus-`>`; DRI observation.  
Conformance: Separate semantic prompt tests from byte-exact presentation policy.

### 0477. CCP buffered command acquisition

The DRI CCP acquires an edited command line through BDOS Function 10, acts after CR, excludes CR from the counted command, and processes no command before termination.

Disposition: REQUIRED  
Evidence: I021; Features and Facilities section 5; CCP; I006; experiment.  
Conformance: Queue edited input and verify dispatch occurs only after CR.

### 0478. DRI CCP command capacity

The examined CP/M 2.2 CCP supplies 127 as its Function-10 maximum; documentation elsewhere says command lines can generally reach 255, so the strict portable capacity needs policy resolution.

Disposition: POLICY PENDING  
Evidence: I021; CCP; Features and Facilities section 5; 127-byte experiment.  
Conformance: Distinguish the DRI 2.2 reference limit from broader documented wording.

### 0479. CCP empty and SPACE-only commands

An empty command or a command containing only one or more SPACEs performs no command, reports no error, and returns to the prompt loop.

Disposition: REQUIRED  
Evidence: I021; CCP; deterministic corpus.  
Conformance: Test CR, one SPACE, and multiple SPACEs independently.

### 0480. TAB is not CCP SPACE

The DRI CP/M 2.2 common parser does not treat TAB as skippable SPACE; TAB in command-token position reaches generic error handling.

Disposition: POLICY PENDING  
Evidence: I021; CCP delimiter/deblank; deterministic TAB cases.  
Conformance: Submit SPACE and TAB cases as distinct bytes.

### 0481. CCP ASCII case normalization

The CCP processes ASCII `a`-`z` as uppercase throughout the counted command before token classification; console echo may retain the typed case.

Disposition: REQUIRED  
Evidence: I021; Features and Facilities section 2.2; CCP; PARSE21/case experiments.  
Conformance: Compare lower/mixed-case dispatch and transient-entry bytes.

### 0482. CCP built-in command set

DRI CP/M 2.2 recognizes exactly DIR, ERA, TYPE, SAVE, REN, and USER as built-in CCP command names.

Disposition: REQUIRED  
Evidence: I021; CCP February 1980 table; DRI command documentation; precedence experiment.  
Conformance: Test each exact name without exercising full command semantics.

### 0483. Exact built-in-name matching

Built-in recognition follows case normalization and requires the exact command name; abbreviations and longer names sharing a prefix are not built-ins.

Disposition: REQUIRED  
Evidence: I021; CCP; DI/DIRX experiment.  
Conformance: Compare exact, prefix, and suffix names.

### 0484. Built-in precedence

Without a command-level drive prefix, a recognized built-in takes precedence over a same-basename COM file; an explicit type does not reliably force transient execution.

Disposition: REQUIRED  
Evidence: I021; CCP; DIR.COM/TYPE.COM MARK21 experiments.  
Conformance: Install harmless colliding COM files and verify markers do not execute.

### 0485. Drive-only CCP selection

`X:` with no command persistently selects X as the logged drive and changes subsequent prompt/current-drive state.

Disposition: REQUIRED  
Evidence: I021; Features and Facilities section 3; CCP; A:/B: experiment.  
Conformance: Issue drive-only commands and query prompt/BDOS drive afterward.

### 0486. Drive-prefixed transient dispatch

`X:NAME` bypasses built-in recognition, temporarily seeks NAME.COM on X, and restores the prior logged drive after success or ordinary failure.

Disposition: REQUIRED  
Evidence: I021; Features and Facilities section 6; CCP; B:DIR/B:NOEXIST experiments.  
Conformance: Use colliding and missing transient names on another drive and inspect the following prompt.

### 0487. Primary-name transient command syntax

The normal transient command token is a primary filename with blank type; CCP supplies COM internally. A nonblank explicit type on a non-built-in command is rejected before detailed loading.

Disposition: REQUIRED  
Evidence: I021; Features and Facilities sections 6/6.3; CCP; FOO.TXT experiment.  
Conformance: Compare NAME and NAME.COM/NAME.TXT for a controlled transient.

### 0488. CCP resident/transient preparation boundary

CCP parses the command token before classification; built-ins reparse operands, while the two default FCBs and command tail are constructed only after a transient has loaded successfully.

Disposition: REQUIRED  
Evidence: I021; CCP; PARSE21; I001.  
Conformance: Instrument both dispatch branches and test only externally visible prepared state.

### 0489. Generic command-error recovery

A malformed common-parser command or missing transient returns to the command loop without changing the persistent logged drive on an ordinary failure path.

Disposition: REQUIRED  
Evidence: I021; CCP; deterministic malformed/missing corpus.  
Conformance: Record drive before failure and the following prompt/query.

### 0490. Exact DRI command-error presentation

DRI prints the offending token followed by `?` with its particular CR/LF placement, but exact byte-for-byte presentation is not established as a universal CP/M 2.2 requirement.

Disposition: POLICY PENDING  
Evidence: I021; CCP comerr; deterministic corpus; documentation silence.  
Conformance: Preserve strict-presentation tests separately from semantic rejection/recovery.

### 0491. CCP parser implementation freedom

Exact CCP memory addresses, internal FCB/buffer placement, registers, comparison order, call graph, and stale bytes are not required when externally observable parsing and dispatch conform.

Disposition: NOT REQUIRED  
Evidence: I021; CCP source analysis; component-boundary scope.  
Conformance: Test public input/output and transient-entry results rather than private layout.

## 17. Proposed corrections/evidence/disposition updates to existing entries

Apply no changes automatically. Proposed future ledger-maintainer actions:

- 0013: change POLICY PENDING to REQUIRED; add I021, Features and Facilities section 2.2, CCP, PARSE21.
- 0014: change POLICY PENDING to REQUIRED; add I021, documented `*` abbreviation, CCP, PARSE21.
- 0015: change POLICY PENDING to REQUIRED; add I021, documented lowercase translation/FCB form, CCP, PARSE21.
- 0012, 0016, 0019, 0020, 0021: retain POLICY PENDING; add I021 as stronger DRI-source/experimental evidence only.

## 18. Incomplete and unresolved cases

1. The 127-versus-255 command-capacity conflict remains POLICY PENDING; no source-only reconciliation is invented.
2. Byte-exact prompt and `token?` presentation remain policy questions.
3. SUBMIT acquisition is visible in source but was not exercised; detailed SUBMIT semantics belong later.
4. Each built-in's operand grammar and results are intentionally deferred.
5. Detailed COM search/load/overflow behavior is intentionally deferred after the dispatch boundary.
6. A 128th graphic input byte was not forced because it would re-test Function-10 editing rather than common CCP classification.

## 19. Artifact and preservation audit

- Report, probes, listings, COM binaries, harnesses, exact corpus, raw transcripts, normalized results, base/fixture/after images, directory listings, emulator identity, and hashes are present.
- PARSE21.COM and MARK21.COM rebuilt byte-identically.
- Fixture and after image hashes match for A and B; experiments made no post-install disk change.
- Ledger 020 hash is unchanged at `e204f30943280ac181d844e3a48c83dd02d1d9918f5aecbee3b2d494faf5cdea`.
- No previous investigation, architecture, roadmap, source archive, ledger, or other BetterCP/M file was modified. No ZIP was created.

## 20. Sources

- Digital Research, *An Introduction to CP/M Features and Facilities*, sections 2, 2.1, 2.2, 3, 5, 6, and 6.3.
- Digital Research, *CP/M 2.0 Interface Guide*, Function 10 and transient interface.
- Digital Research, *CP/M 2.2 Alteration Guide*, CCP/BDOS/boot context.
- DRI CP/M 2.2 `OS2CCP.ASM` (February 1980) and `OS3BDOS.ASM`.
- BetterCP/M Investigations 001, 006, 007, 008, 016, 018, 020 and Ledger 020.
- Preserved Investigation 021 experimental artifacts.
