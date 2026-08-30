# Investigation 050 - CP/M 2.2 Communications Software Compatibility Survey

## 1. Objective and scope

This investigation asks whether representative CP/M 2.2 terminal, modem, and file-transfer programs expose compatibility requirements absent from the ledger through Investigation 049. It examines Generic Kermit-80 4.11, IMSAI-patched QTERM 4.3e, and XMODEM 2.7 through documentation, source, and controlled executable tests. It does not implement BetterCP/M, design networking, modify the ledger, or treat a particular UART as part of generic CP/M.

The principal result is a profile boundary. Generic communications software can use CP/M's logical character devices and IOBYTE, while high-performance or feature-rich software often uses machine-specific direct ports, timing, or patches. The existing ledger describes these layers. I050 strengthens the case for an active, usable IOBYTE/RDR/PUN communications profile, but it establishes no new baseline CP/M proposition.

## 2. Compatibility standard

Evidence classes are **A** (documented interface), **B** (DRI implementation), **I** (controlled observation), and **D** (unresolved policy). Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Application protocol bytes, UART addresses, baud generators, timing constants, terminal emulation, and diagnostics become requirements only for an explicitly advertised application or machine profile.

Any future ledger evidence update from this report must use exactly `I050 COMMUNICATIONS ECOSYSTEM COMPATIBILITY subsystem IG AG`.

## 3. Relationship to previous investigations

Investigation 019 established BIOS logical device and disk interfaces. I020 established BIOS jump-table and raw character-I/O entry behavior. I036 placed physical device ownership below CP/M's portable interface. I041 separated public gateways from private addresses and direct hardware. I049 found no communications executable corpus and left this category open.

I050 fills that corpus gap and specifically exercises ledger entries 0436-0448 and 0606-0612. It does not reopen their low-level propositions: it asks how real software composes them and where software leaves the portable surface.

## 4. Software corpus

| Software | Category | Platform/interface | Evidence |
|---|---|---|---|
| Kermit-80 4.11, Generic CP/M-80 | Terminal connection; Kermit transfer | 8080-compatible CP/M 2.2; BIOS logical devices plus IOBYTE | Official manual (**A**); T01-T05 (**I**) |
| QTERM 4.3e, IMSAI/VT100 patch | Terminal, modem control, chat scripts, capture, Kermit/XMODEM | Z80; patched IMSAI SIO-2 direct ports | Manuals/source; T06 (**I**) |
| XMODEM 2.7 | Checksum/CRC file transfer | CON, BIOS RDR/PUN, configured ports, or installed routines | Source/configuration; T07 (**I**) |
| CP/M 3 Kermit, RZ, SZ | Cross-version comparison | Explicitly CP/M 3 | Inventoried only; excluded from CP/M 2.2 claims |
| BBS/remote-access server | BBS category | No adequate controlled local corpus | Not tested (**D**) |

The preserved IMSAI communications disk, provenance, sizes, and exclusions are recorded in `probes/corpus-inventory.txt`.

## 5. Documentation findings

The CP/M documentation inherited through I049 (**A**) supplies logical CONSOLE, READER, PUNCH, and LIST services and the optional Intel-standard IOBYTE mapping. It does not specify a UART register map, baud control, carrier detect, DTR, BREAK, interrupt service, modem command language, protocol, terminal type, or a universal independent auxiliary port. Thus CP/M defines transport hooks, not a complete modem API.

The official Kermit-80 guide documents a deliberately portable Generic CP/M build. It uses BIOS logical devices and IOBYTE, defaults to the PTR mapping, and supports mappings such as CRT, TTY, UC1, UR1, and UR2 where the BIOS supplies them. The guide also documents the cost: no generic baud-rate setting or BREAK, approximate CPU-dependent timing, and possible performance limits above 1200 baud. These are application documentation facts, not additional CP/M promises.

## 6. Source findings

Earlier DRI source review (**B**) confirms that BDOS character calls dispatch through logical BIOS services and leaves physical routing to BIOS. No DRI source behavior promotes an IMSAI port or file-transfer protocol into the portable interface.

Third-party source identifies the experimental boundary. QTERM's IMSAI patch selects specific SIO-2 channels and implements modem features outside BDOS. XMODEM can select CP/M CON, BIOS RDR/PUN, configured direct ports, or injected I/O routines; its supplied IMSAI configuration names status/data ports and its timeout calculations accept CPU-speed assumptions. The IMSAI BIOS provides distinct modem routines and maps a logical device to them. Full excerpts and provenance are summarized in `probes/source-analysis.txt`.

Source findings guided T06 and T07. They are not substituted for unperformed peer-transfer experiments.

## 7. System interface usage

Generic Kermit started, parsed commands, accessed files, and returned to CCP through the established transient, console, FCB/DMA, and termination surface (**I**). Its communications path used the logical device mapping rather than a universal serial BDOS function. This strengthens the practical importance of separate raw RDR/PUN paths and coherent IOBYTE state.

XMODEM opened a CP/M file and explicitly selected its BIOS RDR/PUN path under `/X1` (**I**). QTERM used normal CP/M startup and file services around a direct-device core, but its communications input bypassed the portable logical-device boundary. No tested program required a literal private BDOS target or fixed resident address.

## 8. Hardware dependency analysis

Three compatibility classes are visible:

1. **Portable CP/M:** Kermit's command and file behavior plus logical-device I/O depend on documented CP/M services. Those services are **REQUIRED** where the corresponding device/profile is advertised.
2. **Configured BIOS extension:** an independently usable RDR/PUN mapping, active IOBYTE routing, and named physical assignments are profile capabilities. CP/M permits them but does not require every machine to contain a modem. Availability is **NOT GUARANTEED** in the baseline and **POLICY PENDING** as a BetterCP/M distribution profile.
3. **Machine-specific direct I/O:** QTERM's IMSAI ports and XMODEM `/X2` configuration are **NOT REQUIRED** outside a matching hardware profile. Under T06, the wrong machine returned repeated FFh bytes, visibly demonstrating why literal ports cannot be generalized.

Exact modem-channel labels, UART status polarity, DTR/BREAK implementation, and hardware initialization are **NOT REQUIRED** baseline behavior.

## 9. Serial and timing analysis

Communications programs commonly poll for readiness and assume raw eight-bit data paths. XMODEM documents that parity stripping can break CON/RDR transfers, supplies status polarity and bit masks for direct ports, and derives timeouts from CPU-speed and BIOS-cycle estimates. QTERM exposes baud, framing, flow control, character pacing, line pacing, and prompt-sensitive upload delays. Generic Kermit uses an approximate CPU/system-dependent timer and documents lower portable throughput.

Therefore a declared communications profile must specify usable data width, status/completion behavior, routing, and any timing/baud facilities it advertises (**REQUIRED** for that profile). Literal polling rates, instruction counts, CPU MHz, and exact timeout duration are **NOT REQUIRED** generic CP/M behavior. Whether BetterCP/M offers a strict historical-speed profile is **POLICY PENDING**.

No interrupt-driven serial workload was executed; interrupt latency and overrun behavior remain unestablished.

## 10. File transfer findings

Kermit opened a known file, emitted a send-init packet, recovered from a scripted no-peer abort, rejected a missing file, and performed a local CP/M file copy (**I**). XMODEM rejected a missing source before transfer and opened an existing file before entering its BIOS-device send path (**I**). These reinforce existing filename, open/read/create/write/close, 128-byte record, and logical-error contracts.

Kermit's binary mode sends complete CP/M records; its text mode recognizes application text conventions. XMODEM uses 128-byte protocol blocks and application-managed retries. Protocol framing, padding choice, checksum/CRC, retry counts, cancellation bytes, terminal UI, and partial-receive cleanup are application behavior and **NOT REQUIRED** of CP/M.

A successful paired Kermit or XMODEM wire transfer was not performed. No claim is made about end-to-end protocol interoperability, carrier loss, receive-side disk-full recovery, or line-noise handling.

## 11. Experimental results

All input was scripted and every test began from a restored disk image.

| Test | Matrix coverage | Procedure | Observed behavior | Compatibility conclusion |
|---|---|---|---|---|
| T01 Kermit startup | Standard; normal | Start, VERSION, SHOW, exit | Generic CP/M-80 v4.11 prompt; clean return; disk unchanged | Existing transient/console surface sufficient |
| T02 Kermit CONNECT | BIOS device; normal/boundary | Set Control-] escape; CONNECT; send `AT`; close | Path entered and closed; RDR/PUN alias console on tested BIOS | Logical path works; independent modem not proved |
| T03 Kermit SEND no peer | Transfer; failure | Send known file; no peer; Control-C | Send-init emitted; prompt recovered; disk unchanged | Application handles bounded no-peer abort |
| T04 Kermit capability errors | Boundary/failure | Set speed; send missing file | `(Not implemented)`; missing-file diagnostic; prompt retained | Baud control not generic; CP/M file failure consumed normally |
| T05 Kermit file copy | File; normal | Copy and list known file | Destination created as one 128-byte record | Existing file/record semantics sufficient |
| T06 IMSAI QTERM mismatch | Direct hardware; failure | Run patched QTERM on Mostek; help/status/channel/quit | Starts; direct input produces FFh stream; escape-Q exits | Wrong-profile port behavior is not portable CP/M |
| T07 XMODEM `/X1` | BIOS device; failure | Missing source, then known source with no peer | Missing file returns; known file opens and waits on RDR/PUN; bounded halt | Separate usable endpoint is a profile prerequisite |

Raw transcripts, executable images, disk fixtures, harnesses, and exact observations are under `probes/`. Normal, boundary, and failure operations were exercised. A successful independent serial peer, BBS session, and interrupt-driven path remain incomplete and are not inferred.

## 12. Compatibility conclusions

**REQUIRED:** Existing public CP/M transient, console, file, termination, raw logical character-device, and coherent IOBYTE behavior; separation of RDR/PUN from formatted console semantics; and conformance to every communications device capability explicitly advertised by a selected profile.

**POLICY PENDING:** Whether BetterCP/M's standard distribution advertises an active IOBYTE communications profile with distinct usable RDR/PUN devices; which terminal/modem and machine profiles are acceptance targets; and whether historical-speed behavior is claimed.

**NOT GUARANTEED:** Presence of a modem or independent auxiliary endpoint; success after selecting an unavailable IOBYTE mapping; exact polling/timing at arbitrary CPU speed; BBS compatibility; and unperformed paired-transfer behavior.

**NOT REQUIRED:** IMSAI port addresses, a universal UART/modem API, baud/BREAK/DTR in generic CP/M, Kermit/XMODEM protocol details, QTERM terminal/chat behavior, vendor diagnostics, and hardware behavior outside a declared matching profile.

## 13. Proposed ledger additions

None. The portable propositions are already independently represented by the logical-device, IOBYTE, BIOS-boundary, file, and direct-system-access entries. An application-named duplicate would violate the one-proposition rule. I050 instead provides ecosystem evidence for existing entries.

## 14. Existing-entry updates

No ledger file was modified. At the next authorized integration step, consider adding `I050 COMMUNICATIONS ECOSYSTEM COMPATIBILITY subsystem IG AG` to:

- **0436-0439 and 0442-0448:** Generic Kermit and XMODEM corroborate raw Reader/Punch use, device separation, coherent IOBYTE access, the BIOS routing boundary, and absent-device limitations.
- **0606-0611:** all three programs corroborate raw distinct device paths, runtime-visible assignment where implemented, and the fact that assignment does not prove physical availability.
- **0612:** the IMSAI distribution's documented assignment workflow supports the DRI-compatible profile use case, without making STAT universal.
- Relevant I041 direct-system-access entries: QTERM and XMODEM demonstrate that literal device ports belong to matching machine profiles, not the portable ABI.

Entry **0446** should remain **POLICY PENDING** at the baseline level. I050 adds a concrete policy consequence: a profile claiming Generic Kermit communications must provide active routing to a usable input/output pair; an inert IOBYTE profile may still be CP/M-permitted but cannot make that application claim.

## 15. Open questions

1. Should BetterCP/M advertise a strict communications profile with distinct eight-bit RDR/PUN devices and active IOBYTE routing? (**D**)
2. Which machine profiles, UARTs, baud controls, BREAK/DTR behavior, and terminal emulations are distribution claims? (**D**)
3. Which rights-cleared BBS or remote-access package should supply server-side acceptance evidence? No BBS experiment was performed. (**D**)
4. A paired endpoint should test successful Kermit and XMODEM send/receive, binary high-bit preservation, retry, cancellation, receive disk full, and carrier loss. These are incomplete. (**D**)
5. What interrupt latency, buffering, and overrun behavior is promised, if any? No interrupt-driven test was performed. (**D**)
6. Should acceptance vary emulated CPU speed and baud rate to define a historical-performance profile rather than correctness alone? (**D**)

## 16. Conformance implications

Baseline conformance should continue to test the established logical devices independently, preserve eight-bit raw bytes where the profile claims binary communications, expose coherent IOBYTE state, and keep device availability separate from assignment validity. A communications-profile suite should add a looped or paired endpoint, verify input and output isolation from console editing, exercise runtime routing, and test successful and failing transfers at declared speeds. Direct-port programs must be accepted only against a named machine profile with the promised ports and status semantics.

### Completion audit

- New I050 report, probe sources/harnesses, executables, raw transcripts, documentation extracts, disk images, inventories, and hashes: present.
- All performed experiments and incomplete cases: explicitly identified; no source-only behavior is claimed as observation.
- Disk fixtures: restored before tests; unchanged cases verified by SHA-256; the local-copy mutation is preserved separately.
- Authoritative ledger before hash: `8c9cf8fb0fe580a3f07d3cc1dd650a088a9807d20984c872d4822dfea109786d`.
- Compatibility Ledger modification: none; after hash recorded separately.
- Existing BetterCP/M files outside the new Investigation 050 directory: not modified by this investigation.
- BetterCP/M implementation changes: none.
- ZIP archive: none created.

Artifact SHA-256 values are recorded in `SHA256SUMS.txt`; source provenance and protected hashes are recorded under `hashes/`.
