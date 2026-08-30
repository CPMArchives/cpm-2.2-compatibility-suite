#!/bin/sh
set -eu
cd "$(dirname "$0")"
z80asm -fb -lCROSS70A.lis -oCROSS70A.COM CROSS70A.ASM
z80asm -fb -lFAULT066.rebuilt.lis -oFAULT066.rebuilt.COM FAULT066.ASM

