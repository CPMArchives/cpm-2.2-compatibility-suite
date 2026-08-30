# GitHub release publication

## Current release

The initial public release is tagged `v0.1.0-alpha.1` and marked as a
pre-release while full provider-assisted and manual validation remains open.
The tag points to the repository's initial public commit. Attach the maintained
disk images, their checksum files, and any desired source archive to that
release.

## Preserved development versions

GitHub releases normally correspond to Git tags. These development revisions
were recovered as files before this Git repository acquired a commit history,
so inventing one commit per revision would imply a chronology the project does
not possess. Publish them as a separate historical pre-release instead.

Generate deterministic per-utility assets outside the repository:

```text
python3 tools/prepare_historical_release_assets.py /tmp/cpm-history
```

After GitHub authentication and the initial commit, publish them with:

```text
gh release create historical-development-archive \
  --prerelease \
  --title "Historical development versions" \
  --notes "Recovered pre-Git development builds. These are preserved for research and reproducibility; use the current release for normal operation." \
  /tmp/cpm-history/*
```

The release contains one ZIP archive per utility. Each ZIP retains every
available `devN` directory beginning with the earliest recovered version;
where source was not recovered, the archive says so and retains the COM file.
`ASSET-MANIFEST.tsv` and `SHA256SUMS.txt` make the upload auditable.

GitHub will display this separately from the current release. It is accurately
described as historical rather than being presented as fabricated Git history.
