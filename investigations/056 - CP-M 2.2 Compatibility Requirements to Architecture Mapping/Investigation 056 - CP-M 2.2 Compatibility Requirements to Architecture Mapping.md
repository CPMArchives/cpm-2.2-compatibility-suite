# Investigation 056 - CP/M 2.2 Compatibility Requirements to Architecture Mapping

## 1. Objective and scope

This investigation maps the established CP/M 2.2 compatibility contract to responsibility boundaries. It identifies which boundary must own each external observation, where coordination is required, what can be isolated behind profiles or abstractions, and which apparent constraints are merely implementation choices.

It does not design BetterCP/M. The terms “boundary” and “owner” describe responsibility for observable behavior, not a required module, process, privilege level, service, address space, data structure or algorithm. No implementation or Compatibility Ledger change is made.

## 2. Compatibility standard

The mapping preserves the community standard defined through I055: documented CP/M behavior (**A**), externally significant DRI behavior (**B**), controlled observation (**I**) and unresolved policy (**D**). Applicable findings remain **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED** or **NOT GUARANTEED**.

Every mapping records a requirement, evidence source, responsible boundary, validation method and classification. Any future ledger citation from this report must use exactly `I056 ARCHITECTURE MAPPING COMPATIBILITY subsystem IG AG`.

An architectural responsibility exists only where some boundary must produce, preserve or coordinate an external observation. The evidence does not constrain how that boundary is implemented unless the implementation property is itself observable—for example writable/executable application-owned memory in the strict profile.

## 3. Relationship to previous investigations

I052 maps all 652 ledger proposition lines to 62 regression tests. I053 shows that those requirements compose for a representative software corpus. I054 confirms the distinction between justified de facto behavior and implementation residue. I055 defines baseline, strict community, optional and hardware-profile claims.

I056 uses those artifacts as inputs. `probes/requirement-responsibility-map.tsv` maps every proposition line; `probes/architecture-mapping-review.tsv` consolidates them into 15 evidence-based ownership conclusions. No new runtime experiment was required because this investigation assigns already evidenced observations rather than discovering behavior.

The ledger still contains the known duplicate 0248-0277 block: 652 proposition lines correspond to 622 unique identifiers. Both duplicate occurrences map identically and do not create distinct responsibilities.

## 4. Requirement ownership analysis

The proposition-level mapping assigns primary ownership as follows:

| Responsible boundary | Proposition lines | Principal ownership |
|---|---:|---|
| BDOS file/directory/storage | 291 | FCB/DMA, directory, namespace, sequential/random I/O, extents, allocation-visible persistence |
| BDOS console services | 90 | Functions 1, 2, 6, 9, 10, 11 and observable console state |
| Transient runtime/memory | 65 | load/entry, page zero, TPA limits, writable/executable application storage, termination handoff |
| CCP/command environment | 60 | acquisition/parsing, resident commands, launch preparation, lookup/load and return cycle |
| BDOS system/disk state | 44 | drive/user/DMA/login/read-only/reset state |
| BIOS configured platform | 39 | boot, jump table, character devices, disk ABI and parameter structures |
| Cross-layer error/recovery | 38 | logical/physical failure propagation and promised recovery |
| BDOS public call | 25 | gateway, selector/input/results and returning-call convention |

These counts identify a primary validation owner, not exclusive implementation jurisdiction. Many propositions require interfaces between owners. For example, directory semantics belong to the BDOS file boundary while sector transfer belongs to the configured BIOS boundary; the required result arises from their composition.

Profile/claim selection owns applicability, not runtime semantics. Validation/evidence owns traceability, not operating-system behavior. Their responsibilities are described separately because neither is a ledger runtime subsystem.

## 5. Compatibility boundary analysis

Some behavior must be preserved directly at the application-visible boundary: 0100h entry, documented page-zero objects, `CALL 0005h`, BDOS results/side effects, FCB/DMA bytes, CCP launch state, discoverable BIOS vectors, logical sectors and required lifecycle/error outcomes. Different internals are acceptable only if these observations remain.

Other behavior may be supplied through abstraction or isolation:

- physical storage may use any backing representation beneath the required logical-sector and file semantics;
- host consoles/devices may sit beneath BIOS and profile boundaries while preserving raw/formatted distinctions;
- private state, caching, parsing, allocation and retry mechanisms may be reorganized;
- named terminal, communications, hardware and error-presentation behavior may be confined to declared profiles;
- cross-platform adaptation may occur below the BIOS/platform boundary.

Abstraction is not permission to replace CP/M semantics with a modern model. A host filesystem abstraction, for example, must still reproduce the required FCB, record, extent, directory, user and persistence observations and must not leak host ordering, naming or error assumptions where CP/M differs.

NOT GUARANTEED behavior may vary intentionally without affecting conformance. NOT REQUIRED mechanisms impose no architecture constraint. POLICY PENDING behavior must remain profile-gated or diagnostic until selected.

## 6. Layer responsibility analysis

The logical interfaces between responsibilities are:

- **CCP -> transient runtime:** supply the required page-zero/FCB/tail state, load within the configured TPA, transfer control and regain a valid command cycle after supported termination.
- **Transient/CCP -> BDOS public call:** preserve the documented gateway and register convention without exposing a private target as a promise.
- **BDOS call -> console/state/file responsibilities:** dispatch the public function while coordinating state visible across later calls.
- **BDOS console -> BIOS character paths:** retain the distinction between formatted BDOS behavior and raw configured devices.
- **BDOS file/state -> BIOS disk:** translate application-visible files, directories, DMA and state into configured logical-sector operations without shifting BDOS policy into direct BIOS calls.
- **BIOS -> configured platform:** present the documented jump-table ABI independent of physical/host implementation.
- **Error/recovery across all boundaries:** distinguish logical results from BIOS/media failures and restore only the state promised after the selected recovery path.
- **Profile selection -> all boundaries:** state which optional or hardware observations are applicable before testing.

Responsibility is clearest where the ledger defines a public interface. It is necessarily cross-layer for warm restart, media errors, storage mutation, SUBMIT/XSUB interposition and profile-driven device routing. Cross-layer ownership means coordinated acceptance criteria, not a required central coordinator.

`probes/responsibility-boundaries.tsv` records ownership, interfaces, allowable isolation and prohibited inference for each boundary.

## 7. Validation mapping

All 652 proposition lines retain at least one I052 primary regression test and none remains unassigned. The mapping uses the first primary test as the responsible validation boundary while preserving every listed supplemental test.

- CCP responsibility: `CCP-001` through `CCP-008`.
- Public BDOS/console/state/file responsibility: `BDOS-CALL-001`, `BDOS-CON-001` through `005`, `BDOS-STATE-001` through `003`, and `BDOS-FILE-001` through `012`.
- Error/recovery responsibility: `ERROR-001` through `005`.
- BIOS/platform responsibility: `BIOS-001` through `007`.
- Runtime/memory responsibility: `MEM-001` through `006`.
- Ecosystem/profile composition: `UTIL-001` through `004`, `APP-001` through `004`, `COMM-001` through `004`, and `HW-001` through `003`.

REQUIRED mappings have positive criteria. POLICY PENDING mappings remain diagnostic/profile-gated. NOT GUARANTEED mappings validate permitted variation or forbid assertions. NOT REQUIRED mappings are anti-requirements: alternate internal mechanisms must pass.

Evidence preservation remains cross-cutting. Each test identifies its profile, inputs, register/memory/FCB/DMA/console/BIOS/image observations, and hashes. A corpus failure is reduced at the mapped boundary before responsibility is reassigned.

## 8. Implementation independence analysis

Compatibility constrains outcomes and a few observable properties. It requires that some responsibility can produce the public interface, maintain cross-call state, preserve selected flat-memory behavior, implement configured BIOS semantics and coordinate promised recovery. It does not prescribe how many internal layers exist.

The evidence leaves free:

- module, kernel, task, process, privilege and address-space organization;
- implementation language, internal API, scheduler and concurrency model;
- dispatch tables, private stacks, caches, buffer representation and algorithms;
- backing store, disk-image, host-filesystem, terminal and emulator integration;
- directory search, allocation and update strategies where exact choices are unpromised;
- instrumentation and regression-runner design.

Even a property often associated with architecture must be phrased externally. “Writable/executable TPA” constrains what a transient can observe; it does not require one global physical address space. “Discoverable BIOS jump table” constrains the CP/M-visible memory interface; it does not dictate how handlers are implemented behind it.

`probes/implementation-independence.txt` supplies the complete constraint/freedom review.

## 9. Remaining questions

Unresolved ownership follows unresolved policy rather than an unidentified baseline subsystem:

- exact console column, pending-key, editing and presentation behavior belongs jointly to BDOS console semantics and a selected terminal/strict-console profile;
- IOBYTE/logical-device claims require a profile to state advertised paths and absent-device behavior;
- communications timing, peer and carrier behavior crosses application, logical device and platform profiles;
- exact physical-error presentation and late-fault mutation state crosses BIOS, BDOS file and recovery responsibilities;
- direct ports, MMIO, controllers and peripherals belong to named hardware profiles, but profile fidelity criteria remain unsettled;
- protected/non-strict memory behavior must disclose which flat-memory/interposition strict requirements it does not claim.

No current ledger proposition is unassigned. Further investigation is needed only to resolve a policy/profile or expand evidence, not to invent an architectural owner.

## 10. Compatibility conclusions

**REQUIRED:** Every applicable REQUIRED proposition has a boundary responsible for its external observation and existing tests. Cross-boundary requirements must compose without changing CP/M-visible semantics. Strict community claims additionally own SUBMIT/XSUB and writable/executable TPA observations.

**POLICY PENDING:** Ownership/applicability of optional console, device, communications, extension, error and hardware behavior remains provisional until a profile is selected.

**NOT GUARANTEED:** Boundaries must tolerate unspecified registers, residue, ordering, private targets, invalid-call aftermath and other permitted variation; architectures must not accidentally publish them as stable interfaces.

**NOT REQUIRED:** No boundary is required to reproduce DRI's private addresses, stacks, tables, call graphs, cache/allocation algorithms, exact internal update order or host mechanisms.

The compatibility contract requires responsibility separation conceptually, but not a particular BetterCP/M architecture. The full contract can be assigned and validated without choosing an implementation design.

## 11. Proposed ledger additions

None. Responsibility mappings are design-accountability metadata, not application-visible CP/M behavior. Adding an entry such as “BDOS owns file semantics” would describe organization rather than an independently testable external proposition and would duplicate the underlying file entries.

The mapping also creates no reason to renumber or otherwise alter the known duplicate ledger block. Editorial normalization remains separately authorized work.

## 12. Existing-entry updates

No ledger file was modified and no disposition or wording correction is proposed.

At a future authorized integration, `I056 ARCHITECTURE MAPPING COMPATIBILITY subsystem IG AG` may be used in design traceability or conformance documentation to link requirements to responsibility and tests. It should not be added as behavioral evidence unless a later experiment actually observes the proposition.

The normative behavioral evidence remains the cited investigation for each ledger entry. I056's value is complete ownership and validation traceability: 652 proposition lines, 622 unique identifiers, zero unassigned mappings.

## 13. Open questions

1. What public names will the project give the responsibility boundaries without implying a fixed module architecture? (**D**, terminology)
2. How will a profile manifest express applicability where one requirement crosses CCP, BDOS, BIOS and platform ownership? (**D**, process)
3. Which POLICY PENDING console/device/error propositions will be selected, thereby fixing their final validation owner? (**D**)
4. What transaction/evidence boundary is sufficient for late physical write failure without requiring universal atomicity? (**D**)
5. How will a non-strict protected-memory claim disclose incompatibility with XSUB-style gateway interposition and other strict flat-memory behavior? (**D**)
6. Which matching hardware environments are faithful enough to activate hardware-profile responsibility? (**D**)
7. Should responsibility metadata become a maintained companion to the ledger after its known duplicate block is normalized? (**D**, maintenance)
8. How will cross-boundary failures be triaged without turning test ownership into runtime architecture? (**D**, process)

## 14. Conformance implications

A conformance claim should bind each applicable ledger proposition to one primary responsibility owner, its supplemental cross-layer participants, enabled profile and test evidence. Passing the narrow owner test is necessary; passing the ecosystem workflow confirms composition. Neither permits untested internal assumptions.

Architecture reviews can use `probes/requirement-responsibility-map.tsv` as a coverage checklist: every REQUIRED observation needs an accountable boundary; every POLICY PENDING row needs an explicit profile state; every NOT GUARANTEED row needs a non-assertion/variation strategy; every NOT REQUIRED row must be absent from mandatory design criteria.

Final review confirms that requirements are separated from implementation design, all mappings are evidence-based, unsupported architectural assumptions are removed, cross-layer and policy questions are explicit, and no proposition remains without ownership or validation.

Completion audit: this 14-section report, 652-line requirement map, 15 consolidated mappings, boundary/interface review, implementation-independence analysis, validation script, source traceability and hashes are present; the authoritative Investigation 055 ledger remained unchanged; no prior BetterCP/M file or implementation was changed; and no ZIP archive was created.
