#!/bin/sh
set -eu
Z80ASM=${Z80ASM:-z80asm}
"$Z80ASM" -fb -oIN42.rebuilt.COM IN42.ASM > IN42.rebuilt.lis
cmp IN42.COM IN42.rebuilt.COM
shasum -a 256 IN42.COM IN42.rebuilt.COM
