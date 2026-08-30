#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Create deterministic GitHub assets for recovered development revisions."""
from __future__ import annotations

import argparse
import csv
import hashlib
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ARCHIVE = ROOT / "suite/archive/dev-versions"
FIXED_TIME = (1980, 1, 1, 0, 0, 0)


def version_key(path: Path) -> tuple[int, str]:
    suffix = path.name.removeprefix("dev")
    return (int(suffix), path.name) if suffix.isdigit() else (10**9, path.name)


def digest(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def add_bytes(archive: zipfile.ZipFile, name: str, data: bytes) -> None:
    info = zipfile.ZipInfo(name, FIXED_TIME)
    info.compress_type = zipfile.ZIP_DEFLATED
    info.external_attr = 0o100644 << 16
    archive.writestr(info, data)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("output", type=Path,
                        help="empty or new directory for release assets")
    args = parser.parse_args()
    output = args.output.expanduser().resolve()
    if output.exists() and any(output.iterdir()):
        raise SystemExit(f"output directory is not empty: {output}")
    output.mkdir(parents=True, exist_ok=True)

    utilities = sorted(path for path in ARCHIVE.iterdir()
                       if path.is_dir())
    asset_rows: list[tuple[str, int, str, str]] = []
    for utility_dir in utilities:
        versions = sorted(
            (path for path in utility_dir.iterdir()
             if path.is_dir() and path.name.startswith("dev")),
            key=version_key,
        )
        asset = output / f"{utility_dir.name.upper()}-development-versions.zip"
        with zipfile.ZipFile(asset, "w") as bundle:
            readme = (
                f"{utility_dir.name.upper()} recovered development versions\n"
                f"Versions preserved: {len(versions)}\n"
                "These files predate the public Git history and are supplied "
                "for research and reproducibility.\n"
            ).encode("ascii")
            add_bytes(bundle, f"{utility_dir.name}/README.txt", readme)
            for version in versions:
                for source in sorted(path for path in version.iterdir()
                                     if path.is_file()):
                    add_bytes(
                        bundle,
                        f"{utility_dir.name}/{version.name}/{source.name}",
                        source.read_bytes(),
                    )
        first = versions[0].name if versions else "NONE"
        last = versions[-1].name if versions else "NONE"
        asset_rows.append((asset.name, len(versions), first, last))

    with (output / "ASSET-MANIFEST.tsv").open("w", newline="", encoding="ascii") as stream:
        writer = csv.writer(stream, delimiter="\t", lineterminator="\n")
        writer.writerow(("asset", "versions", "first", "last"))
        writer.writerows(asset_rows)
    checksum_paths = sorted(output.glob("*.zip")) + [output / "ASSET-MANIFEST.tsv"]
    (output / "SHA256SUMS.txt").write_text(
        "".join(f"{digest(path)}  {path.name}\n" for path in checksum_paths),
        encoding="ascii",
    )
    print(f"created {len(asset_rows)} utility archives in {output}")
    print(f"preserved {sum(row[1] for row in asset_rows)} development versions")


if __name__ == "__main__":
    main()
