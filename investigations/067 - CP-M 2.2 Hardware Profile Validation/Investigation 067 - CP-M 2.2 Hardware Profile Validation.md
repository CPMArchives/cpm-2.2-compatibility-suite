# Investigation 067 - CP/M 2.2 Hardware Profile Validation

## 1. Objective and scope

This investigation validates the boundary between generic CP/M 2.2 compatibility and named processor, BIOS, machine, and peripheral profiles. It uses fresh portable and processor controls on isolated z80pack profiles and incorporates preserved matched/mismatched peripheral evidence from Investigations 051 and 065. It does not design BetterCP/M hardware, add emulator support, modify the Compatibility Ledger, or make an untested machine claim.

Evidence classes are **A** (documented), **B** (DRI or preserved implementation), **I** (experiment), and **D** (policy). Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Later ledger integration must identify this evidence as `I067 HARDWARE PROFILE VALIDATION subsystem IG AG`.

## 2. Relationship to previous investigations

I051 established that portable CP/M use can continue until a program crosses into direct ports, MMIO, firmware, timing, interrupts, or controller state. I056/I057 assigned generic personality and delegated hardware responsibilities. I063 established an 8080-compatible binary baseline and a separate Z80 profile. I065 validated one matched IMSAI SIO/QTERM endpoint. I066 kept physical-fault mechanisms below the CP/M-visible error/recovery boundary.

I067 tests whether those layers form a usable claim structure. They do. The new observations add cross-machine controls and a negative generic-conformance result; they do not justify device-named universal propositions.

## 3. Hardware profile corpus

The complete corpus is `probes/hardware-profile-corpus.tsv`.

| Profile | Principal characteristics | I067 treatment |
|---|---|---|
| Generic binary CP/M | 8080-compatible execution, page zero, BDOS, standard BIOS vector | Fresh processor and service controls |
| Cromemco Z-1 CP/M | Z80/4 MHz configuration, RDOS boot, Cromemco FDC, TU-ART, MMU | Fresh BASE051 run |
| IMSAI CP/M 2.2 B03 | 8080 machine profile, MPU/FIF/SIO/VIO configuration, nominal 2 MHz | Fresh BASE051 and exact Function 12 diagnostic; inherited matched QTERM |
| Intel 8080 processor | Documented 8080 instruction profile | Fresh CPU8080 and mismatch runs |
| Zilog Z80 processor | 8080 subset plus documented Z80 extensions | Fresh CPU8080/CPUZ80 runs |
| Mostek mismatch fixture | Standard CP/M services without IMSAI SIO or Dazzler profile | Inherited I051 QTERM/KSCOPE controls |
| Altair and Intel MDS | Controller/front-panel/VDM and DRI-reference integrations | Inventory/source only; not executed |

No successful Dazzler, VIO, printer, paper-tape, raw-controller, front-panel, physical serial, Altair, or Intel MDS behavior is claimed.

## 4. Hardware dependency analysis

**A/B.** Generic CP/M exposes service contracts and the configured BIOS vector, not a universal port map or peripheral. The reviewed corpus depends variously on display ports/MMIO, keyboard encoding, serial ready/data bits, printer/reader/punch routing, floppy controllers, processor extensions, timing loops, interrupt policy, memory maps, and vendor firmware.

**I.** I051 QTERM and KSCOPE printed through CP/M before trapping at unadvertised `IN 23h` and `OUT 0Eh`. I065 QTERM exchanged exact bytes when the IMSAI SIO profile and peer were present. The same application category therefore supports both halves of the boundary: standard startup remains portable; direct device success requires the named profile.

**NOT REQUIRED:** IMSAI, Cromemco, Mostek, Altair, Intel MDS, Dazzler, VIO, front-panel, raw-controller, or host-socket details are not generic requirements.

**NOT GUARANTEED:** behavior after absent ports, MMIO, firmware, device readiness, timing, or interrupts is unspecified outside an advertised profile.

## 5. CP/M versus hardware boundary analysis

The valid claim stack is cumulative:

1. **Generic CP/M personality:** documented BDOS, page-zero, lifecycle, files, console, and standard BIOS ABI are **REQUIRED**.
2. **Processor profile:** documented instruction semantics named by an 8080, Z80, or other claim are **REQUIRED within that profile**.
3. **BIOS/device profile:** documented BIOS-visible routing, devices, readiness, data width, geometry, and error behavior advertised by the profile are **REQUIRED within that profile**.
4. **Machine profile:** named ports, MMIO, ROM entries, controller behavior, interrupt topology, clocks/tolerances, and optional peripherals are **REQUIRED only to the extent explicitly claimed and evidenced**.
5. **Application claim:** a named binary/workflow requires the preceding layers plus an executable acceptance test.

A higher layer may add requirements but cannot waive a lower-layer requirement included in the claim. T02 is decisive: identifying a system as CP/M 2.2 and supplying a machine-specific BIOS does not convert a nonconforming Function 12 result into permissible hardware variation.

## 6. Software impact analysis

T01 showed portable BASE051 working on the Cromemco profile. T03/T04 showed the same 8080 binary semantics on 8080 and Z80 profiles. T05/T06 showed that documented Z80 software succeeds in the Z80 profile but need not work in an 8080-only profile.

T07-T09 show that machine-specific dependencies are consequential but scoped. Matched QTERM transport works; the mismatched QTERM and KSCOPE binaries cross from normal CP/M output into unsupported direct hardware. Such programs can be historically important without making their machine universal.

Software prevalence affects which optional profiles are worth shipping, not the meaning of generic conformance. A named application compatibility claim requires a rights-available executable, controlled fixture, deterministic inputs, observable oracle, and matching profile—not source inspection alone.

## 7. BIOS profile analysis

The standard seventeen-entry BIOS vector is the common hardware-abstraction ABI (**REQUIRED**). Its externally observable call semantics, returned structures, device routing when advertised, geometry, and physical status behavior can represent machine differences. BIOS location, internal buffers, controller commands, private entries, and host mechanisms remain profile-specific (**NOT GUARANTEED/NOT REQUIRED generically**).

T01's Cromemco BIOS supported the public service path and returned Function 12 `HL=0022h` through BDOS. T02's IMSAI B03 environment loaded the same program and printed via Function 9 but produced `VERSION MISMATCH`. A follow-up ZERO41 run recorded Function 12 as `HL=7799h` and additional `C:` prefixes. This is an experimental result for the preserved configuration, not a hardware requirement. Against ledger entry 0414, that configuration fails strict generic CP/M 2.2 Function 12 conformance; an IMSAI machine label does not excuse it.

The IMSAI startup also changed 254 bytes in otherwise deallocated disk space while directory listings and extracted PROFILE.SUB remained unchanged, consistent with transient submit-stream processing. This is preserved as an observation, not promoted to a persistence or machine-profile requirement.

## 8. Profile conformance analysis

A defensible hardware-profile claim must publish:

- parent generic CP/M and processor profiles;
- exact machine/profile identity and version;
- BIOS ABI and any private extension identifiers;
- port/MMIO/firmware map and absent-device behavior where promised;
- storage geometry/controller-visible behavior;
- character/peripheral routing, readiness, width, buffering, and failure rules;
- clock/timing tolerance and interrupt behavior only if claimed;
- software fixtures, procedures, expected observations, and known exclusions;
- immutable source/binary/configuration/image hashes and repeatable harnesses.

Conformance is conjunctive. Passing machine-specific software does not compensate for a failed generic requirement; passing generic tests does not establish a Dazzler, VIO, SIO, printer, or controller profile. Unsupported behavior should be reported as profile mismatch rather than baseline failure unless the configuration advertised it.

## 9. Experimental results

Detailed seven-field records are in `probes/hardware-profile-validation-records.tsv`. Fresh I067 transcripts and images are preserved; inherited I051/I065 transcripts and peer data are copied with provenance.

| ID | Matrix class | Observation | Conclusion |
|---|---|---|---|
| T01 | Generic CP/M on Cromemco | `VERSION=22 PASS`; normal return; image unchanged | Generic service behavior survives machine variation |
| T02 | Generic CP/M on IMSAI | Function 9 worked; Function 12 mismatch; normal return | Named hardware does not waive generic requirements |
| T03 | 8080 profile | `CPU8080 PASS` in 8080 mode | Required generic instruction baseline |
| T04 | Cross-profile subset | `CPU8080 PASS` in Z80 mode | Z80 profile preserves advertised 8080 subset |
| T05 | Z80 profile | `CPUZ80 PASS` | Z80 semantics required only in Z80 claim |
| T06 | Boundary mismatch | Z80 binary produced no PASS/return on 8080 within 20 seconds | Outside profile; exact mismatch result not guaranteed |
| T07 | Matched peripheral/application | I065 QTERM exchanged exact bytes through IMSAI SIO-2A | Peripheral claim requires matching endpoint evidence |
| T08 | Mismatched serial hardware | I051 QTERM trapped on `IN 23h` after portable banner | Direct port is profile-specific |
| T09 | Mismatched display hardware | I051 KSCOPE trapped on `OUT 0Eh` after portable sign-on | Display port is profile-specific |

The initial sandboxed Cromemco socket-bind failure and two IMSAI harness-alignment attempts are excluded from the evidence matrix. They produced no accepted CP/M observation. The final accepted transcripts are explicit.

## 10. Compatibility conclusions

1. Hardware-specific claims can be defined and validated separately from generic CP/M (**REQUIRED claim layering**).
2. Generic CP/M conformance remains mandatory beneath any machine profile that claims it (**REQUIRED**).
3. Documented processor, BIOS/device, and machine behaviors become **REQUIRED only within the profile that explicitly advertises them**.
4. Machine quirks, ports, MMIO, private firmware, exact clocks, interrupts, controllers, and absent-device outcomes are **NOT REQUIRED** or **NOT GUARANTEED** generically.
5. A named software claim requires executed matching-profile evidence; source or a boot banner is insufficient (**REQUIRED for that claim**).
6. Which named profiles and acceptance applications BetterCP/M will advertise remains **POLICY PENDING**.
7. Existing compatibility propositions are sufficient; the hardware-profile boundary is ready for specification release if claims are explicit and layered.

## 11. Proposed ledger additions

None. Existing entries already distinguish the public BIOS ABI, profile-specific implementation details, optional devices, direct hardware responsibility, processor profiles, and generic Function 12 result. Device-named or claim-process propositions here would duplicate those requirements or belong in the conformance standard rather than the compatibility ledger.

## 12. Existing-entry updates

Do not modify the ledger during I067. At the next authorized integration, add `I067 HARDWARE PROFILE VALIDATION subsystem IG AG` as strengthening evidence to:

- 0414, for T01 and the T02/ZERO41 negative Function 12 conformance result;
- 0598, for use of the standard public BIOS/service boundary across different machine integrations;
- 0600-0601, for raw/profile behavior and the non-universality of BIOS devices and extensions;
- the existing I051 direct-port, optional-device, and direct-caller responsibility entries, using T07-T09;
- the I063 processor-profile integration note, using T03-T06.

No disposition correction is supported. The IMSAI observation is a failing fixture result against 0414, not evidence that 0414 should be weakened.

## 13. Open questions

1. Which named machine, processor, terminal, storage, printer, and communications profiles will BetterCP/M claim initially? (**D / POLICY PENDING**)
2. Which application binaries define acceptance for each profile, and are they distributable? (**D**)
3. Should absent direct hardware trap, float, hang, or be protected in non-strict configurations? (**D / POLICY PENDING**)
4. What timing and interrupt tolerances belong to any named historical profile? (**D**)
5. Matching Dazzler, VIO, printer, paper-tape, raw-controller, front-panel, Altair, Intel MDS, and physical serial success tests remain unperformed. No claims should be advertised for them from I067. (**D**)
6. The exact cause and historical authenticity of the IMSAI B03 Function 12 divergence should be investigated before that image is used as a generic CP/M conformance reference. (**D**)

## 14. Conformance implications

Conformance reporting should name every claimed layer and report results independently: generic CP/M, processor, BIOS/device, machine, and application. A profile manifest should map each promise to a test and immutable fixture. The generic suite must run unchanged on every profile claiming generic CP/M; profile tests then add device and software cases.

Required matrix classes are represented here: generic CP/M (T01-T02), hardware profiles (T01-T02/T07), peripheral behavior (T07-T09), software compatibility (all), and boundaries (T02/T06/T08/T09). Negative results must distinguish baseline failure from unadvertised-profile mismatch. Exact failure behavior outside a profile is not a pass criterion unless promised.

Completion audit: report, prompt, sources/binaries, scripts, records, corpus, analyses, accepted transcripts, copied prior evidence, isolated emulator/configuration trees, before/after images, listings, rebuild checks, and SHA-256 manifests are present. Fresh executable probes rebuild byte-identically. The authoritative Investigation 066 ledger remains unchanged at its recorded SHA-256. The protected BetterCP/M before/after manifests compare identically outside the new I067 directory. No earlier investigation, ledger, or BetterCP/M implementation file was modified.
