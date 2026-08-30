# Investigation 058 - CP/M 2.2 Non-CP/M BetterCP/M Feature Boundary

## 1. Objective and scope

This investigation defines the boundary between the required CP/M 2.2 personality and additional BetterCP/M capabilities. It classifies extension categories by compatibility impact, identifies isolation and validation requirements, and specifies where CP/M-visible behavior must remain unchanged.

The categories are analytical examples, not feature proposals, designs or a roadmap. This report does not implement BetterCP/M, choose service/kernel/personality architecture, or modify the Compatibility Ledger or prior evidence.

## 2. Compatibility standard

The reference contract is the practical community standard and personality boundary established through I057. Evidence remains **A** documented CP/M behavior, **B** DRI implementation/software behavior, **I** controlled observation and **D** unresolved policy. Findings retain **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED** and **NOT GUARANTEED**.

Any later ledger citation must use exactly `I058 EXTENSION BOUNDARY COMPATIBILITY subsystem IG AG`.

Classification applies to the compatibility constraint, not to whether BetterCP/M should implement a feature. No extension is required by this investigation. A REQUIRED label means a CP/M observation must remain unchanged; POLICY PENDING means visible behavior requires explicit profile/policy; NOT REQUIRED means CP/M does not demand the feature/mechanism; NOT GUARANTEED means the baseline makes no stable promise for the classified state.

## 3. Relationship to previous investigations

I055 defines baseline, strict community, optional and hardware-profile claims. I056 assigns all ledger propositions to responsibility boundaries. I057 defines the minimum personality as the complete CP/M-visible projection while permitting delegation of execution, memory, storage and devices.

I058 applies a counterfactual test to that mapping: if an additional capability changes or delegates something, which ledger observations must remain, which may vary, and which require a separate profile or interface? `probes/extension-constraint-map.tsv` answers this for all 652 proposition lines (622 unique identifiers because of the known duplicate ledger block).

No new runtime experiment was needed. The extension boundary is derived from already observed/documented behavior, I052 regression mappings and I053/I054 ecosystem validation.

## 4. Compatibility boundary analysis

The CP/M boundary contains every applicable REQUIRED observation: 0100h execution and page zero, CCP command environment, `CALL 0005h` and BDOS Functions 0-40, FCB/DMA/directory/file semantics, configured BIOS ABI, logical sectors, state/lifecycle and classified errors/recovery. A strict community claim also contains standard SUBMIT/XSUB and writable/executable application-owned TPA.

Extensions are safely outside that boundary in three cases:

1. **Hidden observational equivalence:** a private mechanism changes but every CP/M-visible result remains within the ledger contract.
2. **Separate/opt-in surface:** a visible addition uses an explicitly selected interface or profile and leaves the baseline path unchanged.
3. **Named platform/hardware profile:** direct device, media, processor or timing behavior is activated only for the declared environment.

The following must remain unchanged on the baseline path: public addresses/structures and calling conventions; command parsing/search/namespace; record/extent/DMA behavior; configured BIOS table/services; selected console/device semantics; cross-call state; supported termination; and promised failure/recovery results.

NOT GUARANTEED entries provide safe flexibility but not permission to violate related positive requirements. NOT REQUIRED entries permit internal replacement. POLICY PENDING entries cannot be silently resolved by an extension.

## 5. CP/M-visible extension analysis

A visible extension affects compatibility whenever CP/M software can observe it through memory, registers, command lookup, files/directories, console/devices, BIOS calls, timing/status or failure state.

High-risk examples are:

- extra resident commands changing transient lookup precedence;
- new BDOS selectors colliding with reserved/out-of-range results;
- extended names/paths altering FCB and current drive/user rules;
- larger records/files replacing 128-byte DMA and extent behavior;
- transparent text/Unicode conversion changing stored or console bytes;
- multitasking/background mutation changing global state/search/order;
- memory protection blocking page-zero hooks, overlays or self-modification;
- extra devices or structured errors appearing on baseline paths;
- timestamps/attributes occupying reserved directory/FCB fields;
- automatic path/search/user conveniences replacing CCP namespace rules.

Visibility is not automatically incompatibility. A visible extension can be compatible when explicitly opt-in, separately named and collision-free, and when entry/exit restores coherent CP/M state. A CP/M program that does not select it must continue to receive baseline behavior. The extension must not cause ordinary software to mistake new results for CP/M 2.2 semantics.

## 6. Compatibility-neutral feature analysis

Classes of improvement can be neutral when hidden behind the personality boundary:

- performance optimizations;
- internal caching and buffering;
- alternate memory, storage, disk-image, terminal or host-device backing;
- internal reliability/redundancy;
- out-of-band management, telemetry and diagnostics;
- private extra metadata;
- separate non-CP/M command/UI or application environments;
- test and evidence infrastructure.

Neutrality is conditional, not categorical. Caching ceases to be neutral if close persistence or media-change state shifts. Extra metadata ceases to be neutral if directory order/attributes change. Diagnostics cease to be neutral if they consume CP/M console, memory or files. A separate shell ceases to be neutral if it alters CP/M parsing, lookup or return state.

Evidence for neutrality is therefore regression equivalence, not an architectural assertion. The applicable narrow tests and corpus workflows must produce the same classified CP/M observations with the feature disabled and enabled.

## 7. Compatibility risk analysis

The nine primary risk surfaces are entry/memory, CCP, BDOS calls, console, system state, files/directories, BIOS/platform, errors/recovery and strict ecosystem behavior. `probes/risk-preservation-matrix.tsv` records required observations, unsafe transparent changes, safe boundary conditions and tests.

The largest risks are semantic substitution and leakage:

- replacing CP/M names, records, extents, user areas or errors with host abstractions;
- exposing host terminal editing/encoding instead of BDOS behavior;
- introducing selector/command collisions;
- making background activity mutate state CP/M treats as coherent across calls;
- presenting host exceptions, atomicity or retry guarantees as CP/M behavior;
- protecting memory in a personality claiming XSUB/self-modifying compatibility;
- advertising every configured emulator device as generic CP/M.

Changes in these areas require a separate compatibility mode/profile unless observational equivalence can be proved. A “better” modern behavior is still incompatible when historical software sees a changed CP/M contract.

## 8. Personality and extension separation

The personality retains accountability for CP/M-visible semantics. External mechanisms may supply CPU execution, memory backing, storage, disk/controller access, terminal transport, character/serial devices, scheduling or fault detection. Extensions may live alongside or beneath those mechanisms.

Personality cooperation is required when an extension enters/leaves CP/M execution, adds a visible API/profile, shares files/devices/state, or affects recovery. Cooperation means the personality must:

- declare applicability;
- prevent collision with baseline commands/calls/data;
- translate shared resources into CP/M semantics;
- restore coherent CP/M-visible state on return;
- preserve strict-profile behaviors when that profile is claimed.

Features entirely outside the CP/M personality need no CP/M semantics until they share an observable resource or advertise a CP/M claim. The boundary is behavioral rather than structural: no module split or service architecture is implied.

## 9. Validation requirements

Before enabling an extension under a CP/M claim:

1. Bind the test to the authoritative ledger hash and declare baseline/strict/platform/optional/hardware profiles.
2. Run every applicable I052 narrow test with the extension disabled and enabled.
3. Run affected I053 corpus workflows to verify composition.
4. Compare raw registers, memory, FCB/DMA, console/BIOS activity, files and disk images.
5. Demand observational equivalence for REQUIRED entries.
6. Keep POLICY PENDING behavior inactive/diagnostic unless a named profile selects it.
7. Verify NOT GUARANTEED results are not accidentally advertised as new baseline guarantees.
8. Confirm NOT REQUIRED DRI mechanisms are absent from acceptance criteria.
9. Test entry to and return from visible extensions for state leakage.
10. Preserve extension version/profile, fixtures, transcripts and hashes.

`probes/validation-policy.txt` is the reusable checklist. `probes/extension-boundary-classifications.tsv` maps 26 categories to specific evidence, isolation and validation requirements.

## 10. Compatibility conclusions

**REQUIRED:** Every extension must preserve all applicable REQUIRED CP/M observations on the declared personality path. Delegation, optimization and added capability do not weaken that obligation.

**POLICY PENDING:** CP/M-visible additions—new commands/calls/namespaces, console/device behavior, communications, errors, memory protection/banking, processor or hardware capabilities—require explicit profile/policy unless already observationally neutral.

**NOT GUARANTEED:** Extensions may vary state the ledger leaves unspecified, but must not convert one result into a baseline promise or leak provider-specific assumptions.

**NOT REQUIRED:** CP/M compatibility does not require any BetterCP/M extension, DRI private mechanism, internal optimization, management facility or modern abstraction.

The safe extension boundary is therefore: hidden equivalence, explicit opt-in, or named profile. Transparent semantic replacement is outside a valid CP/M 2.2 compatibility claim.

## 11. Proposed ledger additions

None. BetterCP/M feature categories and isolation policy are not CP/M application-visible requirements. Adding them to the Compatibility Ledger would mix product extension governance with the historical compatibility contract.

No tested evidence indicates a missing CP/M proposition or disposition correction. The existing REQUIRED/POLICY PENDING/NOT GUARANTEED/NOT REQUIRED structure already supplies the preservation rules used here.

## 12. Existing-entry updates

No ledger file was modified and no wording or disposition update is proposed.

At a future authorized integration, `I058 EXTENSION BOUNDARY COMPATIBILITY subsystem IG AG` may appear in extension-conformance documentation or traceability metadata. It should not be added as runtime evidence for individual ledger entries because this review performs no new behavioral experiment.

The complete chain remains: ledger proposition -> I052 test -> I056 responsibility -> I057 personality treatment -> I058 extension constraint.

## 13. Open questions

1. What collision-free mechanism will identify opt-in extension calls or command namespaces without changing the baseline? (**D**, boundary only—not design selected here)
2. Which optional features, if any, will be visible from the first CP/M personality claim? (**D**)
3. Will protected memory, multitasking or extended filesystem behavior use separate personality labels? (**D**)
4. How will shared files/devices be mediated so non-CP/M metadata, naming and concurrency cannot leak into CP/M behavior? (**D**)
5. Which processor, terminal, communications, disk and hardware extension profiles receive stable names? (**D**)
6. What timing/repetition threshold proves an optimization is neutral for blocking/status/retry behavior? (**D**)
7. How will an extension failure return to a coherent CP/M state without inventing rollback guarantees? (**D**)
8. What release artifact binds extension versions to ledger/test/profile hashes? (**D**, process)

## 14. Conformance implications

A BetterCP/M extension claim is separate from a CP/M compatibility claim. The latter remains valid only if its complete applicable suite passes with extensions enabled and disabled, and if visible additions are named rather than silently changing baseline semantics.

The 652-row extension constraint map can serve as a review gate: REQUIRED rows demand preservation; POLICY PENDING rows demand explicit applicability; NOT GUARANTEED rows demand non-assertion; NOT REQUIRED rows prohibit unnecessary coupling to DRI internals. The 26-category review identifies likely collision surfaces without prescribing features or architecture.

Final review confirms that compatibility requirements are separated from extensions, boundaries are evidence-based, architecture assumptions are absent, and compatibility risks and unresolved policy choices are explicit.

Completion audit: this 14-section report, 652-line extension map, 26 feature-category classifications, nine-surface risk matrix, validation policy, generator, validation output, source mappings and hashes are present; the authoritative Investigation 057 ledger remained unchanged; no previous BetterCP/M file or implementation changed; and no ZIP archive was created.
