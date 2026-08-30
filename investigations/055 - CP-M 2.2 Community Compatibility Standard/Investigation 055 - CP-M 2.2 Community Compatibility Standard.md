# Investigation 055 - CP/M 2.2 Community Compatibility Standard

## 1. Objective and scope

This investigation consolidates the evidence through Investigation 054 into a practical CP/M 2.2 community compatibility standard. It identifies the normative ledger content, separates baseline, strict-ecosystem, optional and hardware-profile claims, states what must remain variable or excluded, and ties every conclusion to evidence and validation.

This is an evidence and conformance review. It does not modify the Compatibility Ledger or previous artifacts, implement BetterCP/M, prescribe architecture, or extend the claim to CP/M 3, MP/M or unsupported systems.

## 2. Compatibility standard

Practical compatibility means that historical CP/M 2.2 software observes the documented CP/M interfaces and the small set of additional ecosystem behaviors justified by consequential software dependency. It does not mean cloning every DRI address, algorithm, diagnostic, timing artifact or machine peripheral.

Evidence remains **A** documented CP/M behavior, **B** DRI implementation/distributed-software behavior, **I** controlled observation, and **D** unresolved policy. Findings retain the ledger dispositions **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Any later ledger citation from this report must use exactly `I055 STANDARD CONFORMANCE COMPATIBILITY subsystem IG AG`.

The authoritative Investigation 054 ledger has 652 proposition lines: 445 REQUIRED, 109 NOT GUARANTEED, 50 POLICY PENDING and 48 NOT REQUIRED. Because the known duplicated 0248-0277 block remains present, these are proposition-line counts; there are 622 unique numeric identifiers. The duplication is an editorial issue, not two independent requirements.

## 3. Relationship to previous investigations

I001-I045 established and cross-checked the application-visible CCP, BDOS, BIOS, storage, memory, lifecycle, device and failure boundaries. I046 found baseline boundary closure and isolated remaining policy/profile questions. I047-I051 surveyed utilities, development tools, applications, communications and hardware-dependent software. I052 mapped every ledger proposition to a 62-test regression inventory. I053 validated a representative cross-category corpus without finding a missing baseline rule. I054 classified undocumented behavior and confirmed that justified de facto requirements were already represented.

I055 adds no runtime claim beyond that evidence. It turns the existing classifications into a claim structure suitable for community-facing conformance.

## 4. Compatibility requirement consolidation

The 445 REQUIRED proposition lines define positive application-visible obligations. Their fundamental groups are:

- transient entry at 0100h, page zero, configured memory ceiling, default FCBs/tail/DMA, valid termination and recovery gateways;
- CCP command acquisition/parsing, resident commands, transient lookup/load/dispatch and lifecycle;
- BDOS Functions 0-40, call/result convention, console/system state, FCB/DMA directory and file operations, namespaces, record/extent/persistence and classified error outcomes;
- discoverable configured BIOS jump table, boot, raw character devices, logical-sector disk services and coherent parameter structures;
- configured flat-memory/TPA behavior, including application-owned writable/executable storage;
- cross-layer state and recovery sufficient for documented continued use;
- strict-profile ecosystem protocols such as standard SUBMIT/XSUB where separately specified.

Requirements are fundamental when public CP/M operation cannot be composed without them; they are ecosystem-driven when shipped or historically significant software establishes an observable dependency beyond an individual API description. The distinction affects evidence provenance, not the force of an applicable REQUIRED proposition.

The 109 NOT GUARANTEED propositions constrain claims: applications and tests may not assume one value for unspecified registers, residues, ordering, private targets, invalid-call aftermath or internal state. The 48 NOT REQUIRED propositions exclude private mechanisms and incidental presentation from conformance. The 50 POLICY PENDING propositions are diagnostics or selectable profile questions until evidence and policy activate them.

`probes/community-standard-review.tsv` gives 20 consolidated conclusions with requirement, evidence, classification and validation method. `probes/ledger-test-traceability.tsv` retains proposition-level detail.

## 5. Conformance categories

Five categories are necessary:

1. **Baseline CP/M 2.2.** Every applicable REQUIRED public-interface proposition for a standard configured CP/M 2.2 system. This includes the CCP, BDOS, FCB/DMA/storage, BIOS ABI, memory/lifecycle and documented failure surface.
2. **Strict community ecosystem.** Baseline plus REQUIRED de facto behavior evidenced by important historical software, notably standard SUBMIT/XSUB interoperation and writable/executable application-owned TPA. It does not freeze private DRI implementation.
3. **Optional compatibility profile.** A named selection for terminal/console presentation, IOBYTE/logical devices, communications, extensions, error presentation or another POLICY PENDING area. An unselected profile cannot fail the baseline.
4. **Hardware-profile compatibility.** A named BIOS/machine/device profile: geometry, terminal, ports, MMIO, controller or peripheral. Generic CP/M compatibility never implies all historical machines.
5. **Outside/unsupported behavior.** NOT REQUIRED private mechanisms and behavior outside declared profiles. NOT GUARANTEED is not an optional-feature category; it is permitted variability that conformance must preserve.

A claim therefore names a ledger/version baseline, whether strict community compatibility is included, and every optional and hardware profile enabled. `probes/conformance-categories.txt` supplies the concise definitions.

## 6. Software ecosystem analysis

The current model explains every successful and expected-failure result in the representative I053 corpus: DRI utilities and resident commands; assembly, macro assembly, linking, loading, debugging and submitted builds; WordStar, BASIC/Wumpus and Adventure; generic Kermit startup/failure paths; and public-interface controls plus unsupported QTERM/KSCOPE hardware traps. I054 then reproduced the crucial public/private, SUBMIT/XSUB and self-modifying-memory distinctions. No case required a new baseline proposition.

Important gaps remain: spreadsheets, databases, packaged business software, BBS and printer workflows; additional compiled languages; successful paired communications and receive/carrier failures; matching IMSAI/Dazzler and other hardware; and selected timing-sensitive or late-fault cases. They limit the breadth of a claim but do not reopen baseline boundary closure. A claim covering one of these areas requires a named fixture/profile and new evidence.

Startup evidence alone never certifies an application's full features. A software workflow is cross-layer evidence; exact byte/register semantics remain grounded in narrower probes.

## 7. Documented versus practical standard analysis

Documentation (**A**) is sufficient for the public structure: page zero, 0100h transient model, CCP preparation, BDOS calls/data structures, BIOS table and services, FCB/DMA records, storage parameters, boot and selected error behavior. Most common software assumptions are direct use of this documented surface.

DRI behavior (**B**) matters when documentation is ambiguous and external behavior is stable and consequential, or when separately supplied standard components cooperate through an observable protocol. It supplies test leads and may strengthen or delimit a requirement; source-only private control flow is never enough.

Community practice establishes an expectation only with credible software dependency. A=L/B=H normal BDOS aliases, standard SUBMIT/XSUB cooperation, and writable/executable TPA meet that standard through repeated source/software/experimental evidence. Fixed private targets, stacks, handler addresses, physical allocation choices and vendor diagnostics do not.

When evidence establishes only a named environment—terminal escapes, IOBYTE mapping, serial ports, Dazzler output, disk controller or CPU extension—the practical result is a profile, not a universal CP/M rule.

## 8. Undocumented behavior policy

Preserve undocumented behavior when it is externally observable, stable enough to test, and required by significant software within a stated scope. Existing examples are the normal result aliases and strict community behaviors represented by 0620-0622.

Leave behavior unspecified when applications lack a portable dependency or the manuals deliberately do not define it: entry/residual registers, flags, scratch/reserved bytes, failed-call residue, physical directory/allocation order, private-target behavior and invalid direct-call aftermath. These remain NOT GUARANTEED, and test suites should exercise permitted variation.

Exclude private mechanisms and invisible algorithms: DRI stacks, dispatch tables, call graphs, cache/checksum state, internal allocation walks, exact addresses and host/emulator mechanics. Exact application/vendor UI and diagnostic text is also excluded unless a selected presentation profile independently requires it.

Keep observable but unresolved console, device, exact error, CPU and hardware behaviors POLICY PENDING. Do not silently choose DRI's result merely because it is easy to copy. The 21-item input review is preserved as `probes/undocumented-behavior-inventory.tsv`.

## 9. Validation requirements

Every compatibility claim must provide:

- the exact ledger/version and declared conformance categories/profiles;
- the applicable proposition set and disposition treatment;
- deterministic inputs, environment/profile identity and expected external observations;
- raw register, memory, FCB/DMA, console, BIOS activity and disk evidence as appropriate;
- fixture, executable and before/after image hashes;
- explicit separation of product failure, fixture failure, permitted variation, unsupported profile and unresolved policy.

I052 maps all 652 proposition lines to at least one primary test and defines 62 reusable tests. REQUIRED entries use positive acceptance criteria. NOT GUARANTEED entries use variability/non-assertion tests. NOT REQUIRED entries use anti-requirement tests so alternate internals pass. POLICY PENDING tests remain diagnostic or profile-gated until selected.

Cross-layer corpus tests supplement rather than replace narrow probes. Any unexpected software failure must first be reduced to the relevant narrow test before changing the contract. Timing/asynchronous claims require repeated runs and a declared threshold; destructive/error tests require restored isolated fixtures.

## 10. Compatibility conclusions

**REQUIRED:** Implement and validate every applicable REQUIRED ledger proposition in the baseline/declared profile, including public entry, CCP, BDOS, BIOS, storage, memory, lifecycle, errors and justified strict-ecosystem dependencies. A community claim must state its categories and retain evidence traceability.

**POLICY PENDING:** Exact console/presentation edges, selected IOBYTE/device and communications behavior, extension selectors, some error presentation, optional protection, CPU assumptions and named hardware/media profiles until policy and evidence select them.

**NOT GUARANTEED:** Unspecified registers/state, private-target equivalence, physical ordering/allocation, invalid/malformed aftermath, post-failure residue and behaviors outside a configured profile.

**NOT REQUIRED:** DRI internal algorithms/addresses/stacks/tables, host abstractions, exact vendor UI/diagnostics, universal emulation of every historical machine and untested software quirks.

The evidence supports a usable practical standard now: baseline plus explicitly declared strict/optional/hardware profiles. Remaining gaps affect claim breadth, not the existence of the baseline contract.

## 11. Proposed ledger additions

None. Conformance-category definitions organize existing propositions; they are not new application-visible CP/M behavior. Adding “must conform to the standard” would be circular, while adding broad ecosystem umbrellas would duplicate independently testable entries.

The known duplicate block 0248-0277 and overlapping Function-37 propositions remain editorial normalization work requiring separate authorization. They do not justify semantic additions or renumbering here.

## 12. Existing-entry updates

No ledger file was modified and no disposition correction is proposed.

At a future authorized integration, `I055 STANDARD CONFORMANCE COMPATIBILITY subsystem IG AG` may be cited as consolidation/traceability evidence, not as substitute behavioral evidence. It is appropriate for project conformance documentation and cross-references among profile-boundary entries. It should not be used to manufacture new support for a proposition not independently tested.

The evidence chain remains: original **A/B/I/D** finding -> ledger proposition -> I052 test mapping -> I053/I054 ecosystem/undocumented validation where applicable -> I055 claim category.

## 13. Open questions

1. Will the project use “baseline CP/M 2.2” and “strict community ecosystem” as separate public claims, or make the strict set the default? (**D**)
2. Which of the 50 POLICY PENDING propositions will be selected before the first compatibility release? (**D**)
3. Which terminal, IOBYTE/logical-device, communications, disk/media and hardware profiles receive stable names and versioned manifests? (**D**)
4. What additional rights-cleared spreadsheet, database, business, BBS, printer and compiler corpus is required for broader community claims? (**D**)
5. Which matching hardware/emulation environments are faithful enough to support profile conformance rather than demonstration? (**D**)
6. What repetition thresholds apply to timing, asynchronous I/O and retry behavior? (**D**)
7. When will the ledger's duplicated 0248-0277 block and Function-37 overlap be normalized without renumbering stable identifiers? (**D**, editorial)
8. What release artifact will bind a claim to ledger hash, test inventory, enabled profiles and preserved evidence? (**D**, process)

## 14. Conformance implications

A conforming implementation may use any architecture. It passes by reproducing required external observations and by not overclaiming unspecified/private behavior. Its declaration should state the authoritative ledger hash, baseline/strict selection, named optional/hardware profiles, inapplicable tests and unresolved policy items.

The baseline test run executes every applicable positive test plus negative/variability rules. Strict community claims add SUBMIT/XSUB and self-modifying-memory workflows. Optional and hardware tests activate only through the profile manifest. Corpus workflows then verify composition across CCP, BDOS, BIOS, storage and memory; failures are reduced using narrow tests.

Final review: all conclusions in `probes/community-standard-review.tsv` identify a requirement, evidence source, classification and validation method; ecosystem requirements are separated from private implementation; unsupported assumptions are explicitly excluded; the conformance categories are distinct; all 652 proposition lines remain traceable to the 62-test inventory; no ledger addition or correction is proposed.

Completion audit: this 14-section report and all referenced review, traceability, classification, validation and hash artifacts are present; the authoritative Investigation 054 ledger remained unchanged; no prior report, artifact or BetterCP/M implementation file was changed; and no ZIP archive was created.
