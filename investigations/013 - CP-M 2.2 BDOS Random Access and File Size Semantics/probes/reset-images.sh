#!/bin/zsh
set -e
here=${0:A:h}
diskdir=/private/tmp/inv013-disk
rm -rf "$diskdir"
mkdir -p "$diskdir"
cp "$here"/images-before/drive?.dsk "$diskdir"/
shasum -a 256 "$diskdir"/drive?.dsk
