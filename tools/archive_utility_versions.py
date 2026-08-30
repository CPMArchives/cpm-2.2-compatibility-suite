#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Preserve current and historical utility revisions without disk-image inputs."""
from __future__ import annotations

import hashlib
import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SUITE = ROOT / "suite"
ARCHIVE = SUITE / "archive/dev-versions"
CURRENT_UTILITIES = (
    "FILETEST", "RANDTEST", "DIRTEST", "CONSTEST", "BDOSTEST", "ENTRYTST",
    "CCPTEST", "DISKTEST", "BIOSTEST", "ERRTEST", "ECOTEST", "CPUTEST", "SCRATCH",
)
ARCHIVE_UTILITIES = CURRENT_UTILITIES + ("FILETST2",)


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def source_version(path: Path) -> str:
    match = re.search(r"Version\s+[^\s]*-(dev\d+)", path.read_text(encoding="ascii", errors="replace"))
    if not match:
        raise SystemExit(f"cannot identify source version: {path}")
    return match.group(1)


def prior_origins() -> dict[tuple[str, str], str]:
    """Retain provenance recorded before the per-version images are removed."""
    origins: dict[tuple[str, str], str] = {}
    manifest = ARCHIVE / "MANIFEST.tsv"
    if not manifest.is_file():
        return origins
    for line in manifest.read_text(encoding="utf-8").splitlines()[1:]:
        fields = line.split("\t")
        if len(fields) >= 6:
            origins[(fields[0], fields[1])] = fields[5]
    return origins


def archived_records(origins: dict[tuple[str, str], str]) -> dict[tuple[str, str], dict[str, str]]:
    """Inventory the archive itself; it is now the historical source of truth."""
    records: dict[tuple[str, str], dict[str, str]] = {}
    for utility in ARCHIVE_UTILITIES:
        utility_dir = ARCHIVE / utility.lower()
        if not utility_dir.is_dir():
            continue
        for folder in sorted(utility_dir.glob("dev*")):
            binary = folder / f"{utility}.COM"
            if not binary.is_file():
                continue
            key = (utility, folder.name)
            record = {
                "binary": str(binary.relative_to(ARCHIVE)),
                "origin": origins.get(key, "preserved development archive"),
            }
            source = folder / f"{utility}.ASM"
            if source.is_file():
                record["source"] = str(source.relative_to(ARCHIVE))
            records[key] = record
    return records


def main() -> None:
    ARCHIVE.mkdir(parents=True, exist_ok=True)
    records = archived_records(prior_origins())

    for utility in CURRENT_UTILITIES:
        source = SUITE / "src" / f"{utility}.ASM"
        binary = SUITE / "build" / f"{utility}.COM"
        version = source_version(source)
        folder = ARCHIVE / utility.lower() / version
        folder.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, folder / source.name)
        shutil.copy2(binary, folder / binary.name)
        records[(utility, version)] = {
            "binary": str((folder / binary.name).relative_to(ARCHIVE)),
            "source": str((folder / source.name).relative_to(ARCHIVE)),
            "origin": "current source/build",
        }

    for (utility, version), record in sorted(records.items()):
        folder = ARCHIVE / utility.lower() / version
        if "source" not in record:
            (folder / "SOURCE-NOT-RECOVERED.txt").write_text(
                f"Matching {utility} {version} source was not found.\n"
                "The COM is preserved directly; MANIFEST.tsv records its historical recovery origin.\n",
                encoding="ascii",
            )

    lines = ["utility\tversion\tsource\tcom\tcom_sha256\torigin"]
    for (utility, version), record in sorted(records.items()):
        binary = ARCHIVE / record["binary"]
        lines.append(
            "\t".join((utility, version, record.get("source", "NOT RECOVERED"), record["binary"], sha(binary), record["origin"]))
        )
    (ARCHIVE / "MANIFEST.tsv").write_text("\n".join(lines) + "\n", encoding="utf-8")
    (ARCHIVE / "README.md").write_text(
        "# CP/M compatibility utility development archive\n\n"
        "This archive contains recoverable source and assembled COM revisions only; disk images are excluded. "
        "Historical binaries previously recovered from runtime images are now preserved directly here; rebuilding "
        "the manifest does not depend on those obsolete images. A source file is included only when its embedded "
        "version matches the archived revision. See MANIFEST.tsv for provenance and SHA-256 checksums.\n",
        encoding="utf-8",
    )
    print(f"archived {len(records)} recoverable revisions in {ARCHIVE}")


if __name__ == "__main__":
    main()
