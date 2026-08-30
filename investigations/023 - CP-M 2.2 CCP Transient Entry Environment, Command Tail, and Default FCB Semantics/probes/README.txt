Investigation 023 transient-entry probe
=======================================

ENTRY23 records the entry environment before its first BDOS call: main and
alternate registers, SP, a 16-byte entry-stack window, page zero, both default
FCB regions, and the command-tail/DMA region.  It then queries the live drive
and user and opens/reads DMACHK.DAT without Function 26.  The D023... record at
0080h proves that the inherited DMA address was 0080h.

The probe immediately changes to a private stack after taking its snapshot.
This avoids assuming that the CCP-supplied entry stack provides working space
beyond the return word required by RET termination.  It restores entry SP
before RET.

Build
-----

    z80asm -fb -l -oENTRY23.COM ENTRY23.ASM
    cp ENTRY23.COM BIG23.COM
    truncate -s 2560 BIG23.COM

ENTRY23.COM is 963 bytes (eight CP/M logical records on disk). BIG23.COM is a
20-record padded variant used to show that FCB byte 15 retains loader-derived
record-count state.  DMACHK.DAT begins with:

    D023-DEFAULT-DMA-CHECK-RECORD\n

The preserved rebuild directory was produced from ENTRY23.ASM with the commands
above.  Both COM files compare byte-identically with their named originals.

Automation
----------

run-entry023.exp executes the controlled command matrix twice on separate
copies of the fixture images. run-max023.exp tests the 127-byte CCP input
boundary with the one-character alias T. run-usercheck.exp is a separate
diagnostic cross-check of user-state visibility. No manually timed input is
used. The terminal's echoed lowercase input in console-main.txt proves that
uppercase tail/FCB bytes are not a terminal-side transformation.

Images
------

images-base are unmodified copies of the Investigation 022 accepted images.
images-fixture contain the Investigation 023 programs and data. images-after
are the accepted post-run images. Fixture and after hashes are identical for
both drives; the investigation performs no persistent disk writes.

Transcripts are raw expect/cpmsim captures. The final red emulator diagnostic
in each transcript is caused by the harness sending the emulator interrupt
after the last CP/M prompt; it is not CP/M or probe evidence.

