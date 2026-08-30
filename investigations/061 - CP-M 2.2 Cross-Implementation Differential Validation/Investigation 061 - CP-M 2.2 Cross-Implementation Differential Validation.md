# Investigation 061 - CP/M 2.2 Cross-Implementation Differential Validation

## 1. Objective and scope

This investigation tests whether the compatibility boundary developed through Investigation 060 survives comparison with a materially different historical implementation. It compares Digital Research CP/M 2.2 and Cromemco CDOS 2.58 on the same emulated Cromemco Z-1 hardware, so operating-system differences are separated from hardware differences. CDOS 2.36 is screened as an implementation-family boundary but excluded from the primary CP/M 2.2 comparison after it fails the version and Function 32 criteria.

The work covers application-visible CCP, BDOS, BIOS, file, execution, memory and error-presentation behavior. It does not select an implementation, design BetterCP/M, or treat every behavior of either system as normative. No Compatibility Ledger or prior artifact was modified.

Evidence classes are: **A** documented interface, **B** DRI implementation, **I** experiment, and **D** unresolved policy. `probes/differential-records.tsv` gives the required behavior, implementations, procedure, difference, software impact and compatibility conclusion for each record.

## 2. Compatibility standard

The standard is the documented CP/M 2.2 application and BIOS interface, constrained by historically significant software practice. Agreement across systems strengthens portability evidence but does not override documentation. Disagreement has four possible meanings: a permitted implementation choice, a hardware/profile choice, a nonconforming compatibility subset, or an unresolved policy question.

The following decision rules were applied:

- A documented externally testable interface remains **REQUIRED** even when a comparator violates it; the violation qualifies that implementation rather than silently weakening CP/M.
- Numeric private targets, entry residue, layout addresses and presentation are **NOT GUARANTEED** or **NOT REQUIRED** unless separately documented or required by ecosystem evidence.
- An extension may coexist with CP/M behavior, but software cannot require it in the baseline.
- Source or archive contents identify environments and test requirements; runtime behavior is claimed only from captured execution.

The authoritative ledger baseline is the Investigation 059 file, SHA-256 `8bf7d57d636b66a1d4bf2e08553c1bc462ca08a313214f3e9a413a38313e22d2`. Investigation 060 intentionally added or changed no ledger proposition, so no Investigation 060 ledger file is expected.

## 3. Relationship to previous investigations

I055 defines the community compatibility standard; I056 maps requirements without making internal architecture normative; I059 defines proposition-oriented conformance; and I060 identifies cross-implementation evidence as the highest-priority remaining validation gap. I061 executes that campaign on a deliberately small but controlled corpus.

I001/I023/I028 define transient entry and CCP state. I002/I027/I037 define the BDOS call/result surface. I011/I030 define record-oriented file behavior. I020/I036/I041 define the public BIOS boundary and distinguish vector roles from numeric targets. I043/I054 distinguish usable memory/termination behavior from DRI layout residue. The current tests reuse byte-identical I041/I043 probes where doing so improves direct comparability; copied sources and rebuild checks are preserved.

## 4. Implementation corpus

**Primary reference: DRI CP/M 2.2.** The image is `z80pack/cromemcosim/disks/library/cpm22.dsk`, SHA-256 `b1b3245029a19948ec04dff915595c3369a9f2d0f6bd028e8883ab7f2a53c5b2`. It signs on as `64k CP/M version 2.2`. This supplies A/B/I evidence: documented DRI interface, a DRI-family runtime, and captured observation.

**Primary independent family: Cromemco CDOS 2.58.** The image is `z80pack/cromemcosim/disks/library/cdos258_8.dsk`, SHA-256 `7ad2d79c859f28e5deee787a2e0d6f3aef24d62b1d65a64a307afc9d88acf754`. It signs on as `CDOS version 02.58`, runs ordinary CP/M COM programs and the identical DRI PIP utility, exposes CALL 0005h, and returns 0022h from Function 12. It is materially independent but experimentally proves to be a CP/M application-compatible subset rather than a complete CP/M 2.2 BIOS/BDOS conformance reference.

**Screened boundary: Cromemco CDOS 2.36.** Image SHA-256 `5018cbf0b4346084812465e9b9d5e64ddc8e2f30b7d345b9c4d7095e432bd7d2`. It returns 0084h from Function 12, lacks Function 32 and cannot complete the DRI PIP workflow. It is not counted as an independent agreement vote for CP/M 2.2 requirements.

All run on z80pack revision `91fd28eb04e675c2127df88ed3f40675e15282e2`, simulator releases 1.39/1.19, 64K Z80, the same RDOS ROM, FDC and IBM-3740 disk geometry. This holds hardware constant. `probes/implementation-corpus.tsv`, pristine images and transcripts preserve provenance.

## 5. Differential behavior analysis

The primary agreement surface is substantial. Both systems provide JMP gateways at 0000h and 0005h, prepare the sampled default FCB and command-tail prefix identically, return 0022h from Function 12, report drive/user zero, execute writable/self-modifying transient code, accept an application stack, return to the command processor through the entry RET path, and run the same DRI PIP file copy.

The permitted variations are equally clear. Gateway targets are FA03h/EC06h on DRI and E803h/C800h on CDOS. Entry SP/return words are EBA9h/EB5Fh and F8AAh/D048h. Derived private ceilings are EC05h and C7FFh. Prompts, `DIR` layout and missing-command text differ. These differences are visible but do not impair the tested portable programs. They confirm **NOT REQUIRED** exact entry addresses and **NOT GUARANTEED** numeric system placement and presentation.

Three differences cross documented boundaries. First, initial Function 24 returns 0001h on DRI and 0022h on CDOS 2.58, even though both show A as current and only A media is configured. Second, selector 41 returns zero on DRI but CDOS emits `Illegal system call 29H` and abandons the transient. Third, the DRI image exposes 17 consecutive BIOS JMP entries while CDOS has JMPs only through slot 0Eh; native slots 0Fh/10h are not JMPs. These are software-visible CDOS compatibility limitations, not evidence that the documented CP/M requirements are optional.

Function 8 with value A5h leaves the DRI run visible but removes CDOS output from the captured console. This corroborates that IOBYTE physical routing is BIOS/configuration policy. Because the alternate CDOS device was not captured, no unseen-output claim is made (**D** for its exact route).

## 6. Software impact analysis

The identical DRI `PIP.COM` successfully copies the controlled file under both primary systems. The portable probes using page-zero gateways, default FCBs, the command tail, ordinary BDOS calls, writable code and RET also complete on both. This is positive evidence that the core application interface crosses implementation families.

The differences identify concrete failure classes:

- Software that hard-codes gateway targets, SP, return address, TPA ceiling or BIOS routine addresses is implementation-bound.
- Software using Function 24 for logged-drive discovery receives a misleading CDOS result in this fixture.
- Software probing unsupported calls on the documented assumption of a zero result is terminated by CDOS.
- Software using the documented final BIOS slots cannot treat CDOS's native table as a CP/M 2.2 BIOS.
- Software parsing CCP error text or directory columns is not portable.

PIP's output payload matches on both, but DRI closes the copied file as a full 128-byte record while CDOS preserves the 53-byte exact length. CP/M sequential reads and writes remain 128-byte operations. Exact byte length is a CDOS/cpmtools-visible extension and must not become a baseline assumption.

## 7. Documented versus implemented behavior

Documentation requires the page-zero roles, CALL 0005h, the CP/M 2.2 function semantics, the login-vector meaning and the 17-entry BIOS interface. DRI implements the tested forms, including zero for selector 41. CDOS implements enough of the application interface to run the portable probes and PIP, but its Function 24, selector-41 and BIOS-table behavior do not satisfy the complete documented surface.

This distinction prevents two errors. A repeated DRI address is not promoted merely because DRI is the reference, and a CDOS deviation does not demote a documented CP/M requirement merely because CDOS was historically useful. CDOS demonstrates that “runs CP/M software” and “conforms to every CP/M 2.2 public surface” are different claims.

CDOS 2.36 strengthens that caution. It loads simple COM programs but reports a non-CP/M version value and lacks calls required by later CP/M software. Implementation-family labels therefore need version-qualified capability evidence.

## 8. Specification impact

The current compatibility model remains coherent. Cross-implementation agreement strengthens the gateway, command-tail/default-FCB, Function 12, writable execution, RET and ordinary file-lifecycle requirements. Numeric layout exclusions are directly strengthened by large observed differences.

The experiments do not justify weakening ledger 0042 (out-of-range zero), 0147-0149 (login vector), 0461/0598 (17-entry BIOS), or 0263-0265 (128-byte transfer semantics). The first three identify CDOS nonconformance. The file-length difference is an extension outside the BDOS record-transfer contract.

Conformance claims should therefore identify their surface. A “CP/M application subset” can be useful while failing direct BIOS or less-common BDOS requirements; it must not be reported as full CP/M 2.2 conformance. No architecture implication follows.

## 9. Experimental results

The accepted main sequences boot a fresh prepared image and run, without manual input: VECTOR41; ZERO41 with two operands; STATE61; EDGE43; BIOS41; identical DRI PIP; DIR; and a missing command. BASE61 is run twice per primary implementation and produces identical result lines. The IOBYTE case is isolated because it intentionally changes routing. Every console transcript, pristine/after image and probe is preserved under `probes/`.

Key accepted lines are:

```
DRI  BASE61 ... 0022 00 00 0001 0000 EBA9 EB5F
CDOS BASE61 ... 0022 00 00 0022 0000 F8AA D048

DRI  STATE61 ... F41 ... 0000 ...
CDOS Illegal system call 29H at 013EH

DRI  EDGE43 ... EC05 00 A5 5A 0022
CDOS EDGE43 ... C7FF F8 A5 5A 0022
```

DRI has C3h in BIOS slots 00h-10h; CDOS has C3h in 00h-0Eh and 79h/EEh at 0Fh/10h. PIP creates COPY61.TXT on both. Its first 53 bytes equal the source; extracted sizes are 128 and 53 bytes respectively. Full results and hashes are in `probes/observed-output.txt` and `probes/differential-records.tsv`.

Rejected pilot transcripts are retained but excluded: one CDOS prompt regex matched `A.` inside `BETA.BIN`; two launches encountered a lingering localhost socket; and the intentional IOBYTE case lost the selected visible console. No behavioral conclusion uses those failed combined sequences.

## 10. Compatibility conclusions

1. **REQUIRED:** Public 0000h/0005h roles, documented transient argument objects, Function 12 version behavior, usable RET entry state, ordinary record-oriented file calls, and documented function/BIOS surfaces remain the contract.
2. **NOT REQUIRED:** Exact entry SP, return address, CCP prompt, directory formatting, error wording and byte-for-byte DRI final-record padding.
3. **NOT GUARANTEED:** Numeric gateway targets, BIOS base/targets, private TPA ceiling, entry residue, physical IOBYTE routing and extension metadata.
4. **POLICY PENDING:** Which optional active IOBYTE routes BetterCP/M will expose remains profile policy; I061 does not select devices.
5. CDOS 2.58 is strong positive evidence for a portable application subset and equally strong evidence that historical compatibility subsets may violate full CP/M 2.2 BDOS/BIOS conformance.
6. Cross-implementation agreement is evidence, not a voting mechanism that can repeal documented behavior.

## 11. Proposed ledger additions

None. Every observed proposition is already represented: public gateways, command entry, version/system calls, login vector, out-of-range calls, entry stack, BIOS vector, IOBYTE policy, 128-byte transfers and non-normative presentation. Adding implementation names as behavioral propositions would duplicate the ledger and confuse evidence with requirements.

If future policy creates named conformance levels, “application subset versus full BIOS-visible CP/M 2.2” belongs in claim/profile documentation, not as a new machine behavior.

## 12. Existing-entry updates

No ledger was modified. At the next authorized integration, use the evidence string `I061 DIFFERENTIAL VALIDATION COMPATIBILITY subsystem IG AG` for these evidence-only updates:

- 0005/0008/0028: cross-family strengthening for WBOOT/BDOS gateways and functional RET entry.
- 0029/0030 and 0462: strengthen exact-SP, return-address, BIOS-base and target exclusions with the DRI/CDOS differences.
- 0042: retain **REQUIRED** and record CDOS 2.58's selector-41 diagnostic as an observed nonconformance.
- 0147-0149: retain **REQUIRED** and record the repeatable CDOS Function 24 mismatch.
- 0263-0265: retain 128-byte transfer semantics; note that CDOS exact-byte metadata is an extension, not a required partial-record API.
- 0443-0446 and 0608-0612: strengthen the distinction between Function 8 state and BIOS/profile-specific physical routing.
- 0461 and 0598: retain **REQUIRED**; record CDOS's missing native final two JMP slots as a full-BIOS conformance failure.

No disposition correction or duplicate entry is proposed.

## 13. Open questions

1. Does another materially independent CP/M 2.2 implementation reproduce DRI's Function 24, selector-41 and 17-vector behavior, or reveal a second boundary? (**D**)
2. What CDOS 2.58 metadata encodes the exact 53-byte final length, and how do native CDOS and CP/M tools treat it? This is not needed for baseline CP/M behavior but may define an optional CDOS-media profile. (**D**)
3. Which device received output after CDOS Function 8 set A5h, and should an optional BetterCP/M hardware profile reproduce that routing? (**D**)
4. Should conformance reporting formally distinguish application-only, BDOS-complete and BIOS-visible claim levels? I059 has the machinery, but the release policy remains to be selected. (**D**)
5. Broader software validation remains necessary; one utility plus focused probes cannot establish compatibility with the entire historical ecosystem. (**D**)

## 14. Conformance implications

A full CP/M 2.2 conformance run must test documented surfaces independently; successful execution of common COM files is insufficient. Implementations should be reported with explicit scope, and a disagreement should be classified as permitted variation, extension, fixture defect or nonconformance before changing a requirement.

For BetterCP/M, the current ledger remains a defensible baseline. The differential tests should join the conformance corpus: compare functional gateway roles without fixed addresses; run BASE61 and selector 41 separately; verify all 17 BIOS JMP slots for full-BIOS claims; run an identical portable utility; and compare record payload separately from extension metadata and presentation.

Completion audit: the report has all 14 required sections; implementation records, differential records, software-impact analysis, source probes, rebuild instructions, accepted/rejected transcripts, pristine/after images and SHA-256 records are present. All rebuildable probes compare byte-identically. The authoritative ledger hash remains `8bf7d57d636b66a1d4bf2e08553c1bc462ca08a313214f3e9a413a38313e22d2`. A protected-tree manifest comparison excludes only the new Investigation 061 directory. No prior report, ledger, source archive or BetterCP/M implementation file was modified.

