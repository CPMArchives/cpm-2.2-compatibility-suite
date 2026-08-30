#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d /tmp/i063-rebuild.XXXXXX)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cp "$root"/*.ASM "$root/build.sh" "$tmp/"
for n in CPU8080 CPUZ80 UNDOC63 TIMING63; do cp "$root/$n.COM" "$tmp/$n.accepted.COM"; done
(cd "$tmp" && ./build.sh)
{
  for n in CPU8080 CPUZ80 UNDOC63 TIMING63; do
    cmp "$tmp/$n.accepted.COM" "$tmp/$n.COM"
    shasum -a 256 "$tmp/$n.accepted.COM" "$tmp/$n.COM"
  done
  echo 'All four COM files rebuilt byte-identically.'
} > "$root/rebuild-verification.txt"
