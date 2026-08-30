#!/bin/sh
set -eu
tree=<project-root>
out=${1:?output path required}
find "$tree" -type f ! -path "$tree/investigations/061 - CP-M 2.2 Cross-Implementation Differential Validation/*" -print0 |
  sort -z |
  xargs -0 shasum -a 256 > "$out"

