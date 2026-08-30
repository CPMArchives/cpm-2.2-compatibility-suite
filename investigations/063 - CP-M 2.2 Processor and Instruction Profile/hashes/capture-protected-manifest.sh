#!/bin/sh
set -eu
root=<project-root>
out=$1
find "$root" -type f ! -path "$root/investigations/063 - CP-M 2.2 Processor and Instruction Profile/*" -print0 |
  sort -z |
  xargs -0 shasum -a 256 > "$out"
