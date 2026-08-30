#!/bin/sh
set -eu
root=<project-root>
out=$1
find "$root" -type f ! -path "$root/investigations/064 - CP-M 2.2 Expanded Software Corpus Validation/*" -print0 |
  sort -z | xargs -0 shasum -a 256 > "$out"
