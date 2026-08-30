# Investigation 039 - CP/M 2.2 IOBYTE and Runtime Device Assignment Semantics

Evidence labels: **A** documented behavior, **B** DRI implementation, **I**
controlled observation, and **D** unresolved policy.

## 1. Objective and scope

This investigation defines IOBYTE as a runtime software compatibility interface:
its four logical-device fields, direct and BDOS access, STAT configuration,
immediate switching, persistence, invalid names, and BIOS routing boundary. It does
not prescribe BetterCP/M device architecture or physical hardware.

## 2. Compatibility standard

Portable requirements come from documented CP/M 2.2 semantics, supported DRI
source/experiments and evidenced utility practice. A physical mapping or name is
required only by a declared machine/device profile. Exact STAT prose and vendor
extensions are not elevated from one distribution.

## 3. Relationship to previous investigations

I018 established Functions 7/8 and the field definitions. I020/I036 established
the public BIOS vector and configured routing. I026 established system-state
boundaries. I038 separated raw logical devices and unavailable-device policy. I039
adds STAT, field-preserving changes, transient/WBOOT persistence and coherent
application observation.

## 4. IOBYTE compatibility boundary

IOBYTE is not merely private BDOS/BIOS storage. It is documented at 0003h,
accessible through BDOS Functions 7/8, modified by DRI STAT, and consulted by
configured BIOS routing. Applications may observe and modify it during execution.

The byte's layout and coherent access are portable. Whether a particular BIOS uses
IOBYTE, which physical devices each code selects, and what happens when hardware is
absent are configuration/profile contracts.

## 5. Documentation findings

**A.** IOBYTE occupies 0003h and contains four two-bit fields: CON bits 0-1, RDR
bits 2-3, PUN bits 4-5, and LST bits 6-7. Each field represents one of four physical
assignments. The Alteration Guide explicitly permits assignments to change during
CP/M processing and points to STAT as the user-facing mechanism.

Multiple logical devices may select the same peripheral. Optional devices may be
absent; the BIOS may diagnose, return immediately for output, or return reader
Control-Z EOF. These alternatives are not one universal error protocol.

## 6. Source findings

**B.** OS3BDOS Functions 7/8 read/write 0003h; Functions 3-5 transfer reader/punch/
list calls to BIOS without decoding IOBYTE. BIOS.ASM/CBIOS.ASM may decode the fields
or implement fixed/stub devices. Thus the active routing algorithm belongs to BIOS.

STAT.PLM directly reads/writes 0003h. It displays four fields, recognizes a DRI
name table, rejects unmatched names, masks the selected two bits, and preserves the
other six. Exact table names, output text and parser structure are DRI conventions.

## 7. Logical device assignment

CON, RDR, PUN and LST are independent logical fields. A conforming IOBYTE-enabled
profile must interpret them consistently for documented BIOS/BDOS services. The
same physical device may serve several fields; no one-to-one relation is required.

The default reference byte 00 mapped all four to TTY. Byte 01 changed only CON to
CRT. Byte A5 was accepted as four valid two-bit encodings and immediately visible.
Those particular names/physical effects are reference-profile observations.

## 8. Device assignment state

The public byte is the coherent assignment state. Direct location 0003h and
Functions 7/8 agreed in every observation. Ordinary BDOS calls and transient RET
did not reset it. Applications that temporarily change mappings should save and
restore the complete prior byte, not assume the startup value is zero.

BOOT/WBOOT handling is BIOS policy. On this CBIOS, Function 0 WBOOT preserved byte
01 and STAT still displayed CON=CRT. Other documented BIOSes may initialize IOBYTE
on BOOT/WBOOT according to configuration; universal WBOOT preservation is NOT
GUARANTEED.

## 9. STAT DEV behavior

DRI `STAT DEV:` semantically reports the current mapping of all four logical
devices. `STAT CON:=CRT:` changed only CON, and `STAT CON:=TTY:` restored it.
`STAT CON:=BAD:` printed `Invalid Assignment` and did not change state.

Compatibility attaches to the ability of a supplied STAT-compatible utility to
display/configure declared mappings coherently, where that utility is part of the
profile. Exact spacing, capitalization, ordering, diagnostic wording and the DRI
physical-name vocabulary are NOT REQUIRED globally.

## 10. Runtime device switching

Function 8 and direct 0003h writes change public state immediately; no BDOS cache
flush is required. IOBYTE39 set A5, queried A5 and exposed A5 to a BIOS-facing
handler in one call sequence. Restoring 01 immediately restored the prior state.

Active programs therefore observe changes on subsequent calls. In-flight physical
I/O, device buffering and atomicity are hardware/profile matters. Software cannot
assume assignments remain fixed if it or another utility changes them.

## 11. BDOS interaction

BDOS console/reader/punch/list functions use their logical service paths. Under the
DRI layering, reader/punch/list dispatch to BIOS and the BIOS may consult current
IOBYTE. BDOS39 confirmed that character calls did not overwrite the byte and that
the live value reached interposed BIOS-facing logic.

Console buffering/editing can retain characters across mapping changes in DRI;
IOBYTE does not define queue migration or flushing. Applications should change
assignments at controlled boundaries rather than infer private buffer behavior.

## 12. BIOS interaction

Direct BIOS callers bypass BDOS formatting but call the same configured logical
entries. An IOBYTE-enabled BIOS may decode 0003h on every call; another conforming
fixed-device BIOS may document that it does not implement IOBYTE. BIOS39 operated
with byte 01 visible in page zero and used the standard vector.

Direct callers may inspect IOBYTE but cannot require a vendor's private physical
routine or assume all BIOSes implement the DRI name table. Routing behavior must be
declared by the selected BIOS profile.

## 13. Software ecosystem findings

STAT is direct primary evidence of runtime reassignment. Documented use cases cover
console/batch choice, reader/punch transfer, and list/printer selection. PIP and
DESPOOL provide earlier named consumers of optional character paths. Terminal,
communications, printing and development utilities can reasonably depend on the
byte/field ABI when an IOBYTE profile is present.

No local evidence supports requiring every DRI physical name, a particular modem
or printer, private status bits, or invisible caching. Machine-bound software may
require such behavior only through a named platform profile.

## 14. Error and invalid configuration behavior

All 256 byte values are structurally composed of valid two-bit codes. “Invalid” can
mean an unknown STAT text name or a representable code whose physical device is not
implemented. STAT rejected BAD before changing the byte; raw Function 8 accepts the
byte without validating hardware.

Operation on an unavailable mapping follows the BIOS/device profile. Baseline CP/M
does not supply a structured IOBYTE validation/error function. Applications must not
infer that a successful Function 8 proves device presence.

## 15. Experimental results

Six named probes and DRI STAT ran on fresh A/B copies with all input scripted. STAT
showed default TTY mappings, rejected BAD, selected CRT, reported CRT after multiple
transients and after Function 0 WBOOT, then restored TTY. Raw probes showed 0003h,
Function 7 and BIOS-facing observation remained coherent.

IOBYTE39/DEVICE39/BDOS39/STAT39 reused the accepted controlled logical-device
fixture; BIOS39 exercised the direct vector; SWITCH39 isolated Function 8 plus
WBOOT. Full transcripts are preserved. Both after-images equal their prepared
before-images byte-for-byte.

## 16. Compatibility conclusions

- **REQUIRED:** location 0003h, four two-bit fields, Functions 7/8 coherence,
  immediate runtime visibility, and field-consistent configured routing.
- **REQUIRED:** a profile-supplied assignment utility must report/change declared
  mappings coherently; DRI STAT semantics are historically significant.
- **NOT GUARANTEED:** WBOOT persistence, active-buffer migration, device presence,
  exact failure behavior, or fixed assignments after external change.
- **NOT REQUIRED:** exact STAT wording/name table, DRI parser internals, all physical
  devices, or universal IOBYTE support in a profile that explicitly omits it.
- **POLICY PENDING:** BetterCP/M's default active routing and named device profiles.

## 17. Proposed ledger additions

The authoritative ledger ends at 0608; the next available number is 0609.

### Proposed Compatibility Ledger additions

0609. IOBYTE access coherence

    Direct memory location 0003h and BDOS Functions 7/8 expose one coherent runtime
    IOBYTE value; a change through either supported access is visible to subsequent
    application and configured BIOS device operations.

    Disposition: REQUIRED
    Evidence: I039; I038; IOBYTE; DEVICE; BDOS; BIOS; AG
    Conformance: Set several bytes through Function 8/direct access, query through
    the other path, and verify subsequent configured device routing observes them.

0610. Field-preserving assignment changes

    Changing one logical device assignment shall replace only its designated two-bit
    IOBYTE field and preserve the other three fields.

    Disposition: REQUIRED
    Evidence: I039; I038; IOBYTE; DEVICE; STAT; AG
    Conformance: Begin with distinct field values, change each logical assignment
    independently, and verify the other six bits remain unchanged.

0611. IOBYTE assignment does not validate device presence

    Storing a structurally valid IOBYTE value does not guarantee that the selected
    physical device exists or that I/O will succeed; availability and failure are
    configured BIOS/device-profile behavior.

    Disposition: NOT GUARANTEED
    Evidence: I039; I038; IOBYTE; DEVICE; BIOS; IG; AG
    Conformance: Accept all byte values as assignment state while testing unavailable
    mappings according to the declared profile rather than a universal error code.

0612. STAT device-assignment semantics

    A CP/M 2.2 profile that supplies DRI-compatible STAT device configuration shall
    display current logical mappings, change a named field without altering others,
    and reject an unknown assignment without changing IOBYTE.

    Disposition: REQUIRED
    Evidence: I039; I038; IOBYTE; DEVICE; STAT; IG; AG
    Conformance: Display all fields, make valid single-field changes, attempt an
    invalid textual name, and compare the byte before and after each action.

## 18. Existing-entry updates

No ledger was modified. Proposed updates:

- **0442-0445:** add I039 direct/Function 7/8 coherence and field-preserving STAT
  evidence;
- **0446:** retain POLICY PENDING for BetterCP/M's active default routing profile;
- **0447:** add SWITCH39: tested WBOOT preserved 01, while initialization remains
  NOT GUARANTEED across BIOS configurations;
- **0606-0608:** add I039 assignment/failure context without changing raw-device
  dispositions;
- CCP/STAT entries should gain semantic device-reporting evidence only; exact DRI
  strings and physical-name tables remain NOT REQUIRED.

## 19. Open questions

1. Which physical mappings and names should the default BetterCP/M BIOS profile
   implement for each two-bit code?
2. Should strict WBOOT preserve IOBYTE or follow a selected BIOS profile's explicit
   initialization policy?
3. Which unavailable-device behavior belongs to each profile?
4. Is direct memory writing to 0003h required equally with Functions 7/8, or should
   conformance merely ensure coherence when software uses the documented location?

## 20. Conformance implications

Conformance tests should initialize four distinct fields, query both access paths,
change one field at a time, invoke BDOS and direct BIOS logical services, run the
profile's STAT utility, attempt unknown names, and test BOOT/WBOOT policy. They must
capture the byte around every step.

Tests should not infer physical device existence from Function 8 or demand DRI's
name table outside a DRI-compatible profile. The essential baseline is a coherent
public byte and declared routing behavior, not a modern device registry.

### Completion audit

The report, six required sources/binaries, listings, README, observed output,
ecosystem note, transcript, before/after images, scripts, STAT/source references and
hashes are present. All binaries rebuild identically. Both images are unchanged by
execution. The ledger was read but not modified and the protected-tree audit found
no attributable change to prior BetterCP/M content.
