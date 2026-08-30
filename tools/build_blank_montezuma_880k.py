#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Montezuma Micro 80T SUPER DS DATA DMK geometry and build helpers.

The physical format is mixed-sector MFM: each side of each cylinder contains
five 1024-byte sectors followed by one 512-byte sector.  Across 80 cylinders
and two sides this is exactly 901,120 bytes, conventionally labelled 880K.
The disk is a non-system CP/M data disk, so every logical sector is initialized
to E5h.  No host-specific CP/M filesystem formatter is required.
"""
from __future__ import annotations

CYLINDERS = 80
SIDES = 2
TRACK_LENGTH = 0x18EA
SECTOR_SIZES = (1024, 1024, 1024, 1024, 1024, 512)
# Montezuma's skew-two BIOS presents physical sectors in this logical order.
# Four 1K sectors therefore hold the 4K directory before file data begins.
LOGICAL_SECTOR_ORDER = (0, 2, 4, 1, 3, 5)
TRACK_DATA_SIZE = sum(SECTOR_SIZES)
RAW_SIZE = CYLINDERS * SIDES * TRACK_DATA_SIZE
IDAM_FIRST = 175
IDAM_SPACING = 1110
DATA_MARK_OFFSET = 44


def crc16(data: bytes) -> int:
    """Return the WD177x CCITT CRC used by MFM address and data fields."""
    crc = 0xFFFF
    for byte in data:
        crc ^= byte << 8
        for _ in range(8):
            crc = ((crc << 1) ^ 0x1021) & 0xFFFF if crc & 0x8000 else (crc << 1) & 0xFFFF
    return crc


def make_track(cylinder: int, head: int, track_data: bytes | None = None) -> bytes:
    """Construct one six-sector physical DMK track."""
    if track_data is None:
        track_data = bytes([0xE5]) * TRACK_DATA_SIZE
    if len(track_data) != TRACK_DATA_SIZE:
        raise ValueError(f"expected {TRACK_DATA_SIZE} bytes of track data")
    physical_data: list[bytes] = [b""] * len(SECTOR_SIZES)
    logical_at = 0
    for physical_index in LOGICAL_SECTOR_ORDER:
        size = SECTOR_SIZES[physical_index]
        physical_data[physical_index] = track_data[logical_at:logical_at + size]
        logical_at += size
    track = bytearray([0x4E] * TRACK_LENGTH)
    track[:128] = bytes(128)
    for index, size in enumerate(SECTOR_SIZES):
        sector = index + 1
        size_code = 3 if size == 1024 else 2
        idam = IDAM_FIRST + index * IDAM_SPACING
        track[index * 2:index * 2 + 2] = (0x8000 | idam).to_bytes(2, "little")

        # Twelve zero sync bytes and three missing-clock A1 bytes precede each
        # MFM field.  The DMK pointer addresses the FE identifier byte itself.
        track[idam - 15:idam - 3] = bytes(12)
        track[idam - 3:idam] = b"\xA1\xA1\xA1"
        ident = bytes((0xFE, cylinder, head, sector, size_code))
        track[idam:idam + 5] = ident
        track[idam + 5:idam + 7] = crc16(b"\xA1\xA1\xA1" + ident).to_bytes(2, "big")

        data_mark = idam + DATA_MARK_OFFSET
        track[data_mark - 15:data_mark - 3] = bytes(12)
        track[data_mark - 3:data_mark] = b"\xA1\xA1\xA1"
        field = b"\xFB" + physical_data[index]
        track[data_mark:data_mark + len(field)] = field
        crc_at = data_mark + len(field)
        track[crc_at:crc_at + 2] = crc16(b"\xA1\xA1\xA1" + field).to_bytes(2, "big")
    # The Montezuma formatter leaves the final byte of each DMK track zero.
    track[-1] = 0
    return bytes(track)


def build(raw: bytes | None = None) -> bytes:
    """Build the complete two-sided DMK image, cylinder/head interleaved."""
    if raw is None:
        raw = bytes([0xE5]) * RAW_SIZE
    if len(raw) != RAW_SIZE:
        raise ValueError(f"expected {RAW_SIZE} logical bytes, got {len(raw)}")
    header = bytearray(16)
    header[1] = CYLINDERS
    header[2:4] = TRACK_LENGTH.to_bytes(2, "little")
    header[4] = 0x00  # two-sided, writable image
    image = bytearray(header)
    for cylinder in range(CYLINDERS):
        for head in range(SIDES):
            track_index = cylinder * SIDES + head
            start = track_index * TRACK_DATA_SIZE
            image.extend(make_track(cylinder, head, raw[start:start + TRACK_DATA_SIZE]))
    return bytes(image)


def verify(image: bytes, require_blank: bool = True) -> None:
    """Verify header, identities, CRCs, sector sizes, and blank contents."""
    expected_size = 16 + CYLINDERS * SIDES * TRACK_LENGTH
    if len(image) != expected_size:
        raise ValueError(f"expected {expected_size} DMK bytes, got {len(image)}")
    if image[1] != CYLINDERS or int.from_bytes(image[2:4], "little") != TRACK_LENGTH or image[4] != 0:
        raise ValueError("bad DMK header")
    for cylinder in range(CYLINDERS):
        for head in range(SIDES):
            track_index = cylinder * SIDES + head
            start = 16 + track_index * TRACK_LENGTH
            track = image[start:start + TRACK_LENGTH]
            for index, size in enumerate(SECTOR_SIZES):
                sector = index + 1
                pointer = int.from_bytes(track[index * 2:index * 2 + 2], "little")
                idam = pointer & 0x3FFF
                size_code = 3 if size == 1024 else 2
                ident = bytes((0xFE, cylinder, head, sector, size_code))
                if pointer & 0x8000 == 0 or track[idam:idam + 5] != ident:
                    raise ValueError(f"bad identity on cylinder {cylinder}, head {head}, sector {sector}")
                if int.from_bytes(track[idam + 5:idam + 7], "big") != crc16(b"\xA1\xA1\xA1" + ident):
                    raise ValueError("bad ID CRC")
                data_mark = idam + DATA_MARK_OFFSET
                field = track[data_mark:data_mark + 1 + size]
                if field[0] != 0xFB:
                    raise ValueError("sector data mark is absent")
                if require_blank and field[1:] != bytes([0xE5]) * size:
                    raise ValueError("sector is not blank data")
                stored = int.from_bytes(track[data_mark + 1 + size:data_mark + 3 + size], "big")
                if stored != crc16(b"\xA1\xA1\xA1" + field):
                    raise ValueError("bad data CRC")


def extract_raw(image: bytes) -> bytes:
    """Return sector data in Montezuma logical track and sector order."""
    verify(image, require_blank=False)
    raw = bytearray()
    for track_index in range(CYLINDERS * SIDES):
        start = 16 + track_index * TRACK_LENGTH
        track = image[start:start + TRACK_LENGTH]
        physical_data: list[bytes] = []
        for index, size in enumerate(SECTOR_SIZES):
            pointer = int.from_bytes(track[index * 2:index * 2 + 2], "little")
            data_mark = (pointer & 0x3FFF) + DATA_MARK_OFFSET
            physical_data.append(track[data_mark + 1:data_mark + 1 + size])
        for physical_index in LOGICAL_SECTOR_ORDER:
            raw.extend(physical_data[physical_index])
    return bytes(raw)
