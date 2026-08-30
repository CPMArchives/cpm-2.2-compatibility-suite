# Investigation 064 - CP/M 2.2 Expanded Software Corpus Validation

## 1. Objective and scope

This investigation expands the historical software corpus used to validate the CP/M 2.2 compatibility contract. It targets categories left open by I047-I053, performs controlled normal, failure, and processor-boundary runs, and distinguishes software-product behavior from operating-system requirements.

The principal result is partial closure: Turbo Pascal 3.01A and Microsoft FORTRAN-80 3.44 add two substantial compiled-language workflows, including in-memory compilation, relocatable output, library linking, generated COM execution, syntax failure, missing-source failure, and a Z80/8080 profile boundary. Every observed operating-system dependency fits the existing contract. Spreadsheet, database, packaged business, BBS, dedicated printer, paired-communications, and matching-hardware execution remain genuine corpus gaps because adequate executable fixtures could not be obtained and run.

Evidence classes are **A** (documented), **B** (DRI implementation), **I** (controlled observation), and **D** (policy unresolved). Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Future ledger evidence must use exactly `I064 SOFTWARE CORPUS VALIDATION subsystem IG AG`.

## 2. Relationship to previous investigations

I047 found that standard DRI utilities compose the existing CCP, BDOS, FCB/DMA, disk-state, memory, and lifecycle contracts without exposing a missing proposition. I048 tested assembly, macro, relocatable assembly, linking, loading, and debugging but left additional high-level compilers incomplete. I049 validated WordStar and BASIC/application workflows while explicitly leaving spreadsheet, database, business, and printer categories open. I050 validated communications boundaries but left BBS and paired transfer open. I053 consolidated those results and listed compiled languages among the remaining material gaps. I062 provided the conformance-pilot method, and I063 established the 8080 baseline versus declared Z80 processor profile.

I064 directly extends I048 and I053. It does not repeat WordStar, BASIC, Kermit, QTERM, KSCOPE, or DRI utility experiments whose artifacts remain valid.

## 3. Software corpus

| Software | Version/category | Platform assumptions | Evidence collected |
|---|---|---|---|
| Turbo Pascal | 3.01A; high-level IDE/compiler/runtime | Identifies CP/M-80, Z80; tested with ANSI console | Normal compile/run, syntax failure, Intel 8080 mismatch (**I**) |
| Microsoft FORTRAN-80 | 3.44; compiler | CP/M-80 file/console environment | Source-to-REL compile and missing-source failure (**I**) |
| Microsoft LINK-80/FORLIB | 3.44; linker/runtime library | CP/M relocatable files, TPA and storage | REL/library link, 6656-byte COM generation and execution (**I**) |
| Prior I047-I053 corpus | Utilities, WordStar, BASIC, games, communications and hardware-specific software | Previously stated profiles | Retained evidence; not rerun |
| SuperCalc/Perfect Calc | Spreadsheet candidates | Unknown until executed | Catalog identification only; unavailable (**D**) |
| dBASE II/Perfect Filer | Database candidates | Product/terminal profile unresolved | Catalog identification only; unavailable (**D**) |
| VanData | Packaged accounting candidate | Product/printer profile unresolved | Catalog identification only; unavailable (**D**) |
| PBBS and related families | BBS candidates | BYE/modem/serial and Z80 dependencies likely product-specific | Catalog/source description only; unavailable (**D**) |

Hashes, URLs, copyright caution, and exact exclusions are in `probes/corpus-inventory.txt` and `probes/provenance.txt`. Public archive availability is not treated as a freeware declaration.

## 4. Category coverage analysis

The added workflows close the most concrete development gap. Turbo Pascal exercises a large integrated transient, source-file loading, terminal control, compilation, generated code, and product-level diagnostics. FORTRAN-80 exercises a multi-program chain across source, relocatable object, library search, link output, COM loading, runtime console I/O, and termination. These are materially different from the earlier ASM-only workflow.

The application corpus is still uneven. Word processing, interpreter-hosted programs, games, communications clients, and hardware-crossing programs have executed evidence. Spreadsheet, database, packaged accounting/business, BBS/server, and dedicated printer applications still do not. Candidate names and archive locations were found, but direct acquisition returned authentication HTML or unavailable endpoints; those bytes were rejected. No product behavior is reconstructed from catalogs.

Normal, boundary, and failure classes are present in the accepted matrix. T01/T04 are normal operation; T03 is a processor-profile boundary; T02/T05 are product-visible failure cases. `probes/category-coverage.txt` provides the complete category matrix.

## 5. Documentation findings

CP/M documentation (**A**, inherited from earlier investigations) specifies transient loading and termination, page-zero objects, console/character devices, FCB/DMA file operations, drive/user state, 128-byte logical records, and documented error results. It does not specify Pascal or FORTRAN syntax, compiler memory maps, REL formats, library search algorithms, terminal screen design, or product wording.

Historical archive descriptions identify SuperCalc and dBASE II as consequential CP/M applications and identify public-domain BBS families, but a catalog entry proves significance or availability only. It does not prove an OS dependency. The Turbo banner explicitly states CP/M-80 and Z80; that product declaration is relevant to its processor profile, not a redefinition of generic CP/M.

## 6. Source findings

The Pascal and FORTRAN source fixtures are deliberately small and deterministic. HELLO.PAS uses standard output through the compiler runtime. HELLO.FOR compiles to a Microsoft REL file, links with FORLIB, and emits a standalone COM. BAD.PAS isolates syntax-failure handling. No compiler source was available or required to claim the externally observed workflows.

The product binaries visibly consume the established surfaces: CCP lookup/command tails, TPA loading, console I/O, sequential and directory file operations, file creation/close, multi-stage program execution, and normal termination. The generated files and transcripts do not expose direct private BDOS targets, literal resident addresses, or a new page-zero convention.

Catalog descriptions say PBBS requires a remote-access environment such as BYE and that some packages are Z80-specific. Because those programs were not executed, this remains planning evidence (**D**), not an observed requirement.

## 7. Experimental results

| ID | Purpose/environment/procedure | Observation | Compatibility result |
|---|---|---|---|
| T01 | Turbo Pascal normal; Z80; load HELLO.PAS, compile, run | Version 3.01A loaded and compiled four lines; `TP64 PASS` | Existing TPA, console, file, and lifecycle requirements sufficient |
| T02 | Turbo Pascal failure; Z80; compile BAD.PAS | Syntax error reported; marker did not run | Product diagnostic **NOT REQUIRED**; no missing OS behavior |
| T03 | Turbo Pascal boundary; Intel 8080 mode; start identical binary | No banner or CCP return in bounded run; scripted interruption | Z80 product requires Z80 profile; exact mismatch **NOT GUARANTEED** |
| T04 | FORTRAN normal; Z80; F80, LINK-80/FORLIB, execute | REL and 6656-byte COM created; `F80-64 PASS` | Existing multi-stage file/toolchain contract sufficient |
| T05 | FORTRAN failure; Z80; compile absent MISSING.FOR | `File not found`, then product prompt | Existing open/no-match failure sufficient; wording **NOT REQUIRED** |

Each mandatory record field—software, purpose, environment, procedure, observation, and conclusion—is in `probes/software-validation-records.tsv`. All input was scripted and each case began from recreated images. Raw transcripts, before/after images, and the generated COM are preserved.

## 8. Compatibility impact analysis

**REQUIRED:** The documented CP/M mechanisms already used by the new corpus: CCP lookup/loading, adequate configured TPA, console byte transport, FCB/DMA file access, source/object/library/output lifecycle, and normal return. The declared Z80 profile must execute the documented Z80 instructions needed by Turbo Pascal, consistent with I063.

**POLICY PENDING:** Which exact third-party versions become release acceptance fixtures; which terminal, printer, BBS/remote-access, and machine profiles BetterCP/M will advertise; and acquisition of reproducible spreadsheet, database, business, and printer fixtures.

**NOT REQUIRED:** Turbo Pascal menu layout, ANSI screen design, Pascal/FORTRAN grammar, Microsoft REL/library formats, compiler allocation maps, generated-code layout, diagnostics, prompt characters, and temporary-file algorithms. These are software-product behaviors.

**NOT GUARANTEED:** Running a Z80-labelled binary in an 8080-only profile; exact behavior after unsupported instruction execution; behavior of unexecuted spreadsheet/database/business/BBS/printer products; and successful physical-device workflows outside advertised profiles.

No observed failure suggests a correction to the compatibility contract. T02 and T05 are expected application failures. T03 is the processor-profile distinction already established by I063.

## 9. Compatibility conclusions

1. The current CP/M 2.2 contract adequately explains both new compiled-language workflows (**I**).
2. Multi-stage high-level compilation adds strong ecosystem evidence for ordinary FCB/DMA file lifecycle, relocatable-tool chaining, TPA reuse, generated COM loading, console I/O, and termination (**REQUIRED surfaces; no new proposition**).
3. Turbo Pascal 3.01A provides consequential software evidence for a declared Z80 profile but does not make Z80 universal to generic CP/M (**REQUIRED within Z80 profile; NOT REQUIRED generically**).
4. Compiler syntax, REL formats, screens, diagnostics, and prompts remain product concerns (**NOT REQUIRED**).
5. Spreadsheet, database, business, BBS, printer, paired-communications, and matching-hardware coverage remain incomplete (**POLICY PENDING**); absence of evidence is not evidence of missing semantics.
6. No new baseline compatibility boundary or contradiction was found.

## 10. Proposed ledger additions

None. The observations strengthen existing propositions for transient loading, console I/O, file lifecycle, failure results, toolchain composition, profile-specific terminal behavior, and the 8080/Z80 processor boundary. A new “Turbo Pascal” or “FORTRAN” proposition would encode product identity rather than an independently testable CP/M behavior.

No Compatibility Ledger file was modified.

## 11. Existing-entry updates

At the next authorized ledger integration, add `I064 SOFTWARE CORPUS VALIDATION subsystem IG AG` as strengthening evidence to:

- the existing transient loading, TPA, command-tail, termination, and CCP recovery entries exercised by both toolchains;
- the FCB/DMA open/read/create/write/close and failure entries exercised by source, REL, library, and COM workflows;
- the existing ecosystem/toolchain propositions strengthened by I048 and I053;
- the I063 processor-profile propositions for 8080 generic and Z80-declared execution.

Do not change dispositions merely because a specific compiler uses the surface. No correction or duplicate proposition was identified.

## 12. Open questions

1. Which reproducibly obtainable spreadsheet should supply normal recalculation, save/reopen, full-disk, and terminal-profile evidence? (**D**)
2. Which database should test create/index/query/update, multi-extent growth, damaged-index recovery, and failure behavior? (**D**)
3. Which packaged accounting/business workflow can be legally preserved and driven deterministically? (**D**)
4. Which public-domain BBS package and BYE/serial harness can support a complete local session without physical modem input? (**D**)
5. Which printer-oriented package and captured LIST-device profile should test formatting, unavailable printer, pause/status, and output failure? (**D**)
6. Should Turbo Pascal 3.01A and FORTRAN-80 3.44 become strict release fixtures or optional ecosystem-tier fixtures? (**D**)
7. Successful paired communications, receive-side disk full/carrier loss, and named matching-hardware runs remain open from I050-I053. (**D**)

## 13. Conformance implications

Add both accepted compiler workflows to the ecosystem tier, not the proposition-level baseline. Pin binary and fixture hashes; restore fresh disks; compile, link, execute, and verify generated outputs; separately test syntax and missing-file failures. A Z80-tier run may include Turbo Pascal, while an 8080-tier result must classify it as an inapplicable profile fixture rather than a CP/M failure.

Future spreadsheet, database, business, BBS, and printer tests should first identify their terminal, processor, device, and rights/provenance profiles. Unexpected failures should be reduced against the existing proposition suite before proposing a ledger change. Tests should assert application-visible outcomes and persisted data, not exact screens, diagnostics, file placement, allocation order, compiler internals, or timing.

### Completion audit

- This report has exactly the thirteen required numbered sections.
- Five complete software-validation records cover common/specialized software, normal operation, a processor boundary, and failure cases.
- All performed experiments are documented; unavailable categories are explicitly incomplete and no behavior is inferred from them.
- Historical binaries, source fixtures, scripts, transcripts, before/after images, generated COM, inventories, provenance, and SHA-256 records are present.
- All source fixtures re-stage identically and the generated FORTRAN COM is pinned; validation checks pass.
- The authoritative ledger remained SHA-256 `dd9ac078c64ebe72ef9a1493ac79305b97840cc7d3965e2eba7f2e185ef875ee`.
- Protected-tree comparison records only the new Investigation 064 directory; no previous BetterCP/M file was modified.
- No BetterCP/M implementation or architecture change was made.
