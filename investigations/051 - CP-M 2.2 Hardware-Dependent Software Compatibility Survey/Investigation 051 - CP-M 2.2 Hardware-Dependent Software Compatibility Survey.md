# Investigation 051 - CP/M 2.2 Hardware-Dependent Software Compatibility Survey

## 1. Objective and scope

This investigation establishes the boundary between CP/M 2.2 compatibility and software that assumes a particular machine, BIOS extension, display, controller, serial interface, clock, interrupt regime, or peripheral. It surveys and tests preserved hardware-oriented software without modifying BetterCP/M or demanding universal hardware emulation.

The principal result is layered: portable CP/M services remain required; a declared hardware profile must faithfully supply the extra behavior it advertises; software that directly selects an unadvertised device falls outside the generic contract. Controlled execution shows programs can use CP/M normally up to the exact instruction where they cross that boundary.

## 2. Compatibility standard

Evidence classes are **A** (documented CP/M), **B** (DRI implementation), **I** (controlled observation), and **D** (policy unresolved). Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. A literal port, screen address, clock loop, interrupt assumption, controller command, firmware entry, or vendor extension is not promoted merely because preserved software uses it.

Future ledger evidence from this report must use exactly `I051 HARDWARE COMPATIBILITY ECOSYSTEM subsystem IG AG`.

## 3. Relationship to previous investigations

I036 established BIOS as CP/M's configured hardware-abstraction boundary and classified vendor-private extensions as profile-specific. I041 established public page-zero and BIOS-vector discovery while rejecting fixed implementation targets. I049 exercised ordinary applications. I050 demonstrated the same profile boundary in communications software.

I051 broadens the evidence to direct display ports, memory-mapped video, EPROM programming, front-panel/controller utilities, custom timing, interrupt assumptions, and a machine BIOS. It tests existing conclusions rather than redefining the BIOS ABI.

## 4. Software corpus

| Software | Hardware target | Category and dependency | Evidence |
|---|---|---|---|
| BASE051 | Any CP/M 2.2 | Portable BDOS control | Source, rebuild, T01 (**I**) |
| QTERM 4.3e IMSAI patch | IMSAI SIO-2 | Serial ports 22h-25h; 4 MHz setting | Source, executable, T02 (**I**) |
| KSCOPE | Cromemco Dazzler | Ports 0Eh/0Fh, display memory, interrupts disabled | Source, executable, T03 (**I**) |
| VI/Open | IMSAI VIO | F000h video memory, 6Eh/6Fh, discovered BIOS page | Source, executable, T04 (**I**) |
| PROMMER 2.0 / patch 1.0 | Mostek-hosted EPROM board | Base port 14h, clock loops, interrupts, terminal patch | Source; T05 inconclusive |
| FDCT1 / KILLBITS | Altair controller/front panel | Ports 8/9 and FFh | Source only |
| IMSAI CP/M 2.2 BIOS | IMSAI FIF, VIO, SIO, printer | Configured BIOS implementation and device extensions | Source only |

Exact provenance and exclusions are in `probes/corpus-inventory.txt`.

## 5. Documentation findings

CP/M documentation (**A**) specifies public BDOS entry, page-zero objects, the standard BIOS jump table, BIOS call conventions, and structures returned by standard interfaces. It deliberately leaves physical ports, display maps, controller commands, baud generators, clocks, interrupt topology, firmware, and optional peripherals to system integration.

Accordingly, CP/M compatibility does not imply binary compatibility with every CP/M machine. A hardware-profile claim adds requirements beyond generic CP/M; it does not retroactively make those requirements universal. Documentation does not define a standard EPROM programmer, graphics display, raw floppy-controller API, memory-mapped screen, or front-panel switch port.

## 6. Source findings

DRI source behavior inherited from I036/I041 (**B**) implements standard calls through a configured BIOS and does not create portable names for vendor devices. Preserved third-party source shows common mixed layering:

- QTERM uses BDOS/file services around direct IMSAI serial polling.
- KSCOPE prints its sign-on through CP/M, then writes Dazzler ports and memory.
- VI/Open discovers the BIOS page from the public WBOOT gateway but writes an F000h VIO window and ports 6Eh/6Fh.
- PROMMER uses BDOS console services while compiling terminal, port, CPU-speed, and interrupt choices into its patch area.
- FDCT1 and KILLBITS are direct controller/front-panel programs.

The IMSAI BIOS source maps standard jump-table services onto fixed serial, printer, VIO, interrupt-controller, and disk mechanisms. These are evidence of how one profile implements CP/M, not standard extensions. Details are preserved in `probes/source-analysis.txt`.

## 7. Hardware dependency analysis

The corpus exhibits six dependency types:

1. **Direct I/O ports:** QTERM, KSCOPE, PROMMER, FDCT1, and KILLBITS.
2. **Memory-mapped hardware:** VI/Open and Dazzler software.
3. **Custom firmware/BIOS behavior:** IMSAI VIO firmware and configured physical-device routing.
4. **Interrupt behavior:** KSCOPE disables interrupts; PROMMER compiles different interrupt policy.
5. **Timing:** QTERM records CPU MHz; PROMMER uses instruction-counted delays.
6. **Controller/peripheral state:** IMSAI FIF descriptors, raw FDC commands, EPROM voltage/status, and front-panel switches.

These patterns are widespread across multiple categories in the available corpus, but corpus breadth does not make their exact values portable. Replacement software may serve the same user purpose; binary compatibility requires the matching profile.

## 8. CP/M versus hardware boundary analysis

**CP/M environment:** transient loading, command tail, public 0005h calls, page-zero gateway discovery, standard BIOS entries, files, console, and termination are **REQUIRED**.

**BIOS/profile environment:** standard BIOS services must exhibit their documented behavior, but their physical realization and optional devices are **NOT GUARANTEED** generically. If a profile advertises IMSAI-style device routing or a specific display, that profile's stated behavior becomes **REQUIRED** within the profile.

**Machine-specific environment:** direct ports, MMIO, controller formats, private firmware entries, timing loops, and interrupt topology are **NOT REQUIRED** outside the matching profile. Unsupported access may trap, return floating-bus values, corrupt unrelated memory, hang, or appear inert; the exact outcome is **NOT GUARANTEED**.

The boundary can occur mid-program. T02 and T03 printed banners through CP/M, then trapped precisely on the first observed unsupported direct-port operation.

## 9. BIOS extension findings

No cross-vendor extension convention in this corpus justifies a new generic BIOS entry. The standard 17-entry table and discovery rules remain the portable ABI. Extra routines, bytes beyond the table, firmware entry points, IOBYTE physical mappings, and controller-specific work areas belong to a declared BIOS or machine profile.

VI/Open demonstrates a valid combination: discover the configured BIOS page through public indirection, then use a private VIO device. Public discovery is **REQUIRED**; the VIO memory map is **NOT REQUIRED** generically. A program does not make a private extension portable by discovering the standard BIOS correctly.

Profiles must document extension identity and semantics rather than relying on accidental placement. Behavior after calling an absent extension is **NOT GUARANTEED**.

## 10. Experimental results

All input was scripted, images were restored, and unsupported access was isolated.

| Test | Matrix class | Purpose and procedure | Observation | Classification |
|---|---|---|---|---|
| T01 BASE051 | Standard CP/M | Call Functions 9 and 12 via 0005h | `VERSION=22 PASS`; normal B> return | Existing public path **REQUIRED** |
| T02 QTERM | Direct serial; unsupported | Run IMSAI patch on Mostek with unused-port trap | Banner, then `IN 23h` trap at 0112h | IMSAI port **NOT REQUIRED** outside profile |
| T03 KSCOPE | Direct display; unsupported | Run Dazzler program on Mostek with trap | CP/M sign-on, then `OUT 0Eh` trap at 0110h | Dazzler port **NOT REQUIRED** outside profile |
| T04 VI/Open | MMIO/machine mismatch | Run IMSAI VIO editor on Mostek, bounded halt | No portable UI; returned to B>; no VIO display | VIO behavior **NOT GUARANTEED** without profile |
| T05 PROMMER | Peripheral/timing | Invoke preserved distribution with scripted input | No stable interpretable UI before halt | Inconclusive; no experimental claim |

All completed-test disk images remained byte-identical. T02/T03 prove executed direct-port paths; T04 proves only the observed mismatch result, not successful MMIO operation. No matching hardware peripheral was executed, and source is not substituted for that missing evidence.

## 11. Compatibility conclusions

**REQUIRED:** Documented CP/M environment and standard BIOS ABI; public discovery mechanisms; coherent behavior for every device or extension explicitly advertised by a selected hardware profile.

**POLICY PENDING:** Which historical machine profiles BetterCP/M will claim; whether unsupported direct hardware access traps, floats, or is protected outside strict profiles; and which applications define profile acceptance.

**NOT REQUIRED:** Universal IMSAI, Cromemco, Altair, Mostek-peripheral, VIO, Dazzler, EPROM programmer, front-panel, raw-controller, clock-loop, or terminal behavior.

**NOT GUARANTEED:** Results of absent ports, MMIO, private firmware/BIOS calls, timing at unspecified CPU speeds, interrupt assumptions, and unexecuted matching-hardware cases.

## 12. Proposed ledger additions

None. The portable/profile boundary, vendor-private extensions, raw BIOS layering, address freedom, optional devices, and direct-caller responsibility are already independently represented. Adding device-named propositions would duplicate or overfit the ledger.

## 13. Existing-entry updates

No ledger file was modified. At the next authorized integration, consider adding `I051 HARDWARE COMPATIBILITY ECOSYSTEM subsystem IG AG` to:

- **0462-0463, 0473:** address freedom, BIOS discovery, and raw direct-call layering.
- **0598, 0600-0601:** public BIOS vector, vendor-private extensions, and optional device profiles.
- **0606-0611:** raw device paths and the separation of assignment from availability.
- **0617 and relevant I040/I041 direct-caller entries:** direct callers assume controller/device responsibility outside BDOS protection.

No disposition correction is supported. I051 supplies executable ecosystem evidence for the existing profile model.

## 14. Open questions

1. Which named machines merit binary-compatible BetterCP/M hardware profiles? (**D**)
2. Should a strict profile reproduce floating-bus values and absent-device hangs, or may a non-strict profile trap them visibly? (**D**)
3. Which matching emulators/peripherals can provide controlled success tests for Dazzler, VIO, EPROM programming, raw FDC, and front-panel software? (**D**)
4. Are any private BIOS extensions repeated across independent vendors strongly enough to justify opt-in convention profiles? Not established here. (**D**)
5. What CPU-speed and interrupt guarantees, if any, belong to named profiles? (**D**)
6. PROMMER matching-peripheral operation and all destructive raw-controller operations remain unperformed; no behavior is claimed.

## 15. Conformance implications

Baseline conformance should validate only documented CP/M entry points, discovery, and service semantics while permitting different physical hardware. Each additional hardware profile should publish its ports, MMIO, firmware/BIOS extensions, devices, timing, and interrupt assumptions and run isolated application tests against them. Unsupported direct accesses should be tested only for the policy promised by that configuration; their accidental behavior must not become a baseline ABI.

### Completion audit

- New report, sources, executable corpus, probe source/binary, harnesses, transcripts, disk fixtures, and hashes: present.
- BASE051 rebuild: byte-identical.
- Completed disk runs: before/after SHA-256 identical.
- Inconclusive and unperformed matching-hardware cases: explicit; no source reconstruction presented as observation.
- Authoritative ledger before hash: `280c001c1bb3ca7fdd0858c6c1341a38ff334c5e9d51234b2bf7b6014677d26e`.
- Ledger modification: none; after hash recorded separately.
- Existing BetterCP/M files outside new I051 directory: protected by before/after manifest comparison.
- BetterCP/M implementation changes: none.
- ZIP archive: none created.
