Investigation 002 probe artifacts
=================================

ABI002.ASM tests the common CP/M 2.2 BDOS call-and-return convention.
It runs safe functions 12, 7, 24, 26, and out-of-range function 41.
The probe seeds registers, records SP immediately before CALL 0005H, and
captures returned main/alternate registers and flags before making another
BDOS call. It temporarily sets IOBYTE to A5h for function 7 and restores it.

Build:

  z80asm -fb -oABI002.COM ABI002.ASM

Output is one hexadecimal stream containing five 25-byte records:

  function (1), pre-SP (2), post-SP (2), AF, BC, DE, HL, IX, IY,
  AF', BC', DE', HL' (twelve 2-byte words, little-endian)

See the report and observed-output.txt for exact environment, method,
decoded observations, evidence classification, and limitations.
