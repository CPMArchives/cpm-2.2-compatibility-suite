Investigation 007 probe artifacts
=================================

DSK007.ASM observes CP/M 2.2 BDOS disk reset, explicit selection, login-vector,
current-disk, read-only-vector, page-zero 0004h, and implicit FCB selection
state. DSK007.COM is the assembled probe.

Build:

  z80asm -fb -oDSK007.COM DSK007.ASM

Install DSK007.COM on drive A of disposable copies of z80pack's CP/M 2.2
distribution disks and run under cpmsim in Z80 mode. Both A and B must be
mounted; B must contain at least one directory entry for the DMA diagnostic.

Record fields are:

  function-25 current disk
  function-24 login-vector low byte
  function-24 login-vector high byte
  page-zero byte 0004h
  function-29 read-only-vector low byte
  function-29 read-only-vector high byte

The final line shows byte 0080h, the first byte of an alternate DMA buffer,
and the function-17 return code after reset followed by an explicit-drive-B
wildcard search. A changed byte at 0080h with an unchanged alternate byte is
evidence that function 13 restored DMA 0080h. The search is used only as a
safe directory-producing operation; its result and matching semantics are not
classified by this investigation.

The probe calls documented BDOS interfaces and reads documented page-zero
state. It does not patch or instrument the DRI BDOS, BIOS, or emulator.
