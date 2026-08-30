# Investigation 035 - CP/M 2.2 Cold Boot, Warm Boot, and Restart Semantics

Evidence classes used below are: **A** documented behavior, **B** DRI
implementation behavior, **I** experimental observation, and **D** unresolved
BetterCP/M policy. They are investigation labels, not ledger evidence tags.

## 1. Objective and scope

This investigation defines the application-visible CP/M 2.2 contract for cold
BOOT, WBOOT, CCP restart, BDOS disk reset, and restart after an abortable disk
error. It identifies the participating BIOS, BDOS, and CCP components and
separates required transition outcomes from residual implementation state.

Hardware ROM loaders, vendor hardware initialization, CP/M 3, MP/M, and a
BetterCP/M boot design are outside scope. Directly invoking BIOS BOOT tests the
configured entry contract; it is not evidence about power cycling or a ROM.

## 2. Relationship to previous investigations

Investigation 020 established the BIOS jump-table and BOOT/WBOOT interfaces.
Investigation 024 distinguished RET, Function 0, and address-zero termination.
Investigation 026 covered application-visible system state and Function 13.
Investigation 028 established the CCP handoff and saved return mechanism.
Investigation 033 established DRI disk-error presentation and abort recovery.
Investigation 034 established memory ownership and the overlayable TPA.

Investigation 035 adds a single controlled state matrix across these mechanisms.
It strengthens, rather than repeats, their interface conclusions. In particular,
it resolves an older reference observation about user state by deliberately
placing STATE35 in user 7 on both tested drives: the tested DRI warm paths
preserved user 7. Whether every compatible implementation must preserve it
remains governed by the existing policy-pending ledger entry 0155.

## 3. Documentation findings

**A.** The CP/M 2.2 Alteration Guide defines the BIOS as a 17-entry jump vector
whose first entries are BOOT and WBOOT. BOOT is entered from the cold loader,
performs basic initialization, may print a sign-on, initializes IOBYTE if the
implementation supplies it, prepares WBOOT parameters, and transfers to the CCP
with C selecting drive A. WBOOT is entered through the address-zero path, reloads
CP/M from drive A except for the BIOS, restores the address-zero WBOOT jump and
address-five BDOS jump, applies the BIOS's IOBYTE policy, and transfers to the
CCP with C selecting the drive.

**A.** The Interface Guide documents Function 0 as system reset/return to CP/M,
Function 13 as disk-system reset, Function 14 as drive selection, Function 25 as
current-drive query, Function 26 as DMA selection, and Function 32 as user-code
access. The documented interfaces define useful postconditions, not blanket
memory erasure, exact reload addresses, exact console buffering, or private
CCP/BDOS data structures.

**A.** Documentation does not promise that arbitrary TPA bytes, application
FCBs, directory-search continuation, pending console characters, or private
BIOS device state survive a restart. Nor does it prescribe an exact boot
loader, sign-on text, sector-read sequence, or hardware reset procedure.

## 4. BIOS source findings

**B.** CBIOS.ASM implements BOOT by setting the IOBYTE and saved current disk to
zero and then joining a common CCP-entry path. WBOOT reloads the CCP and BDOS,
then joins that path. The common code restores the 0000h WBOOT jump and 0005h
BDOS jump, sets DMA to 0080h, and passes the saved drive in C to the CCP.

**B.** The supplied MDS BIOS has the same public control shape but a different
IOBYTE policy: its initialization establishes the byte and WBOOT leaves it set.
This source contrast is affirmative evidence that the documented IOBYTE
initialization hook is a BIOS policy boundary, not one universal byte value.

**B.** Neither reviewed BIOS performs a blanket TPA clear. Exact disk sectors,
reload loops, console initialization, and sign-on output are implementation
mechanisms. Compatibility attaches to the usable environment they establish.

## 5. CCP source findings

**B.** OS2CCP receives packed state in C: the low nibble identifies the drive
and the high nibble identifies the user. At CCP start it establishes the user,
initializes the disk interface, selects the drive, resets its stack, and restores
the default DMA for command processing.

**B.** The ordinary transient RET route uses the return word supplied by the CCP.
That route restores the CCP's saved execution context; it does not itself call
the BIOS WBOOT entry. Consequently RET and WBOOT may converge on an interactive
prompt while having different intermediate and final public state.

**B.** Command lookup can itself log drives. Therefore a login vector measured
only after STATE35 has been found and loaded is not the vector at the instant of
WBOOT entry. This investigation does not infer that WBOOT initially produced
the later observed value 0003.

## 6. Cold boot semantics

**A/I - REQUIRED.** Cold BOOT must establish a usable configured CP/M system:
BIOS services, BDOS and CCP availability, valid public page-zero gateways,
initial disk environment, the BIOS-defined IOBYTE policy, and entry to the CCP
with drive A selected.

On the reference system the initial observation was drive A, user 0, login vector
0001h, read-only vector 0000h, IOBYTE 00h, valid 0000h/0005h jumps, and default
DMA 0080h. A direct BOOT after deliberate mutation repeated the sign-on and
restored these public values.

**I - NOT GUARANTEED.** BOOT left the deliberately written bytes at 0050h and
D000h intact. Applications therefore cannot use “cold boot” as a portable claim
that every RAM byte was cleared, even though a particular physical power-on may
incidentally alter RAM.

## 7. Warm boot semantics

**A/B/I - REQUIRED.** WBOOT is a nonreturning system transition that restores or
reconstructs the resident command environment, the address-zero WBOOT gateway,
the address-five BDOS gateway, and the default DMA, then enters a usable CCP.
Reloading the exact same physical CCP/BDOS sectors is DRI/BIOS behavior; an
equivalent compatible reconstruction is sufficient.

WARM35 selected B/user 7, selected DMA 0800h, changed IOBYTE and safe gateway
operands, and set memory markers before jumping to 0000h. STATE35 then observed
B/user 7, restored gateway destinations, and active DMA 0080h. Function 0
produced the same result for every measured field.

**I - NOT GUARANTEED.** Bytes at 0050h and D000h survived in this configuration,
as did IOBYTE 40h and the packed drive/user choice. Their observation describes
DRI plus this BIOS; it is not a general promise that WBOOT preserves arbitrary
memory or every device-private state item.

## 8. Boot entry points

**A.** BOOT and WBOOT are compatibility-visible BIOS jump-table entries. BOOT is
for cold initialization; WBOOT is the restart/reload path. Address 0000h is the
application-visible route to WBOOT, while address 0005h remains the BDOS call
gateway. The CCP entry and private reload routines are not stable application
entry points.

**I.** Direct BOOT and WBOOT did not return to their probes. Both established a
CCP prompt, but BOOT selected A/user 0 and applied cold IOBYTE initialization,
whereas WBOOT carried the tested B/user 7 and IOBYTE 40h state.

## 9. BDOS reset behavior

**B/I.** OS3BDOS dispatches Function 0 to WBOOT. Its Function 13 clears the
read-only and logged-drive vectors, selects A through the drive-selection path,
and restores the default DMA; it does not explicitly change `usrcode`.

RESET35 established B/user 7, login vector 0003h, read-only vector 0002h, and DMA
0800h. After Function 13 it measured A/user 7, login vector 0001h, read-only
vector 0000h, and active DMA 0080h. Thus the reference implementation preserved
user 7. Entry 0155 correctly remains POLICY PENDING for the universal user-code
requirement; this result is not grounds to silently promote it.

Function 13 returned normally and is distinct from WBOOT: it resets the disk
subsystem without reconstructing the whole CCP/page-zero environment.

## 10. Disk state transitions

Cold BOOT produced drive A and a usable logged-in A. Function 13 explicitly
reduced the controlled login vector to A and cleared the read-only vector. WBOOT
carried the tested current-drive choice B to the CCP, but later command lookup
logged A as well; the resulting 0003h observation must not be misidentified as
the instantaneous WBOOT value.

Allocation-vector and DPB pointers observed after each transition were usable
for the selected drive. Their exact addresses (FCB0h/FCCFh and FA8Dh here),
allocation contents, directory scan cursor, and cached private disk structures
are not portable restart state. Open FCBs and search continuations must be
treated as invalid across restart unless a separately documented interface says
otherwise.

## 11. Memory state transitions

The public page-zero control cells are transition outputs. WBOOT rebuilt the
0000h and 0005h gateways and set the drive/user byte used by the CCP. The tested
BIOS reloaded CCP/BDOS while retaining itself; those exact resident boundaries
remain configuration-specific.

The TPA and other unowned bytes are residual, not preserved storage. Their
survival in the test is positive evidence only that neither tested BOOT nor
WBOOT cleared them. Applications relinquish their transient environment at
termination and cannot assume that any FCB, stack, buffer, code, or marker will
remain usable after a restart.

## 12. Console state transitions

BOOT may print a BIOS sign-on and initialize console/IOBYTE state according to
the configured BIOS. WBOOT need not print the cold sign-on. Exact escape
sequences, cursor state, physical device state, and buffered device internals
are BIOS/terminal details.

PEND35 observed a scripted `Z` through Function 11 without consuming it and then
jumped to 0000h. After restart, a carriage return executed an empty CCP command;
`Z` was not dispatched. Thus pending input was lost in this configuration.
Preservation or loss of an unconsumed character across WBOOT is NOT GUARANTEED.

## 13. Drive and user state transitions

The controlled reference outcomes were:

| Transition | Drive | User | Gateways | DMA |
|---|---:|---:|---|---|
| Initial/direct BOOT | A | 0 | reconstructed | 0080h |
| ordinary RET | A (saved CCP context) | 7 | deliberately altered values survived | 0800h until CCP command setup |
| Function 0 | B | 7 | reconstructed | 0080h |
| JMP 0000h | B | 7 | reconstructed | 0080h |
| Function 13 | A | 7 | not a gateway transition | 0080h |
| disk-error Control-C | B | 7 | reconstructed | 0080h |

The RET result is especially important: reaching the prompt is not sufficient
to prove that WBOOT occurred. The tested saved CCP return restored A while the
warm-start routes carried B in the packed restart state.

## 14. Error-induced restart behavior

RECOVER35 opened a controlled file, established B/user 7 and the same public
mutations, and armed a one-shot physical BIOS read failure. DRI printed `Bdos Err
On B: Bad Sector` and waited for its recovery choice. The harness supplied
Control-C. BDOS did not return to the probe; the system entered a usable CCP and
STATE35 observed the same reconstructed gateways/default DMA and B/user 7 result
as the deliberate warm paths.

This establishes the DRI Control-C abort branch for the tested physical read
error. It does not generalize to retry, ignore, hard reset, non-DRI diagnostics,
every BIOS failure, CCP lookup failure, or an uncontrolled program crash. A
plain erroneous transient instruction has no documented automatic recovery
contract; only defined termination/restart paths are portable.

## 15. Experimental results

Seven isolated cases ran from fresh copies of controlled A/B disk images. No
manual keyboard input was used. Full transcripts, before/after images, sources,
listings, executables, harnesses, and hashes accompany this report.

| Case | Trigger | Principal result |
|---|---|---|
| cold | startup, then BIOS BOOT | CCP usable; cold public state restored; markers survived |
| ret | transient RET | saved CCP return; no WBOOT gateway reconstruction |
| fzero | BDOS Function 0 | WBOOT-equivalent measured state |
| warm | JMP 0000h | WBOOT-equivalent measured state |
| reset | BDOS Function 13 | A, login A, RO clear, DMA 0080h; user 7 observed |
| pending | status then JMP 0000h | offered unconsumed `Z` did not survive |
| error | physical read error, Control-C | no BDOS return; WBOOT reconstruction and CCP recovery |

All after-images matched their corresponding before-images byte-for-byte; the
matrix executed no successful disk writes. The standard emulator and the custom
one-shot fault emulator are separately identified in the hash records.

## 16. Compatibility conclusions

1. **REQUIRED:** provide cold BOOT and WBOOT entry contracts and valid public
   page-zero gateways in the configured system.
2. **REQUIRED:** cold BOOT must yield a usable CCP/BDOS/BIOS environment with
   drive A selected; exact loader and hardware initialization are free.
3. **REQUIRED:** WBOOT must restore or equivalently reconstruct a usable command
   environment and default DMA before normal CCP operation.
4. **REQUIRED:** Function 0 and address-zero termination enter the system restart
   path; ordinary RET may return by the CCP-supplied frame without WBOOT.
5. **REQUIRED:** implement documented Function 13 disk reset effects already
   captured by ledger entries 0132-0137.
6. **NOT GUARANTEED:** arbitrary TPA, scratch RAM, application FCB/search state,
   console pending input, and private device state across BOOT/WBOOT.
7. **NOT REQUIRED:** exact DRI sector reload, sign-on wording, memory-clear
   pattern, internal CCP entry, private pointers, and source layout.
8. **POLICY PENDING:** whether BetterCP/M promises Function 13 user preservation
   beyond the documented minimum (existing entry 0155).

## 17. Proposed ledger additions

The current ledger ends at 0592; the next available number is 0593.

### Proposed Compatibility Ledger additions

0593. Cold BOOT public postcondition

    A configured cold BOOT shall establish usable BIOS, BDOS, and CCP service,
    valid public page-zero gateways, the configured initial IOBYTE policy, and
    CCP entry with drive A selected.

    Disposition: REQUIRED

    Evidence: I035, BIOS, BDOS, CCP, IG, AG

    Conformance: From an arbitrary pre-BOOT public-state pattern, invoke the
    configured BOOT entry and verify a usable A-drive CCP/BDOS environment and
    valid 0000h/0005h gateways; do not require a particular loader or sign-on.

0594. Cold BOOT does not promise blanket memory clearing

    Applications shall not assume that cold BOOT clears every TPA, zero-page,
    or otherwise unspecified RAM byte.

    Disposition: NOT GUARANTEED

    Evidence: I035, BIOS, MEMORY, AG

    Conformance: A system may retain or overwrite unspecified memory during
    BOOT; applications must rely only on documented post-BOOT state.

0595. WBOOT command-environment reconstruction

    WBOOT shall nonreturningly restore or equivalently reconstruct a usable CCP
    environment, the public 0000h/0005h gateways, and default DMA state.

    Disposition: REQUIRED

    Evidence: I035, BIOS, CCP, MEMORY, AG

    Conformance: Corrupt safe gateway operands and select a nondefault DMA, then
    enter WBOOT and verify reconstructed gateways, DMA 0080h, and a usable CCP.

0596. Residual state across WBOOT

    Survival of arbitrary TPA/scratch bytes, pending console input, application
    FCB/search state, and private BIOS/BDOS/CCP state across WBOOT is not part of
    the CP/M 2.2 compatibility contract.

    Disposition: NOT GUARANTEED

    Evidence: I035, BIOS, BDOS, CCP, MEMORY, IG, AG

    Conformance: Applications shall remain correct whether such unspecified
    state survives or is overwritten; implementations need not reproduce the
    reference residue.

0597. Console-pending state across WBOOT

    CP/M 2.2 does not guarantee preservation of a character reported pending but
    not consumed before WBOOT.

    Disposition: NOT GUARANTEED

    Evidence: I035, BIOS, IG, AG

    Conformance: After WBOOT, either loss or BIOS-defined retention of previously
    pending unconsumed console input is compatible unless the configured BIOS
    interface separately promises otherwise.

## 18. Existing-entry updates

No ledger file was changed. The following evidence-only updates are proposed:

- **0133-0136:** add I035 RESET35 evidence for read/write-state reset, drive A,
  DMA 0080h, and controlled login-vector reinitialization.
- **0155:** add the DRI observation that Function 13 preserved user 7, while
  retaining POLICY PENDING.
- **0397 and 0586-0588:** add RECOVER35 evidence that Control-C at the tested DRI
  physical-read error did not return to the application and joined WBOOT.
- **0464-0467:** add direct BOOT/WBOOT experiment evidence and the memory-residue
  boundary; keep exact loading mechanics implementation-free.
- **0504 and 0509:** add the measured Function 0/JMP 0000h convergence.
- **0510 and 0541:** add the deliberately changed gateway/DMA evidence showing
  that ordinary RET did not perform WBOOT reconstruction.
- **0512:** clarify that I035 observed DRI WBOOT carry B/user 7, while ordinary
  RET restored the CCP's saved A drive; retain stated policy boundaries.
- **0538:** add evidence that WBOOT and CCP command setup restored DMA 0080h.

No new entry duplicates Function 0 selector behavior, the existing termination
taxonomy, or the general memory-ownership rules.

## 19. Open questions

- **D:** Whether BetterCP/M elects to guarantee Function 13 user preservation is
  still the existing entry 0155 policy decision.
- **D:** A later conformance suite may define a portable way to observe the
  immediate post-WBOOT login vector before CCP lookup itself changes it.
- **D:** Pending-input behavior should remain BIOS-defined unless a target BIOS
  profile adopts a stronger rule.
- Physical write-error abort, retry/ignore branches, and vendor BIOS reset
  behavior remain governed by their own investigations and profiles; they were
  not silently inferred from the performed read-failure case.

## 20. Conformance implications

A BetterCP/M implementation passes this contract when its configured BOOT and
WBOOT entries establish the documented public environment, Function 0 and
address-zero restart reach a usable CCP, Function 13 supplies its documented
disk reset, and applications cannot distinguish it by depending on private DRI
reload machinery. Tests should poison public state before transitions and check
postconditions, not exact instruction sequences or private addresses.

Conformance must also test the negative boundary: surviving RAM, exact current
user policy where unresolved, pending input, open FCBs, directory cursors, and
private pointers must not accidentally become universal promises. Error recovery
is conformant through its documented/profiled presentation and restart outcome,
not necessarily through DRI's exact diagnostic text.

### Completion audit

- The Investigation 035 directory, report, five required probes, four supporting
  fixtures, transcripts, preserved images, references, harnesses, and hash files
  are present.
- Every COM file rebuilt byte-identically from its preserved source.
- The custom fault emulator rebuilt identically from its preserved source.
- Each controlled after-image matched its corresponding before-image.
- This investigation made no ledger write. During execution, an external change
  replaced the authoritative ledger's baseline SHA-256
  `e199cfb104bb3f9b675a08e579ef7562bbed7ea34286853fe42dfda42827fb09`
  with `62e6614d59ef63cd391e05e273c35fbed8ab9d9be1ea83e79083a0933fd8d9c9`;
  it still ends at 0592. The discrepancy is recorded rather than misreported as
  an Investigation 035 modification.
- The protected-tree check found only that external ledger change and a Finder
  `.DS_Store` change inside Investigation 033. All other 1,749 pre-existing
  files matched the baseline. No architecture, roadmap, specification, earlier
  report, or BetterCP/M implementation file was changed by this investigation.
