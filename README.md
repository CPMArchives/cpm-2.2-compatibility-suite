# CP/M Compatibility

Research, specifications, fixtures, and the CP/M 2.2 Compatibility Suite.

- `investigations/` contains the compatibility research record.
- `docs/` contains publication and release documentation.
- `suite/` contains eleven logical conformance utilities in twelve test
  executables, plus the SCRATCH support program, controlled fixtures,
  build tools, validation material, and maintained disk images.
- `external/` contains pinned convenience binaries that are not suite-owned.

SYSINFO is maintained under `sysinfo/` in the
[CP/M Tools](https://github.com/CPMArchives/cpm-tools) repository. Its pinned
binary remains on the runtime disk for operator convenience.

Start with `docs/USER-MANUAL.md` to install, operate, and interpret the eleven
compatibility tools. See `suite/README.md` and `suite/RELEASE-WORKFLOW.md` for
build and release instructions.

See `THIRD-PARTY-NOTICES.md` for the licenses, reproduction terms,
provenance, and hashes of the bundled build and compression tools.

## License

Unless otherwise noted, the original source code and documentation in this
repository are licensed under the GNU General Public License, version 2 or,
at your option, any later version (`GPL-2.0-or-later`). See `LICENSE`.

Bundled third-party programs are not relicensed. Their separate terms are
recorded in `THIRD-PARTY-NOTICES.md`.
