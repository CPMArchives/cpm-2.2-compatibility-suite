Investigation 019 BIOS boundary tracer
======================================

BIOS019 temporarily replaces the SELDSK, SETTRK, SETSEC, SETDMA, READ, WRITE,
and SECTRAN BIOS jump entries. Every wrapper records a ten-byte raw record and
delegates to the preserved original target. The original 24-byte vector slice
is restored before a warm start. No BDOS/BIOS binary or disk system area is
permanently modified.

Record format:
 event, drive, track-lo, track-hi, sector-lo, sector-hi, DMA-lo, DMA-hi,
 auxiliary, result.

Events: S=SELDSK, T=SETTRK, C=SETSEC, M=SETDMA, R=READ, W=WRITE, X=SECTRAN.
For W, auxiliary is write type and result is BIOS A. For X, auxiliary/result
are translated HL low/high. Values are hexadecimal.

Build:
  z80asm -fb -oBIOS019.COM BIOS019.ASM

Run:
  ./run-bios019.exp /path/to/fresh/disk-directory console.txt

The harness needs no manual input. The probe restores the saved vectors and
requests warm start after printing all evidence. In the accepted run no CCP
prompt followed, so Expect timed out and interrupted the emulator. That
post-evidence shutdown anomaly is not treated as a disk-interface result. The run preserves raw
output, images, hashes, and final directory listings.
