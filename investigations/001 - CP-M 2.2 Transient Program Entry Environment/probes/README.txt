Investigation 001 experimental artifacts
========================================

ENTRY001.ASM is a Z80-specific CP/M .COM entry-state probe. It records the
entry registers before making a BDOS call, copies page zero, and copies 16
bytes beginning at the original SP. See the investigation report for the
reference image identity, exact commands, decoded result, limitations, and
evidentiary classification.

The three output lines are, respectively:

  1. 33-byte register record (pairs are little-endian)
  2. 256-byte page-zero snapshot
  3. 16 bytes beginning at entry SP

Register-record order:

  SP AF BC DE HL IX IY AF' BC' DE' HL' I R AF-after-LD-A-I PC format
