# Investigation 024 - CP/M 2.2 Transient Program Lifecycle, Termination, and BDOS Return-State Semantics

## 1. Objective and scope

This investigation establishes the application-visible CP/M 2.2 lifecycle
after a transient has begun execution: how RET, BDOS Function 0, and JMP 0000h
return control; which state is preserved, restored, or reconstructed; and which
cleanup an application must perform itself. It does not prescribe BetterCP/M
internals or repeat file-operation semantics.

## 2. Method and evidence classification

- **A** is documented CP/M behavior.
- **B** is behavior explained by DRI CCP/BDOS source.
- **I** is behavior measured in deterministic z80pack CP/M 2.2 experiments.
- **D** is an unresolved compatibility-policy question.

Source was used to select discriminating tests, not as a substitute for them.
Each accepted case began with a fresh copy of one fixture. A following OBS24
transient recorded page zero, live drive/user, and default-DMA behavior. Raw
transcripts and before/after images are preserved.

## 3. Relationship to earlier investigations

I001 and I002 established the three termination forms and the BDOS calling
boundary. I007 established drive/user operations. I020 established WBOOT and
page-zero reconstruction. I021-I023 established CCP dispatch, CALL 0100h,
entry stack, and default DMA. I024 does not relitigate those propositions; it
compares their consequences after the application has changed state.

## 4. Documentation findings

The Alteration Guide defines 0000h as the WBOOT gateway and says a user branch
to 0000h performs a warm start. WBOOT reloads CP/M below the BIOS, reconstructs
0000h and 0005h jump gateways, establishes IOBYTE as the BIOS implements it,
and enters CCP with C specifying the selected drive. The documented contract is
semantic; exact vector targets and reload addresses are configuration-specific.

The Interface Guide and Features and Facilities describe BDOS as the transient
system interface and document the standard page-zero/FCB lifecycle. They do not
promise that termination implicitly closes application FCBs, restores arbitrary
page-zero bytes, preserves registers, or normalizes character-device state.

Function 0 is System Reset. The DRI BDOS dispatch table routes selector zero to
BIOS WBOOT rather than returning normally. The manuals do not define RET in
terms of CCP's private stack layout; the valid return environment is established
by the combined documented/DRI/experimental record from I002, I022, and I023.

## 5. CCP source findings

OS2CCP.ASM invokes a transient with `CALL 0100h`. If it returns, CCP replaces SP
with its private stack, writes its saved command drive to page-zero state,
selects that drive, and jumps to its command loop. It does not invoke WBOOT and
does not reset the BDOS user number. Before each new transient it restores DMA
0080h and saves current packed user/drive state.

OS3BDOS.ASM dispatches Function 0 directly to BIOS WBOOT. JMP 0000h reaches the
same BIOS gateway without entering BDOS. Neither path returns through the
caller's BDOS or CCP stack. DRI source contains no implicit iteration over open
application FCBs at any of these termination points.

These implementation facts explain the experiments but exact labels, stack
addresses, and reload sequence are NOT REQUIRED.

## 6. Termination mechanisms

| Property | RET | BDOS Function 0 | JMP 0000h |
|---|---|---|---|
| Immediate control path | CCP's CALL return | BDOS dispatch to WBOOT | page-zero WBOOT gateway |
| BIOS WBOOT | no | yes | yes |
| Valid application stack needed | yes | only to call BDOS until dispatch | no call stack requirement |
| CCP becomes usable | yes | yes | yes |
| Page-zero vectors reconstructed | no | yes | yes |
| Exact private route required | no | no | no |

All immediate probes returned to a usable prompt. The absence of a second cold
boot banner is not evidence that WBOOT was skipped: vector reconstruction in
the mutated tests independently distinguishes RET from the two warm starts.

RET restores control, not application register or memory state. It consumes the
word at the application's SP. BADSP24 safely supplied 0000h there; RET entered
WBOOT. CP/M performed no stack validation or repair. A valid entry return word
is REQUIRED, but an application that corrupts SP has left the contract.

## 7. State preservation results

### Drive and user

STATE24 changed from A/user 0 to B/user 1. After RET, CCP restored its saved
command drive A while BDOS user 1 survived; OBS24 saw packed page-zero 10h and
live A/user 1. After Function 0 and JMP 0000h, the prompt was B and OBS24 saw
packed 11h with live B/user 1. Thus DRI RET and WBOOT differ: RET reselects the
CCP's pre-command drive; warm start carries coherent current drive/user state
through this BIOS/CCP path.

Because WBOOT drive transfer and user packing straddle BIOS and DRI CCP policy,
exact cross-BIOS preservation beyond the documented selected-drive handoff is
POLICY PENDING. Programs cannot observe state after their own termination; the
compatibility consumer is the next CCP command or transient.

### DMA

STATE24 selected DMA 0200h. The next transient received DMA 0080h after RET,
Function 0, and JMP 0000h, proven by a read without Function 26 overwriting
0080h with `D023-DEFAULT-DMA`. This strengthens I022/I023: applications may rely
on default DMA at a new transient boundary, not on the value during private CCP
or WBOOT processing.

### Page zero

STATE24 replaced 0000h/0005h with safe trampolines and set IOBYTE to 40h. RET
left the trampoline gateways visible to the next transient. Function 0 and JMP
0000h reconstructed the configured WBOOT and BDOS vectors. Thus RET performs no
general page-zero restoration; WBOOT must reconstruct required gateways.

IOBYTE 40h survived all three paths on this BIOS. Documentation delegates its
initialization to the BIOS if implemented, so neither reset-to-zero nor
preservation of an arbitrary IOBYTE is a universal CCP requirement.

### Files and disk

FILE24 successfully made and wrote one record to a path-specific file, then
omitted Close. After every termination form, CHECK24 could open the directory
entry but Read Sequential returned 01h (EOF), RC was zero, and no written record
was delivered. Drive A images changed because Make/write updated disk state;
drive B did not. The result demonstrates no implicit FCB Close or file-length
finalization on RET, Function 0, or JMP 0000h. Applications must close files
whose metadata must persist. Open FCB memory is application memory, not a
system-owned handle that CCP cleans up.

### Console

BDOS Function 2 output completed before all three terminations. CP/M 2.2 exposes
no general per-process echo or output mode for CCP to restore. LIST/console
routing represented by IOBYTE is global/BIOS state; its 40h test value survived
here. Exact post-termination routing is NOT GUARANTEED beyond the BIOS's WBOOT
contract.

## 8. Experimental results

The accepted matrix comprised fourteen isolated runs:

1. immediate RET, Function 0, and JMP 0000h;
2. drive/user/DMA/page-zero mutation followed by each path;
3. Make/write-without-Close followed by each path;
4. console output/IOBYTE mutation followed by each path;
5. out-of-range BDOS Function 41;
6. a safely corrupted RET stack whose supplied word was 0000h.

Immediate and all nonwriting state/console/error case images match their
fixtures byte-for-byte. The file cases differ only on drive A. Function 41
returned 00h and execution continued, confirming the already-established
out-of-range selector behavior rather than adding a new termination rule.

The exact state matrix is:

| State at next transient | RET | Function 0 | JMP 0000h |
|---|---|---|---|
| CCP route usable | yes | yes | yes |
| current drive after B selection | A (saved CCP drive) | B | B |
| user after selecting 1 | 1 | 1 | 1 |
| DMA at new entry | 0080h | 0080h | 0080h |
| modified vectors | survive | reconstructed | reconstructed |
| IOBYTE 40h on this BIOS | survives | survives | survives |
| unclosed record finalized | no | no | no |

No required experimental case is incomplete. The discarded preliminary probe
with an incoherent 0004h value was a design error and is not preserved or cited
as lifecycle evidence.

## 9. Compatibility conclusions

**REQUIRED:** usable termination by RET with the supplied return environment;
System Reset through Function 0; programmed warm restart through JMP 0000h;
WBOOT reconstruction of required page-zero gateways; and default DMA 0080h at
the next transient boundary.

**NOT GUARANTEED:** exact SP/return address, registers, arbitrary page-zero
restoration after RET, IOBYTE normalization, implicit FCB cleanup, unclosed
write persistence, and application behavior after corrupting its return stack.

**NOT REQUIRED:** DRI private CCP stack arrangement, exact resident/reload
addresses, exact instruction path, cold-boot banner on warm start, or an
internal open-file registry matching DRI's FCB model.

**POLICY PENDING:** the exact drive/user state that BetterCP/M should preserve
across each termination form where DRI CCP state, the packed byte, and BIOS
WBOOT conventions interact.

## 10. Proposed Compatibility Ledger additions

The ledger is not modified. New proposals begin at 0509.

### 0509. Transient termination mechanisms

A CP/M 2.2 transient can return control through the valid entry RET environment,
invoke BDOS Function 0 (System Reset), or branch to 0000h. RET returns through
CCP without WBOOT; Function 0 and 0000h invoke warm-start semantics. All must
restore a usable CCP environment.

Disposition: REQUIRED

Evidence: I024; I002; I022; CCP; BDOS; AG

Conformance: Execute minimal transients using each mechanism and verify a usable
CCP prompt, distinguishing RET from WBOOT by controlled page-zero reconstruction.

### 0510. RET does not generally reconstruct page zero

Normal RET termination follows CCP's post-call path and need not restore
arbitrary application modifications to page zero. Required semantic gateways
must remain usable when the application obeys the entry contract, but no general
RET-time memory cleanup is guaranteed.

Disposition: NOT GUARANTEED

Evidence: I024; CCP

Conformance: Install safe forwarding modifications to 0000h/0005h, terminate by
RET, and verify that compatibility does not depend on CCP rewriting them.

### 0511. Termination does not implicitly close application FCBs

RET, BDOS Function 0, and JMP 0000h do not guarantee an implicit Close or
file-length finalization for FCB writes. Applications must explicitly close
files when Close is required to persist metadata.

Disposition: NOT GUARANTEED

Evidence: I024; CCP; BDOS; IG

Conformance: Make and write a record without Close, terminate through each path,
and verify that an implementation is not required to finalize the FCB as if
Function 16 had been called.

### 0512. Post-termination drive and user policy

The DRI RET path restores CCP's saved command drive while leaving the selected
BDOS user active; the tested WBOOT paths preserved coherent selected drive/user
state. The exact portable preservation rule across BIOS implementations is not
fully established beyond documented WBOOT drive handoff semantics.

Disposition: POLICY PENDING

Evidence: I024; I007; CCP; AG

Conformance: Change drive and user, terminate through all three mechanisms, and
measure the next CCP prompt and BDOS Functions 25/32 without assuming DRI's
private state arrangement.

## 11. Existing-entry updates

- **0001-0004:** strengthen evidence for warm-start and BDOS gateway semantics;
  no duplicate or disposition change.
- **0010 and 0025-0030:** strengthen lifecycle evidence where these entries
  address termination, page zero, drive/user, or DMA; retain exact-state limits.
- **0031-0034:** no change; I024 reinforces that exact stack addresses,
  registers, flags, and vector targets are not guaranteed.
- **0475-0488:** no command-acquisition duplicates. Add I024 evidence only where
  a new command begins after termination.
- **0492-0505:** strengthen CALL/RET, WBOOT convergence, and DMA-restoration
  evidence. Do not duplicate I022's load/entry propositions.
- **0508:** strengthen the valid return-environment evidence; exact SP and return
  address remain unguaranteed.
- The out-of-range Function-41 result is confirming evidence for the existing
  BDOS selector-range proposition, not a new ledger entry.

## 12. Open questions

1. Which drive/user preservation rule should BetterCP/M promise across WBOOT on
   BIOSes that implement the documented C-register handoff differently?
2. Should BetterCP/M intentionally preserve IOBYTE across WBOOT, initialize it
   through BIOS policy, or expose this solely as BIOS-defined behavior?
3. Should conformance diagnostics warn about unclosed writable FCBs even though
   CP/M compatibility must not silently close them?

These are policy questions; no experiment required by this investigation is
missing.

## 13. Artifact preservation audit

- The new Investigation 024 directory contains report, sources, binaries,
  listings, harnesses, transcripts, memory snapshots, disk images, directory
  listing, build instructions, and SHA-256 manifests.
- All nine original COM binaries rebuild byte-identically.
- Each accepted case has its own preserved post-run A/B images; the fixture is
  the common before-image. All nonwriting images match the fixture.
- File cases changed only drive A, as expected.
- Ledger 023 SHA-256 before and after is
  `7160044713c5a43aac1aaa4544720334e940ec5c0003c8b76d841e6df66944ae`.
- No previous investigation, ledger, architecture, roadmap, specification, or
  source file was modified. All writes are confined to Investigation 024.
- No ZIP archive was created.

## 14. Sources

- Digital Research, *CP/M Features and Facilities*.
- Digital Research, *CP/M 2.0 Interface Guide*.
- Digital Research, *CP/M 2.2 Alteration Guide*.
- Digital Research CP/M 2.2 `OS2CCP.ASM` and `OS3BDOS.ASM`.
- BetterCP/M Investigations 001, 002, 007, and 020-023, plus Compatibility Ledger 023.
- z80pack cpmsim Release 1.39, repository commit `91fd28eb04e675c2127df88ed3f40675e15282e2`.
- Investigation 024 probe sources, raw transcripts, image corpus, and hashes.

