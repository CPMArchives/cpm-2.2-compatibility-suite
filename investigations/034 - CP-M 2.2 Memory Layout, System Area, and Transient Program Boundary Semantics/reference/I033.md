# Investigation 033 - CP/M 2.2 BDOS/BIOS Error Propagation and Recovery Semantics

The filesystem artifact uses `BDOS-BIOS` because `/` cannot occur in a filename. The report title preserves the requested subject.

Evidence classes used below are: **A** documented CP/M behavior; **B** behavior of the examined DRI implementation; **I** controlled experimental observation; and **D** unresolved BetterCP/M policy. These classes describe this report only. Proposed ledger evidence uses the project abbreviations requested by the investigation.

## 1. Objective and scope

This investigation defines the externally visible CP/M 2.2 propagation boundary when a BIOS disk READ or WRITE reports final physical failure: what BDOS does, what a direct BDOS caller or transient program sees, how the CCP participates, and what can safely be assumed about state and recovery.

The scope includes sequential and random I/O, directory I/O, retry ownership, ignored and aborted physical errors, later operation after either choice, and the distinction between logical file-operation results and physical-media presentation. It does not define hardware-controller behavior, host errors, CP/M 3 extensions, or a BetterCP/M error architecture.

## 2. Relationship to previous investigations

I015 established the physical-error presentation and its foundational entries 0390-0413. I019 established the stateful BIOS disk-call boundary and one-logical-sector READ/WRITE result. I020 established WBOOT's public recovery result. I025 established function-specific logical errors rather than a universal BDOS error number. I027 established the BDOS register/result convention. I030 established file lifecycle and metadata transitions. I032 established CCP resident-command and BDOS interaction.

I033 does not reopen those conclusions. It joins them into a propagation and recovery contract and adds controlled directory-read, Delete-write, repeated-failure, and post-error recovery evidence. References to prior findings identify inherited evidence rather than new experiments.

## 3. Documentation findings

**A.** The CP/M 2.2 Alteration Guide defines BIOS READ and WRITE results as zero for success and nonzero for nonrecoverable error. CP/M distinguishes only zero from nonzero at this boundary. The BIOS is directed to retry recoverable disk errors at least ten times before returning a nonzero final result.

**A.** A final error causes BDOS to display a drive-qualified `BDOS ERR ... BAD SECTOR` diagnostic. The documented operator choices are carriage return to ignore the error or Control-C to abort. Thus the documented physical-error interface is interactive; it is not specified as another Function 20, 21, 33, 34, Make, Delete, Rename, Search, or Close return code.

**A.** The Interface Guide defines logical results per BDOS function: for example read success versus EOF/unwritten data, write success versus capacity/directory failure, and directory success/no-match codes. It does not define a universal physical-error status, failed-DMA validity, FCB rollback, sector-write atomicity, private BDOS-state restoration, or a portable post-ignore continuation state.

**A.** WBOOT is the documented programmed restart route. Its compatibility result is a functioning resident system and command environment, not a particular reload loop, set of physical sectors, retry count, stack value, or private-state image.

## 4. BIOS source findings

**B.** The distributed BIOS/CBIOS examples implement the documented selected-drive/track/sector/DMA context and return zero or nonzero from READ/WRITE. Retry and controller interpretation occur below BDOS in the BIOS-specific layer.

**B.** Exact controller status values, head movement, physical-sector mapping, delay, and retry loop are configuration details. The examined source supports the boundary and guided fault injection; it is not by itself experimental proof of every BIOS.

## 5. BDOS source findings

**B.** In the examined February 1980 DRI `OS3BDOS.ASM`, the disk-buffer read/write helpers call BIOS READ/WRITE and test only zero/nonzero. A nonzero result diverts through the permanent-error path before the calling file operation constructs its ordinary logical result.

**B.** That path prints the Bad Sector diagnostic and reads an operator character. Control-C enters the BDOS reboot path. Any other character in this DRI build returns from the handler and resumes the interrupted higher-level path. This is broader than the guide's stated carriage-return ignore choice.

**B.** BDOS contains no second disk-transfer retry loop on this path; it relies on BIOS to return nonzero only after BIOS-level recovery has failed. Routine names, vector addresses, stack routing, and private flags are not compatibility requirements.

## 6. BIOS error reporting

The compatibility boundary is a single status distinction in A: zero means that the selected 128-byte logical transfer succeeded; nonzero reports final physical failure after BIOS recovery attempts (**A**, strengthened by I019/I033). No exact nonzero numeric taxonomy is carried upward.

The injected reference failures occurred before DMA or media transfer. They therefore establish behavior for that controlled failure point only. They do not establish what a real controller leaves after a late or partial transfer, nor do they generalize controller-specific causes such as not-ready, selection failure, or damaged media into separate portable codes (**I**).

## 7. BDOS error propagation

A BIOS nonzero result does not propagate as a normal file-call value. It transfers control into BDOS operator-error presentation. Consequently, the direct caller is suspended while the prompt waits for a response (**A/B/I**).

If the operator ignores the error, DRI resumes the interrupted BDOS path. The caller can then receive the path's ordinary success-looking result even though the physical transfer did not occur. If the operator enters Control-C, the BDOS call does not return to the interrupted caller; recovery transfers through warm restart to the CCP (**A/B/I**).

Logical failures remain different: the probes' EOF and unwritten-random-record controls returned 01h directly, emitted no Bad Sector diagnostic, and required no CCP or operator intervention (**I**, consistent with the Interface Guide and I025).

## 8. Retry behavior

**REQUIRED:** the BIOS must make the documented recovery attempts before reporting final failure. The Alteration Guide's minimum is at least ten retries for recoverable READ/WRITE errors.

**NOT REQUIRED:** BetterCP/M need not reproduce a particular controller retry sequence, timing, status code, or the DRI distribution's implementation layout. It also need not place an additional retry loop in BDOS if the externally visible BIOS/BDOS contract conforms.

**I:** the deterministic injector deliberately produces a final one-shot failure at the BIOS boundary; it does not count underlying controller retries. Two freshly armed failures in one CP/M session each reached Bad Sector presentation. After each scripted ignore, the caller returned; a subsequent unarmed read succeeded.

## 9. File operation failure behavior

### Reads

Sequential and random physical read failures displayed Bad Sector and, after ignore, returned 00h. DMA retained the prefilled EEh marker because no transfer occurred. Sequential CR nevertheless advanced from 00h to 01h; the random operation's working position followed its own higher-level path (**I015/I033**). A normal-looking result, changed FCB, or unchanged DMA is not a portable success certificate after an ignored physical failure.

### Writes and lifecycle

Injected sequential and random physical write failures displayed Bad Sector. After ignore they returned success-looking values, and in-memory FCB state could advance, although the before/after images were identical because the injector failed before transfer (**I015/I033**).

Injected Make and Close directory writes likewise could produce success-looking directory results without media persistence. Controlled allocation-full and extent-extension failures from I030 are logical nonzero returns, not physical-error presentation. They establish the logical contrast, not the physical state of a partially completed allocation.

No claim is made that a real failed write is atomic. Data, extent, allocation, and directory sectors may have reached different stages before final failure. CP/M 2.2 specifies neither rollback nor a transaction boundary.

## 10. Directory operation failure behavior

The new Search test injected a physical directory READ failure during Function 17. BDOS printed Bad Sector; after ignore, Search returned slot 01h, but the caller DMA did not contain a valid newly transferred directory record. The slot code therefore did not certify a successful physical directory read (**I**).

The new Delete test injected the directory WRITE used to remove `ATTR.DAT`. BDOS printed Bad Sector; after ignore, Function 19 returned 00h, but the disk image remained byte-identical and `ATTR.DAT` was still present (**I**).

I015's Make case similarly returned a success-looking result without creating the file after an ignored directory-write failure. Search Next and Rename were not separately injected in I033; the DRI source routes their physical directory transfers through the same common handler (**B**), but this report does not label unperformed Search Next or Rename cases as experimental evidence.

Directory order, search cursor, DMA record, allocation bookkeeping, and cached directory state following ignore are not documented continuation contracts.

## 11. BDOS state after failure

The configured DMA address itself is not shown to be reset by the error path, but data at that address is not valid new input after an ignored failed read. The current drive remained usable in the reference runs, yet exact private drive/login/checksum/allocation state after arbitrary physical failure is unspecified.

After ignore, affected public state may reflect higher-level progress despite absent transfer: CR may advance, a working FCB may change, and directory functions may return ordinary-looking codes. Applications cannot infer rollback, coherence, or persistence from those values (**NOT GUARANTEED**).

The safe compatibility conclusion is narrower than a recovery design: CP/M permits execution to continue when the operator chooses ignore, but does not promise that the interrupted operation's FCB, DMA contents, search cursor, or file lifecycle remains a sound basis for further use.

## 12. CCP error handling

The Bad Sector text and response loop are BDOS behavior in the examined DRI system; CCP is not translating the physical failure into a resident-command result. While a transient is blocked in BDOS, the CCP does not receive a command.

After Control-C, WBOOT restores a command environment and CCP displays a new prompt. After ignore, control first returns through the interrupted BDOS call and transient; only when that program terminates does CCP resume normally. Logical errors can instead be interpreted and presented by the resident command or transient that receives the function-specific return (**I032/I033**).

## 13. Transient program error handling

A transient calling BDOS cannot assume every disk error returns. A logical file failure normally returns according to the function's contract. A final physical failure suspends the call for operator action. Ignore may return with a misleading ordinary result; Control-C abandons the transient and does not return to its instruction stream.

Therefore an application cannot portably discover the physical failure from the returned A/L/HL value after ignore, and it must not treat changed FCB fields or DMA contents as validation. CP/M 2.2 supplies no documented application callback, structured controller status, retry count, or resumable exception object.

## 14. Recovery behavior

In the ignore recovery run, the failed sequential read returned to the transient. The transient completed, CCP accepted `DIR ATTR.DAT`, and a subsequent healthy probe read returned 00h with DMA marker 41h. In the abort run, Control-C prevented the transient's `RETURNED` marker, WBOOT reached CCP, and the same later DIR and healthy read succeeded (**I**).

The repeated A-A-N run demonstrated two ignored final read failures in one session followed by a successful read; its image remained identical to the base (**I**).

These results show that this reference system can remain usable after either route. They do not guarantee preservation of the interrupted operation's private state after ignore or application state across WBOOT. WBOOT's required result is the usable reinitialized resident/CCP environment established by I020; exact disk reset, login-vector, allocation-vector, DMA, stack, and cached-state mechanics are not portable.

## 15. Experimental results

All tests used a preserved CP/M 2.2 image and a local z80pack cpmsim 1.39 build whose only functional instrumentation is an unused output port that arms one pre-transfer BIOS READ or WRITE failure. Console responses were scripted; no manually typed input was used.

| Matrix item | Probe/case | Observable result |
|---|---|---|
| Successful read | READERR33 / N | 00h, DMA marker 41h, no diagnostic |
| Failed sequential read | READERR33 / A | Bad Sector; ignore; 00h; CR advanced; DMA marker remained EEh |
| Failed random read | READERR33 / B | Bad Sector; ignore; 00h; DMA marker remained EEh |
| Repeated failed read | RECOVER33 / A-A-N | Both failures prompted/returned after ignore; later healthy read succeeded |
| Logical EOF/unwritten | READERR33 / I/J | 01h, no Bad Sector diagnostic |
| Failed sequential/random write | WRITEERR33 / C/D | Bad Sector; ignore; success-looking result; no pre-transfer image change |
| Failed Make/Close write | WRITEERR33 / E/F | Bad Sector; ignore; success-looking result; metadata did not persist |
| Failed extension/allocation | I030 controls | Logical nonzero result; no physical-error prompt |
| Failed Search directory read | DIRERR33 / K | Bad Sector; ignore; slot 01h; no valid transferred directory record |
| Failed Delete directory write | DIRERR33 / L | Bad Sector; ignore; 00h; file remained; image unchanged |
| Continue after error | RECOVER33 / A | Caller returned, then CCP DIR and healthy read succeeded |
| Warm boot/restart | RECOVER33 / G | Caller did not return; CCP restarted; later DIR/read succeeded |
| Direct BDOS caller | READERR33/WRITEERR33/DIRERR33 | Function result, FCB, and DMA captured by transient probe |
| Transient program | all named probes | Suspended at prompt; ignore resumed or Control-C abandoned it |
| CCP command | CCPERR33 / recovery scripts | Later DIR worked; CCP was restart destination after abort |

Every accepted injected run started from a fresh copied image. For the pre-transfer cases, image identity proves only that the instrumentation performed no media transfer. Search Next, Rename, real partial transfers, controller-specific invalid-media states, and cross-BIOS behavior remain unperformed and are not claimed.

## 16. Compatibility conclusions

**REQUIRED**

- Preserve the BIOS zero/nonzero final READ/WRITE result and documented BIOS recovery duty.
- Keep physical BIOS failure separate from function-specific logical BDOS result codes.
- Present the documented operator Bad Sector path, including ignore continuation and Control-C abort, in strict CP/M 2.2 compatibility behavior.
- On physical-error Control-C, abandon the interrupted call and restore a usable warm-started command environment.
- Preserve normal direct returns for documented logical errors.

**NOT GUARANTEED**

- A normal-looking result after ignore does not prove transfer, persistence, deletion, creation, or valid directory enumeration.
- Affected DMA, FCB, search, extent, allocation, and directory state need not be coherent or rolled back.
- Physical writes need not be atomic, and partial data visibility is unspecified.
- Application execution state does not survive the abort/WBOOT route.

**NOT REQUIRED**

- Exact BIOS controller codes, retry timing/algorithm beyond the documented duty, DRI internal handler names/addresses, exact CCP reload mechanics, or private-state layout.
- A universal modern error number, exception, or transaction model absent from CP/M 2.2.

**POLICY PENDING**

- Exact diagnostic spelling and capitalization; whether strict mode accepts only carriage return or DRI's any-non-Control-C ignore behavior; optional structured/headless error extensions; and any BetterCP/M guarantee stronger than CP/M for post-ignore recovery.

## 17. Proposed Compatibility Ledger additions

The authoritative ledger ends at 0580. The following proposals begin at 0581 and avoid restating entries 0390-0413.

### 0581. Physical failure suspends the BDOS caller

    A final nonzero BIOS READ/WRITE result diverts BDOS into operator-error
    handling; the invoking BDOS call does not deliver an ordinary function
    result until the operator chooses a continuation path.

    Disposition: REQUIRED
    Evidence: I033; BIOS; BDOS; AG
    Conformance: Inject a final BIOS read and write failure and verify that the
    direct caller is suspended at physical-error presentation.

### 0582. Logical failures return without physical-error intervention

    Documented logical file and directory failures return through each
    function's own result convention without entering Bad Sector handling.

    Disposition: REQUIRED
    Evidence: I033; BDOS; IG; AG
    Conformance: Compare EOF, unwritten-record, capacity, and no-match cases
    with injected BIOS failures and verify distinct return/presentation paths.

### 0583. Ignored directory-search result is not validation

    After an ignored physical directory-read failure, a returned Search slot
    code does not guarantee that the caller's DMA contains a valid newly read
    directory record or that search continuation state is coherent.

    Disposition: NOT GUARANTEED
    Evidence: I033; BDOS; BIOS
    Conformance: Fail the directory read during Search, ignore, and inspect the
    returned slot, DMA record, and continuation behavior independently.

### 0584. Ignored directory-update result is not persistence

    After an ignored physical directory-write failure, a success-looking Make,
    Delete, Rename, or Close result does not guarantee that the requested
    directory or allocation change persisted.

    Disposition: NOT GUARANTEED
    Evidence: I033; BDOS; BIOS
    Conformance: Inject pre-transfer directory-write failures and compare the
    returned value with an independently read post-operation disk image.

### 0585. Post-ignore affected state is not a continuation contract

    CP/M 2.2 does not guarantee rollback or coherence of the affected FCB, DMA
    contents, directory-search cursor, extent state, allocation state, or
    private BDOS state after an ignored physical error.

    Disposition: NOT GUARANTEED
    Evidence: I033; BDOS; IG omission
    Conformance: Capture every public state object before and after ignored
    failures without treating unchanged or advanced fields as success proof.

### 0586. Physical-error abort abandons the interrupted caller

    Control-C at Bad Sector presentation aborts the interrupted BDOS path; the
    transient caller is not resumed at the instruction following the call.

    Disposition: REQUIRED
    Evidence: I033; BDOS; CCP; AG
    Conformance: Place a marker after the BDOS call, inject failure, answer with
    Control-C, and verify the marker is absent and CCP recovery occurs.

### 0587. Abort recovery establishes a usable command environment

    The physical-error Control-C route must leave a functioning warm-started
    resident system and CCP command environment, without promising preservation
    of the interrupted application's state.

    Disposition: REQUIRED
    Evidence: I033; BIOS; BDOS; CCP; AG
    Conformance: Abort an injected failure, then execute a CCP command and an
    independent healthy BDOS disk operation.

### 0588. Exact recovery internals are not part of the contract

    Exact disk-reset calls, reload sectors, stack/register residue, private
    BDOS caches, retry implementation, and CCP reconstruction sequence after a
    physical-error abort are not required if the documented public recovery
    result is achieved.

    Disposition: NOT REQUIRED
    Evidence: I033; BIOS; BDOS; CCP; AG
    Conformance: Compare distinct conforming implementations by public
    post-restart behavior rather than internal call sequence or addresses.

## 18. Proposed existing-entry updates

- **0390-0396:** add I033 as strengthening evidence for BIOS final-result propagation, BIOS retry ownership, physical/logical separation, Bad Sector presentation, ignore, and abort. No wording correction is required.
- **0397:** replace POLICY PENDING with **REQUIRED** for the public recovery destination/result only: Control-C abandons the interrupted BDOS call and reaches a usable warm-started CCP environment. Keep exact restart mechanics NOT REQUIRED. Evidence: I020/I033; BIOS; BDOS; CCP; AG.
- **0398-0403:** add I033 directory Search/Delete and recovery evidence. Preserve their NOT GUARANTEED dispositions and the partial-write limitation.
- **0404-0408:** add I033 as comparative evidence that logical result codes remain distinct from physical-error presentation.
- **0409-0413:** no disposition change. I033 confirms duplicate avoidance and leaves exact text, accepted ignore characters, and structured extensions as policy questions.
- **I019 BIOS disk entries, I025 file-error entries, I027 call-result entries, I030 lifecycle entries, and I032 CCP entries:** add I033 only where cross-layer propagation or post-abort CCP usability is useful corroboration; do not duplicate their function-level propositions.

## 19. Open questions

1. Should strict BetterCP/M accept only documented carriage return to ignore, or every non-Control-C character as the examined DRI BDOS does?
2. Is literal diagnostic spelling part of strict compatibility or only the operator-visible meaning and choices?
3. Should an optional noninteractive/headless mode expose structured physical errors while strict mode retains CP/M behavior?
4. Should BetterCP/M deliberately provide stronger post-ignore reset/reopen guidance or guarantees outside strict mode?
5. How do other historical BIOSes implement the required retry duty and respond to selection/not-ready/write-protect controller failures?
6. What application-visible states follow genuine late or partial physical writes? This investigation's pre-transfer injector cannot answer that.
7. Separate Search Next and Rename injection, and cross-BIOS repetition, remain useful strengthening work but are not claimed here.

## 20. Conformance implications

A conformance suite must test the boundary, not DRI's private implementation. It should supply controlled BIOS success and final nonzero results for both READ and WRITE; distinguish logical errors from physical presentation; script ignore and Control-C; verify whether the direct caller resumes; capture results, FCB, DMA, directory, and media independently; and execute a new CCP command plus healthy disk operation after abort.

Tests must not equate success-looking post-ignore codes with success, require atomic rollback, demand an exact nonzero BIOS value, or inspect DRI handler addresses. Tests of retry duty should use an instrumented BIOS capable of reporting attempts, while allowing controller-specific algorithms. Tests of recovery should require a usable public CCP/BDOS environment, not byte identity of private state.

## Preservation and completion audit

- The investigation directory and all five required named ASM/COM probes are present.
- Every probe contains or references purpose, procedure, observation, and compatibility conclusion in `observed-output-033.txt` and `README.txt`.
- The five named COM files and the underlying extended PHYS015 COM rebuild byte-identically; `rebuild.diff` is empty.
- Fresh before-images, accepted after-images, raw transcripts, deterministic harnesses, complete modified-emulator source, and hashes are preserved under `probes/`.
- All performed cases are reported; Search Next, Rename, partial-transfer, and cross-BIOS cases are explicitly marked unperformed.
- No evidence is claimed from source alone where an experiment is described as observed.
- The authoritative Compatibility Ledger was not modified; its pre-investigation SHA-256 is preserved in `probes/ledger-sha256-before.txt`.
- A protected-tree before/after manifest verifies that no pre-existing BetterCP/M file changed. Only the new Investigation 033 directory is added.

## Sources

- Digital Research, *CP/M 2.0 Interface Guide*, printed file-operation sections (visually checked PDF source).
- Digital Research, *CP/M 2.2 Alteration Guide*, BIOS READ/WRITE and error-handling sections (visually checked PDF source).
- Digital Research, `OS3BDOS.ASM`, February 1980; distributed BIOS/CBIOS sources.
- BetterCP/M Investigations 015, 019, 020, 025, 027, 030, and 032.
- z80pack cpmsim 1.39 with DRI CP/M 2.2 and Z80 CBIOS 1.2; preserved I033 fault-injection source, images, harnesses, transcripts, and rebuild records.
