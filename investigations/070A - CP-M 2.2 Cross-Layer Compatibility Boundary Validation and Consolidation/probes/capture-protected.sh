#!/bin/sh
set -eu
out=$1
root=<project-root>
find "$root" -type f \
  ! -path "$root/investigations/070 - CP-M 2.2 Cross-Layer Compatibility Boundary Validation and Consolidation/*" \
  ! -path "$root/investigations/070A - CP-M 2.2 Cross-Layer Compatibility Boundary Validation and Consolidation/*" -print0 \
  | sort -z \
  | xargs -0 shasum -a 256 > "$out"
