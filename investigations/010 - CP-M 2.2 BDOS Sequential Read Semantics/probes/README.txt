Investigation 010 probe artifacts
=================================

READ010.ASM exercises BDOS function 20 using files opened by function 15. Each
reported line contains the open result, read result, current drive, byte 0080h,
all 33 sequential FCB bytes, and all 128 active-DMA bytes.

READ010.COM SHA-256:

  995b1a1a5f8e2d7e461f6e2eb1b34cb2d38f2c8ed6a5fc2dde04253dc6c03a5a

Build:

  z80asm -fb -oREAD010.COM READ010.ASM

The disposable image preparation and file sizes are recorded in
observed-output.txt. Run under the identified DRI CP/M 2.2 environment:

  A>READ010

The probe uses no timed input and does not patch BDOS, BIOS, or the emulator.
It performs only open and sequential-read operations. Test images are
disposable, although the accepted run is read-only and their hashes are checked
before and after.

observed-output.txt is the decoded evidence record. observed-raw.txt is the
complete terminal transcript. capture.exp documents the deterministic emulator
invocation; its final console-read diagnostic occurs only after READ010 has
returned to the CCP prompt and is not a probe failure.
