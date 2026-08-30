# Investigation 015 - CP/M 2.2 BDOS Physical Disk Error and Error Presentation Semantics

Date: 14 August 2026  
Status: evidence report only; no Compatibility Ledger or pre-existing BetterCP/M file modified

## 1. Scope

This investigation separates ordinary BDOS file-operation results from physical CBIOS read/write failures and DRI's permanent-error presentation. It covers sequential/random read and write, Make, Close, and the documented logical results for Delete and Rename. It does not claim that all controllers fail atomically or that one BIOS's retry algorithm describes every CP/M machine.

The existing ledger ends at 355. Investigation 014 proposed 356-389 without editing it; proposals here therefore begin at 390. They remain report proposals only.

## 2. Sources and evidence classes

1. DRI, *CP/M 2.0 Interface Guide*, `<reference-archive>/CPM_2_0_Interface_Guide.pdf`, SHA-256 `e10f525fcf399897fa86703eb930e21ba59fa54c0708c1cf5909e92beaf7a279`: Functions 16, 19-23, 33-34, printed pp. 16, 18-20, 25-27 / PDF pp. 22, 24-26, 31-33. Relevant pages were rendered and visually inspected.
2. DRI, *CP/M 2.2 Alteration Guide*, `<reference-archive>/CPM_2.2_Alteration_Guide_1979.pdf`, SHA-256 `98a176be191c68207b5859371cf3d95eb90f517a72bdeb3b3699833e7c368891`: CBIOS READ/WRITE contract, printed pp. 18-20 / PDF pp. 22-24; PDF p. 23 was rendered and visually inspected.
3. `<reference-archive>/cpm2-plm/OS3BDOS.ASM`, February 1980 BDOS 2.2, SHA-256 `a22b7dd0f8adaa8dd9affe2cbb0f5749ddf278bf36ca9f94e38f9acf335a44d8`: `rdbuff`, `wrbuff`, `diocomp`, `pererr`, `persub`, `errflg`, and file-operation paths.
4. z80pack commit `91fd28eb04e675c2127df88ed3f40675e15282e2`, cpmsim 1.39, Z80 CBIOS 1.2, and the preserved local fault-injection build.
5. Existing BetterCP/M Investigations 008-015.

Evidence classes are **A** documented interface, **B** DRI source/behavior, **I** incidental to the tested BIOS/injector, and **D** unresolved policy.

## 3. Documented interface behavior

### 3.1 CBIOS physical I/O contract

CBIOS READ and WRITE each transfer one selected sector using the selected drive/track/sector/DMA state. They return A=0 for success and A=1 for a nonrecoverable error. BDOS currently tests only zero versus nonzero, so nonzero implementation-specific values are equivalent at this boundary.

The Alteration Guide assigns recovery to the BIOS: it should attempt at least ten retries before reporting a nonrecoverable error. Once reported, BDOS displays `BDOS ERR ON x: BAD SECTOR`; the documented operator choices are carriage return to ignore or control-C to abort. The guide applies the READ error contract and recovery description to WRITE as well.

This is not the same namespace as a BDOS file-call return in A. The BIOS A value is consumed internally by BDOS; the application may instead see the interactive error path.

### 3.2 Documented BDOS file-operation results

- **Read Sequential (20):** 00 success; nonzero means no data at the next logical record, such as EOF. No physical-media return code is specified.
- **Write Sequential (21):** 00 success; nonzero means unsuccessful write due to full disk. No physical-media return code is specified.
- **Read Random (33):** 00 success; 01 unwritten data, 03 cannot close current extent, 04 seek to unwritten extent, 06 seek past CP/M 2.2's physical address limit/nonzero r2. These are logical/position/extent conditions, not controller read-error codes.
- **Write Random (34):** the random-read codes plus 05 when a new extent cannot be created due to directory overflow. DRI may also expose 02 for allocation failure (Investigation 013), but the exact promise remains policy pending.
- **Make (22):** 00-03 success directory code; FF when no directory space is available.
- **Delete (19):** 00-03 when one or more files were found/deleted; FF no match.
- **Rename (23):** 00-03 success; FF source not found.
- **Close (16):** 00-03 success; FF filename not found.

The Interface Guide does not define application-visible physical-sector failure codes for these BDOS calls, DMA validity after ignored physical failure, partial-write atomicity, FCB rollback, or how an application can bypass the operator interaction.

## 4. DRI source implementation

`rdbuff` and `wrbuff` call the BIOS READ/WRITE entry. `diocomp` returns immediately only for zero; any nonzero status jumps through `pererr` to `persub`. Thus logical BDOS result construction is bypassed while the permanent-error handler runs.

`persub` prints the drive-qualified `Bad Sector` message and reads one console character. Control-C jumps to the BDOS reboot path. Any other character returns from the handler and resumes the interrupted BDOS path as though the low-level helper completed. There is no BDOS retry at this layer and no synthesized file-call error code. DRI relies on BIOS retry before the nonzero return.

Consequences visible in source, then tested below, include possible apparent success after ignore: the higher-level path can update FCB state and return its normal code even though no physical transfer occurred. Routine names, error-vector layout, and stack routing are implementation details.

## 5. Experimental method

To force a physical failure after boot and immediately before a selected operation, the investigation preserves a complete local cpmsim source tree. Its only functional change adds unused port 18: OUT 1 fails the next physical read with controller status 5; OUT 2 fails the next physical write with status 6. It then disarms. No host I/O or DMA transfer occurs for that operation.

This changes neither DRI BDOS nor CBIOS. The stock Z80 CBIOS passes the nonzero controller status to BDOS. The injector makes the failure point deterministic and avoids corrupting the production emulator. It is instrumentation, not a proposed CP/M API.

Every case booted from a fresh copy of SHA-256 `9d07cd7d4954cdfff268ce7698b3faf393c25a1b4785de81ffdfbcf5f8fc5d77`. The harness executed exactly one selected failure, supplied deterministic `x` or control-C, recorded console/FCB/DMA, and hashed/decoded the after image.

## 6. Experimental results

### 6.1 Controls

N: normal sequential read returned 00, advanced CR, and replaced DMA sentinel EE with file marker 41.

I: sequential EOF returned 01 normally, left DMA EE, and printed no diagnostic. J: random read of an unwritten record returned 01 normally, left DMA EE, and printed no diagnostic. These establish the ordinary documented BDOS return-code path against which physical failures were compared.

### 6.2 Ignored physical read failures

A (sequential) and B (random) each displayed `Bdos Err On A: Bad Sector` and blocked for input. After scripted `x`, both BDOS calls returned 00. DMA remained EE because no sector transferred. Sequential CR nevertheless advanced from 00 to 01; random working position remained record zero.

Therefore, after the DRI ignore choice, A=00 means only that higher-level processing continued; it does not certify that physical read data reached DMA.

### 6.3 Ignored physical write failures

C (sequential) and D (random) displayed the same diagnostic. After `x`, both returned 00; sequential CR advanced. Their images remained byte-identical, so the apparent successful calls did not write data in these controlled pre-transfer failures.

E failed the directory write during Make. After `x`, Make returned directory code 03 and activated the in-memory FCB, but NEW015.DAT did not exist and the image was unchanged.

F opened DSKFILE.DAT, marked its activated FCB dirty in memory, requested RC=2, and failed the directory write during Close. After `x`, Close returned directory code 02, but the directory remained unchanged.

These results prove that normal-looking BDOS results can follow an ignored physical write failure. They do not prove general media atomicity: a real controller may report failure after partial alteration.

### 6.4 Abort behavior

G repeated sequential physical read failure and H repeated sequential physical write failure. Control-C at `Bad Sector` warm-booted to `A>`; neither call returned to the probe. Both images were unchanged by this pre-transfer injector.

### 6.5 Hash and directory audit

All N/A-J post-run images equalled their before image hash. All decoded directory listings matched. This is expected for reads, logical failures, aborts, and the injector's pre-transfer write failures. Complete evidence is under `probes/cases/` and `probes/images-after/`.

## 7. Compatibility conclusions

### Required surface

- The CBIOS READ/WRITE zero/nonzero contract and pre-report recovery duty.
- Separation of ordinary BDOS logical result codes from nonrecoverable physical I/O presentation.
- Strict CP/M behavior must provide the documented Bad Sector operator path, including ignore and abort choices.
- Ignoring means continuation, not validation: applications receive no trustworthy physical-error return code and cannot assume DMA/data persistence.

### DRI implementation details

- `pererr`/`persub` names, vector addresses, stack route, exact internal flags, and lack of an internal retry loop beyond delegating retry to BIOS.
- z80pack controller status values 5/6 and the investigation-only port 18.

### Policy pending

- Exact message capitalization/punctuation versus semantically equivalent presentation.
- Whether BetterCP/M offers a noninteractive extension that returns structured physical errors while strict mode remains compatible.
- How to expose partial-write uncertainty, device-specific diagnostics, retry telemetry, and headless operation.
- Whether strict mode accepts any non-control-C ignore character like DRI or only the documented carriage return.

## 8. Proposed Compatibility Ledger additions

Proposals only; the ledger was not modified.

390. **REQUIRED - CBIOS physical read result.** BIOS READ returns zero for success and nonzero for nonrecoverable physical failure. Source: Alteration Guide; Investigation 015.

391. **REQUIRED - CBIOS physical write result.** BIOS WRITE returns zero for success and nonzero for nonrecoverable physical failure. Source: Alteration Guide; Investigation 015.

392. **REQUIRED - BIOS retry responsibility.** A conforming CP/M 2.2 BIOS attempts at least ten retries for a recoverable physical read/write error before reporting nonrecoverable failure. Source: Alteration Guide; Investigation 015.

393. **REQUIRED - Physical/logical error separation.** A BIOS physical-error status is consumed by BDOS and is not one of the documented file-call logical return codes. Source: Interface/Alteration Guides; Investigation 015.

394. **REQUIRED - Bad Sector presentation.** A nonrecoverable BIOS disk-I/O status enters the CP/M Bad Sector operator-error path rather than automatically becoming a file-call code. Source: Alteration Guide/experiment; Investigation 015.

395. **REQUIRED - Physical-error ignore choice.** The operator can choose to ignore a reported physical error and continue the interrupted BDOS path. Source: Alteration Guide/experiment; Investigation 015.

396. **REQUIRED - Physical-error abort choice.** Control-C at the physical-error presentation aborts the interrupted operation. Source: Alteration Guide/experiment; Investigation 015.

397. **POLICY PENDING - Abort restart details.** Decide whether BetterCP/M promises DRI's exact warm-boot destination and state after physical-error control-C. Source: DRI source/experiment; Investigation 015.

398. **NOT GUARANTEED - Result after ignored physical error.** A normal-looking BDOS result after the ignore choice does not establish successful physical transfer. Source: DRI source/experiment; Investigation 015.

399. **NOT GUARANTEED - DMA after ignored physical read.** DMA contents are not valid new record data after an ignored physical read failure. Source: experiment; Investigation 015.

400. **NOT GUARANTEED - Persistence after ignored physical write.** A success-looking sequential/random write result after ignore does not establish media persistence. Source: experiment; Investigation 015.

401. **NOT GUARANTEED - Make persistence after physical error.** A directory code after ignored Make physical failure does not establish that the file exists on disk. Source: experiment; Investigation 015.

402. **NOT GUARANTEED - Close persistence after physical error.** A directory code after ignored Close physical failure does not establish that FCB metadata was persisted. Source: experiment; Investigation 015.

403. **NOT GUARANTEED - Physical-write atomicity.** CP/M 2.2 does not guarantee that a physical write failure leaves the sector or directory wholly unchanged. Source: interface omission; Investigation 015.

404. **REQUIRED - Sequential read logical result.** Function 20 returns 00 for transferred data and nonzero for no logical data/EOF; that nonzero is not the physical-error presentation. Source: Interface Guide/experiment; Investigation 015.

405. **REQUIRED - Sequential write logical result.** Function 21 returns 00 for success and nonzero for documented disk-full failure; physical I/O errors use the operator path. Source: Interface Guide; Investigation 015.

406. **REQUIRED - Random read logical codes.** Function 33 codes 01/03/04/06 describe unwritten data, extent/close, and address-limit conditions, not controller read failure. Source: Interface Guide; Investigation 015.

407. **REQUIRED - Random write logical codes.** Function 34 uses random-read logical codes plus 05 for new-extent directory overflow; these do not replace the physical-error path. Source: Interface Guide; Investigation 015.

408. **REQUIRED - Make/Delete/Rename/Close logical codes.** Their documented 00-03/FF results describe directory success/no-match-or-space conditions, not physical controller failure. Source: Interface Guide; Investigation 015.

409. **NOT REQUIRED - DRI permanent-error internals.** BetterCP/M need not reproduce DRI's error-vector addresses, routine names, stack routing, or private flags. Source: DRI source; Investigation 015.

410. **NOT REQUIRED - z80pack status values.** Controller statuses 5/6 and investigation port 18 are test-fixture details, not CP/M interfaces. Source: probe instrumentation; Investigation 015.

411. **POLICY PENDING - Exact Bad Sector text.** Decide whether capitalization, punctuation, and spacing of DRI's diagnostic are strict compatibility surface. Source: guides/experiment; Investigation 015.

412. **POLICY PENDING - Accepted ignore characters.** Documentation names carriage return; DRI accepts any character except control-C. Choose strict BetterCP/M policy. Source: Alteration Guide/DRI source/experiment; Investigation 015.

413. **POLICY PENDING - Structured physical-error extension.** Decide whether noninteractive/headless BetterCP/M may optionally return structured physical errors while preserving strict CP/M presentation mode. Source: Investigation 015.

## 9. Unresolved policy questions

1. Must strict mode reproduce the diagnostic byte-for-byte, or only the operator choices and drive identity?
2. Should strict mode accept every non-control-C character as ignore (DRI) or only carriage return (documentation)?
3. What optional API can report operation, drive, track, sector, retry count, and device status without confusing it with BDOS logical codes?
4. How should BetterCP/M warn about possible partial writes and invalid DMA after ignore?
5. What is the appropriate headless policy when no operator can answer the error prompt?

## 10. Recommended future investigations

1. Natural controller/media failures that occur after partial transfer, including sector corruption and torn directory writes.
2. Cross-BIOS comparison of retry count, delay, and diagnostics on historical CP/M systems.
3. Select/not-ready/write-protect hardware errors versus BDOS software read-only handling.
4. Function 40 and multi-sector allocation behavior under physical failure.

## 11. Completion audit

- Required report, probe source/binary, README, observed output, transcripts, harnesses, complete fault-emulator source/binary, hashes, base image, and eleven post-run images exist.
- Required sequential/random read and write, Make, and Close physical failures ran from fresh images. Delete/Rename have no additional physical-write mechanism beyond their directory write; their documented logical codes and the common DRI physical dispatch are analyzed without falsely labelling an unrun Delete/Rename injection as experimental.
- Logical sequential/random failure controls ran and are clearly separated from physical failures.
- PHYS015.COM and the custom emulator rebuild byte-identically; SHA-256 hashes are recorded.
- All accepted images and directory listings were compared. No evidence is claimed for partial-transfer behavior or an untested BIOS.
- Compatibility Ledger SHA-256 remains `316b2c6eda23a62581f073e95013d27009dab1c9561ec4762c77351131bd42f9`.
- No pre-existing BetterCP/M file was modified, no ledger was edited, and no ZIP archive was created.
