Investigation 012 probe artifacts
=================================

DELREN012.ASM exercises BDOS functions 19 and 23, using search, open, read,
make, write, close, Set DMA, Get Current Drive, and Set/Get User only for
controlled lifecycle verification. It is deterministic and noninteractive.

Build:

  z80asm -fb -oDELREN012.COM DELREN012.ASM

DELREN012.COM SHA-256:

  afee3d9d22dbbd57bed80a5eac6cbfc4294bdaec8b54700640190b98ddfecfd3

DELREN012 exceeds CP/M's 8-character filename limit, so the preserved A image
contains the identical binary as DREN012.COM. Restore and run with:

  ./reset-images.sh
  ./capture012.exp

observed-output.txt is the decoded evidence; observed-raw.txt is the complete
terminal transcript. The final console-read diagnostic follows return to A>
and is only the scripted emulator shutdown.

Ordinary report lines contain result, current drive, FCB bytes 0-32, and DMA
byte 0. Search lines contain result plus the matching 32-byte directory entry.
