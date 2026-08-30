# Investigation 023 - CP/M 2.2 CCP Transient Entry Environment, Command Tail, and Default FCB Semantics

## 1. Objective and scope

This investigation defines the externally visible environment delivered by the
DRI CP/M 2.2 CCP to a successfully loaded transient immediately at 0100h. It
covers the command tail, two default-FCB regions, initial DMA, page zero,
drive/user visibility, and the entry return environment. It does not reopen the
lookup/loading questions settled by I022 or prescribe a BetterCP/M design.

The principal boundary is: CP/M applications may rely on the documented
locations and semantics and on those de facto CCP results classified REQUIRED;
they may not rely on residual bytes, particular register values, exact resident
addresses, exact SP, or DRI's private preparation order.

## 2. Method and evidence classification

Four evidence classes are kept distinct:

- **A - documented interface:** the DRI manuals describe the application-visible
  location or semantic.
- **B - DRI implementation:** OS2CCP.ASM explains how the reference CCP produces
  a result but does not by itself prove a portable contract.
- **I - experiment:** deterministic cpmsim runs expose the delivered state.
- **D - policy:** evidence is insufficient to turn a DRI convention into a
  mandatory BetterCP/M promise.

The probe snapshots state before its first BDOS call. It then changes to a
private stack, queries drive/user, and reads a signature file without setting
DMA. Two fresh-image repetitions test stable construction versus residue. A
separate maximum-input run exercises the boundary. Source review selected and
explained tests; no conclusion rests on source alone.

## 3. Relationship to I001, I021, and I022

I001 established the broad entry locations and termination paths. I021
established command acquisition and the DRI 127-byte console-buffer limit.
I022 established lookup/loading, restoration of DMA to 0080h, and `CALL 0100h`.
I023 begins after those operations. It confirms rather than duplicates the
0100h entry, DMA, and RET propositions, and narrows I001's claims concerning
FCB initialization and page-zero 0004h.

I007 supplies the live drive/user model; I008 supplies the FCB layout; I020
supplies page-zero reconstruction semantics. Those results are used rather than
reinvestigated.

## 4. Documentation findings

The Alteration Guide's standard memory map assigns 0000h to warm start, 0003h
to IOBYTE, 0004h to the current default disk, 0005h to the BDOS entry jump,
005Ch-007Ch to the default FCB supplied by CCP, 007Dh-007Fh to optional default
random-record bytes, and 0080h-00FFh to the default 128-byte buffer which holds
the command line when a transient is loaded (AG, printed pp. 23-24). It specifies
semantic locations, not the observed resident jump targets.

The Interface Guide defines an FCB as drive, eight-character name,
three-character type, EX/S1/S2/RC, allocation map, CR, and optional random-record
bytes. Drive zero means the current drive; names/types are uppercase and
space-padded. It does not document that all control, allocation, or random bytes
in CCP's default regions are cleared.

Features and Facilities describes CCP command processing and the conventional
default FCB/command-buffer interface. The manuals do not unambiguously specify
the second FCB construction, a NUL byte after the counted tail, preservation of
multiple leading spaces, all tail case conversion details, or the exact
DRI-specific tail maximum derived from the command token's length.

## 5. CCP source findings

Relevant OS2CCP.ASM behavior is narrowly summarized:

1. `readcom` uses BDOS Function 10 with maximum length 127, translates ASCII
   lowercase letters to uppercase in the acquired line, and writes a NUL after
   the returned count.
2. `fillfcb` skips spaces, recognizes an optional drive prefix, truncates at
   eight name and three type characters, space-pads, retains `?`, and expands
   `*` to `?` through the rest of that component. It explicitly clears only
   three bytes following the type (EX/S1/S2).
3. After loading, CCP builds the first operand in private FCB storage, builds
   the second beginning 16 bytes later, explicitly zeroes the first CR byte,
   and copies 33 bytes to 005Ch. Thus the second operand is a 16-byte prefix
   overlapping the first FCB allocation region; it is not a second independent
   33/36-byte FCB.
4. CCP finds the first space or NUL after the command token, copies from there
   through the NUL to 0081h, and writes the number of non-NUL bytes at 0080h.
5. Before `CALL 0100h`, CCP selects DMA 0080h and stores packed user/drive state
   at 0004h (user in the high nibble, drive in the low nibble).

The source does not initialize first-FCB RC, all allocation bytes, the second
FCB's later control bytes, or 007Dh-007Fh. Their observed values are not
promises. Exact internal labels and construction order are NOT REQUIRED.

## 6. Entry memory map

| Address | Delivered meaning | Classification |
|---|---|---|
| 0000h | jump whose semantics are warm start | A/I; REQUIRED semantic, exact target NOT REQUIRED |
| 0003h | IOBYTE | A/I; REQUIRED location/meaning |
| 0004h | DRI CCP entry snapshot: user high nibble, drive low nibble | B/I; existing ledger wording needs correction |
| 0005h | jump whose semantics are BDOS entry | A/I; REQUIRED semantic, exact target NOT REQUIRED |
| 005Ch-006Bh | first operand's drive/name/type and EX/S1/S2 | A/B/I; default-FCB contract |
| 006Ch-007Bh | second operand's overlapping 16-byte prefix | B/I; POLICY PENDING as an independently required interface |
| 007Ch | first default FCB CR, explicitly zero | A/B/I; REQUIRED |
| 007Dh-007Fh | optional random-record area; residual at entry here | A/B/I; contents NOT GUARANTEED |
| 0080h | tail count and initial DMA base | A/B/I; REQUIRED |
| 0081h onward | counted tail; DRI writes a following NUL | A/B/I; counted bytes REQUIRED, NUL remains POLICY PENDING |
| after NUL | untouched residue until a later DMA operation | I; NOT GUARANTEED |

The labels “FCB 1” and “FCB 2” can mislead: only the first has the documented
full FCB location. The second begins inside its allocation area.

## 7. Command-tail findings

At entry, 0080h is the number of tail characters and the first character is at
0081h. For an argument-bearing normal command, the first counted character is
the separator following the command token. `ENTRY23 ARG` therefore yields count
04h and ` SPACE ARG`; `ARG1 ARG2` yields 0Ah and preserves the internal space.
Three spaces before `ARG` are all preserved and counted. No argument yields
count zero, not a one-byte blank tail.

The carriage return is neither counted nor stored. The DRI CCP writes a NUL
immediately after the counted bytes, including at 0081h for an empty tail.
Repeated runs show different bytes after that NUL, so no later byte may be
treated as initialized.

The entire acquired ASCII line is uppercased before both tail copying and FCB
construction. The transcript visibly echoes lowercase input while the snapshot
contains uppercase, excluding terminal uppercasing as the cause. Digits,
punctuation, `*`, and `?` are unchanged.

With alias `T`, 127 input bytes (`T`, space, 125 letters) produce a 126-byte
tail. An attempted 128th byte is excluded from that line and remains queued as
the next command, which fails as `B?`; the transcript contains no bell. Thus the
reference limit is the 127-byte Function-10 CCP input buffer. The maximum tail
is not independently 127: it depends on the command token and retained
separator. Because the documentation reviewed is not uniform enough to require
this exact capacity, the existing maximum-capacity policy remains pending.

## 8. FCB findings

The first two space-separated operands, not the executable token, supply the
two default regions. With no operand each prefix has drive zero and eleven
spaces. `NAME` and `NAME.EXT` are uppercase and padded to 8.3. Longer components
are truncated in the FCB without truncating the tail.

An unprefixed operand receives drive byte zero even when the current drive is B.
Explicit `A:` and `B:` receive 1 and 2. An explicit drive on the executable
(`B:ENTRY23`) affects lookup only and does not become an operand drive or change
the current drive. User number does not alter FCB drive encoding.

The CCP does not enumerate wildcards. `?` remains in its position; `*` fills
the remainder of the current 8- or 3-character component with `?`. For
`A*.T?T B:???.*`, FCB1 contains `A???????`/`T?T` with drive 0 and FCB2 contains
`???     `/`???` with drive 2. The tail retains the literal wildcard spelling.

EX/S1/S2 are zero in each constructed 16-byte prefix and CR at 007Ch is zero.
Other bytes must be treated carefully. First-FCB byte 15 is 08h for ENTRY23 and
14h for 20-record BIG23, reflecting loader/Open-derived state. The second
prefix overwrites the first allocation area. Bytes 007Dh-007Fh are residual.
Neither observation permits a general zero-initialization requirement.

## 9. DMA findings

The counted tail is intact at initial snapshot. Without issuing Function 26,
ENTRY23 opens and sequentially reads DMACHK.DAT; the signature
`D023-DEFAULT-DMA` then appears at 0080h. Therefore the inherited DMA address is
0080h, confirming I022 and the documented default-buffer location. Once the
program invokes a DMA-using BDOS operation, the tail may be overwritten. The
initial tail contract is not a persistence guarantee.

## 10. Page-zero findings

The accepted configuration shows `JMP FA03h` at 0000h and `JMP EC06h` at 0005h.
Only warm-start and BDOS-entry semantics are portable; exact targets depend on
memory/BIOS/BDOS layout. IOBYTE was zero in these runs but retains its separately
defined meaning.

At command entry, 0004h was 00h for user 0/drive A, 10h for user 1/drive A,
and 01h for user 0/drive B. BDOS Functions 32 and 25 reported corresponding
live values. This experimentally and textually establishes that the DRI CCP
uses the high nibble for user and low nibble for drive at this boundary; existing
entry 0007's description as only a value 0..15 is too narrow. Applications
should query BDOS for live state after changing it.

## 11. Stack/register findings

In this 64K configuration entry SP was EBA9h and the word at SP was EB5Fh.
Returning through that word restored CCP control. This confirms the CALL/RET
contract from I001/I002/I022. Exact SP, return address, deeper stack bytes, and
available stack depth are NOT REQUIRED.

Main and alternate registers, flags, R, and observed instruction-timing values
differed across emulator processes while the constructed interface remained
stable. No reviewed document assigns them an entry contract. IX/IY, alternate
registers, flags, and exact interrupt state are NOT GUARANTEED. The `LD A,I`
snapshot reports the emulator's IFF2 observation, but one observation is not a
portable interrupt-state requirement.

## 12. Experimental design

ENTRY23 performs only stores, exchanges, pushes, and copies until it has saved
registers, SP/stack, and all 256 page-zero bytes. It then adopts private stack
space so diagnostic calls cannot consume unpromised CCP stack space. Output is
through BDOS Functions 9 and 2. Live drive/user use Functions 25 and 32. The DMA
check uses Functions 15 and 20 with no intervening Function 26.

The automated matrix covers no argument, one/two operands, lowercase/mixed
case, punctuation, extension, overlong name, multiple separators, explicit and
invalid drive prefixes, wildcards, a larger executable, explicit executable
drive, current drive B, explicit operand drives, and user 1. The full matrix is
repeated from the same fixture. A separate alias-based run reaches the input
boundary. Fresh disposable images are used for accepted runs.

## 13. Experimental results

Representative exact results are preserved rather than recopied wholesale:

| Command | Tail prefix | FCB consequence |
|---|---|---|
| `ENTRY23` | `00 00` | both names blank |
| `ENTRY23 ARG` | `04 20 41 52 47 00` | FCB1 `ARG` |
| `ENTRY23 ARG1 ARG2` | `0A 20 ... 20 ... 00` | FCB1/2 from operands 1/2 |
| `entry23 lower Mixed.txt 9-z_?` | uppercase counted tail | FCB1 `LOWER`, FCB2 `MIXED.TXT` |
| `ENTRY23   ARG` | count 06, three spaces | FCB parser skips spaces; tail does not |
| `ENTRY23 A*.T?T B:???.*` | literal wildcard tail | prepared `?` patterns, no expansion |
| `B:ENTRY23 ARG` from A | normal ARG tail | current drive remains A |
| `ENTRY23 A:ONE B:TWO` from B | both prefixes retained | drives 1 and 2 |

All accepted reads returned success, the signature appeared at the default DMA,
and accepted post-run image hashes equal fixture hashes. The main and repeat
transcripts agree on constructed fields while differing in unpromised register
and residual bytes. No required matrix case is incomplete.

## 14. Compatibility conclusions

**REQUIRED:** semantic page-zero warm-start/BDOS entries; the documented default
FCB and command-buffer locations; count at 0080h and counted bytes from 0081h;
uppercase CCP-delivered tail; default-FCB drive/name/type parsing including
uppercase, padding, explicit-drive encoding, and wildcard preparation; zeroed
EX/S1/S2 and first CR; initial DMA 0080h; a valid RET return word.

**NOT GUARANTEED:** residual FCB/allocation/random bytes, bytes after the DRI NUL,
registers, flags, interrupt state, exact SP/return address, exact vector targets,
and tail persistence after a DMA-using call.

**NOT REQUIRED:** DRI private work-area placement, exact construction order,
exact resident addresses, exact residue, and duplication of the reference
stack's unused bytes.

**POLICY PENDING:** treating the overlapping second default-FCB prefix as a
mandatory portable interface; requiring a NUL after the counted tail; requiring
the exact leading-separator convention independently of the counted-tail
contract; and requiring DRI's command-token-dependent maximum capacity.

## 15. Proposed Compatibility Ledger additions

The authoritative ledger is not modified. New propositions begin at 0506 and
avoid restating entries that I023 merely strengthens.

### 0506. Default FCB operand assignment

The first command operand is represented by the default FCB prefix beginning at
005Ch. The DRI CP/M 2.2 CCP represents the second operand by an overlapping
16-byte prefix beginning at 006Ch; whether every BetterCP/M-compatible CCP must
provide this second prefix remains unresolved because the reviewed manuals do
not state it with comparable precision.

Disposition: POLICY PENDING

Evidence: I023; CCP; AG

Conformance: Invoke a transient with two distinct operands and compare the
drive/name/type and EX/S1/S2 bytes beginning at 005Ch and 006Ch.

### 0507. Default FCB residual fields

CCP preparation does not guarantee zero or any other fixed value in default-FCB
bytes outside the constructed drive/name/type/EX/S1/S2 prefixes and the first
FCB current-record byte. In particular, loader-derived RC/allocation state and
the optional random-record bytes may contain residual values.

Disposition: NOT GUARANTEED

Evidence: I023; CCP; IG

Conformance: A compatible implementation may vary those residual bytes without
failing compatibility; applications must initialize fields required by later
BDOS operations.

### 0508. Tail capacity is bounded by CCP input acquisition

The command tail delivered by the DRI CCP is the suffix of its bounded input
line after the command token. Consequently its maximum observed count depends
on command-token length: the one-character command `T` produced a maximum count
of 126 from a 127-byte accepted input line. The exact cross-implementation
minimum capacity is not established by the reviewed documentation.

Disposition: POLICY PENDING

Evidence: I023; I021; CCP

Conformance: Boundary tests must distinguish the accepted CCP input-line length
from the resulting 0080h suffix count and record overflow handling separately.

## 16. Proposed existing-entry updates

- **0001-0004:** stronger I023 evidence only; no wording or disposition change.
- **0007:** wording correction. At DRI CCP transient entry, 0004h is not merely a
  drive value 0..15: it packs current user in the high nibble and current drive
  in the low nibble. Add I023/CCP evidence and retain the existing rule that live
  state is obtained through BDOS. Disposition remains REQUIRED for the
  application-visible entry convention.
- **0011:** stronger evidence for FCB1 at 005Ch; no duplicate.
- **0012:** stronger DRI source/experimental evidence for FCB2 at 006Ch, but the
  documentation gap remains; retain POLICY PENDING. Entry 0506 adds the operand
  assignment and overlap boundary rather than silently resolving it.
- **0013-0015:** stronger evidence for drive prefixes, wildcard preparation,
  uppercase and padding; no disposition change.
- **0016:** wording correction required. CCP explicitly initializes EX/S1/S2
  and first CR, but does not generally zero RC, allocation, second-control, or
  random-record bytes. Entry 0507 records the negative guarantee.
- **0017-0018:** stronger evidence; count and characters remain REQUIRED.
- **0019:** multiple spaces and the normal leading separator are established for
  DRI, but documentation is insufficient to resolve portable reliance; retain
  POLICY PENDING.
- **0020:** change from POLICY PENDING to REQUIRED, aligned with entry 0481:
  CCP's ASCII lowercase-to-uppercase processing is visible in the entire counted
  transient tail, not only the FCBs. Evidence I023/I021/CCP.
- **0021:** DRI NUL is confirmed by source and experiment but not clearly
  documented as the counted-tail interface; retain POLICY PENDING.
- **0022-0024:** stronger evidence only: bytes after NUL are not guaranteed,
  initial DMA is 0080h, and tail/DMA overlap is required.
- **0031-0034:** stronger evidence only; registers and exact vector targets remain
  unpromised.
- **0475-0477, 0479-0488:** stronger entry-boundary evidence where applicable;
  no duplicate. Entry 0481 supports the proposed 0020 disposition change.
- **0478:** retain POLICY PENDING and add I023 evidence. Entry 0508 narrows why
  input capacity and delivered-tail capacity must not be conflated.
- **0492-0505:** I023 confirms successful-load state, DMA restoration, page-zero
  reconstruction, and CALL/RET behavior; no wording or disposition change.

## 17. Unresolved questions

1. Do independently written CP/M 2.2-compatible CCPs consistently provide the
   second overlapping prefix at 006Ch, or should BetterCP/M expose it only as a
   compatibility policy?
2. Should BetterCP/M deliberately guarantee the DRI NUL following the counted
   tail, despite the count-delimited documented interface?
3. What minimum command-line/tail capacity should BetterCP/M promise given the
   manual/source discrepancy already identified by I021?
4. Should the exact DRI leading-separator behavior be mandatory, or should the
   count and preserved argument text alone define conformance?

These are policy questions, not missing experimental cases.

## 18. Artifact preservation audit

- New investigation directory and all referenced artifacts exist.
- ENTRY23.COM and BIG23.COM rebuild byte-identically; hashes are in
  `probes/rebuild.sha256`.
- Raw main, repeat, maximum, and user-check transcripts are preserved separately.
- Base, fixture, and after disk images are preserved with SHA-256 hashes.
- Fixture and after hashes match for A and B; accepted experiments made no
  persistent disk-image changes.
- The authoritative Ledger 022 hash before and after is
  `748ecaed773e2b612b3138914b1877b62c4a25174725183cce46708f291eb789`.
- No ledger, earlier investigation, architecture, roadmap, or source file was
  edited. All writes are confined to the new I023 directory.
- Artifact and source manifests permit independent integrity verification.
- No ZIP archive was created.

## 19. Sources

- Digital Research, *CP/M Features and Facilities* (`Intro_to_CPM_Feat_and_Facilities.pdf`), SHA-256 `2335c4fd552829c612ba0c3d881cce25be9d8ba0f1bde575103802d2ba1b2bdf`.
- Digital Research, *CP/M 2.0 Interface Guide* (`CPM_2_0_Interface_Guide.pdf`), SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`.
- Digital Research, *CP/M 2.2 Alteration Guide* (`CPM_2.2_Alteration_Guide_1979.pdf`), SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`.
- Digital Research CP/M 2.2 CCP source, `OS2CCP.ASM`, SHA-256 `9d13a24553e16accbb8e2e345a1d3736d4ee4b7d2d80b452818218935cab1188`.
- Existing BetterCP/M Investigations 001, 007-010, 013, and 018-022, plus the authoritative Investigation 022 compatibility ledger.
- z80pack cpmsim Release 1.39 at repository commit `91fd28eb04e675c2127df88ed3f40675e15282e2`, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`.
- This investigation's source, transcripts, images, listings, and hash manifests under `probes/`.

