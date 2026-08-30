#!/bin/sh
set -eu
cd "$(dirname "$0")"
z80asm -fb -lFAIL44.lis -oFAIL44.COM FAIL44.ASM
