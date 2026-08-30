#!/bin/sh
set -eu
cd "$(dirname "$0")"
z80asm -fb -lCROSS45.lis -oCROSS45.COM CROSS45.ASM
