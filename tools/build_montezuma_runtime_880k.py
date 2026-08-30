#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Build the maintained 880K runtime disk from canonical host inputs."""
from __future__ import annotations

import argparse
import hashlib
import shutil
import tempfile
from pathlib import Path

from build_blank_montezuma_880k import build, extract_raw, verify
from build_montezuma_utils_880k import (
    BLOCK_COUNT, BLOCK_SIZE, FIRST_DATA_BLOCK, install_files, recover_files,
)


ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "suite/build"
PAYLOAD = ROOT / "suite/runtime-payload"
EXTERNAL = ROOT / "external/sysinfo/SYSINFO.COM"
DEFAULT_OUT = ROOT / "suite/disk-images/trs80-montezuma/Conformance Suite.dmk"
UTILITIES = (
    "FILETEST", "RANDTEST", "DIRTEST", "CONSTEST", "BDOSTEST", "ENTRYTST",
    "CCPTEST", "DISKTEST", "BIOSTEST", "ERRTEST", "ECOTEST", "CPUTEST", "SCRATCH",
)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def extent_count(path: Path) -> int:
    records = (path.stat().st_size + 127) // 128
    return max(1, (records + 127) // 128)


def set_user(raw: bytearray, first: int, count: int, user: int) -> None:
    for index in range(first, first + count):
        raw[index * 32] = user


def set_read_only(raw: bytearray, filename: str) -> None:
    stem, suffix = filename.upper().split(".")
    for index in range(128):
        entry = raw[index * 32:(index + 1) * 32]
        if entry[0] == 0xE5:
            continue
        found_stem = bytes(byte & 0x7F for byte in entry[1:9]).decode("ascii").rstrip()
        found_suffix = bytes(byte & 0x7F for byte in entry[9:12]).decode("ascii").rstrip()
        if found_stem == stem and found_suffix == suffix:
            raw[index * 32 + 9] |= 0x80


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", nargs="?", type=Path, default=DEFAULT_OUT)
    args = parser.parse_args()
    output = args.output.expanduser().resolve()

    for utility in UTILITIES:
        if not (BUILD / f"{utility}.COM").is_file():
            raise SystemExit(f"missing current build: {utility}.COM")
    if not PAYLOAD.is_dir():
        raise SystemExit(f"missing canonical runtime payload: {PAYLOAD}")
    if not EXTERNAL.is_file():
        raise SystemExit(f"missing pinned external utility: {EXTERNAL}")

    with tempfile.TemporaryDirectory(prefix="runtime-880k-") as temporary:
        work = Path(temporary)
        paths: list[Path] = []
        for source in sorted(PAYLOAD.iterdir()):
            if source.is_file() and source.suffix.upper() in (".DAT", ".CFG", ".COM"):
                destination = work / source.name
                destination.write_bytes(source.read_bytes())
                paths.append(destination)
        for utility in UTILITIES:
            source = BUILD / f"{utility}.COM"
            destination = work / source.name
            destination.write_bytes(source.read_bytes())
            paths.append(destination)
        destination = work / EXTERNAL.name
        destination.write_bytes(EXTERNAL.read_bytes())
        paths.append(destination)

        license_text = (ROOT / "LICENSE").read_text(encoding="ascii")
        license_text = license_text.replace("\r\n", "\n").replace("\r", "\n")
        destination = work / "COPYING.TXT"
        destination.write_bytes(
            license_text.replace("\n", "\r\n").encode("ascii") + b"\x1a"
        )
        paths.append(destination)
        destination = work / "SOURCE.TXT"
        destination.write_bytes(
            b"Suite programs are GPL-2.0-or-later.\r\n"
            b"Corresponding source accompanies this disk in the host source\r\n"
            b"tree and in Conformance Suite Source.dmk.\r\n\x1a"
        )
        paths.append(destination)

        # BDOSTEST uses two alternate names containing the current executable.
        for name in ("BDSA.TMP", "BDSB.TMP"):
            destination = work / name
            destination.write_bytes((BUILD / "BDOSTEST.COM").read_bytes())
            paths.append(destination)

        paths.sort(key=lambda path: path.name.lower())
        expected_user_zero = {path.name.lower(): path.read_bytes() for path in paths}

        # DIRTEST.COM is required in user one for item 0567.  BTUSR.DAT must
        # exist independently in users zero and one for items 0559 and 0561.
        user_one_dir = work / "user1"
        user_one_dir.mkdir()
        user_one_dirtest = user_one_dir / "DIRTEST.COM"
        user_one_dirtest.write_bytes((BUILD / "DIRTEST.COM").read_bytes())
        user_one_btusr = user_one_dir / "BTUSR.DAT"
        user_one_btusr.write_bytes((PAYLOAD / "BTUSR.DAT").read_bytes())
        first_user_one = sum(extent_count(path) for path in paths)
        user_one_paths = [user_one_dirtest, user_one_btusr]
        all_paths = paths + user_one_paths
        raw = bytearray(install_files(all_paths))
        set_user(raw, first_user_one,
                 sum(extent_count(path) for path in user_one_paths), 1)
        set_read_only(raw, "BTRO.DAT")

        image = build(bytes(raw))
        verify(image, require_blank=False)
        if extract_raw(image) != bytes(raw):
            raise SystemExit("runtime DMK logical-sector round-trip failed")

        output.parent.mkdir(parents=True, exist_ok=True)
        if output.is_file():
            shutil.copy2(output, output.with_suffix(output.suffix + ".bak"))
        output.write_bytes(image)

    # User-zero recovery verifies every canonical payload and current utility.
    # The shared recovery helper intentionally accepts a user-zero-only image.
    # Hide user-one directory entries for this verification; their blocks stay
    # allocated and are checked separately below.
    user_zero_raw = bytearray(raw)
    for index in range(128):
        if user_zero_raw[index * 32] not in (0, 0xE5):
            user_zero_raw[index * 32] = 0xE5
    recovered = recover_files(bytes(user_zero_raw))
    for name, expected in expected_user_zero.items():
        data = recovered.get(name)
        if data is None or not data.startswith(expected):
            raise SystemExit(f"runtime payload verification failed: {name}")

    used_blocks: set[int] = set()
    directory_entries = 0
    users: dict[int, list[str]] = {}
    for index in range(128):
        entry = raw[index * 32:(index + 1) * 32]
        if entry[0] == 0xE5:
            continue
        directory_entries += 1
        stem = bytes(byte & 0x7F for byte in entry[1:9]).decode("ascii").rstrip()
        suffix = bytes(byte & 0x7F for byte in entry[9:12]).decode("ascii").rstrip()
        name = stem + (("." + suffix) if suffix else "")
        users.setdefault(entry[0], []).append(name)
        used_blocks.update(int.from_bytes(entry[pos:pos + 2], "little")
                           for pos in range(16, 32, 2)
                           if int.from_bytes(entry[pos:pos + 2], "little"))
    used_k = len(used_blocks) * 2
    free_k = (BLOCK_COUNT - FIRST_DATA_BLOCK) * 2 - used_k
    lines: list[str] = []
    for user, names in sorted(users.items()):
        lines.append(f"User {user}:")
        lines.extend(f"  {name}" for name in sorted(set(names)))
    lines.extend(("", f"{directory_entries} directory extents", f"{used_k}K used; {free_k}K free"))
    listing = "\n".join(lines) + "\n"
    (output.parent / "Conformance-Suite-listing.txt").write_text(listing, encoding="ascii")
    (output.parent / "Conformance-Suite-SHA256.txt").write_text(
        f"{sha256(output)}  {output.name}\n", encoding="ascii")
    print(f"created: {output}")
    print(f"sha256:  {sha256(output)}")
    print("\n" + listing)


if __name__ == "__main__":
    main()
