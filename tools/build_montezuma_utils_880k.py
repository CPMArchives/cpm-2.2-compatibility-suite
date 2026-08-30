#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Shared CP/M 2.2 filesystem helpers for the 880K suite images."""
from __future__ import annotations

from pathlib import Path

from build_blank_montezuma_880k import RAW_SIZE


BLOCK_SIZE = 2048
DIRECTORY_ENTRIES = 128
DIRECTORY_BYTES = DIRECTORY_ENTRIES * 32
FIRST_DATA_BLOCK = DIRECTORY_BYTES // BLOCK_SIZE
BLOCK_COUNT = RAW_SIZE // BLOCK_SIZE
BLOCKS_PER_EXTENT = 8  # DSM exceeds 255, so each FCB stores eight 16-bit blocks


def cpm_name(host_name: str) -> tuple[bytes, bytes]:
    """Return an upper-case, space-padded CP/M 8.3 name."""
    stem, dot, suffix = host_name.upper().partition(".")
    if not stem or len(stem) > 8 or len(suffix) > 3 or (not dot and suffix):
        raise ValueError(f"not a CP/M 8.3 name: {host_name}")
    return stem.ljust(8).encode("ascii"), suffix.ljust(3).encode("ascii")


def install_files(files: list[Path]) -> bytes:
    """Build a CP/M 2.2 filesystem using 2K blocks and 16-bit allocation entries."""
    raw = bytearray([0xE5] * RAW_SIZE)
    directory_index = 0
    next_block = FIRST_DATA_BLOCK
    for path in files:
        content = path.read_bytes()
        records = (len(content) + 127) // 128
        padded = content + bytes([0x1A]) * (records * 128 - len(content))
        block_total = (len(padded) + BLOCK_SIZE - 1) // BLOCK_SIZE
        extent_total = max(1, (records + 127) // 128)
        name, suffix = cpm_name(path.name)
        content_at = 0
        for extent_number in range(extent_total):
            if directory_index >= DIRECTORY_ENTRIES:
                raise SystemExit("utility files exceed the 128-entry directory")
            blocks_here = min(BLOCKS_PER_EXTENT, block_total - extent_number * BLOCKS_PER_EXTENT)
            records_here = min(128, max(0, records - extent_number * 128))
            entry = bytearray(32)
            entry[0] = 0
            entry[1:9] = name
            entry[9:12] = suffix
            entry[12] = extent_number & 0x1F
            entry[14] = extent_number >> 5
            entry[15] = records_here
            for slot in range(blocks_here):
                if next_block >= BLOCK_COUNT:
                    raise SystemExit("utility files exceed the 880K disk capacity")
                entry[16 + slot * 2:18 + slot * 2] = next_block.to_bytes(2, "little")
                chunk = padded[content_at:content_at + BLOCK_SIZE]
                raw[next_block * BLOCK_SIZE:next_block * BLOCK_SIZE + len(chunk)] = chunk
                content_at += len(chunk)
                next_block += 1
            start = directory_index * 32
            raw[start:start + 32] = entry
            directory_index += 1
    return bytes(raw)


def recover_files(raw: bytes) -> dict[str, bytes]:
    """Independently reconstruct files from CP/M directory extents."""
    entries: dict[str, list[tuple[int, int, list[int]]]] = {}
    for index in range(DIRECTORY_ENTRIES):
        entry = raw[index * 32:(index + 1) * 32]
        if entry[0] == 0xE5:
            continue
        if entry[0] != 0:
            raise SystemExit("unexpected nonzero user area in generated directory")
        stem = bytes(byte & 0x7F for byte in entry[1:9]).decode("ascii").rstrip()
        suffix = bytes(byte & 0x7F for byte in entry[9:12]).decode("ascii").rstrip()
        filename = stem + (("." + suffix) if suffix else "")
        extent = entry[12] + (entry[14] << 5)
        blocks = [int.from_bytes(entry[pos:pos + 2], "little") for pos in range(16, 32, 2)]
        entries.setdefault(filename.lower(), []).append((extent, entry[15], [block for block in blocks if block]))
    recovered: dict[str, bytes] = {}
    for filename, extents in entries.items():
        content = bytearray()
        for _, records, blocks in sorted(extents):
            extent_data = bytearray()
            for block in blocks:
                extent_data.extend(raw[block * BLOCK_SIZE:(block + 1) * BLOCK_SIZE])
            content.extend(extent_data[:records * 128])
        recovered[filename] = bytes(content)
    return recovered
