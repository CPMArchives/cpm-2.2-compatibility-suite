#!/bin/sh
set -eu
Z80ASM=${Z80ASM:-z80asm}
"$Z80ASM" -fb -oIN42.COM IN42.ASM > IN42.lis

