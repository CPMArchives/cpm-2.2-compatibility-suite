Investigation 014 probe
=======================

Required tools
--------------
- z80asm
- cpmsim
- cpmtools configured for the ibm-3740 format
- expect

Build
-----
From this directory:

  z80asm -fb -oPROT014.COM PROT014.ASM

Expected SHA-256:

  PROT014.ASM  fe1f310e92796a1dbf44bd58113a3ea5265e1da1896ac7eca30959484b0b675a
  PROT014.COM  1307f96971db70f8123b52f297eb465d2a764391dfbc1cf13bd3f90926aeb9e8

Byte-identical verification:

  cp PROT014.COM /private/tmp/PROT014.accepted.COM
  z80asm -fb -oPROT014.COM PROT014.ASM
  cmp /private/tmp/PROT014.accepted.COM PROT014.COM

Run
---
run-all-prot014.sh restores images-before/drivea.dsk separately for modes N,
A-K and records each console stream, hash pair, and directory listing under a
temporary run directory. It requires write access to /private/tmp. Modes A-D
test file read-only fatal paths; E tests Close after an intervening attribute
change; F-J test Function 28 disk protection; K tests the vector and reset.
Mode N covers normal Function 30/22 and Function 28/29/13 behavior.

The accepted evidence is already preserved here:

  cases/<mode>/console.txt
  cases/<mode>/before.sha256
  cases/<mode>/after.sha256
  cases/<mode>/directory.txt
  images-after/drivea-<mode>.dsk

The harness sends a deterministic 'x' to each fatal handler and then verifies
that CP/M warm-boots. It never relies on manually typed keyboard input.

Fixture files
-------------
ATTR.DAT (1 record), BIG.DAT (130 records/two extents), CLOSEME.DAT (1),
DSKFILE.DAT (1), and read-only ROFILE.DAT (1). PROT014.COM is installed on the
image. Mode N also creates MADEATTR.DAT with read-only and system bits.

Important transcript note
-------------------------
In modes G/H the BEFORE line's first byte is 02, the directory-slot result left
by Function 15 Open. The protected write itself never returns and therefore
has no BDOS result byte. The absence of RETURNED, fatal message, scripted input,
warm boot, and unchanged image are the operative observations.
