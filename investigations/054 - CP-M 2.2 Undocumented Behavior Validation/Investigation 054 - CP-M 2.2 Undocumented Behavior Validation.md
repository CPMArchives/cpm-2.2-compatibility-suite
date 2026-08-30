# Investigation 054 - CP/M 2.2 Undocumented Behavior Validation

## 1. Objective and scope

This investigation determines which undocumented or de facto CP/M 2.2 behaviors have enough evidence and software dependency to belong to the practical compatibility contract. It inventories behavior identified through Investigation 053, rechecks the strongest candidates with fresh controlled execution, and separates public contract, strict-profile ecosystem convention, implementation residue, and unresolved policy.

It does not modify the Compatibility Ledger, prior reports or artifacts; implement BetterCP/M; or invent undocumented features. The principal result is conservative: the current ledger already encodes the justified distinctions, and no new compatibility proposition is required.

## 2. Compatibility standard

Evidence classes remain **A** documented behavior, **B** DRI implementation or distributed-software behavior, **I** controlled experiment, and **D** unresolved policy. Any later ledger use of this investigation must identify `I054 UNDOCUMENTED COMPATIBILITY BEHAVIOR subsystem IG AG`.

An undocumented observation becomes **REQUIRED** only when it is externally observable, stable enough to test, and supported by a consequential software dependency or a separately documented interface consequence. A repeatable DRI value without such dependency remains **NOT GUARANTEED** or **NOT REQUIRED**. Profile-dependent but potentially material behavior remains **POLICY PENDING**.

## 3. Relationship to previous investigations

I041 separated public gateways and the discoverable BIOS table from their private targets, and demonstrated reversible page-zero interposition. I042 found that most ecosystem assumptions merely repeat documented CP/M interfaces, while standard SUBMIT/XSUB forms a genuine de facto DRI protocol. I043 established writable/executable TPA and distinguished configured entry/loader values from required lifecycle effects. I045 enforced cross-layer non-inference; I046 found the boundary substantially closed; I053 validated representative software without finding a missing baseline requirement.

I054 retests selected I041-I043 cases using fresh restored images and reviews the authoritative I053 ledger. It does not duplicate narrow evidence for every ledger entry; unrerun items retain their original evidence and classification.

## 4. Undocumented behavior inventory

The proposition-granular inventory is `probes/undocumented-behavior-inventory.tsv`. Its 21 rows cover five kinds of behavior:

1. **Documented interfaces commonly mistaken for folklore:** 0100h entry, page-zero gateways, the 0006h configured ceiling, default FCB/DMA, and BIOS-vector discovery are documented and REQUIRED, not undocumented exceptions.
2. **De facto behavior with consequential dependency:** normal BDOS result aliases, standard SUBMIT/XSUB protocol and gateway interposition, and writable/executable self-modifying TPA are REQUIRED in the applicable strict CP/M 2.2 profile.
3. **Observable but unspecified residue:** entry registers, flags, reserved bytes, failed-call buffers/FCBs, physical directory/allocation order, and private-target behavior are NOT GUARANTEED.
4. **Private or incidental DRI implementation:** local stacks, dispatcher residue, E=FEh Function-6 branch, exact internal algorithms, and fixed handler addresses are NOT REQUIRED.
5. **Insufficiently resolved observable/profile behavior:** exact console state interactions, some write-error results, disk-error presentation, and named CPU/hardware behavior remain POLICY PENDING.

This inventory avoids counting a private algorithm merely because source exposes it. It also avoids demoting a documented behavior merely because programmers historically described it as conventional.

## 5. Evidence analysis

Frequency alone is not decisive. `CALL 0005h`, the 0006h ceiling, page zero, FCBs, and WBOOT are both common and documented (**A**, **B**, **I**). Their frequency strengthens confidence but creates no new rule.

The strongest undocumented/de facto case is shipped-software composition. DRI's separately supplied SUBMIT, XSUB, CCP, and Function-10 consumer cooperate through `A:$$$.SUB`, warm restart, page-zero interposition, and ordinary chained BDOS calls (**B**, **I**). Multiple later utility/toolchain surveys reproduced it. This supports existing entries 0620-0621 as strict-profile REQUIRED behavior.

Writable/executable application-owned TPA is externally visible, compatible with the documented flat-memory ownership model, and used by debuggers, overlay techniques, and self-modifying programs (**A**, **B**, **I**). It supports 0622. By contrast, the private BDOS target returned the same version as `CALL 0005h` in this DRI build, but the public gateway can be interposed and targets vary by configuration. Repeatability therefore strengthens 0619's NOT GUARANTEED boundary rather than equivalence.

Exact entry SP, return address, private bytes, BIOS base, handler targets, loader ceiling, output wording, and media/allocation order recur in controlled fixtures but have no evidence of universal stability. Their observation is evidence about a reference configuration, not evidence of a general promise.

## 6. Software dependency analysis

Widespread portable software depends primarily on documented interfaces. DRI and independent assemblers, editors, linkers, debuggers, utilities, and applications repeatedly use 0100h, page zero, `CALL 0005h`, the 0006h ceiling, FCB/DMA services, 128-byte records, and WBOOT. I053 showed these suffice across the tested corpus.

Three narrower dependencies justify strict-profile requirements:

- SUBMIT requires CCP consumption of its counted records across transient returns.
- XSUB requires writable gateway interposition, chaining of ordinary BDOS calls, and Function-10 delivery from the submitted stream.
- Debuggers/overlays/self-modifying transients require writable and executable application-owned TPA.

No reviewed software establishes a widespread dependency on a fixed private BDOS/BIOS address, exact entry SP, residual registers, DRI private stack, Function-6 E=FEh, exact failed-call state, exact directory/allocation order, or exact diagnostics. Hardware-dependent software can depend on private ports or CPU behavior, but that establishes a named machine/processor profile, not generic CP/M.

## 7. Experimental results

Seven deterministic validation records are preserved in `probes/validation-records.txt`.

| Test | Matrix class | Observation | Compatibility conclusion |
|---|---|---|---|
| T054-01 | Documented/common control | Valid page-zero gateways, Function 12=0022h, derived 17-entry BIOS table | Public meanings REQUIRED; exact targets not |
| T054-02 | Undocumented/rare | Private target happened to return 0022h; invalid direct SELDSK returned 0000h | Equivalence/aftermath NOT GUARANTEED |
| T054-03 | Undocumented/common | Wrapper count 01, result 0022h, gateway restored | Interposition class REQUIRED strict profile |
| T054-04 | De facto/common | XSUB delivered BATCH42; later commands and HELLO42 completed | Entries 0620-0621 REQUIRED strict profile |
| T054-05 | Undocumented/common | Application patch values 00/A5/5A observed | Writable/executable TPA REQUIRED strict profile |
| T054-06 | Undocumented/rare | Exact SP/return/private values repeated across lifecycle cases | Values NOT REQUIRED/NOT GUARANTEED |
| T054-07 | Boundary | MAXOK43 executed; next fixture produced BAD LOAD | Enforce configured boundary; number/text not universal |

I041 and I043 before/after disk pairs were byte-identical. I042 changed only disposable images through expected assembler/editor/copy/submission work. Eleven rebuilt COM probes were byte-identical. Raw transcripts, sources, binaries, images, and hashes are preserved under `probes/`.

These results reproduce the intended contrasts. They do not provide new evidence for unperformed console-policy, physical-error-presentation, matching-hardware, or CPU-profile cases.

## 8. Compatibility classification

**REQUIRED**

- Documented interfaces and meanings, regardless of whether historical programmers called them conventions.
- A=L and B=H on normal BDOS returns as already established by entries 0039-0040.
- Strict-profile standard SUBMIT stream and XSUB Function-10/interposition compatibility (0620-0621).
- Writable/executable application-owned TPA and self-modifying execution (0622).

**POLICY PENDING**

- Exact formatted-console column/pending-key/editing presentation where the ledger already identifies an observable profile choice.
- Exact logical write-error and fatal-disk-error presentation not fully fixed by documentation.
- Named CPU, terminal, hardware, and non-strict protected-memory profiles.

**NOT GUARANTEED**

- Private-target equivalence, unspecified entry/residual registers and flags, reserved/scratch bytes, failed-call residue, physical enumeration/allocation order, unspecified return residue, and invalid direct-call aftermath.

**NOT REQUIRED**

- Exact numeric SP/return/CCP/BDOS/BIOS addresses, DRI private stacks/tables/algorithms, dispatcher residue, Function-6 E=FEh branch, exact internal update order, and vendor/emulator diagnostic wording.

## 9. Compatibility conclusions

The practical CP/M 2.2 contract is not “all repeatable DRI behavior.” It consists of documented external behavior plus a small number of independently evidenced ecosystem mechanisms. The decisive tests are observability, dependency, stability, and scope.

The current ledger correctly recognizes the principal undocumented/de facto requirements: return aliases, strict-profile SUBMIT/XSUB behavior, reversible flat-memory gateway access sufficient for XSUB, and writable/executable TPA. It also correctly refuses to freeze private targets, residual state, internal data structures, physical ordering, and exact diagnostics.

Fresh execution strengthens both sides of that boundary. A private target can work in one build while remaining nonportable; a repeatable numeric state can remain irrelevant; and an undocumented multi-program protocol can become required because standard shipped software demonstrably depends on it. No contradiction or missing baseline proposition was found.

## 10. Proposed ledger additions

None. The inventory maps to existing independently testable propositions. Adding generic statements such as “support common undocumented behavior” would be ambiguous and duplicate the specific ledger entries. No experimental result justifies a new CP/M requirement.

## 11. Existing-entry updates

No ledger file was modified and no disposition correction is proposed.

At a future authorized integration, `I054 UNDOCUMENTED COMPATIBILITY BEHAVIOR subsystem IG AG` may strengthen:

- 0004, 0008 and related public-vector entries with T054-01, without freezing observed addresses;
- 0591 and 0619 with T054-02/T054-03, sharpening public interposition versus private-target bypass;
- 0620-0621 with T054-04 as another fresh standard SUBMIT/XSUB execution;
- 0622 with T054-05 as another fresh writable/self-modifying TPA execution;
- 0029-0034 and related negative guarantees with T054-06/T054-07, as evidence that repeatable configuration values still need not be universal.

No evidence should be added to an entry whose specific behavior was not exercised. Source-only inventory rows retain their original evidence.

## 12. Open questions

1. Which real software, if any, depends on Function-6 E=FEh, exact ready values, pending-key interaction, or exact Function-10 correction display? (**D**)
2. Should strict console compatibility select exact DRI column/editing behavior, or should terminal profiles state permitted variants? (**D**)
3. Do applications distinguish the unresolved exact sequential/random write failure codes or fatal-disk response characters? (**D**)
4. Which rights-cleared software depends on undocumented Z80 instructions, interrupt modes, or timing, and which named CPU profile should own that dependency? (**D**)
5. Are any historically significant programs private-BDOS-target callers rather than gateway interposers, sufficient to justify an opt-in quirk profile? (**D**)
6. Should a non-strict BetterCP/M profile protect page-zero/system vectors, and how must it disclose that it is not the strict flat-memory profile? (**D**)
7. What differential set of CP/M 2.2 implementations is adequate to demonstrate that a NOT GUARANTEED observation actually varies? (**D**)

## 13. Conformance implications

Conformance tests must identify whether a behavior is public, strict-profile de facto, optional-profile, or deliberately unasserted. They should vary memory size, BIOS placement, media layout, and permitted residue so software cannot accidentally depend on one reference image. Negative tests should accept alternative residual registers, private targets, ordering, and internal algorithms.

A strict ecosystem profile should run the standard SUBMIT/XSUB workflow, reversible gateway interposition, and self-modifying TPA tests in addition to documented API probes. Private-target and invalid-direct-call tests must remain isolated and must never demand recovery state not promised by a selected machine profile. Policy-pending console, physical-error, CPU, and hardware cases must not fail a baseline until their profiles and evidence are selected.

Completion audit: the 13-section report, 21-row inventory, seven validation records, source, 11 byte-identical rebuilt binaries, raw transcripts, before/after images, validation script, and hashes are present; fresh tests are distinguished from inherited evidence; incomplete policy cases are explicit; no unsupported behavior was promoted; no BetterCP/M implementation was created; the authoritative Investigation 053 ledger remained unchanged; prior BetterCP/M files remained unchanged; and no ZIP archive was created.
