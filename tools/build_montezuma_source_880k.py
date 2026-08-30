#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Build the maintained 880K CP/M-native conformance-suite source disk."""
from __future__ import annotations

import hashlib
import argparse
import csv
import tempfile
from pathlib import Path

from build_blank_montezuma_880k import build, extract_raw, verify
from build_montezuma_utils_880k import BLOCK_COUNT, BLOCK_SIZE, FIRST_DATA_BLOCK, install_files, recover_files


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "suite/disk-images/trs80-montezuma/Conformance Suite Source.dmk"
TOOLS = ROOT / "suite/build-tools"
CRUNCHED = ROOT / "suite/crunched-source"
UTILITY_NAMES = (
    "FILETEST", "RANDTEST", "DIRTEST", "CONSTEST", "BDOSTEST", "ENTRYTST",
    "CCPTEST", "DISKTEST", "BIOSTEST", "ERRTEST", "ECOTEST", "CPUTEST", "SCRATCH",
)


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def source_path(name: str) -> Path:
    """Return the canonical working source."""
    in_suite = ROOT / "suite/src" / f"{name}.ASM"
    if in_suite.is_file():
        return in_suite
    raise SystemExit(f"missing current source: {in_suite}")


def zsm4_source(path: Path) -> bytes:
    """Convert the canonical ASCII source to a CP/M ZSM4 .MAC file."""
    text = path.read_text(encoding="ascii")
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    return text.replace("\n", "\r\n").encode("ascii") + b"\x1a"


def verified_crunched_sources() -> dict[str, bytes]:
    """Load only crunched files tied to the current generated MAC sources."""
    manifest = CRUNCHED / "MANIFEST.tsv"
    if not manifest.is_file():
        raise SystemExit(
            "missing crunched-source manifest; run "
            "tools/build_crunched_sources.py"
        )
    with manifest.open(newline="", encoding="ascii") as stream:
        rows = {row["utility"]: row for row in csv.DictReader(stream, delimiter="\t")}
    result: dict[str, bytes] = {}
    for name in UTILITY_NAMES:
        row = rows.get(name)
        if row is None:
            raise SystemExit(f"missing crunched-source manifest row: {name}")
        mac = zsm4_source(source_path(name))
        if len(mac) != int(row["mac_size"]) or sha256(mac) != row["mac_sha256"]:
            raise SystemExit(
                f"stale crunched source for {name}; run "
                "tools/build_crunched_sources.py"
            )
        path = CRUNCHED / f"{name}.MZC"
        if not path.is_file():
            raise SystemExit(f"missing crunched source: {path}")
        data = path.read_bytes()
        if len(data) != int(row["mzc_size"]) or sha256(data) != row["mzc_sha256"]:
            raise SystemExit(f"crunched-source integrity failure: {path}")
        result[name] = data
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", nargs="?", type=Path, default=OUT,
                        help="destination DMK (default: maintained local source image)")
    args = parser.parse_args()
    output = args.output.expanduser().resolve()
    crunch = TOOLS / "CRUNCH.COM"
    uncr = TOOLS / "UNCR.COM"
    zsm4 = TOOLS / "ZSM4.COM"
    link = TOOLS / "LINK.COM"
    readme = TOOLS / "README.TXT"
    notice = TOOLS / "NOTICE.TXT"
    license_file = ROOT / "LICENSE"
    for tool in (crunch, uncr, zsm4, link, readme, notice, license_file):
        if not tool.is_file():
            raise SystemExit(f"missing source-disk tool: {tool}")
    crunched = verified_crunched_sources()

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="source-880k-") as temporary:
        payload = Path(temporary)
        for name, data in crunched.items():
            (payload / f"{name}.MZC").write_bytes(data)
        (payload / "CRUNCH.COM").write_bytes(crunch.read_bytes())
        (payload / "UNCR.COM").write_bytes(uncr.read_bytes())
        (payload / "ZSM4.COM").write_bytes(zsm4.read_bytes())
        (payload / "LINK.COM").write_bytes(link.read_bytes())
        notice_text = notice.read_text(encoding="ascii")
        notice_text = notice_text.replace("\r\n", "\n").replace("\r", "\n")
        (payload / "NOTICE.TXT").write_bytes(
            notice_text.replace("\n", "\r\n").encode("ascii") + b"\x1a"
        )
        license_text = license_file.read_text(encoding="ascii")
        license_text = license_text.replace("\r\n", "\n").replace("\r", "\n")
        (payload / "COPYING.TXT").write_bytes(
            license_text.replace("\n", "\r\n").encode("ascii") + b"\x1a"
        )
        # BUILD.SUB accepts a utility stem: SUBMIT BUILD FILETEST.
        (payload / "BUILD.SUB").write_bytes(
            b"UNCR $1.MZC /Q\r\n"
            b"ZSM4 =$1\r\n"
            b"LINK $1[A]\r\n"
            b"ERA $1.MAC\r\n"
            b"ERA $1.REL\r\n\x1a"
        )
        readme_text = readme.read_text(encoding="ascii")
        readme_text = readme_text.replace("\r\n", "\n").replace("\r", "\n")
        (payload / "README.TXT").write_bytes(
            readme_text.replace("\n", "\r\n").encode("ascii") + b"\x1a"
        )

        paths = sorted(path for path in payload.iterdir() if path.is_file())
        raw = install_files(paths)
        recovered = recover_files(raw)
        for path in paths:
            restored = recovered.get(path.name.lower())
            if restored is None or not restored.startswith(path.read_bytes()):
                raise SystemExit(f"source-disk verification failed: {path.name}")

        image = build(raw)
        verify(image, require_blank=False)
        if extract_raw(image) != raw:
            raise SystemExit("source DMK logical-sector round-trip failed")
        output.write_bytes(image)

    used_k = sum(((len(data) + BLOCK_SIZE - 1) // BLOCK_SIZE) * 2
                 for data in recovered.values())
    free_k = (BLOCK_COUNT - FIRST_DATA_BLOCK) * 2 - used_k
    listing = ["0:"]
    for name, data in sorted(recovered.items()):
        listing.append(f"{name:12s} {len(data):7d}")
    listing.extend(("", f"{len(recovered)} files, occupying {used_k}K of 876K total capacity",
                    f"{free_k}K remain"))
    listing_text = "\n".join(listing) + "\n"
    (output.parent / "Conformance-Suite-Source-listing.txt").write_text(listing_text, encoding="ascii")
    (output.parent / "Conformance-Suite-Source-SHA256.txt").write_text(
        f"{sha256(output.read_bytes())}  {output.name}\n", encoding="ascii"
    )
    print(f"created: {output}")
    print(f"sha256:  {sha256(output.read_bytes())}")
    print("\nCurrent directory:\n" + listing_text)


if __name__ == "__main__":
    main()
