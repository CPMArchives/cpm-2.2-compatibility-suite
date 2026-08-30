# Investigation 028 - CP/M 2.2 CCP Transient Execution Handoff and Loader State Contract

Status: Complete evidence report; Compatibility Ledger not modified  
Date: 2026-08-16

## 1. Objective and scope

This investigation defines the externally visible handoff from CCP loader to a
transient at 0100h and the state CCP reconstructs after ordinary return. It
integrates, rather than repeats, I021-I024 and I026-I027. Evidence labels are
**A** documented, **B** DRI source, **I** experiment, and **D** unresolved
policy. Exact CCP addresses, private variables, and instruction order are not
requirements.

## 2. Relationship to previous investigations

I021 established parsing/dispatch, I022 lookup and contiguous COM loading,
I023 the entry environment, I024 termination, I026 global BDOS state, and I027
the CALL 0005h ABI. I028 tests those pieces as one boundary: whether all public
objects coexist before the first transient BDOS call, what memory the loader
does not initialize, what survives RET, and how load failures suppress entry.

## 3. Documentation findings

**A:** CCP recognizes nonresident commands, loads `NAME.COM` from the resolved
drive into the TPA, and transfers execution. The TPA begins at 0100h; page zero
provides warm-start and BDOS jumps, current command environment, a default FCB,
and the 0080h default buffer/command line. The manuals define the state visible
to the transient, not a required private preparation order.

**A:** Address 0005h is the primary BDOS gateway and also exposes the configured
resident boundary through the documented page-zero convention. A transient may
immediately call BDOS with the I027 convention. The manuals do not promise that
unloaded TPA bytes, free stack space, memory above the COM image, or residual
registers are cleared or initialized.

**A:** A transient command prefixed by a drive is loaded temporarily from that
drive and the original logged disk is restored for subsequent processing. COM
files are record-oriented; no portable byte count exists inside the final
128-byte record.

## 4. CCP source findings

**B:** DRI CCP parses the command, supplies type COM, temporarily selects an
explicit command drive, Opens the FCB, and reads sequential 128-byte records
with DMA destinations 0100h, 0180h, and upward. It performs no general TPA clear
and initializes no separate transient stack area.

After each successful record it advances and compares the next destination to
`tranm', the configured resident boundary. EOF code 1 accepts the image; other
nonzero read results or boundary equality/overflow select `BAD LOAD'. On
success CCP restores the command drive, constructs default FCB state and the
tail, selects DMA 0080h, saves packed user/drive state, and executes `CALL
0100h'.

After RET, DRI resets its private SP, restores saved user/drive through BDOS,
selects the drive, and restarts command acquisition. Function 0 and JMP 0000h
instead reach warm-start handling as characterized by I024. Source order
explains observations but is not itself the portable contract.

## 5. Loader sequence

The externally necessary sequence is semantic:

1. Resolve an executable candidate and successfully obtain its COM records.
2. Place accepted records contiguously from 0100h without reaching protected
   resident system memory.
3. Before transfer, expose valid page-zero gateways/state, default FCB/tail,
   default DMA 0080h, and callable BDOS.
4. Transfer with a valid return word compatible with RET.

Whether page zero is rewritten before Open, during loading, or only at accepted
EOF is not observable by ordinary transient code, because it is not executing
during load. Exact order among FCB construction, tail copying, DMA restoration,
and private saves is therefore **NOT REQUIRED**, provided the complete handoff
exists before the first instruction at 0100h.

## 6. Entry handoff state

ENTRY28 captured state before diagnostic output and made Function 12 its first
BDOS call. It entered with SP=EBA9h, warm-start jump bytes beginning C3/03,
IOBYTE 00h, packed environment 0004h=00h, BDOS jump beginning C3/06, and
Function-12 result 0022h. Exact addresses/SP are **I**; gateway semantics,
valid return word, and immediate BDOS readiness are REQUIRED.

For `B:ENTRY28 ONE TWO`, CCP delivered the first FCB prefix for `ONE', the
overlapping second prefix for `TWO', and counted tail `08 20 4F 4E 45 20 54 57
4F'. These strengthen I023 but do not settle its second-FCB/NUL policy items.
Initial DMA is 0080h as established by I022/I023; loader DMA destinations are
not inherited by the transient.

MIN28 consisted solely of RET and returned normally. No separate application
stack initialization was needed beyond CCP's CALL-produced return environment.
Exact stack depth and bytes above/below the return word remain unpromised.

The page-zero BDOS jump and resident-boundary convention make the available TPA
discoverable in the documented manner, but the exact maximum COM size is
configuration-dependent. Programs must not infer a universal numeric top from
this 64K run.

## 7. Error paths

`B:NOFILE28' produced `B:NOFILE28?' and reprompted: failure occurred before
entry. ERROR28 was a small positive control and printed `ERROR28 EXECUTED'. The
same executable prefix padded to 454 records as BIGERR28 reached the reference
resident boundary, produced `BAD LOAD', reprompted, and did not print the
execution marker.

Thus missing Open and oversized/rejected load are distinct DRI presentations,
but both suppress CALL 0100h and recover a usable CCP. Exact wording,
punctuation, and internal cleanup path remain presentation/implementation
details. Physical-media failures remain governed by I015/I025 and were not
re-injected.

## 8. Experimental results

Seven deterministic assembly sources and five named investigation roles were
used under z80pack cpmsim 1.39, DRI CP/M 2.2, Z80 CBIOS 1.2.

- Minimal one-byte MIN28 returned successfully.
- Before LOAD28, MEM28 observed 3000h/4000h/8000h = 87h/7Fh/83h.
- LOAD28 immediately called BDOS Function 12 (0022h), recorded entry SP, wrote
  5Ah at 4000h, and RETurned.
- A newly loaded MEM28 then observed 87h/5Ah/83h. CCP had not cleared memory
  above the small new image. Those byte values are residue, not a guarantee.
- ENTRY28 captured page-zero, 32 FCB bytes, counted tail, SP, and immediate BDOS
  version for two operands.
- RETURN28 wrote A5h at 5000h, changed DMA to 0300h, selected B/user 7, and
  RETurned. CHECK28 then saw command drive A, user 7, and A5h still at 5000h.
  This agrees with I024: CCP reconstructs state it needs but does not sanitize
  the TPA. DMA for the next transient is reset to 0080h by its own handoff.
- Missing and oversized cases reprompted; rejected oversized bytes did not run.

The tests show DRI preserves residue; they do not require BetterCP/M to preserve
it. Applications must regard memory beyond loaded records as undefined and must
initialize their own data/stack. Transient modifications to page zero are
possible while it runs, but may break gateways and are reconstructed by later
boot/CCP handoff as specified elsewhere; they do not alter the immutable meaning
of the entry contract.

## 9. Compatibility conclusions

**REQUIRED:** contiguous accepted COM records at 0100h; protection of resident
memory; complete page-zero/default-FCB/tail/default-DMA state before execution;
immediate BDOS availability; valid RET environment; suppression of execution
after lookup/load rejection; recovery of usable CCP state.

**NOT GUARANTEED:** memory beyond the loaded records; final-record padding;
registers; flags; exact SP/return address; stack contents; persistence of DMA,
drive, user, page-zero modifications, or arbitrary TPA data after termination;
numeric TPA top/maximum file size; behavior of code that overwrites gateways.

**NOT REQUIRED:** clearing or preserving unused TPA, exact CCP preparation
order, private loader FCBs/addresses, exact load loop, exact diagnostic text,
physical WBOOT reload mechanics, or DRI's CALL-site address.

**POLICY PENDING:** I023's NUL/second-FCB/tail-capacity issues and I024's broader
post-termination state policy remain unresolved. I028 adds no new policy choice.

## 10. Proposed Compatibility Ledger additions

The ledger is not modified. Proposals begin at 0534.

### 0534. Complete transient handoff

    Before execution at 0100h, CCP provides the required page-zero gateways,
    command environment, default FCB/tail state, default DMA, and RET context.

    Disposition: REQUIRED

    Evidence: I028; CCP; AG; IG; I022; I023; I027.

    Conformance: Capture all public entry objects before the first diagnostic
    call and immediately invoke BDOS.

### 0535. Handoff preparation ordering

    CP/M 2.2 does not require an exact internal ordering for load, page-zero,
    FCB, tail, DMA, or private CCP preparation when the complete entry state is
    established before control reaches 0100h.

    Disposition: NOT REQUIRED

    Evidence: I028; CCP; documentation specifies resulting interfaces.

    Conformance: Test entry state, not private instruction order.

### 0536. Unloaded transient memory

    Memory above the accepted COM records, unused TPA space, and any separate
    stack area have no defined initial contents and need not be cleared or
    preserved between transient programs.

    Disposition: NOT GUARANTEED

    Evidence: I028; IG/AG silence; CCP; MEM28 residue experiment.

    Conformance: Vary unused memory contents; applications initialize storage
    before relying on it.

### 0537. Immediate BDOS readiness

    The page-zero BDOS gateway and initialized BDOS state are usable by the
    transient immediately upon entry at 0100h.

    Disposition: REQUIRED

    Evidence: I028; AG; IG; CCP; I027; LOAD28/ENTRY28.

    Conformance: Make a documented BDOS call as the first external operation.

### 0538. Loader DMA isolation

    CCP's changing DMA destinations used to load COM records are not inherited;
    the transient entry DMA is restored to 0080h with the command buffer.

    Disposition: REQUIRED

    Evidence: I028; CCP; I022; I023; AG.

    Conformance: Load a multirecord program and use DMA immediately without
    Function 26.

### 0539. Transient stack preparation

    CCP supplies a valid CALL-produced RET word, but no exact entry SP, return
    address, deeper stack contents, or separately cleared application stack.

    Disposition: NOT GUARANTEED

    Evidence: I028; IG; CCP; I001; I023; I027.

    Conformance: Require immediate RET to work while varying numeric stack state.

### 0540. Load rejection suppresses execution

    Missing, failed, or oversized transient loads do not execute partial/rejected
    bytes and recover a usable command environment at the applicable error layer.

    Disposition: REQUIRED

    Evidence: I028; CCP; I022; I025; ERROR28/BIGERR28.

    Conformance: Embed a visible entry marker and verify it is absent on failure.

### 0541. Post-RET reconstruction boundary

    After ordinary RET, CCP may reconstruct command drive/user, stack, DMA, and
    page-zero state needed for the next command; arbitrary TPA residue and
    transient-selected state are not a persistence interface.

    Disposition: NOT GUARANTEED

    Evidence: I028; CCP; I024; I026; RETURN28/CHECK28.

    Conformance: Mutate state and memory, return, and validate only the next
    command's documented environment.

## 11. Existing-entry updates

- Entries 0001-0034: add I028 to 0100h origin, bounds, page-zero, default DMA,
  RET word, and undefined-register/memory propositions; no disposition change.
- Entries 0475-0505: add I028 handoff-wide evidence. Preserve I022's lookup,
  loading, boundary, and error propositions rather than duplicating details.
- Entries 0506-0508: add ENTRY28 evidence but retain all I023 policy statuses.
- Entries 0509-0512: add RETURN28/CHECK28 evidence; do not generalize the
  observed user-7 survival or TPA residue into required persistence.
- Entries 0518-0525: add I028 to BDOS/DMA state at handoff; no change.
- Entries 0526-0533: add immediate-BDOS and RET-stack evidence to the common
  call contract; no change.

## 12. Open questions

1. The second default-FCB prefix, following NUL, and exact tail-capacity policies
   remain those identified by I023.
2. Whether BetterCP/M deliberately clears free TPA for security is an extension
   policy; strict compatibility must not let applications depend on either
   clearing or DRI-style residue.
3. Exact loader diagnostic presentation remains governed by I021/I025 policy.
4. Physical read failures were not repeated; I015 controls that evidence layer.

## 13. Artifact preservation audit

The new directory contains this report, sources, binaries/listings, oversized
fixture generator, deterministic harnesses, transcripts, memory dumps, base and
case images, directory listings, build instructions, and SHA-256 manifests.
All source-built COM files rebuild byte-identically and BIGERR28 regenerates
byte-identically. The authoritative Investigation-027 ledger SHA-256 before and
after is `126131a96608ab7fa4516be3b8f838dfb925dfb204da8576a7dd85280c62c06c`.
All prior protected files remain unchanged.

## 14. Sources

- Digital Research, *An Introduction to CP/M Features and Facilities*, transient
  commands section.
- Digital Research, *CP/M 2.0 Interface Guide*, TPA/BDOS/FCB/DMA conventions.
- Digital Research, *CP/M 2.2 Alteration Guide*, reserved page-zero locations.
- Digital Research CP/M 2.2 `OS2CCP.ASM` and `OS3BDOS.ASM`.
- BetterCP/M Investigations 021-024 and 026-027.
- z80pack cpmsim 1.39 reference environment and preserved I028 artifacts.

