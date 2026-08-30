# Investigation 008 - CP/M 2.2 FCB File Identification and Open/Close Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger, prior investigation, architecture, roadmap, or BetterCP/M implementation modified

## 1. Investigation question and scope

This investigation defines the compatibility-visible File Control Block foundation and BDOS functions 15 and 16:

1. What are the documented sequential FCB fields and caller responsibilities?
2. Which fields identify a file or extent for open and close?
3. What does successful or failed open return and place in the FCB?
4. How do wildcards, explicit drives, and nonzero extents affect open?
5. When is close necessary, what does it persist, and what does it return?
6. Which DRI mutations are contract, possible de facto behavior, or private machinery?

Directory enumeration (functions 17-18), make/delete/rename, sequential and random I/O, detailed extent transition algorithms, allocation-map encoding across formats, and error recovery are out of scope except where unavoidable to interpret open/close.

Evidence classes are **A** documented CP/M 2.2 requirement, **B** DRI implementation behavior, **C** possible de facto dependency, **I** incidental behavior, and **D** unresolved.

## 2. Why this matters to BetterCP/M

The FCB is CP/M's application-visible file handle. Open turns caller-supplied identity into active directory/allocation state; close commits state changed by writes. Sequential I/O, random access, file creation, directory search, and extent management all depend on this lifecycle.

BetterCP/M must reproduce the external FCB contract without hard-coding DRI's private flags or one disk format's allocation representation.

## 3. Relationship to existing ledger entries

This investigation depends on entries 11-16 (CCP default unopened FCBs), 23-24 (default DMA), 35-51 (BDOS ABI), and 132-155 (reset, current drive, login vector, and explicit-FCB temporary selection). Entry 146 already requires that an explicit-drive FCB can log a drive without permanently changing the current default.

The authoritative Investigation 007 ledger ends at entry 155. It does not define the general FCB layout or functions 15-16. Investigation 001's default-FCB entries concern CCP construction before open; this report concerns BDOS activation and close.

## 4. Sources examined

### 4.1 Digital Research documentation

1. Digital Research, *CP/M 2.0 Interface Guide*, copyright 1979, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`:
   - FCB overview and diagram, printed pp. 5-7 / PDF pp. 11-13;
   - function 15, printed p. 15 / PDF p. 21;
   - function 16, printed p. 16 / PDF p. 22;
   - DUMP and random-access examples, printed pp. 34-43.
2. Digital Research, *CP/M 2.2 Alteration Guide*, copyright 1979, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`, including section 9's interface and page-zero environment.

The relevant scanned pages were rendered and visually inspected. The 2.0 Interface Guide is applicable for the bounded reason used in Investigations 002-007: CP/M 2.2 incorporates the interface, and the identified February 1980 2.2 source implements it.

### 4.2 Original DRI source and callers

3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, “Bdos Interface, Bdos, Version 2.2 Feb, 1980,” SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: FCB constants; search comparator; `open`, `close`, automatic reselection, and common return paths.
4. DRI `DUMP.ASM`, `OS2CCP.ASM`, `PIP.PLM`, `ED.PLM`, `LOAD.PLM`, and `SYSGEN.ASM` callers. DUMP explicitly clears CR before sequential access; CCP constructs unopened names; utilities treat open failure as FFh.
5. `OS3BDOS1.ASM` was compared in the relevant regions; no material open/close contract difference was found.

### 4.3 Reference environment

- z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`;
- `cpmsim` Release 1.39 in Z80 mode, executable SHA-256 `30374c2df2f44118d2b36a8bfef651a9f2d0ee9b9ddd0039c044b9f06df4708d`;
- disposable copies of distribution disk images identified in `probes/observed-output.txt`;
- byte-identified DRI CP/M 2.2 CCP+BDOS and z80pack Z80 CBIOS V1.2;
- cpmtools used only to prepare and independently inspect disposable images.

DRI documentation/source establish CP/M and DRI behavior. BIOS supplies disk access/format parameters. cpmsim executes the system. cpmtools' host-side exact-byte-count use of reserved S1 is explicitly excluded from CP/M conclusions.

## 5. Documented requirements

### 5.1 FCB form

**A:** DE addresses an FCB. A sequential FCB is 33 bytes (0-32); a random-access FCB adds bytes 33-35.

**A:** Byte 0 `dr` is 0 for the current default drive or 1-16 for A-P automatic selection.

**A:** Bytes 1-8 contain an uppercase, high-bit-clear, blank-padded filename; bytes 9-11 contain the uppercase type. The high bits of the three type bytes are documented file attributes: t1' read-only, t2' system/no-DIR-list, and t3' reserved.

**A:** Byte 12 `ex` is the current extent, normally initialized to zero by the caller and in range 0-31 during I/O.

**A:** Byte 13 `s1` is reserved for internal system use. Byte 14 `s2` is reserved for internal use and is set to zero on calls to OPEN, MAKE, and SEARCH.

**A:** Byte 15 `rc` is the record count for the extent, 0-128. Bytes 16-31 `d0...dn` are CP/M-filled allocation information reserved for system use.

**A:** Byte 32 `cr` is the current record for sequential read/write, 0-127, and is normally initialized to zero by the caller. The program is responsible for initializing the lower 16 bytes and CR as applicable; CP/M fills system-owned state.

### 5.2 Function 15 - Open File

**A:** C=0Fh and DE=FCB address select Open File. It activates a file that exists in the referenced disk directory for the current user.

**A:** FDOS scans the FCB identification region. `?` in matchable positions is a wildcard; normally no wildcard is used and EX and S2 are zero. With wildcards, the first matching FCB is activated.

**A:** On success, relevant directory information, including allocation state, is copied into the FCB for subsequent read/write operations. Existing files must be successfully opened before access.

**A:** A returns directory code 0-3 on success and FFh if not found.

**A:** For sequential access from the beginning, the caller must set CR to zero. Open does not relieve that caller responsibility.

### 5.3 Function 16 - Close File

**A:** C=10h and DE=the previously activated FCB select Close File.

**A:** Close performs the inverse lifecycle operation, matching the same file identity and permanently recording new FCB directory information.

**A:** A returns directory code 0-3 on successful close and FFh if the filename cannot be found.

**A:** A file need not be closed when only read operations occurred. If write operations occurred, close is necessary to record the new directory information permanently.

## 6. DRI implementation behavior

Function 15 clears byte 14, performs automatic drive selection, and searches a 15-byte identity region. The comparator treats `?` as wildcard, masks attribute bits, compares extent groups using the disk's extent mask, and always ignores S1 because it is reserved. This qualifies the manual's general “positions 1 through 14” wording: literal S1 is not an application identity requirement.

On success DRI copies directory bytes 0-31 to the memory FCB, sets the high bit of S2 as a private “not written” flag, restores the caller's requested EX, calculates RC relative to requested/directory extent, and leaves CR untouched. These steps explain externally visible state, but their order and private flag representation are **I**.

On failed open, DRI returns FFh after having cleared S2. Other tested bytes remain caller values. Documentation requires the failure code but does not fully specify every FCB byte after failure; exact preservation is **B/C, POLICY PENDING**.

DRI close first defaults its result to zero. On a read-only disk it returns immediately. If its private no-write flag remains set, it also returns immediately without searching or writing the directory. Thus a gratuitous close after read-only use returns zero in DRI, not necessarily the file's directory slot. The manual says such a close is unnecessary; the exact zero is **I/NOT REQUIRED**.

For a dirty FCB, DRI searches the name/extent, merges the allocation map with the directory entry, rejects conflicting nonzero map entries, updates EX/RC when appropriate, and writes the directory. Single- versus double-byte maps depend on the disk parameter block. The observable requirement is valid directory-state persistence, not DRI's merge loop.

After explicit-drive open/close, DRI restores the prior current disk through its common reselection path while leaving the drive logged, consistent with Investigation 007.

## 7. Experimental method and results

### 7.1 Probe and preparation

Artifacts are `probes/FCB008.ASM`, `FCB008.COM`, `observed-output.txt`, and `README.txt`. The final binary SHA-256 is `b42b6416579a25b849af29d2001bb239cd4a49853b8dd85e5bae0170e709d95e`.

Disposable A/B images were cleared and populated with small A/B files, a 20000-byte multi-extent file, and a one-record file reserved for dirty close. The source constructs distinctive 33-byte FCBs, calls functions 15/16, and prints every returned byte. No BDOS, BIOS, or emulator code was patched; no timed input was used.

### 7.2 Results

| Case | Result | Significant observation |
|---|---:|---|
| Existing A file | 0 | Actual directory/allocation bytes copied; CR AA preserved. |
| Missing file | FFh | Failure; S2 cleared; remaining tested caller bytes preserved. |
| Wildcard name | 0 | First match activated and actual `OPENME  DAT` copied. |
| Explicit B file | 0 | FCB drive 2 retained; B metadata copied; current A restored. |
| Requested EX=1 | 3 | EX 1 retained; extent-specific RC/allocation returned. |
| Close after no write | 0 | Private S2 high bit caused DRI early success/no directory write. |
| Dirty close with RC=2 | 1 | Directory entry updated; actual directory code returned. |
| Reopen after dirty close | 1 | RC=2 recovered, proving persistence. |
| Dirty close of missing name | FFh | No matching directory entry. |

The B image hash remained unchanged. The A image changed only after the deliberate disposable close sequence. Exact byte records and preparation hashes are in `observed-output.txt`.

### 7.3 Limitations

The test disk uses a single-byte allocation map. Double-byte maps are documented/configuration-driven and source-supported but were not separately probed. The experiment did not use BDOS writes; it directly created the post-write FCB condition needed to isolate close. It does not establish media-error, read-only-disk close, disk-full, damaged-map, or allocation-conflict behavior.

cpmtools placed exact host byte counts in reserved S1 and later interpreted them. DRI copied that byte but ignored it for matching. This cross-tool observation demonstrates why reserved bytes must not be promoted to CP/M requirements.

## 8. Compatibility analysis

The FCB divides into caller-owned identity/position and CP/M-owned active state. Applications supply drive, 8.3 identity, initial extent/state zeros, and CR. Successful open replaces the relevant memory FCB with active directory/allocation information while preserving the caller's sequential position responsibility.

Wildcard open is documented but activates only the first match; it is not directory enumeration. Search functions remain the proper enumeration interface.

Close is conditional lifecycle work: mandatory after writes, unnecessary after reads. BetterCP/M may track dirty state differently from DRI, but a close after writes must persist compatible directory state and report success/failure correctly.

Allocation bytes and extent grouping are format-dependent CP/M state. Applications must preserve them after open rather than interpret or synthesize a universal map. BetterCP/M's storage architecture should derive representation from disk format parameters.

## 9. Unresolved questions

1. After failed open, which FCB bytes beyond documented S2 clearing may portable software expect to retain?
2. What result should close return when called unnecessarily after read-only access: any successful directory code, DRI's zero, or merely non-FF success?
3. What exact errors and recovery apply to close on read-only disks, allocation-map conflicts, or physical write failure?
4. Do significant applications depend on DRI's high-S2 private dirty/no-write convention?
5. How do all valid DPB extent masks affect requested EX matching and returned RC across directory extents?
6. Are high bits of filename bytes (not type attributes) consistently masked/rejected across DRI tools and software?

## 10. Proposed conformance tests

Mandatory tests:

1. Validate 33-byte sequential and 36-byte random FCB boundaries.
2. Open existing and missing files on default and explicit drives.
3. Test success codes 0-3 and FFh independently.
4. Verify successful open supplies usable directory/allocation state.
5. Verify caller CR controls the first sequential record and is not implicitly promised reset by open.
6. Open with exact and wildcard names; verify wildcard activates the first match.
7. Open nonzero EX across representative extent-mask formats.
8. Verify type attribute bits survive as documented attributes without changing base type matching.
9. Close a file after writes and reopen to verify persistent EX/RC/allocation state.
10. Close a missing dirty FCB and require FFh.
11. Verify explicit-drive operations restore the prior current default and retain login state.

Diagnostic/policy tests:

12. Snapshot all bytes after failed open.
13. Close an unchanged open FCB and compare DRI's zero result.
14. Exercise read-only disk, conflicting allocation maps, and BIOS write failures under controlled error handlers.
15. Diagnose DRI high-S2 behavior without requiring its representation.

Must-not-require observations:

16. Do not require exact S1 contents, DRI private flag bits, internal search variables, merge order, or directory-buffer addresses.
17. Do not require a universal single-byte allocation map.

## 11. Proposed ledger findings

One row is one independently testable proposition. The authoritative ledger was not modified.

| Proposed no. | Proposition | Evidence | Disposition |
|---:|---|---|---|
| 156 | A sequential FCB occupies bytes 0-32 (33 bytes). | A | REQUIRED |
| 157 | A random-access FCB adds random-record bytes 33-35. | A | REQUIRED |
| 158 | FCB byte 0 uses 0 for current default and 1-16 for explicit A-P selection. | A | REQUIRED |
| 159 | FCB bytes 1-8 contain an uppercase, high-bit-clear, blank-padded filename. | A | REQUIRED |
| 160 | FCB bytes 9-11 contain the uppercase file type. | A | REQUIRED |
| 161 | High bits of type bytes 9-11 carry the documented read-only, system, and reserved attributes. | A | REQUIRED |
| 162 | FCB byte 12 is current extent, normally caller-initialized to zero and ranging 0-31 during I/O. | A | REQUIRED |
| 163 | FCB byte 13 is reserved for system use; applications have no portable literal-content guarantee. | A + source + experiment | NOT GUARANTEED |
| 164 | FCB byte 14 is reserved for system use and supplied as zero on OPEN, MAKE, and SEARCH calls. | A + source | REQUIRED |
| 165 | FCB byte 15 holds extent record count in the range 0-128. | A | REQUIRED |
| 166 | FCB bytes 16-31 hold CP/M-supplied allocation state reserved for system use. | A | REQUIRED |
| 167 | FCB byte 32 holds the sequential current record 0-127 and is normally initialized by the caller. | A | REQUIRED |
| 168 | Function 15 is selected by C=0Fh and takes the FCB address in DE. | A | REQUIRED |
| 169 | Function 15 opens an existing file for the current user on the FCB-selected drive. | A + source + experiment | REQUIRED |
| 170 | Successful function 15 returns a directory code 0-3 in A. | A + experiment | REQUIRED |
| 171 | Function 15 returns FFh in A when no matching file exists. | A + experiment | REQUIRED |
| 172 | Successful open supplies directory/allocation information in the FCB for later file I/O. | A + source + experiment | REQUIRED |
| 173 | Existing files must be successfully opened before read/write access. | A | REQUIRED |
| 174 | `?` wildcards in open identity fields match corresponding directory characters. | A + source + experiment | REQUIRED |
| 175 | Wildcard open activates the first matching FCB rather than enumerating all matches. | A + experiment | REQUIRED |
| 176 | For sequential access from the beginning, the caller sets CR to zero; open need not do so. | A + source + experiment | REQUIRED |
| 177 | Function 16 is selected by C=10h and takes an activated FCB address in DE. | A | REQUIRED |
| 178 | Close after writes permanently records compatible new FCB directory information. | A + source + experiment | REQUIRED |
| 179 | A file used only for reads need not be closed. | A + source | REQUIRED |
| 180 | Successful close returns a directory code 0-3 in A. | A + experiment | REQUIRED |
| 181 | Close returns FFh when the FCB filename cannot be found. | A + experiment | REQUIRED |
| 182 | FCB allocation-map representation is disk-format-dependent and has no universal application-owned encoding. | A + source | NOT GUARANTEED |
| 183 | Exact FCB bytes after failed open, except documented effects, are not yet guaranteed. | B/C + experiment | POLICY PENDING |
| 184 | DRI's high-S2 no-write/dirty flag representation is private. | I | NOT REQUIRED |
| 185 | DRI's exact zero result for unnecessary close after read-only access is not required. | I/B | NOT REQUIRED |
| 186 | DRI's internal open-copy order, search variables, and close map-merge algorithm are private. | I | NOT REQUIRED |
| 187 | Host-tool exact-byte-count data placed in reserved S1 is not a CP/M 2.2 requirement. | non-DRI diagnostic | NOT REQUIRED |

Proposed additions: **32 entries (156-187)**.

## 12. Proposed corrections/reclassifications

No existing ledger entry requires correction, splitting, merging, or reclassification.

Entry 16 remains about DRI CCP initialization of unopened default FCB control fields. The new general propositions explain which fields the application/BDOS own after that entry environment, without changing the accepted CCP finding.

Entry 146 remains the drive-state rule for temporary explicit-FCB selection. The function-15 experiment confirms it but does not duplicate or alter it.

## 13. Engineering implications

BetterCP/M should expose the documented byte-compatible FCB while keeping internal open-file and dirty-state logic independent of DRI's high-S2 bit. The implementation must write compatible field values back to application memory at observable boundaries.

File identity, active extent state, allocation state, sequential position, and dirty state should remain conceptually distinct. Disk-format parameters must control extent grouping and allocation-map width. Close must commit state atomically enough that normal return does not expose a half-updated directory entry.

Reserved fields must be preserved/interpreted only as required by CP/M policy; extensions such as exact byte counts must not silently become baseline requirements.

## 14. Recommended future investigations

1. **BDOS Directory Search and DMA Transfer Semantics** - functions 17-18 and 26-27, directory-code/DMA placement, wildcards, all-user search, and iteration lifetime.
2. **BDOS Sequential File Read Semantics** - function 20, CR/EX/RC transitions, EOF codes, automatic extent opening, and DMA records.
3. **BDOS Sequential File Write and Make Semantics** - functions 21-22, allocation, directory creation, dirty state, disk-full behavior, and close requirements.
4. **BDOS Delete and Rename Semantics** - functions 19 and 23 after identity/search rules are established.
5. **BDOS Read-Only and Drive-Reset Vector Semantics** - functions 28-29 and 37, including close/write error policy.
6. **BDOS User Number and Namespace Semantics** - function 32 and its relationship to file identity and directory entries.

## Completion audit

- Actual investigations 001-007 and authoritative ledger through 155 verified before selection: **yes**.
- No preexisting Investigation 008 artifact found: **yes**.
- Scope is narrow and nonduplicative: **yes**.
- All completed reports, roadmap, policy, architecture, and cumulative ledger reviewed: **yes**.
- DRI manual pages visually inspected under the PDF workflow: **yes**.
- Evidence classes and DRI/BIOS/emulator/host-tool boundaries preserved: **yes**.
- Probe source, binary, raw output, preparation, hashes, interpretation, and limitations preserved: **yes**.
- One independently testable proposition per proposed ledger row: **yes**.
- Existing ledger and project files modified: **no**.
