# Investigation 065 - CP/M 2.2 Communications Profile Validation

## 1. Objective and scope

This investigation validates the CP/M 2.2 communications boundary with a machine-matched program, serial endpoint, and protocol peer. It asks which observed behavior is portable CP/M, which belongs to an advertised BIOS/device profile, and which is application or hardware behavior. It does not alter BetterCP/M, define networking, or promote an IMSAI UART into the generic contract.

Evidence is classified **A** (documented interface), **B** (DRI or preserved implementation), **I** (controlled experiment), and **D** (policy). Findings use **REQUIRED**, **POLICY PENDING**, **NOT REQUIRED**, and **NOT GUARANTEED**. Any later ledger integration must cite exactly `I065 COMMUNICATIONS PROFILE VALIDATION subsystem IG AG`.

## 2. Relationship to previous investigations

I020 established the BIOS character entry points and their register-facing behavior. I050 surveyed Generic Kermit, QTERM, and XMODEM and left successful paired transfer, disconnect, unavailable-device, and timing evidence open. I053 retained the paired-communications gap. I059 designed profile-scoped conformance, and I062 demonstrated evidence capture and requirement traceability. I063 separated processor profiles; the QTERM fixture is Z80 software. I064 did not close communications coverage.

I065 closes the narrow paired-transfer gap for one named configuration: QTERM 4.3e's IMSAI patch, z80pack IMSAI SIO-2 channel A, and a controlled Unix-socket peer. It does not establish Generic Kermit interoperability, BBS behavior, modem carrier semantics, or physical UART fidelity.

## 3. Communications software corpus

| Software | Version/category | Archive/source | Platform assumptions | Evidence |
|---|---|---|---|---|
| QTERM | 4.3e; terminal and XMODEM/Kermit client | z80pack `imsaisim/disks/library/comms.dsk`; QTERM documentation and `QT-IMSAI.ASM` preserved from I050 | Z80; IMSAI SIO-2 ports 22h/23h or 24h/25h | T01-T06 (**I**), source (**B/third-party**) |
| XMODEM peer | Investigation harness; checksum receiver | `probes/peer065.py` | Host Unix socket; checksum-mode XMODEM | T02-T03 (**I**) |
| Generic Kermit-80 | 4.11; portable terminal/transfer client | I050/I053 preserved corpus and official guide | CP/M logical devices and IOBYTE | reviewed, not re-executed (**A/I050**) |
| XMODEM 2.7 | transfer utility | z80pack communications disk; source preserved by I050 | selectable BIOS or direct-port path | reviewed, not re-executed (**source/I050**) |

No BBS or modem-dial application was executed. No claim is made for untested software.

## 4. Interface usage analysis

The documented portable surface (**A**) consists of CP/M transient loading, files, console, logical READER/PUNCH, optional IOBYTE routing, and BIOS character services. CP/M 2.2 documents no universal serial port, carrier flag, baud setter, timeout clock, BREAK/DTR operation, modem command set, or file-transfer protocol.

Generic Kermit demonstrates the portable logical-device strategy in I050. The I065 fixture deliberately exercises the other class. `QT-IMSAI.ASM` names status/data ports 23h/22h and 25h/24h, tests device-ready bits, and selects channel A or B. The matched IMSAI BIOS can route logical RDR/PUN to related device routines, but QTERM's patched core bypasses BDOS and the logical BIOS jump table. Its terminal transport therefore depends on a named hardware profile, while its startup, command input, file open/read, and CCP return still use ordinary CP/M services.

## 5. Transfer validation results

T02 transferred `PAYLD65.TXT` from QTERM to the controlled peer in XMODEM checksum mode. The peer sent NAK, received block 1 with a valid number complement and checksum, returned ACK, received EOT, and returned ACK. The recovered 128-byte record begins with the complete 119-byte source and contains nine zero padding bytes supplied by the stored CP/M record. QTERM displayed `Transfer complete` and returned to CCP. This proves successful application interoperability on the declared endpoint (**I**).

T03 injected NAK for the first valid block. QTERM reported `Non-ACK: 0x15`, retransmitted the same valid block, completed after ACK, and returned to CCP. The recovered T02 and T03 records are byte-identical. Retry count, screen text, checksum framing, padding, and retransmission interval are QTERM/XMODEM behavior (**NOT REQUIRED** of CP/M). The OS-relevant requirements are usable profile transport plus the existing CP/M file lifecycle (**REQUIRED** when that profile/application claim is advertised).

## 6. Failure behavior analysis

In T04 the peer received `CPM65-UP\r` and then closed the endpoint. Further QTERM output did not produce an application diagnostic or CCP return during the bounded interval; the harness stopped the emulator. In T05 no peer ever connected. QTERM accepted channel selection and remained in its direct-port polling path until the harness stopped it. In T07 the XMODEM peer closed immediately after receiving the first valid block without acknowledging it. QTERM counted a non-ACK and did not complete during the following 15 seconds; the harness stopped the emulator. All three runs left the communications disk unchanged (**I**).

These are observations of QTERM plus the emulated IMSAI device. They do not establish a CP/M fatal handler, BDOS return code, or mandatory timeout. CP/M has no portable carrier-loss signal at this layer (**A**). Exact polling, hang duration, recovery UI, and behavior of output to an absent device are **NOT GUARANTEED** generically. A named device profile must document whatever availability and failure semantics it promises; application-level timeout and cancellation remain application responsibilities unless that profile says otherwise.

## 7. Timing analysis

The host log measured the nine-byte `CPM65-UP\r` sequence from first to last byte in about 0.094 seconds with SIO2A configured as 9600 and about 0.095 seconds with it configured as 1200. Startup banners confirmed the two requested settings. This short host-backed experiment therefore found no material baud-dependent difference (**I**); it does not validate either nominal baud rate or a physical UART.

The normal XMODEM block was acknowledged about 4.11 seconds after the initial NAK and EOT about 0.11 seconds later. Injecting one NAK delayed accepted-block acknowledgement by about 2.82 seconds. Those intervals include QTERM, emulator scheduling, configured CPU, and harness behavior and are **NOT REQUIRED** generic timing.

Polling readiness and eventual byte delivery are relevant to a declared synchronous profile. Literal loop counts, CPU MHz, host scheduling, exact timeout, baud accuracy, interrupt latency, buffering depth, and overrun behavior remain **NOT GUARANTEED** unless a profile states them. Historical-speed acceptance remains **POLICY PENDING**.

## 8. Hardware profile boundary analysis

**REQUIRED:** the public CP/M console/file/lifecycle surfaces; documented logical character interfaces where implemented; and every byte width, ready/completion rule, routing behavior, and endpoint capability explicitly advertised by a selected communications profile.

**POLICY PENDING:** whether BetterCP/M ships a standard independent eight-bit communications endpoint; which IOBYTE, machine/UART, baud, carrier, BREAK/DTR, buffering, and terminal profiles it advertises; and whether QTERM or Generic Kermit becomes a release fixture.

**NOT REQUIRED:** IMSAI ports 22h-25h, z80pack's Unix socket, its host-backed baud model, QTERM's protocol/UI, XMODEM framing, modem AT commands, or a universal serial API.

**NOT GUARANTEED:** a modem or independent endpoint in baseline CP/M; useful behavior from a nonmatching direct-port program; exact behavior after endpoint loss; transfer success outside a declared profile; and physical timing from this emulator test.

## 9. Experimental results

Every test used a restored CP/M 2.2 system image and restored communications image. Input was scripted. Console transcripts, peer byte/timing logs, received records, before/after disks, harnesses, configurations, emulator binary, and relevant source are preserved.

| ID | Software/scenario/environment/procedure | Observed behavior | Compatibility conclusion |
|---|---|---|---|
| T01 | QTERM 4.3e; normal terminal; Z80 IMSAI/SIO2A at 9600; attach peer and exchange markers | Bidirectional exact byte transport; peer received nine application bytes | Matching endpoint works; profile capability, not generic UART requirement |
| T02 | QTERM XMODEM send; same environment; peer NAK/ACK receiver | One valid 128-byte block and EOT; `Transfer complete`; CCP return | Paired transfer gap closed for this named profile |
| T03 | QTERM XMODEM retry; peer NAKs first valid block | QTERM counted one non-ACK, retransmitted, then completed | Recovery is application protocol behavior; transport must remain usable |
| T04 | QTERM terminal; peer disconnects after exchange | Direct-port path did not diagnose or return in bounded interval; harness stop | Carrier-loss recovery is not portable CP/M behavior |
| T05 | QTERM terminal; no peer | Program remained in polling path until harness stop | Assignment/port selection does not guarantee device presence |
| T06 | QTERM terminal; SIO2A settings 9600 versus 1200 | Both exchanged exact bytes; short measured durations were materially equal | Nominal baud fidelity unproved; timing remains profile-scoped |
| T07 | QTERM XMODEM send; peer disconnects after first valid block before ACK | QTERM counted a non-ACK and did not complete in 15 seconds; bounded harness stop | Interrupted-transfer recovery is application/profile behavior, not a CP/M return contract |

The detailed six-field validation records are in `probes/communications-validation-records.tsv`.

## 10. Compatibility conclusions

1. The existing CP/M 2.2 boundary is sufficient: portable OS services plus explicitly selected device profiles explain every successful and failed run (**A/I**).
2. A communications application claim requires a usable matching endpoint, not merely a writable IOBYTE or accepted port selection (**REQUIRED for that claim**).
3. Successful paired XMODEM and retry strengthen the evidence for profile-scoped byte transport and existing CP/M file semantics; they add no generic protocol proposition (**I**).
4. Direct-port polling after absence/disconnect is machine/application behavior, not a CP/M recovery contract (**NOT GUARANTEED/NOT REQUIRED**).
5. No reliable baud-rate or historical-performance requirement was established (**POLICY PENDING**).
6. The communications compatibility boundary is sufficiently understood for specification release if release claims remain explicitly profile-scoped. BBS, modem-control, and physical timing claims require separate evidence before they are advertised.

## 11. Proposed ledger additions

None. The independent propositions already exist: logical-device behavior, optional active IOBYTE routing, device presence not following from assignment, BIOS/profile ownership, and direct-hardware profile boundaries. An application- or XMODEM-named entry would duplicate them.

## 12. Existing-entry updates

No ledger was modified. At the next authorized integration, `I065 COMMUNICATIONS PROFILE VALIDATION subsystem IG AG` can strengthen:

- 0446: active routing is a profile choice, but an application claim requires a functioning endpoint;
- 0601 and the direct-system-access profile entries: successful QTERM use depends on its matching IMSAI ports;
- 0606-0611: raw device separation, active routing where advertised, and assignment/device-presence distinction;
- the I050 communications review note: paired XMODEM success, retry, absence, disconnect, and timing-boundary evidence are now available.

No classification correction is warranted. Duplicate protocol propositions should not be added.

## 13. Open questions

1. Which independent serial/IOBYTE profile, if any, will BetterCP/M advertise by default? (**D**)
2. Will Generic Kermit, QTERM/IMSAI, or another rights-cleared pair become a release fixture? (**D**)
3. What baud accuracy, buffering, flow control, carrier, BREAK/DTR, and interrupt/overrun behavior will each profile promise? (**D**)
4. BBS/server, modem dial/answer, receive-side disk-full, noisy-line, binary high-bit, and cancellation workflows remain unexecuted. (**D**)
5. Physical serial hardware and cross-emulator peers remain untested; the Unix socket is not their substitute. (**D**)

## 14. Conformance implications

Baseline CP/M conformance should continue to test public logical character services and coherent optional IOBYTE behavior without requiring a modem. A communications-profile suite must additionally name the endpoint, byte width, readiness semantics, routing, availability behavior, supported speed claims, and machine ports if direct-I/O software is claimed. It should perform a real paired transfer, compare payload bytes, inject a retry, remove the peer, interrupt a transfer, and vary declared timing. Exact application diagnostics and protocol timing are not pass criteria unless the advertised application profile says so.

Completion audit: all seven performed records and incomplete cases are explicit; the report does not infer experimental behavior from source; required source, executable, configurations, transcripts, peer logs, disk images, and received records are preserved; SHA-256 manifests are under `hashes/`; the Investigation 064 ledger and every earlier BetterCP/M file were protected by a before/after manifest; no BetterCP/M or ledger file was modified.
