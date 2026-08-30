# Investigation 036 - CP/M 2.2 BIOS Runtime Environment and Hardware Abstraction Boundary Semantics

Evidence labels: **A** documented CP/M behavior; **B** DRI implementation;
**I** experiment; **D** unresolved policy. Historical-practice conclusions name
their corpus rather than treating one example as universal.

## 1. Objective and scope

This investigation defines the CP/M 2.2 BIOS as a runtime compatibility boundary:
the documented vector, direct calls, public disk structures, raw devices, failure
returns, and the implementation freedom behind them. It does not design a new
BetterCP/M abstraction or require vendor-private routines.

## 2. Compatibility standard

The standard combines the published CP/M 2.2 ABI, DRI source behavior, controlled
z80pack observations, and demonstrated ecosystem practice. A de facto requirement
is admitted only where preserved software actually uses it. The local corpus proves
direct BIOS use by DRI SYSGEN and vector manipulation by XSUB; it does not prove
that every listed third-party software category used identical conventions.

## 3. Relationship to previous investigations

Investigations 018-020 established character devices, disk calls, and the vector.
Investigation 033 established physical-error propagation. Investigations 034-035
established system-memory and restart boundaries. Investigation 036 tests those
parts together and determines what direct BIOS clients, rather than BDOS alone,
may rely upon.

## 4. Documentation findings

**A.** The Alteration Guide publishes 17 consecutive three-byte JMP entries,
BOOT through SECTRAN, and gives register contracts for character and disk calls.
It explicitly says BDOS needs only CONST/CONIN/CONOUT for console operation while
PIP may use LIST/PUNCH/READER and DESPOOL used LISTST. Thus the vector is meant to
be callable outside a private BIOS implementation.

Character data is seven-bit ASCII with zero parity. Disk calls form a stateful
sequence: SELDSK, SETTRK, SETSEC, SETDMA, then READ/WRITE. READ/WRITE return zero
for success and nonzero for unrecoverable failure. SELDSK returns a DPH or zero.
SECTRAN maps a zero-based logical index and table pointer to the sector passed to
SETSEC. Documentation leaves physical hardware, addresses, buffering, optional
device implementations, and residual registers open.

## 5. BIOS source findings

**B.** BIOS.ASM and CBIOS.ASM preserve the 17-slot order but differ in device
routing, IOBYTE handling, controller commands, translation, buffering, sign-on,
and optional-device stubs. DEBLOCK.ASM shows a BIOS may translate 128-byte logical
requests into larger physical transfers without changing the public interface.

OS3BDOS names all BIOS entries as `bios+3*n`, calls console entries directly, and
maintains disk selection state before READ/WRITE. Exact routines, private variables,
stacks, controller status, and DPH addresses are implementation details.

## 6. BIOS as a public interface

**A/B/I - REQUIRED.** The documented BIOS vector is a public system-software ABI.
DRI SYSGEN derives entries from the WBOOT operand and directly invokes SELDSK,
SETTRK, SETSEC, SETDMA, READ, and WRITE. This is decisive de facto evidence that a
CP/M-compatible environment cannot treat BIOS as inaccessible BDOS internals.

The obligation is the documented vector and configured behavior, not unrestricted
access to arbitrary code/data inside BIOS. Programs that bypass BDOS also bypass
BDOS file-system protection, buffering, error presentation, and serialization.

## 7. BIOS jump table contract

The 17 entries must occur in the published order and be callable as three-byte JMP
slots. BOOT/WBOOT are control transfers; remaining entries use the documented
register parameters and results. The base is configuration-dependent and is derived
from the WBOOT gateway rather than hard-coded.

No general register-preservation promise exists beyond documented outputs. The BIOS
is stateful and is not required to be reentrant. Empty routines may RET where their
device is unsupported, but the vector slot must remain present.

## 8. Direct BIOS calling conventions

Direct clients load documented parameters, CALL the selected JMP slot (or transfer
to BOOT/WBOOT), and consume only documented results. VECTOR36 observed the public
discovery bytes; BIOS36 found base FA00h and 17 C3 slots. Absolute FA00h, target
addresses, stack residue, undocumented flags, and private entry points are NOT
GUARANTEED.

DRI SYSGEN demonstrates the common portable pattern: read the WBOOT target from
page zero and add documented vector offsets. Hard-coding a vendor BIOS address or
calling past the table is vendor binding, not general CP/M compatibility.

## 9. Console service behavior

CONST reports immediate availability with the documented zero/nonzero convention;
CONIN waits and returns the seven-bit character in A; CONOUT accepts C. LIST and
PUNCH accept C, READER returns A/Control-Z at EOF, and LISTST is callable. CON36
validated that C and A cross this boundary without BDOS transformation.

Direct calls expose raw BIOS device behavior: they do not acquire BDOS line editing,
echo, tab expansion, printer echo, Control-C policy, or IOBYTE routing unless that
BIOS implements it at the device layer. Exact LISTST encoding and absent optional
device behavior remain policy pending from Investigation 020.

## 10. Disk service behavior

SELDSK selects logical drive C and returns the public DPH; HOME/SETTRK/SETSEC/SETDMA
establish persistent context; READ/WRITE transfer one 128-byte logical sector and
return raw status; WRITE receives type C=0/1/2; SECTRAN returns the translated
sector. DISK36 observed the ordered state changes, directory DMA substitution,
all write types, translation, and direct sector reads.

Direct disk use is historically real (DRI SYSGEN) but dangerous: callers must know
the configured DPB/DPH geometry, coordinate with BDOS, avoid corrupting allocated
media, and reset/revalidate higher layers. Physical cylinders, sector IDs, host
files, controller timing, and blocking algorithms are NOT REQUIRED.

## 11. BIOS memory structures

Compatibility-visible structures are the jump table and the DPH graph returned by
SELDSK: XLT, directory scratch buffer, DPB, allocation-vector and checksum-vector
pointers, with documented layouts and sharing rules. The DPB defines logical
geometry. These objects must be readable while valid because both BDOS and direct
disk utilities consume them.

Their addresses, placement, writable private workspace, buffer implementation, and
unpublished system variables are NOT GUARANTEED. Direct clients may not infer that
every pointer denotes exclusive or permanently stable memory.

## 12. Vendor BIOS variations

Normal variations include BIOS base, supported drives, DPBs/DPHs, translation
tables, physical sector size, deblocking, IOBYTE policy, optional character devices,
status encoding details, retry mechanics, console escape handling, and hardware
initialization. Software historically tolerated these by using the vector and
returned tables rather than controller ports or absolute addresses.

Vendor extensions outside the 17 entries may be useful within a named machine
profile, but are NOT GUARANTEED by generic CP/M 2.2. BetterCP/M must make configured
device/media profiles coherent; it need not emulate every vendor extension globally.

## 13. Application and utility BIOS usage

The evidence supports these categories and motives:

- system generation/disk imaging: DRI SYSGEN directly reads/writes system tracks;
- command extensions: DRI XSUB discovers and temporarily changes the WBOOT vector;
- spool/file utilities: documentation names PIP and DESPOOL as optional-device users;
- debuggers/diagnostics/disk tools: the published vector enables raw console and
  media access, but exact prevalence was not quantified in the local corpus;
- communications/hardware diagnostics: direct raw devices are plausible and common
  in machine-bound software, but vendor ports/extensions remain profile-specific.

The resulting requirement is support for the standard direct BIOS ABI. It is not a
claim that every assembler, debugger, or communications package bypassed BDOS.

## 14. BIOS error behavior

Direct READ/WRITE callers receive A=0 success or A nonzero final failure after the
BIOS's required recovery attempts. They do not inherently receive DRI's `Bdos Err`
message, retry/ignore/abort prompt, rollback, or warm restart; those are BDOS/CCP
layers. Console/list/reader/punch unavailability is BIOS/profile behavior where the
published interface gives no richer standardized error object.

ERROR36 injected a pre-transfer BIOS read failure. BDOS converted it into the DRI
prompt; carriage-return ignore returned to the transient with affected FCB state and
unchanged DMA. This confirms the layer boundary, not a universal direct-call UI.

## 15. BIOS/CCP interaction

The CCP obtains command characters and output through BDOS, which in turn uses BIOS
console services. It relies on WBOOT for reconstruction and uses BDOS for ordinary
file lookup/loading. The cold/warm transfer parameters and device sign-on policy
belong to BIOS; command parsing, echo policy above raw calls, and transient dispatch
belong to CCP/BDOS.

## 16. BIOS/BDOS boundary

BIOS owns configured physical-device access, logical-sector transfer, translation,
raw status, and DPH/DPB publication. BDOS owns FCB semantics, directories,
allocation, record positioning, disk login/read-only state, higher-level buffering,
and DRI physical-error presentation. Software observes both layers when it calls
BIOS directly, but must not attribute BDOS guarantees to the raw call.

## 17. Experimental results

Five named artifacts ran from fresh disk copies. BIOS36/CON36 enumerated and
interposed direct vectors; VECTOR36 independently captured page zero; DISK36 traced
the boundary and directly translated/read sectors; ERROR36 used a one-shot physical
failure. Full transcripts and images are preserved.

The normal disk case changed only A as expected from its controlled file lifecycle;
B remained identical. Both error-case images remained identical because injection
occurred before host transfer. All programs rebuild byte-identically.

## 18. Compatibility conclusions

- **REQUIRED:** callable 17-entry standard BIOS vector, public discovery, documented
  registers/results, DPH/DPB graph, raw character calls, and stateful logical-sector
  disk sequence.
- **REQUIRED:** direct BIOS access for compatible system utilities; BDOS-only access
  is insufficient.
- **NOT GUARANTEED:** residual registers, reentrancy, hard-coded addresses, private
  variables, optional-device availability, and state survival after unrelated calls.
- **NOT REQUIRED:** DRI source layout, exact hardware/controller model, exact buffers,
  exact retries beyond documented outcome, or unprofiled vendor extensions.
- **POLICY PENDING:** strict LISTST/absent-device conventions and which named vendor
  profiles BetterCP/M elects to expose.

## 19. Proposed ledger additions

The authoritative ledger ends at 0597; the next available number is 0598.

### Proposed Compatibility Ledger additions

0598. Public DPH object graph

    The DPH returned by SELDSK and its documented XLT, directory-buffer, DPB,
    checksum-vector, and allocation-vector references are readable runtime BIOS
    interface objects for BDOS and direct system software.

    Disposition: REQUIRED
    Evidence: I036; BIOS; BDOS; IG; AG
    Conformance: Select a configured drive, traverse the documented DPH fields,
    and perform operations consistent with the returned DPB/translation data.

0599. Raw direct-BIOS error boundary

    A direct BIOS disk caller receives the documented zero/nonzero transfer result;
    BDOS diagnostic text, retry/ignore/abort interaction above final BIOS status,
    and CCP recovery are not inherent effects of the direct BIOS call.

    Disposition: REQUIRED
    Evidence: I036; BIOS; BDOS; CCP; AG
    Conformance: Inject a final BIOS transfer failure both through a direct caller
    and through BDOS; require raw status in the former and configured BDOS handling
    only in the latter.

0600. Vendor-private BIOS extensions

    Routines, variables, ports, vector slots, and entry conventions outside the
    standard CP/M 2.2 BIOS interface are not portable unless a named platform
    profile explicitly supplies them.

    Disposition: NOT GUARANTEED
    Evidence: I036; BIOS; DEVICE; IG; AG
    Conformance: Generic applications shall not require a vendor-private entry;
    profile-specific tests may require only the extension declared by that profile.

0601. Optional BIOS device profile

    Which reader, punch, list, LISTST, IOBYTE-routing, and unavailable-device
    behaviors BetterCP/M guarantees beyond the documented minimum is a configured
    compatibility-profile decision.

    Disposition: POLICY PENDING
    Evidence: I036; BIOS; DEVICE; IG; AG
    Conformance: Declare a device profile and test its entries consistently without
    imposing that profile on every CP/M 2.2 configuration.

## 20. Existing-entry updates

No ledger was modified. Proposed evidence updates:

- **0449-0460:** add I036 DISK36 and SYSGEN evidence; preserve stateful/nonreentrant
  and physical-storage boundaries.
- **0461-0463:** add VECTOR36/BIOS36 and DRI SYSGEN de facto discovery evidence.
- **0468-0471:** add CON36 register-transport evidence.
- **0472:** retain POLICY PENDING; synthetic 00/FF transport is not historical
  LISTST-encoding evidence.
- **0473:** strengthen with DRI SYSGEN as an actual direct-BIOS utility.
- **0474:** retain NOT GUARANTEED for residual registers and reentrancy.
- **0581-0588:** add ERROR36 evidence for the raw-BIOS versus BDOS-presentation split.
- **0593-0597:** add I036 boundary context without changing boot/restart dispositions.

## 21. Open questions

1. Which vendor/platform profiles have enough preserved software demand to warrant
   explicit BetterCP/M extension contracts?
2. What exact LISTST and unavailable optional-device rules should each profile use?
3. A broader curated application corpus is needed before assigning frequency to
   debugger, communications, and diagnostic direct-BIOS practices.
4. Direct write conformance needs a disposable reserved-area fixture per target
   format; generic tests must not assume IBM 3740 geometry.

## 22. Conformance implications

A conforming implementation must expose the standard vector as executable runtime
ABI, honor documented register/state contracts, publish coherent disk structures,
and allow legacy direct utilities to discover it through page zero. It may freely
change hardware, buffering, placement, and internal algorithms.

Tests must separate raw BIOS from BDOS: poison undocumented registers, vary BIOS
base and DPH addresses, exercise optional-device profiles, sequence disk state
explicitly, and inject failures at the BIOS boundary. Passing BDOS file tests alone
does not establish direct-BIOS compatibility.

### Completion audit

The report, five required probe sources/binaries, listings, build/run instructions,
transcripts, before/after disks, custom emulator, references, and hashes are present.
All COM files rebuilt byte-identically. Expected disk changes are recorded. The
ledger baseline was checked without writing it, and the protected-tree audit found
no pre-existing BetterCP/M content change attributable to Investigation 036.

