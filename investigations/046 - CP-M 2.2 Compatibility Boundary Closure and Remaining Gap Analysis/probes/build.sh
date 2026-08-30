#!/bin/sh
set -eu
cd "$(dirname "$0")"
z80asm -fb -lGAP46.lis -oGAP46.COM GAP46.ASM
