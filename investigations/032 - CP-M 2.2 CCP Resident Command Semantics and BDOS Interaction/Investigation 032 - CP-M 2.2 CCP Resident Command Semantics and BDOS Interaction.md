# Investigation 032 - CP/M 2.2 CCP Resident Command Semantics and BDOS Interaction

Date: 17 August 2026  
Status: complete evidence report; no Compatibility Ledger, earlier report, or BetterCP/M implementation modified

Evidence classes: A documented; B DRI implementation; I controlled observation; D unresolved policy.

## 1. Objective and scope

This investigation defines the user-visible CP/M 2.2 DRI CCP contract for resident DIR, ERA, REN, SAVE, TYPE, and USER: recognition, operands, BDOS use, state, output, and recovery. Transient equivalents, CCP layout, CP/M 3, and new command design are excluded.

## 2. Relationship to previous investigations

I021 establishes acquisition/parsing/resident precedence; I022-I024 transient lookup, entry, and lifecycle; I026 BDOS state; I029 search/DMA; I031 user namespaces. I032 exercises the complete resident implementations and relates their presentation to those established BDOS contracts.

## 3. Documentation findings

DRI Features and Facilities documents CCP as command interpreter and identifies ERA, DIR, REN, SAVE, and TYPE as built-ins; the February 1980 CP/M 2.2 CCP also contains USER. Documented filename, drive, wildcard, and case rules feed these commands. Function-level manuals establish the Search/Delete/Rename/Make/Write/Open/Read/User services beneath them. Documentation does not standardize every column, blank, diagnostic phrase, or private sequence of BDOS calls.

## 4. CCP source findings

`OS2CCP.ASM` contains a six-name table `DIR `, `ERA `, `TYPE`, `SAVE`, `REN `, `USER`. Recognition compares the four-character primary name after uppercase parsing and ignores the FCB type; it occurs before ordinary transient lookup. Each handler reparses operands, constructs `comfcb`, optionally selects a drive, invokes BDOS wrappers, presents results, resets DMA where needed, and returns through the common CCP loop. Exact table storage, buffers, counters, and routine order are NOT REQUIRED.

## 5. Resident command dispatch

Unprefixed exact resident names take precedence over same-name COM files. Both `DIR` and `DIR.COM` ran resident DIR and never emitted the marker COM's text. I021 established exact-name recognition and that a command-level drive prefix bypasses resident dispatch and enters transient lookup. Unknown `BOGUS` printed `BOGUS?` and returned a usable prompt.

## 6. Command parsing behavior

CCP uppercases command input and reparses command-specific operands. DIR accepts blank or an FCB pattern. TYPE and SAVE reject ambiguous names. REN uses `new=old` (DRI also accepts left arrow) with compatible drive selection. USER parses a decimal number but DRI limits it to 0-15. Invalid tokens use common offending-token-plus-`?` recovery; extra garbage is rejected at common command completion.

## 7. DIR command behavior

Blank DIR replaces name/type with eleven `?` characters; an operand supplies its pattern. CCP performs Search First/Next on current user and selected/default drive, skips system-attributed files, masks attribute bits, and prints four names per line with `A:` at each line start and colon separators. `DIR *.TXT` listed controlled matches; no match printed `NO FILE`. Directory order is BDOS order, not alphabetic. Exact columns and wrapping are DRI presentation, while recognizable names, filtering, and no-match indication are compatibility relevant.

## 8. ERA command behavior

ERA constructs a possibly wildcard FCB and calls Delete. Exact and partial-wildcard successes were silent; missing files printed `NO FILE`. Only the all-wildcard form (`*.*`, eleven question marks internally) prompted `ALL (Y/N)?`; only exactly one `Y` accepted the destructive operation. The controlled N response cancelled it. A read-only-attributed test entry was deleted silently on the reference system, so the attribute is not a portable ERA protection guarantee. Operations remain current-user/selected-drive scoped.

## 9. REN command behavior

DRI syntax is `REN new=old`. CCP first requires a nonambiguous new name, rejects an existing destination with `FILE EXISTS`, parses the separator and source, rejects drive conflict/ambiguity, searches the source, and invokes BDOS Rename. Valid rename was silent; absent source printed `NO FILE`. Rename is current-user scoped and preserves directory user number.

## 10. SAVE command behavior

`SAVE n file` parses an 8-bit decimal page count, requires an unambiguous filename, deletes an existing target, Makes a replacement, converts pages to twice as many 128-byte records, and writes from 0100h upward before Close. `SAVE 1 SAVED.COM` produced 256 bytes. Invalid `X` printed `X?`; allocation-full D printed `NO SPACE`. SAVE restores default DMA before returning. Because it deletes first, failure can lose a preexisting destination; transactional replacement is not promised.

## 11. TYPE command behavior

TYPE requires an unambiguous existing file, Opens it, reads sequential 128-byte records, and sends each byte to console until 1Ah or physical EOF, checking for console break. Controlled text printed as stored; empty output was silent; tab/BEL were passed through; bytes after 1Ah were suppressed. Missing file printed `MISSING.TXT?`. TYPE is not encoding-aware, line-ending-normalizing, or binary-safe presentation.

## 12. USER command behavior

DRI USER accepts decimal 0-15 and calls BDOS Function 32. USER 1 and USER 0 immediately changed subsequent DIR/TYPE namespace results; USER 16 printed `16?` and recovered. The prompt did not display user number. BDOS supports 0-31 modulo 32, but that wider range is not exposed by this CCP command.

## 13. BDOS interaction

DIR exposes Functions 17/18 and DMA directory entries; ERA Function 19; REN Function 23 plus searches; SAVE Delete/Make/Write/Close/Set DMA; TYPE Open/Read Sequential; USER Function 32. Resident commands consume BDOS results and translate them to CCP presentation. They do not construct a transient entry environment. Drive selection is temporary where command syntax specifies another drive; current user scopes ordinary file services.

## 14. Error behavior

Malformed tokens and unknown commands return to the prompt with token-plus-`?`. Semantic file errors use `NO FILE`, `FILE EXISTS`, or `NO SPACE`. Successful mutating commands are generally silent. Invalid Q: selection entered `Bdos Err On Q: Select` and did not return normally before Control-C. Disk-fatal behavior is distinct from ordinary resident-command errors. Exact spelling/capitalization is DRI-observed presentation unless separately promoted by policy.

## 15. Output behavior

Compatibility requires sufficient output to identify directory results, file content, confirmation, and failure class. DRI's exact DIR four-column spacing, colon placement, CR/LF choices, command echo, BEL/control effects, and diagnostic wording are application-visible observations but are not all documented requirements. Screen-scraping dependencies remain a policy/corpus question.

## 16. Experimental results

The deterministic fixture used a cleared bootable A:, controlled user-0/user-1 files, marker COMs under all resident names, wildcard/rename/delete targets, a read-only-attributed entry, and allocation-full D:. Automated Expect harnesses supplied every command and the deliberate fatal-handler Control-C.

| Test | Principal accepted result |
|---|---|
| DISK32 | Four-column DIR, wildcard filtering, `NO FILE`, current-user scope, resident precedence. |
| ERA32 | Exact/partial wildcard delete; special `*.*` confirmation; missing and attribute case. |
| REN32 | Silent success, `FILE EXISTS`, `NO FILE`. |
| SAVE32 | One page became 256 bytes; bad number `X?`; full disk `NO SPACE`. |
| TYPE32 | Text/control pass-through until 1Ah/EOF; empty and missing cases. |
| USER32 | USER 0/1 changed BDOS namespace; 16 rejected. |
| PARSE32 | Resident conflict won; unknown/malformed recovery; fatal invalid drive separated. |

The first development fixture was rejected because its inherited directory was full; a later unsafe binary fixture was also rejected. Both were corrected and overwritten before the accepted transcripts.

## 17. Compatibility conclusions

REQUIRED: six resident names and precedence; exact primary-name recognition after case normalization; each command's operand grammar and semantic operation; DIR current-user/wildcard behavior; ERA all-files confirmation; REN new=old behavior; SAVE page/record mapping and replacement lifecycle; TYPE byte stream through 1Ah/EOF; USER 0-15 shared BDOS state; usable CCP recovery after ordinary errors.

NOT GUARANTEED: alphabetic DIR order; read-only attribute preventing ERA; transactional SAVE replacement; TYPE sanitization; USER 16-31 through CCP; normal return from disk-fatal errors; exact output layout/wording unless policy adopts it.

NOT REQUIRED: CCP private buffers/table layout, exact BDOS call sequence, four-column implementation algorithm, or transient-style FCB/tail preparation for resident commands.

POLICY PENDING: strict-mode fidelity for exact messages/layout and whether command-output consumers constitute an application compatibility surface.

## 18. Proposed Compatibility Ledger additions

The authoritative I031 ledger ends at 0568.

0569. Resident command semantic set

    DRI CP/M 2.2 CCP provides resident DIR, ERA, TYPE, SAVE, REN, and USER commands with precedence over same-name unprefixed transient files.

    Disposition: REQUIRED

    Evidence: I032; CCP; IG; I021.

    Conformance: install marker COMs and invoke each unprefixed resident name.

0570. DIR search and visibility

    DIR lists non-system matches from ordinary current-user BDOS search on the selected/default drive; blank DIR is equivalent to an all-name/type wildcard.

    Disposition: REQUIRED

    Evidence: I032; CCP; BDOS; IG; I029; I031.

    Conformance: test blank, exact, wildcard, system-attributed, user, and drive cases.

0571. DIR ordering and exact layout

    DIR follows BDOS directory order; alphabetical order and DRI's exact four-column spacing/wrapping are not generally guaranteed.

    Disposition: NOT GUARANTEED

    Evidence: I032; CCP; IG; I029.

    Conformance: validate names/visibility without sorting or pixel-exact layout requirements.

0572. ERA wildcard confirmation boundary

    ERA deletes exact/partial-wildcard current-user matches without confirmation, but its complete `*.*` erase requires the `ALL (Y/N)?` decision and proceeds only for Y.

    Disposition: REQUIRED

    Evidence: I032; CCP; BDOS; IG; I012; I031.

    Conformance: test exact, partial wildcard, all wildcard with N/Y, and other-user preservation.

0573. ERA read-only attribute is not protection

    Applications may not rely on the CP/M directory read-only attribute alone to prevent resident ERA from deleting a matching entry.

    Disposition: NOT GUARANTEED

    Evidence: I032; CCP; BDOS; IG.

    Conformance: attempt ERA on a controlled read-only-attributed entry.

0574. REN resident syntax and validation

    REN accepts an unambiguous `new=old` pair on one selected drive, rejects an existing destination or absent source, and preserves current user identity.

    Disposition: REQUIRED

    Evidence: I032; CCP; BDOS; IG; I012; I031.

    Conformance: test success, collision, missing source, drive conflict, and duplicate other-user names.

0575. SAVE page mapping

    `SAVE n file` writes `n` 256-byte pages beginning at 0100h as `2*n` sequential 128-byte records and successfully Closes the result.

    Disposition: REQUIRED

    Evidence: I032; CCP; BDOS; IG; I011; I030.

    Conformance: SAVE known memory pages and verify exact file length/content.

0576. SAVE destructive replacement

    DRI SAVE deletes an existing destination before Make/write; failure does not guarantee preservation of the prior file.

    Disposition: NOT GUARANTEED

    Evidence: I032; CCP; BDOS; IG; I030.

    Conformance: exercise replacement with controlled allocation failure.

0577. TYPE byte-stream contract

    TYPE sequentially emits stored bytes to console until 1Ah or physical EOF and does not promise character-set conversion or control-byte sanitization.

    Disposition: REQUIRED

    Evidence: I032; CCP; BDOS; IG; I010.

    Conformance: test text, empty, embedded controls, 1Ah, multirecord, and missing files.

0578. CCP USER accepted range

    Resident USER accepts decimal 0-15, changes shared BDOS current-user state, and affects subsequent commands/transients; higher BDOS user codes are not accepted by DRI CCP USER.

    Disposition: REQUIRED

    Evidence: I032; CCP; BDOS; IG; I026; I031.

    Conformance: test 0, 1, 15, 16 and a following transient Function-32 query.

0579. Ordinary resident-command recovery

    Unknown commands, malformed operands, and ordinary file-operation failures recover to a usable CCP prompt without transient execution.

    Disposition: REQUIRED

    Evidence: I032; CCP; BDOS; IG; I021; I025.

    Conformance: test token errors, missing files, collision, invalid count, and no-space cases.

0580. Exact resident output presentation

    Whether BetterCP/M strict mode guarantees DRI's exact DIR layout and diagnostic strings beyond their semantic content remains undecided.

    Disposition: POLICY PENDING

    Evidence: I032; CCP; IG.

    Conformance: corpus-test utilities/scripts that may parse CCP output before deciding.

## 19. Proposed existing-entry updates

Add I032 evidence without disposition changes to CCP parsing/dispatch entries 0475-0491; FCB/default parsing entries 0506-0508; directory entries 0188-0218 and 0542-0550; Make/write/lifecycle entries 0248-0284 and 0551-0558; Delete/Rename entries 0285-0316; system/user entries 0518-0525 and 0559-0568; and error entries 0513-0517. No correction is proposed.

## 20. Open questions

1. Which real CP/M programs or scripts parse exact DIR/diagnostic layout?
2. Should strict mode reproduce DRI command echo and control-character presentation exactly?
3. Does a significant corpus depend on SAVE's destructive failure behavior?
4. Further controlled tests may distinguish erase behavior for every attribute combination and BIOS write-protect state.

## 21. Conformance implications

A suite must place marker COM conflicts, controlled users/drives/attributes, directory patterns, text/control/1Ah files, rename/delete targets, and full media; drive all commands without timed input; verify semantic output and post-command disk state; distinguish ordinary recovery from BDOS fatal presentation; and separately score exact formatting as policy until resolved.

### Preservation audit

The I031 ledger began and ended SHA-256 `57783f5f04893cf17f4f566a114dd30a1a537437bdc0e7577567ffa7c83905ed`. Seven named test records, probe source/binary/listing, harnesses, accepted transcripts, base and before/after images, directory listings, rebuild evidence, hashes, and reference reports are preserved. Protected files were verified unchanged. No ZIP or BetterCP/M implementation change was made.

### Sources

Digital Research, *An Introduction to CP/M Features and Facilities*; Digital Research, *CP/M 2.0 Interface Guide*; Digital Research, *CP/M 2.2 Alteration Guide*; DRI `OS2CCP.ASM` and `OS3BDOS.ASM`; I021-I024, I026, I029, I031; z80pack cpmsim 1.39 with DRI CP/M 2.2.
