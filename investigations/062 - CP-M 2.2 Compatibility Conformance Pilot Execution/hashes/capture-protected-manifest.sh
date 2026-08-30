#!/bin/sh
set -eu
tree=<project-root>
out=${1:?output path required}
find "$tree" -type f ! -path "$tree/investigations/062 - CP-M 2.2 Compatibility Conformance Pilot Execution/*" -print0 |
  sort -z | xargs -0 shasum -a 256 > "$out"

