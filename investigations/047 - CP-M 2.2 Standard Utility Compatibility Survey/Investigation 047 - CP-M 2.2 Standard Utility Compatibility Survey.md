# Investigation 047 - CP/M 2.2 Standard Utility Compatibility Survey

## 1. Objective and scope

This investigation asks whether the standard Digital Research CP/M 2.2 utilities PIP, STAT, ED, ASM, LOAD, DDT, SUBMIT, and XSUB expose compatibility requirements not already captured by Investigations 001-046. It reviews documentation and DRI source, then executes all eight utilities in a fresh deterministic z80pack CP/M 2.2 session. It covers utility execution, file and disk operations, normal error handling, and record/page-zero boundaries. It does not design replacement utilities, generalize machine-specific paths, or implement BetterCP/M.

The principal result is closure, not expansion: the utilities are demanding cross-layer consumers of the existing CCP, page-zero, BDOS, FCB/DMA, disk-state, memory, and lifecycle contracts, but the tested corpus disclosed no new independently testable ledger proposition. SUBMIT and XSUB independently confirm existing entries 0620 and 0621.

## 2. Compatibility standard

Evidence classes are:

- **A** - published CP/M documentation.
- **B** - preserved Digital Research source or distributed utility behavior.
- **I** - controlled observation on the reference CP/M 2.2 system.
- **D** - an unresolved BetterCP/M policy choice.

A utility dependency strengthens a requirement when it uses a documented interface or when separately justified ecosystem compatibility requires the observable behavior. A private algorithm, diagnostic, address, or hardware path is not promoted merely because DRI used it. Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Evidence updates use the required string `I047 UTILITY ECOSYSTEM COMPATIBILITY subsystem IG AG`.

## 3. Relationship to previous investigations

I021 established interactive CCP acquisition, parsing, and dispatch. I025 classified application-visible file-operation failures. I040 defined configured geometry, DPH/DPB/ALV coherence, and direct-structure responsibility. I041 separated public page-zero/system interfaces from private targets. I042 surveyed broader software assumptions and established the standard SUBMIT/XSUB workflow. I046 found baseline boundary closure, recorded bounded policy gaps, and identified ledger editorial duplication without changing runtime requirements.

I047 narrows the corpus to the eight standard DRI utilities and runs them together. It does not duplicate the detailed semantics of those earlier investigations. Its question is whether composition by DRI's own tools reveals a missing contract.

## 4. Utility coverage

| Utility | Preserved evidence | Experimental coverage | Compatibility role |
|---|---|---|---|
| PIP | COM and PIP.PLM | explicit-drive two-record copy; missing source | FCB/DMA file lifecycle; console/device paths |
| STAT | COM and STAT.PLM | file record count; drive free space | search, DPB/ALV/login/read-only system state |
| ED | COM and ED.PLM | create, edit, close, reopen-visible one-record text | console buffering; workspace; file replacement |
| ASM | COM and seven ASM modules | explicit-drive assembly; missing source | 0006h ceiling; FCB/DMA; HEX/PRN output |
| LOAD | COM and LOAD.PLM | one-record COM construction and execution | HEX input; output lifecycle; 0100h image |
| DDT | COM and DDT2MON.ASM | page-zero dump; G0 restart | public vectors; writable/executable TPA |
| SUBMIT | COM and SUBMIT.PLM | complete multi-command RUN42 stream | default FCB/tail; A:$$$.SUB; WBOOT |
| XSUB | COM and XSUB1.ASM | Function-10 injection and continued calls | page-zero interposition; DMA tracking |

All required utilities received behavioral coverage. Full feature coverage of every command option was neither required nor claimed.

## 5. Documentation findings

The CP/M Features and Facilities manual presents STAT as the status/free-space/device-assignment utility; ASM and LOAD as the source-to-HEX-to-COM development path; PIP as the file/device transfer utility; ED as the standard disk editor; and SUBMIT as ordered command-file processing with parameter substitution (**A**). The ASM, ED, and DDT manuals describe their command interfaces and standard CP/M file/execution environment (**A**).

These descriptions make the utilities useful acceptance evidence but do not specify every internal BDOS call, temporary file, diagnostic, or allocation decision. XSUB's interposition mechanics are most clearly established by DRI source and controlled execution rather than the surveyed user-level manuals (**B/I**). Documentation does not make Intel/ICOM ports, one terminal protocol, literal system addresses, or exact banners a universal CP/M interface.

## 6. Source findings

PIP composes console/device services with search, open/close, delete, sequential and random I/O, Make/Rename, Set DMA, attributes, current disk and user state. It selects successive private 128-byte buffers through Function 26. STAT consumes 0003h, 0006h, 005Ch/0080h and BDOS version, disk, search, login-vector, allocation-vector, read-only-vector, DPB, user, and file-size services. ED sizes workspace from 0006h and combines console/status/buffered input with ordinary file operations and alternate DMA (**B**).

ASM calls 0005h and derives workspace from its operand; its I/O module uses FCB/DMA file services. LOAD reads HEX through sequential records and deletes/makes/writes/closes COM output at the standard transient origin. DDT uses page-zero WBOOT/BDOS vectors and debugger-owned patches while treating execution inside BDOS specially (**B**).

SUBMIT reads the CCP-prepared default FCB, writes counted command records to A:$$$.SUB, closes the file, and invokes WBOOT. XSUB saves and redirects page-zero gateway operands, chains ordinary calls, tracks Function 26, intercepts Function 10, and copies a submission record into the caller's counted buffer (**B**). These are strong concrete dependencies, already represented by entries 0620-0621 and I041's public/private distinction.

The detailed per-utility review is preserved in `probes/source-analysis.txt`.

## 7. BDOS usage findings

The utility set spans the relevant public CP/M 2.2 service families:

- console input/output/status and buffered input;
- disk reset/select/current-disk and user state;
- FCB Open, Close, Search First/Next, Delete, sequential Read/Write, Make, Rename, random I/O, file size and attributes;
- Set DMA and pointer-returning disk-state services.

The observed calls follow the established selector-in-C and parameter-in-DE/E convention and rely on function-specific results (**B/I**). PIP, ED, STAT, SUBMIT, LOAD, and XSUB assume that Function 26 changes the DMA used by subsequent relevant BDOS calls; they do not imply that console functions consume DMA. Utility composition requires coherent state across calls, not new register-preservation guarantees.

The unusual pattern is XSUB's interception of Function 10 and tracking of Function 26. It is REQUIRED for the strict standard-utility profile by existing entry 0621, while arbitrary calls to a private BDOS target remain NOT GUARANTEED under entry 0619.

## 8. BIOS usage findings

The ordinary tested disk workflows reach hardware through BDOS, not by hard-coding a BIOS controller. STAT obtains configured disk structures through BDOS. This reinforces the documented/profiled BIOS-DPH-DPB-ALV boundary (**B/I**).

PIP source contains device-specific Intel/ICOM reader paths. DDT necessarily reasons about system execution and the BDOS gateway, but the tested debugger commands use the standard loaded environment. Such specialized paths are **NOT REQUIRED** in a generic BetterCP/M platform and direct raw behavior remains **NOT GUARANTEED** outside the declared BIOS/device profile. No tested utility required a universal port map, sector skew, controller protocol, or physical geometry.

## 9. File and disk assumptions

The utilities reinforce these existing **REQUIRED** assumptions:

- uppercase FCB names and explicit-drive fields identify files in the current user area;
- directory search, extent aggregation, 128-byte records, sequential progression, allocation and close persistence compose coherently;
- Function 26 selects caller DMA for relevant record transfers;
- DPB/ALV and free-space reporting describe the selected configured disk;
- COM output is a contiguous transient image beginning at 0100h;
- CP/M text can contain CR/LF and 1Ah padding while BDOS storage remains byte-transparent;
- ordinary no-match/open failures return to the utility, permitting it to diagnose and return to the CCP.

Exact block choice, physical directory order, output spacing, backup/temporary names, residual directory bytes, and reference-image capacity are **NOT REQUIRED** or **NOT GUARANTEED** as already classified. The run used only disposable restored images.

## 10. Undocumented convention analysis

Four categories must remain distinct:

1. **Documented and repeatedly consumed:** 0100h, page zero, CALL 0005h, 0006h ceiling, FCBs, DMA, 128-byte records, WBOOT, and configured disk structures are REQUIRED.
2. **Standard ecosystem protocol:** A:$$$.SUB processing and XSUB Function-10 delivery are REQUIRED in the strict profile under entries 0620-0621.
3. **Specialized/profile behavior:** PIP's hardware reader code and exact device assignments are NOT GUARANTEED without the matching machine profile.
4. **Incidental implementation:** source algorithms, private stacks/tables, exact diagnostics/banners, temporary names, literal gateway targets, disk allocation placement, and emulator timing are NOT REQUIRED.

The recurrence of a convention in several DRI utilities strengthens its evidence. It does not override an existing NOT GUARANTEED boundary or create an obligation to reproduce DRI code internally.

## 11. Experimental results

The deterministic `run047.sh` restored private A:/B: images and required no manually typed input. The full transcript is `probes/transcripts/utility-survey.txt`; complete purpose/procedure/observation/conclusion records are in `probes/observed-output.txt`.

| Test | Observed behavior | Compatibility conclusion |
|---|---|---|
| ASM/LOAD/HELLO42 | assembled, loaded 0100h-0113h into one COM record, printed marker | established development/transient contracts sufficient (REQUIRED) |
| PIP copy | B:COPY47.ASM was two records; extracted logical bytes matched | file lifecycle/DMA/record behavior sufficient (REQUIRED) |
| STAT file/disk | reported two records and free space; free space changed after ED | configured search/DPB/ALV coherence sufficient (REQUIRED) |
| ED | scripted insertion created durable one-record ALPHA47 text | console plus Make/Write/Close behavior sufficient (REQUIRED) |
| ASM/PIP errors | both diagnosed missing input and returned to A> | documented logical failure and recovery sufficient; wording NOT REQUIRED |
| DDT D0,7; G0 | showed page-zero vectors and restarted to A> | public vectors/restart REQUIRED; exact targets NOT GUARANTEED |
| SUBMIT RUN42 | ordered job continued across transients to unique final marker | independently confirms entry 0620 (REQUIRED) |
| XSUB/IN42 | Function 10 received count 07/data BATCH42 without keyboard input | independently confirms entry 0621 (REQUIRED) |

The extracted PIP text was byte-identical, ED extraction contained `ALPHA47`, and IN42 rebuilt byte-identically. Expected disk-image changes were confined to the case copies. The final `User Interrupt` and speed/address variations are harness/emulator artifacts, not CP/M evidence.

## 12. Compatibility conclusions

**REQUIRED:** Preserve the existing documented and ledgered public environment strongly exercised here: 0100h execution, page-zero WBOOT/BDOS and configured-memory fields, CCP FCB/tail preparation, public BDOS convention and function-specific results, FCB/DMA/record/directory/file lifecycle, configured DPB/ALV state, ordinary logical-error return, and the strict-profile SUBMIT/XSUB behavior of entries 0620-0621.

**NOT GUARANTEED:** Literal private targets; incidental register/state contents; exact allocation or directory order; raw device behavior outside a profile; behavior of utility options and failures not tested here; and exact emulator timing or residual data.

**NOT REQUIRED:** DRI's source algorithms, memory layouts, tables, banners, diagnostics, whitespace, temporary naming, exact tool implementations, Intel/ICOM hardware paths, or modern replacements for the utilities.

**POLICY PENDING:** Whether a reduced, non-strict BetterCP/M profile may omit standard SUBMIT/XSUB interposition; which additional standard-utility options and machine/device profiles belong in release acceptance; and whether exact user-facing utility presentation is a separate distribution goal. These are product/profile questions, not missing baseline ABI discoveries.

## 13. Proposed ledger additions

None.

Every compatibility proposition demonstrated by the survey is already present in the authoritative ledger through Investigation 046. In particular, adding new generic propositions such as "PIP works" or "standard utilities run" would combine many independently testable contracts and violate the ledger standard. Entries 0620 and 0621 already state the only unusual standard-utility ecosystem mechanisms at the proper granularity.

If future evidence from this report is incorporated, use `I047 UTILITY ECOSYSTEM COMPATIBILITY subsystem IG AG` and attach it to the existing independently testable proposition rather than creating an umbrella duplicate.

## 14. Existing-entry updates

Recommended evidence-only updates, not applied:

- **0001-0005 and entry/lifecycle group:** add ASM/LOAD/DDT execution as I047 corroboration for 0100h, WBOOT, BDOS and configured ceiling.
- **CCP/default-environment entries:** add ASM, LOAD, SUBMIT and explicit-drive execution evidence; retain all existing policy distinctions for incidental FCB/tail fields.
- **BDOS call/file/DMA/search/system-state entries:** add PIP, STAT, ED and LOAD composition evidence; no wording or disposition change.
- **0598-0601 and 0613-0617:** add STAT/PIP evidence for configured BIOS/disk structures while retaining profile and direct-caller limits.
- **0619:** add DDT/XSUB corroboration without weakening the NOT GUARANTEED private-target rule.
- **0620-0621:** add the independent RUN42 transcript and XSUB/IN42 observation using the I047 evidence string.
- **0622:** add DDT execution only as strengthening for writable/executable transient storage.

No correction or reclassification was justified. I046's duplicate 0248-0277 maintenance issue remains an editorial task outside I047.

## 15. Open questions

1. Should release conformance exercise every documented option of the eight utilities, or retain a smaller dependency-oriented acceptance matrix? (**D**)
2. Which physical-device PIP paths belong to named machine profiles, and which preserved hardware can validate them? (**D**)
3. Should a reduced profile be allowed to omit SUBMIT/XSUB while clearly disclaiming strict standard-utility compatibility? (**D**)
4. Are exact DRI utility diagnostics and editor interaction a distribution/user-experience target even though they are not baseline OS requirements? (**D**)
5. Which additional DRI utilities, versions, or corrupted-media cases would test a presently unresolved ledger proposition rather than merely repeat covered behavior? (**D**)

No required experiment in the requested eight-utility survey remains incomplete.

## 16. Conformance implications

BetterCP/M conformance should test the utilities as end-to-end compositions after proposition-level tests pass. A strict utility-corpus run should restore known media; assemble/load/run a marker program; copy and verify a multi-record file; query file and disk state; create and close editor output; recover from normal missing-file errors; inspect/restart through DDT; and complete a SUBMIT/XSUB job with Function-10 injection. Tests should assert stable observable state, not DRI wording, addresses, allocation order, or internal algorithms.

### Completion audit

- New Investigation 047 directory and all referenced report/probe/reference artifacts: verified.
- Eight named utilities executed in a deterministic no-keyboard-input run: verified.
- Before/after disk images and SHA-256 hashes: preserved.
- PIP output logical bytes: verified byte-identical to input.
- IN42 probe rebuild: verified byte-identical.
- DRI distributed COM files: hashes preserved; no unsupported historical rebuild claim made.
- Protected BetterCP/M baseline outside the new directory: verified unchanged.
- Authoritative ledger: unchanged at SHA-256 `544ee061fe8e19c5e0b429d989b9946694b59561634eb0c51205e78666d3f3ee`.
- Previous investigation and implementation files: not modified.
- Compatibility Ledger: not modified.
- ZIP archives: none created.

