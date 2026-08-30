# Investigation 027 - CP/M 2.2 BDOS Call Interface Convention and Register-State Semantics

Status: Complete evidence report; Compatibility Ledger not modified  
Date: 2026-08-16

## 1. Objective and scope

This investigation consolidates the common application-facing contract around
every normally returning CP/M 2.2 BDOS call: entry, selector and parameters,
results, register state, stack balance, invalid/unsupported inputs, and
reentrancy limits. Individual function semantics remain with their earlier
investigations. Evidence is classified **A** documented, **B** DRI source,
**I** observed, and **D** unresolved policy.

## 2. Relationship to previous investigations

I001 established page-zero entry vectors. I002 first measured this ABI. I008,
I017-I020, and I025-I026 supplied file, pointer, BIOS-boundary, error, and
system-state cases. I024 separated returning BDOS calls from termination. I027
repeats the essential I002 measurements with independent programs, wider
unsupported-selector coverage, 64-call stack guards, parameter normalization,
and malformed-FCB handling. It strengthens I002; it does not replace per-call
contracts.

## 3. Documentation findings

**A:** The primary FDOS/BDOS entry is the jump at 0005h. A transient normally
uses `CALL 0005H`. C carries the function number. DE is the general information
pair, with function descriptions sometimes using E alone or interpreting DE as
an address. Unused registers have no documented required input values.

**A:** A byte result is returned in A and a word result in HL. On every normal
return A=L and B=H. An out-of-range selector returns zero. Combined with the
CP/M 2.2 implementation's 0-40 table, strict 2.2 selectors 41-255 return the
zero result and aliases.

**A:** The manual describes the transient entry stack and says FDOS switches
to a local stack at system entry. This supports balanced return to the caller,
not application access to that private stack. No examined manual promises
preservation of C, DE, flags, IX/IY, alternate registers, or any other state
beyond documented outputs and restored caller SP. No manual authorizes recursive
or interrupt-time BDOS entry.

## 4. BDOS source findings

**B:** Entry saves the application's SP in one global `entsp', switches to one
local stack, saves DE in global `info', clears global two-byte `aret', validates
C against `nfuncs=41', and dispatches through a table. Valid calls copy input E
to C as internal residue. The common epilogue restores the saved SP, loads HL
from `aret', assigns A=L and B=H, and returns.

This mechanism explains the public aliases and balanced SP, but the variables,
addresses, table form, E-to-C copy, local-stack size, and exact instructions are
**NOT REQUIRED**. One `entsp', one `info', one `aret', mutable disk/search state,
and one local stack make DRI BDOS non-reentrant in structure. Recursive entry
could overwrite the outer call's return context. That establishes no portable
right to nested calls; it does not require BetterCP/M to use identical internals.

## 5. Entry convention

The compatible application gateway is page-zero address 0005h, whose jump may
target the installed BDOS. Programs must not depend on the numeric destination
or call private code behind it. `CALL 0005H` supplies the return word required
for returning services. Function 0 is termination and does not follow the
ordinary return contract. Direct invocation of a discovered DRI BDOS address is
outside the interface and **NOT GUARANTEED**.

## 6. Parameter convention

C is the eight-bit selector. DE/E is function-specific input: pointer, FCB,
character, drive, user, vector, or unused. It is incorrect to require DE always
to be a pointer. Function 32 experimentally accepted 00h, 1Fh, 20h, and FEh and
subsequent queries returned 00h, 1Fh, 00h, and 1Eh, confirming documented modulo
32 normalization.

Invalid input is not one common ABI case. A missing/malformed Open returned FFh
in the safe probe, while earlier controlled evidence showed invalid/unavailable
drives can enter fatal/operator diagnostic paths and bad memory pointers lie
outside any safe contract. Applications must satisfy each function's documented
preconditions; the common call convention does not convert arbitrary bad
pointers or FCBs into a universal error return.

## 7. Return convention

CALL27 repeated I002's five raw register records. Function 12 returned
HL=0022h/A=22h/B=00h; Function 7 returned HL=00A5h/A=A5h/B=00h; Function 24
returned HL=0001h/A=01h/B=00h; void Function 26 and out-of-range 41 returned
zero. In every case A=L and B=H.

FUNC27 independently returned HL/A/B zero for DRI-reserved 38 and 39 and for
41, 42, 7Fh, and FFh. Only 41-255 are documented out of CP/M 2.2's implemented
range. Zero from defined-but-reserved 38/39 is observed DRI behavior and should
not be generalized into a rule that every documented no-result function must
return zero unless its contract or software evidence requires it.

## 8. Register preservation

REG27 seeded main registers around Functions 12, 25, 26, and 41. Returned
results and aliases were correct. C became E=34h on valid calls, while
out-of-range 41 retained C=29h. Function 26 changed DE from 1234h to F902h;
other sampled paths left DE unchanged. IX/IY happened to remain 5678h/9ABCh.
CALL27 also observed survival of alternate registers on this configuration.

These are diagnostic observations, not a callee-save convention. Portable
software may rely only on function-defined results, A=L, B=H, and ordinary SP
restoration. C, DE, AF/flags, BC, HL, IX, IY, alternate registers, I, and R are
otherwise **NOT GUARANTEED**. A function that explicitly returns another
register would control for that function, but no general extra return register
exists.

## 9. Experimental results

Five deterministic probes ran under z80pack cpmsim 1.39, DRI CP/M 2.2, Z80
CBIOS 1.2:

- CALL27 captured 25-byte before/after records for Functions 12, 7, 24, 26,
  and 41; raw and decoded dumps are preserved.
- FUNC27 tested value, reserved, and selectors 41/42/7F/FF.
- REG27 recorded AF, BC, DE, HL, IX, and IY sentinels across four paths.
- STACK27 made 64 consecutive Function-12 calls from a controlled guarded
  stack. Every pre/post SP was 0233h; guard bytes remained A5h/3Ch.
- PARAM27 tested Function-32 normalization and a malformed/unactivated Open,
  which returned FFh on this DRI system.

Repeated runs produced the same functional output. Exact SP, internal DE F902h,
flags, and numeric addresses are **I**, not requirements. The harness's final
Ctrl-\\ produces the expected emulator shutdown diagnostic after the CP/M
prompt; it is not a probe failure. Disk hashes show no operation-induced media
change beyond deliberate probe installation.

No unsafe arbitrary-memory pointer was dereferenced: such a test could corrupt
the reference system and cannot create a portable result. Invalid-drive and
fatal-path evidence is incorporated from I025 rather than duplicated.

## 10. Compatibility conclusions

**REQUIRED:** CALL 0005h gateway; selector C; function-specific DE/E input;
byte result A; word result HL; A=L and B=H after every normal return; zero result
for strict CP/M 2.2 selectors 41-255; balanced caller SP for returning calls.

**NOT GUARANTEED:** any general register/flag preservation beyond the defined
outputs; safe behavior for arbitrary pointers, malformed objects, invalid
drives, or violated preconditions; direct calls to private BDOS addresses;
recursive, nested, or interrupt-time BDOS entry.

**NOT REQUIRED:** DRI's local-stack implementation, stack depth/address,
`entsp/info/aret', dispatch table, E-to-C residue, exact flags, observed IX/IY
or alternate-register survival, and exact zero results for reserved 38/39.

**POLICY PENDING:** whether extensions may consume selectors 41-255 despite the
baseline zero contract, and whether BetterCP/M will offer an explicitly separate
reentrant system-service interface. Neither changes strict CP/M 2.2 mode here.

## 11. Proposed Compatibility Ledger additions

The ledger is not modified. Proposals begin at 0526.

### 0526. Common BDOS gateway and invocation

    Returning BDOS services are invoked by CALL 0005h through the page-zero
    BDOS jump; applications must not depend on its private destination.

    Disposition: REQUIRED

    Evidence: I027; IG; AG; BDOS; I001; I002.

    Conformance: Relocate the BDOS target while preserving the 0005h gateway.

### 0527. Common selector and parameter carriers

    C carries the selector and DE/E carries function-specific input; unused
    registers need not contain defined values.

    Disposition: REQUIRED

    Evidence: I027; IG; BDOS; I002.

    Conformance: Exercise pointer, word, byte, and unused DE/E cases.

### 0528. Common result and alias convention

    Normal returns place byte results in A and word results in HL, with A=L
    and B=H in all cases.

    Disposition: REQUIRED

    Evidence: I027; IG; BDOS; I002; CALL27; FUNC27.

    Conformance: Check primary and alias registers for success, error, void,
    and out-of-range returns.

### 0529. Strict CP/M 2.2 unsupported selectors

    Selectors 41-255 are outside CP/M 2.2's 0-40 table and return zero with
    HL=0000h, A=L=00h, and B=H=00h.

    Disposition: REQUIRED

    Evidence: I027; IG; BDOS; I002; FUNC27.

    Conformance: Test 41, 42, 7Fh, 80h, and FFh in strict mode.

### 0530. General register preservation

    No general preservation is guaranteed for registers or flags beyond
    function-defined outputs, result aliases, and restored caller SP.

    Disposition: NOT GUARANTEED

    Evidence: I027; IG silence; BDOS; I002; REG27.

    Conformance: Applications reload needed inputs and tests accept arbitrary
    undocumented residual register state.

### 0531. Returning-call stack balance

    A normally returning BDOS call restores the caller's SP and consumes no
    caller-owned stack beyond the ordinary call/return requirement.

    Disposition: REQUIRED

    Evidence: I027; IG; BDOS; I002; STACK27.

    Conformance: Repeat returning calls on a guarded caller stack and compare SP.

### 0532. Invalid parameters are function-specific

    The common BDOS ABI defines no universal result or safe behavior for
    invalid drives, pointers, malformed FCBs, or violated preconditions.

    Disposition: NOT GUARANTEED

    Evidence: I027; I025; BDOS; IG function-specific contracts.

    Conformance: Validate documented errors per function and require no common
    bad-parameter code.

### 0533. BDOS reentrancy

    CP/M 2.2 does not guarantee recursive, nested, or interrupt-time BDOS
    entry while a prior call is active.

    Disposition: NOT GUARANTEED

    Evidence: I027; IG silence; DRI global-state/local-stack structure.

    Conformance: Compatible applications do not make nested calls; no DRI
    private implementation is required.

## 12. Existing-entry updates

- Entries 0001-0034: add I027 to the page-zero BDOS vector, command-entry
  stack, and default environment propositions; no disposition changes.
- Entries 0080-0170: strengthen the established I002 ABI propositions with
  CALL27/FUNC27/REG27/STACK27 evidence. Preserve all function-specific console,
  disk, and user dispositions.
- Entries 0190-0247: add I027 only where calls rely on common C/DE and A/HL
  mechanics; do not replace search/read-specific results.
- Entries 0509-0512: distinguish termination paths from the ordinary returning
  stack contract; no lifecycle disposition change.
- Entries 0513-0517: add I027 support for function-specific errors and malformed
  parameter limits; no universal error is introduced.
- Entries 0518-0525: add I027 ABI support to the system-state functions and
  strict selector-range correction; no disposition change.

## 13. Open questions

1. Whether a meaningful CP/M 2.2 software corpus depends on incidental IX/IY,
   alternate-register, or reserved-function behavior.
2. How extensions should negotiate selectors without changing strict 2.2's
   observable zero return for 41-255.
3. Whether any DRI publication expressly prohibits interrupt-time BDOS calls;
   absence of permission and non-reentrant source are enough to deny a portable
   guarantee, but not to prescribe BetterCP/M internals.
4. Whether defined void functions need exact zero results individually; this
   must be established function by function, not inferred from the common ABI.

## 14. Artifact preservation audit

The Investigation 027 directory contains the report, five assembly sources,
five binaries and listings, common routines, deterministic harness, raw and
decoded memory/register dumps, transcript, before/accepted images, directory
listing, build instructions, emulator identification, and SHA-256 manifests.
All binaries rebuild byte-identically. The authoritative Investigation-026
ledger SHA-256 before and after is
`d0e1e80848cbba88a2648c0696d4bfdda2d12db0b4b7e158bd1bc1a5a3346c16`.
All protected prior files are unchanged.

## 15. Sources

- Digital Research, *CP/M 2.0 Interface Guide*, Operating System Call
  Conventions and function descriptions.
- Digital Research, *CP/M 2.2 Alteration Guide*, primary BDOS entry and 2.2
  additions.
- Digital Research CP/M 2.2 `OS3BDOS.ASM` and `OS2CCP.ASM`.
- Investigations 001, 002, 008, 017-020, and 024-026.
- z80pack cpmsim 1.39 reference environment and preserved probe evidence.

