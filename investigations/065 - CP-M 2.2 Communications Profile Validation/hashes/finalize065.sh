#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"
find . -type f ! -path './hashes/SHA256SUMS' ! -path './hashes/protected-after.sha256' ! -path './hashes/protected-diff.txt' -print0 |
  sort -z | xargs -0 shasum -a 256 > hashes/SHA256SUMS
