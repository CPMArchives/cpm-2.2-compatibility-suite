# Investigation 057 - CP/M 2.2 Required CP/M Personality Boundary

## 1. Objective and scope

This investigation defines the minimum CP/M personality boundary required by the established CP/M 2.2 compatibility contract. It identifies which observations must be presented to CP/M software, which mechanisms may be delegated, what state remains accountable at the boundary, and what must be excluded from the promise.

“Personality” here means the logical projection of CP/M-visible semantics. It does not imply one module, process, privilege level, address space, kernel component, service or implementation technique. This report neither designs nor implements BetterCP/M and does not modify the Compatibility Ledger.

## 2. Compatibility standard

The personality must satisfy the applicable practical community standard established through I055 and the responsibility mapping in I056. Evidence remains **A** documented behavior, **B** DRI implementation/distributed-software behavior, **I** controlled observation and **D** unresolved policy. Findings retain **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED** and **NOT GUARANTEED**.

Each mapping records the compatibility requirement, evidence, personality responsibility, validation method, classification and delegation boundary. Any later ledger citation must use exactly `I057 PERSONALITY BOUNDARY COMPATIBILITY subsystem IG AG`.

The decisive rule is accountability: a mechanism may live outside the personality, but if its result is part of a declared CP/M claim, the personality boundary must project the classified CP/M-visible observation and prevent incompatible provider details from leaking through.

## 3. Relationship to previous investigations

I055 defines baseline, strict community, optional and hardware-profile conformance categories. I056 assigns every ledger proposition line to a responsibility boundary and regression test without prescribing internal architecture. I052 supplies the 62-test inventory; I053 verifies representative software composition; I054 validates the documented/de facto/private distinction.

I057 converts I056 ownership into personality inclusion, delegation and exclusion rules. `probes/personality-requirement-map.tsv` covers all 652 proposition lines (622 unique identifiers, reflecting the known duplicated 0248-0277 ledger block). No proposition is missing or remapped semantically.

## 4. Personality responsibility analysis

For the 445 REQUIRED proposition lines, the minimum personality accountability is:

| Personality responsibility | Lines | Required projection |
|---|---:|---|
| CP/M BDOS call/state/service semantics | 318 | Public gateway, console/system state, FCB/DMA, directory/file/storage behavior |
| CP/M CPU/memory/entry/lifecycle view | 43 | 0100h entry, page zero, TPA bounds/ownership, supported termination and recovery handoff |
| CP/M command environment | 38 | CCP acquisition/parsing, resident commands, launch state, lookup/load and command-cycle return |
| CP/M BIOS ABI/configured structures | 27 | Discoverable jump table, boot, raw character paths, logical sectors and disk parameters |
| CP/M result/recovery boundary | 19 | Classified logical/physical failure presentation and promised restart/reset/reopen state |

The remaining proposition lines define the edge of responsibility: 50 POLICY PENDING observations are profile-gated, 109 NOT GUARANTEED observations must not be published as stable promises, and 48 NOT REQUIRED mechanisms are excluded from personality acceptance criteria.

The strict community claim adds standard SUBMIT/XSUB interoperation and writable/executable application-owned TPA. Optional and hardware-profile responsibilities activate only when named. The personality need not own physical execution, memory, disk or terminal mechanisms, but it owns the compatibility result for every mechanism used by its claim.

## 5. CP/M-visible interface boundary

The required boundary presented to CP/M software contains:

- **Execution and memory view:** compatible transient execution at 0100h, configured load ceiling, documented page-zero objects, default FCB/tail/DMA locations, application-owned TPA semantics and supported termination paths.
- **Command environment:** CP/M command acquisition/parsing, resident commands, default launch preparation, COM lookup/load/dispatch and restoration of a valid command cycle.
- **BDOS interface:** `CALL 0005h`, selector/input/result aliases, returning-call stack behavior, Functions 0-40 and all classified console, state, DMA, FCB, directory, namespace and file observations.
- **BIOS interface:** configured discoverable jump table, boot behavior, raw character-device paths, logical-sector disk ABI and coherent DPH/DPB/translation structures.
- **Persistent/application state:** current drive/user, login/read-only vectors, selected DMA, directory/file state, extents, allocation-visible persistence and lifecycle transitions.
- **Failure/recovery view:** documented logical results, declared physical-error presentation and only the post-recovery state actually promised.
- **Strict ecosystem surface:** standard SUBMIT/XSUB behavior and writable/executable TPA where that claim is made.

State preservation is functional, not blanket register or memory preservation. The personality preserves only state explicitly required across a call, launch, file lifecycle or recovery boundary. Residual registers, reserved bytes, private targets, failed-call contents and physical ordering remain governed by their NOT GUARANTEED/NOT REQUIRED entries.

## 6. Compatibility isolation analysis

The following mechanisms may be outside the personality implementation while remaining behind its compatibility boundary:

- processor execution and memory backing/protection;
- physical or host storage, disk images and controllers;
- terminal transport and character/serial devices;
- scheduling, timing and concurrency machinery;
- error detection, retry and unwind mechanisms;
- CCP parser/loader internals;
- test and evidence infrastructure.

Delegation is valid only when the personality projects CP/M semantics. Host filenames cannot replace FCB naming; host byte streams cannot erase 128-byte record/extent behavior; host terminal editing cannot replace BDOS Function-10 rules; host exceptions cannot become CP/M error codes; and protected memory cannot contradict a selected strict flat-memory/interposition claim.

Private DRI stacks, tables, targets, call graphs, caching, allocation algorithms, update order and exact diagnostics should be isolated from CP/M software because they are NOT REQUIRED. Provider-specific state must not become a new accidental ABI. `probes/delegation-boundaries.tsv` records these constraints.

## 7. Software compatibility analysis

The proposed boundary explains the tested corpus:

- DRI utilities and development tools remain within the CCP/page-zero/BDOS/FCB/memory/lifecycle personality surface.
- SUBMIT/XSUB crosses CCP, writable gateway and BDOS Function-10 responsibilities, but all crossings remain CP/M-visible strict-personality obligations.
- WordStar uses personality file/console semantics plus a declared terminal profile; terminal transport may remain external.
- BASIC/Wumpus and Adventure use the personality runtime, console, files and lifecycle while execution/storage mechanisms may be delegated.
- Generic Kermit uses CP/M logical devices and files; a successful peer/serial endpoint belongs to an optional communications profile.
- IMSAI QTERM and KSCOPE load through the personality but cross into direct hardware ports. Their absent-port traps correctly fall outside baseline; matching behavior belongs to named hardware profiles.

Thus no tested software assumption falls into an unexplained gap. Some software crosses from personality semantics to profile/platform behavior, but the crossing is explicit and already represented. Successful paired communications and matching hardware remain evidence gaps, not missing personality interfaces.

## 8. Validation ownership

The personality is the primary acceptance owner for CCP, BDOS and memory test families. It jointly owns BIOS and error results with configured platform/device providers. Optional communications and hardware tests are active only for declared profiles.

- `CCP-001..008`: command environment and strict submitted-input surface.
- `BDOS-CALL-001`, `BDOS-CON-001..005`, `BDOS-STATE-001..003`, `BDOS-FILE-001..012`: public service/state surface.
- `MEM-001..006`: CP/M execution, memory, lifecycle and private-target boundary.
- `BIOS-001..007`: personality-visible ABI, jointly validated with platform/hardware provider.
- `ERROR-001..005`: personality result/recovery, jointly validated with fault-producing provider.
- `UTIL`, `APP`, `COMM`, `HW`: cross-layer acceptance and profile composition.

The test runner and evidence store remain outside the runtime personality. They validate its declaration but are not CP/M-visible requirements. `probes/validation-ownership.tsv` provides the complete family mapping.

## 9. Remaining questions

The baseline boundary is complete. Unresolved personality scope follows existing policy choices:

- whether “strict community” is part of the default personality claim or a distinct tier;
- which exact console/pending-key/editing/presentation behaviors become a strict console profile;
- which IOBYTE, logical-device, terminal and communications mappings are advertised;
- how exact physical-error presentation and late-fault state are divided between personality and provider profiles;
- which processor extensions, direct ports, MMIO, controllers and peripherals belong to named profiles;
- whether a protected non-strict personality intentionally omits gateway interposition or other flat-memory behavior;
- what profile manifest binds these choices to tests and evidence.

No ledger proposition lacks personality treatment. Additional investigation is needed only to select or evidence a profile, not to discover another generic CP/M personality boundary.

## 10. Compatibility conclusions

**REQUIRED:** The personality claim presents every applicable CP/M-visible entry, memory, CCP, BDOS, BIOS ABI, state, storage, lifecycle and recovery observation. Delegated mechanisms do not reduce personality accountability. Strict community claims include SUBMIT/XSUB and writable/executable TPA.

**POLICY PENDING:** Console/device/communications/error/processor/hardware behavior whose applicability depends on a selected profile. If selected, the personality must expose the profile's CP/M-visible portion and coordinate its provider.

**NOT GUARANTEED:** The personality must not promise unspecified registers/residue, private-target equivalence, physical order/allocation, invalid-call aftermath, absent hardware behavior or other classified variation.

**NOT REQUIRED:** The personality need not reproduce DRI private structures/algorithms/addresses, host mechanisms, exact vendor UI or unselected diagnostics.

The minimum personality boundary is therefore the complete observable CP/M projection, not ownership of every underlying mechanism. It is small in architectural prescription but comprehensive in semantic accountability.

## 11. Proposed ledger additions

None. “Inside the personality” and “delegated provider” are responsibility labels, not independently observable CP/M behavior. Adding them to the ledger would mix implementation accountability with the compatibility contract and duplicate existing propositions.

No result warrants a disposition change or a new umbrella personality requirement. The known duplicate ledger block remains editorial work outside this investigation.

## 12. Existing-entry updates

No Compatibility Ledger file was modified and no wording or disposition correction is proposed.

At a future authorized integration, `I057 PERSONALITY BOUNDARY COMPATIBILITY subsystem IG AG` may be referenced in design/conformance traceability to show whether an entry is personality-visible, profile-gated, deliberately unguaranteed or excluded. It is not new behavioral evidence and should not replace the original **A/B/I/D** sources.

The full traceability chain is preserved: ledger proposition -> I052 regression test -> I056 responsibility owner -> I057 personality/delegation treatment.

## 13. Open questions

1. Will the default product claim include strict community behavior, or expose baseline and strict as distinct personalities? (**D**)
2. How will profile manifests distinguish personality-visible semantics from provider capabilities without revealing architecture? (**D**)
3. Which of the 50 POLICY PENDING propositions activate in the first personality declaration? (**D**)
4. What processor baseline and optional instruction/timing profiles will be declared for historical software? (**D**)
5. How will a protected-memory personality label incompatibility with XSUB-style interposition and self-modifying expectations? (**D**)
6. What evidence makes an emulator/device provider sufficient for a named hardware-profile claim? (**D**)
7. Who owns late-write-failure mutation evidence when storage is delegated but CP/M-visible file state belongs to the personality? (**D**, validation coordination)
8. Should the personality map become a maintained companion artifact after the ledger duplicate block is normalized? (**D**, maintenance)

## 14. Conformance implications

A personality conformance declaration identifies its ledger hash, baseline/strict tier, processor assumption, configured BIOS/platform and every optional/hardware profile. Every applicable REQUIRED row receives a positive test; POLICY PENDING rows are either selected with tests or explicitly inactive; NOT GUARANTEED rows receive non-assertion/variation treatment; NOT REQUIRED rows are excluded from design gates.

Provider substitution is a key test of the boundary. Changing memory backing, storage, terminal or device implementation must leave required CP/M observations unchanged. Conversely, varying private addresses, residue, allocation order and internal algorithms must not cause conformance failure. Cross-layer corpus tests verify that personality and providers compose.

Final review confirms that personality responsibilities are evidence-based, requirements remain separated from implementation structure, unsupported architecture assumptions are absent, every proposition line has personality/delegation treatment, and all remaining questions are profile or validation choices.

Completion audit: this 14-section report, 652-line personality map, 17 consolidated mappings, delegation/software/validation analyses, generator, validation output, source traceability and hashes are present; the authoritative Investigation 056 ledger remained unchanged; no previous BetterCP/M file or implementation changed; one new I058 prompt appeared externally during the run and is disclosed in the protected-file audit; and no ZIP archive was created.
