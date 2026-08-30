#!/bin/sh
set -eu
asm=z80asm
$asm -fb -oMAXOK.HDR -dmarkch=79 BOUND22.ASM
$asm -fb -oBOUND.HDR -dmarkch=88 BOUND22.ASM
cp MAXOK.HDR MAXOK.COM
cp BOUND.HDR BOUND.COM
# FA00 BIOS and EC06 BDOS in the accepted 62K reference; the resident CCP
# begins at E400h. DRI requires the next DMA destination strictly below CCP:
# 453 records end at E380h and succeed; 454 end at E400h and are rejected.
truncate -s 57984 MAXOK.COM
truncate -s 58112 BOUND.COM
