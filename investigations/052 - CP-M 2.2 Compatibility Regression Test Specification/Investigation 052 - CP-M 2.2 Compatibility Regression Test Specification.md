# Investigation 052 - CP/M 2.2 Compatibility Regression Test Specification

## 1. Objective and scope

This investigation converts the compatibility contract accumulated through Investigation 051 into a repeatable regression-test specification. It identifies test categories, maps every numbered ledger proposition to a validation class and proposed test, defines expected observations and evidence requirements, and exposes remaining coverage gaps. It does not implement BetterCP/M or design a test framework.

The result is a 62-test proposed inventory covering all 652 current ledger propositions. Coverage includes positive requirements and, equally importantly, tests that prevent incidental, optional, or policy-dependent behavior from becoming an accidental requirement.

## 2. Compatibility standard

Evidence remains separated as **A** documented behavior, **B** DRI implementation behavior, **I** experimental observation, and **D** unresolved policy. Any future ledger evidence from this report must use exactly `I052 TESTING VALIDATION COMPATIBILITY subsystem IG AG`.

Disposition determines validation semantics:

- **REQUIRED:** positive observable pass criterion.
- **NOT GUARANTEED:** variability/non-assertion criterion; at least two conforming variants should be accepted where practical.
- **POLICY PENDING:** profile-gated test that cannot produce a baseline failure until policy selects the profile.
- **NOT REQUIRED:** anti-requirement test; an implementation must not be rejected merely because it omits or changes the incidental behavior.

Tests must validate the external CP/M contract, not internal BetterCP/M structure.

## 3. Relationship to previous investigations

I045 tested cross-layer composition and warned against turning lower-layer observations into upper-layer guarantees. I046 reviewed closure and remaining gaps. I047-I051 supplied utility, toolchain, application, communications, and hardware-profile acceptance evidence. Earlier investigations supplied deterministic probes for CCP, BDOS, BIOS, memory, storage, and errors.

I052 does not supersede those reports. Their reports define evidence and their preserved fixtures are candidate regression assets. I052 supplies stable test identifiers, grouping, expected-result discipline, and a complete ledger-to-test map.

## 4. Compatibility requirement mapping

The authoritative Investigation 051 ledger contains 652 propositions: 445 **REQUIRED**, 109 **NOT GUARANTEED**, 50 **POLICY PENDING**, and 48 **NOT REQUIRED**. `probes/ledger-requirement-map.tsv` extracts every identifier, title, source section, disposition, and conformance statement. `probes/ledger-test-coverage.tsv` assigns each one a validation class and primary proposed tests.

All 652 entries map to at least one test; none are omitted. A single test may validate several tightly coupled propositions, but the coverage file remains proposition-granular. Cross-layer tests supplement rather than replace function-level probes. Duplicate tests are retained only when one is a narrow diagnostic and another is an application-level acceptance path.

Manual validation is limited to genuinely visual, physical, destructive, or named-profile behavior. Register, memory, FCB, DMA, console, BIOS-call, directory, image, and failure results should be automated.

## 5. Test category definitions

| Category | Scope | Principal evidence | Default validation |
|---|---|---|---|
| CCP | Acquisition, parsing, resident commands, lookup, load, tail/FCBs, termination | I021-I024, I028, I032 | Scripted transcript plus memory/image |
| BDOS call/console | Dispatch, registers, console modes, buffering, status | I002-I006, I016, I027 | Instrumented BIOS and register probe |
| BDOS storage/state | Drive, user, DMA, FCB lifecycle, search, sequential/random I/O | I007-I014, I017, I025-I031, I037 | FCB/DMA captures and image diffs |
| BIOS | Jump table, boot, character devices, IOBYTE, disk calls/structures | I018-I020, I035-I040 | Instrumented BIOS and profile fixtures |
| Memory/execution | Page zero, TPA, ceiling, overlays, stack, self-modification | I001, I023-I024, I028, I034, I041-I043 | Memory/register snapshots |
| Error/recovery | Logical/physical errors, restart, damaged media | I015, I025, I033, I044 | Deterministic fault injection |
| Utilities/toolchains | DRI utilities, assembler, linker, debugger workflows | I047-I048 | Scripted workflows and hash checks |
| Applications | Full-screen, interpreter, large multi-file, storage failure | I049 | Transcript/image acceptance |
| Communications | Logical devices, transfer, serial profiles | I050 | Controlled endpoint/profile tests |
| Hardware boundary | Direct ports, MMIO, private peripherals | I051 | Matching-profile checks and isolated traps |

## 6. Regression test inventory

The normative proposed inventory is `probes/regression-test-inventory.tsv`. It contains 62 identifiers with the required area, requirement, procedure, expected result, evidence source, and validation mode.

Inventory totals by prefix are: 8 CCP, 1 general BDOS-call, 5 console, 3 system-state, 12 file, 5 error/recovery, 7 BIOS, 6 memory/execution, 4 utility/toolchain, 4 application, 4 communications, and 3 hardware-boundary tests.

The inventory deliberately groups propositions by reusable fixture and observation boundary. For example, `BDOS-FILE-003` covers Search First/Next, wildcard enumeration, result slot, selected DMA, drive handling, and directory order because one controlled directory/DMA fixture observes them together. The per-entry coverage map preserves independent traceability.

## 7. Software-based validation

Preserved software should be used only where it adds cross-layer evidence:

- DRI resident commands, PIP, STAT, SUBMIT/XSUB, and DDT: utility-profile workflows.
- Assembler/loader/linker/library artifacts from I048: build and executable-generation acceptance.
- WordStar, MBASIC/Wumpus, and Adventure: terminal/file, interpreter, and large multi-file acceptance.
- Generic Kermit: logical-device and communications-profile acceptance.
- IMSAI QTERM, KSCOPE, and VI/Open: named hardware-profile and unsupported-boundary tests.

`probes/preserved-artifact-index.tsv` identifies 257 available COM, harness, observed-output, and README artifacts across the archive. Inclusion in the index does not automatically make an artifact normative. Software-specific text, screen layout, protocol diagnostics, private file formats, and unsupported hardware are not baseline assertions.

Each accepted software workflow must pin the software hash, fixture hash, profile, deterministic input, and OS-level observations it is intended to cover.

## 8. Probe specifications

Every probe specification must state purpose, procedure, expected observation, ledger identifiers, profile, pass/fail boundary, permitted variation, and evidence to preserve. `probes/test-case-template.txt` is the reusable form.

Minimum deterministic probe families are:

1. entry/register/page-zero and call-return sentinels;
2. instrumented console and raw character devices;
3. FCB/DMA/directory and before/after image fixtures;
4. extent, capacity, user, read-only, and malformed-input boundaries;
5. instrumented BIOS jump-table, disk-state, and parameter structures;
6. memory-size, loader-limit, stack, overlay, and self-modifying cases;
7. logical and physical fault injection at exact call counts;
8. cross-layer utility/application workflows;
9. named communications endpoints and hardware-profile traps.

Normal, boundary, and failure cases must use distinct restored fixtures. A hang, warm restart, fatal message, normal return, or trapped unsupported access must be recorded as observed; tests must not normalize unlike outcomes into a generic “error.”

## 9. Coverage analysis

The mapping audit reports 652 mapped entries and zero missing primary tests. Structural coverage is therefore complete, but executable coverage is not.

Strong existing coverage includes BDOS Functions 0-40, FCB/DMA storage, directory semantics, standard BIOS calls, entry/lifecycle, memory layout, utility workflows, selected applications, and unsupported direct-port traps.

Material execution gaps remain:

- successful paired Kermit/XMODEM binary and text transfers;
- receive-side communications failures and carrier loss;
- matching Dazzler, IMSAI VIO, EPROM programmer, raw-FDC, and front-panel runs;
- interrupt-driven serial timing/overrun behavior;
- spreadsheet, database, business application, and BBS packages;
- repeatable matching-profile physical-device tests;
- some destructive damaged-media and raw-controller recovery cases.

These are profile/corpus gaps, not permission to infer behavior. Tests remain disabled or manual until fixtures and policy exist.

Potential duplication exists between narrow probes and ecosystem workflows. Narrow probes are authoritative for byte/register semantics; software workflows test composition. A workflow failure should be reduced with the narrow probe rather than changing several compatibility propositions at once.

## 10. Documentation findings

CP/M documentation (**A**) defines externally observable calls, data structures, boot/vector conventions, and selected error outcomes. It does not prescribe host test architecture, file formats for evidence, emulator internals, or universal third-party compatibility. Therefore the regression contract specifies observations and fixtures, not a BetterCP/M implementation or runner.

Documented silence is itself test-relevant: exact residual registers, physical layout, directory slot, private address, device timing, and post-fatal state must not be asserted unless another evidence class and selected profile supports them.

## 11. Source findings

DRI source (**B**) is useful for identifying paths to stimulate—dispatch, directory scans, BIOS calls, fatal handlers, CCP loading, and restart—but source-only state is not a pass criterion unless it is externally observable and classified by the ledger. Third-party source similarly identifies direct ports, MMIO, timing, or extension assumptions without making them portable.

Tests should instrument boundaries rather than compare internal control flow. An implementation with different code, data placement, caching, allocation strategy, or host storage passes if required observations agree and prohibited over-assertions are avoided.

## 12. Compatibility conclusions

**REQUIRED:** A compatibility implementation must be testable against every applicable REQUIRED proposition using deterministic externally observable criteria; evidence must identify exact inputs/profile and preserve raw results.

**POLICY PENDING:** The enabled application corpus, named terminal/communications/hardware profiles, unsupported-access policy, and certain recovery/destructive tests remain gated decisions.

**NOT GUARANTEED:** One universal result for unspecified registers, internal layout, absent hardware, private interfaces, fatal continuation, and other ledger-defined variations. The suite must accept permitted alternatives.

**NOT REQUIRED:** Testing BetterCP/M's internal design, reproducing incidental DRI algorithms, universal hardware emulation, vendor presentation, or every archived executable.

## 13. Proposed ledger additions

None. Regression methodology is not a CP/M application-visible proposition. All test subjects already have independently numbered ledger entries. Adding “must pass the test suite” would be circular and duplicate the underlying requirements.

## 14. Existing-entry updates

No ledger file was modified and no disposition change is proposed. I052 is a validation index, not new behavioral evidence. At a future authorized integration, `I052 TESTING VALIDATION COMPATIBILITY subsystem IG AG` may be referenced in project test documentation, but it should not be used to manufacture evidence for entries whose behavior was established elsewhere.

The authoritative source for each expected result remains the cited investigation and ledger proposition. If a future test exposes a contradiction, that experiment must be investigated separately before any ledger change.

## 15. Open questions

1. Which POLICY PENDING profiles become mandatory release gates? (**D**)
2. What rights-cleared spreadsheet, database, business, BBS, and communications peer corpus will be preserved? (**D**)
3. Which matching hardware emulations are sufficiently faithful for profile conformance rather than demonstration? (**D**)
4. Which destructive fault tests may run routinely, and which require isolated/manual campaigns? (**D**)
5. What repeat count is sufficient for timing, retry, and asynchronous device behavior? (**D**)
6. Which NOT GUARANTEED propositions need explicit two-implementation differential tests rather than static non-assertion review? (**D**)
7. How should profile manifests identify enabled/disabled tests without turning runner design into the compatibility contract? (**D**)

## 16. Conformance implications

A BetterCP/M release claim should name the baseline plus optional profiles, execute every applicable positive test, evaluate every negative/variability rule, and mark no policy-gated test as failed merely because its profile is absent. Results must remain traceable from test identifier to ledger entry to original evidence.

Evidence preservation requirements are normative for trustworthy results and are listed in `probes/evidence-preservation-requirements.txt`. The suite should restore fixtures before every mutation, compare hashes, capture raw bytes and structured state, and distinguish product defects from fixture defects, permitted variation, policy gaps, and unsupported tests.

### Completion audit

- Report and proposed inventory: present.
- Ledger propositions extracted: 652.
- Disposition totals: 445 REQUIRED, 109 NOT GUARANTEED, 50 POLICY PENDING, 48 NOT REQUIRED.
- Ledger entries with primary-test mapping: 652; missing: zero.
- Proposed regression tests: 62; duplicate identifiers: zero; malformed rows: zero.
- Existing artifact index: present; prior artifacts remained read-only.
- Authoritative ledger before hash: `e6379715a972bb5682f13af9a6fcc8215fc8205ca100e9234343f0f16e0d6153`.
- Ledger modification: none; after hash recorded separately.
- Existing BetterCP/M files outside new I052 directory: protected by manifest comparison.
- BetterCP/M/test-framework implementation: none.
- ZIP archive: none created.
