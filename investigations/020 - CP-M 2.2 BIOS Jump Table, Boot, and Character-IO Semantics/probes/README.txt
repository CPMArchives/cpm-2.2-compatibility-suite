Investigation 020 BIOS jump-table, character-call, and WBOOT probes
==================================================================

BIOS020 discovers the BIOS base from the operand of the page-zero WBOOT
jump, dumps all 17 three-byte vector entries, and temporarily replaces only
CONST, CONIN, CONOUT, LIST, PUNCH, READER, and LISTST. It calls those vector
entries directly with deterministic values, records results, and restores all
21 modified bytes before returning. It does not modify a system image.

WBOOT20 records page-zero bytes 0000h-0007h, saves the real WBOOT target,
changes only the JMP opcodes at 0000h and 0005h to 00h, and transfers directly
to the saved WBOOT target. PZERO20, invoked by the automated harness after the
CCP prompt returns, records the reconstructed bytes. Neither operand is
damaged and no disk/system structure is deliberately corrupted.

Build (from this directory):

  z80asm -fb -oBIOS020.COM -lBIOS020.lst BIOS020.ASM
  z80asm -fb -oWBOOT20.COM -lWBOOT20.lst WBOOT20.ASM
  z80asm -fb -oPZERO20.COM -lPZERO20.lst PZERO20.ASM

Prepare fresh IBM 3740 images and install the three COM files with cpmcp:

  cpmcp -f ibm-3740 drivea.dsk BIOS020.COM 0:BIOS020.COM
  cpmcp -f ibm-3740 drivea.dsk WBOOT20.COM 0:WBOOT20.COM
  cpmcp -f ibm-3740 drivea.dsk PZERO20.COM 0:PZERO20.COM

Run without manually timed input:

  ./run-bios020.exp /path/to/disk-directory transcripts/console.txt

Record format is self-describing. Vector rows contain index, opcode, and
little-endian decoded target printed as a word. Direct results are CONST
empty, CONST ready, CONIN, READER, first LISTST, second LISTST, and output-log
length. Output pairs contain a device marker ('C', 'L', or 'P') and the raw
byte received in C.

The harness terminates cpmsim with its control-\ character after the final
prompt. The resulting emulator "can't read console" diagnostic is fixture
shutdown behavior, not CP/M evidence.

Cold BOOT was observed only as the stock deterministic emulator startup in
the transcript. No transient invoked BOOT and no instrumented cold-start
image was built; the report explicitly limits that evidence.
