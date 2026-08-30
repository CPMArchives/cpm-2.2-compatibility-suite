# CP/M 2.2 Compatibility Suite architecture decisions

## ADR-001 — Generic suite processor baseline

Status: Accepted  
Decision date: 2026-08-20

The generic executable conformance suite shall use only Intel 8080-compatible
instructions. This includes the shared runtime and generic FILE, directory,
disk, BDOS, console, entry, CCP and BIOS-facing modules.

The purpose is to keep the suite runnable on original and emulated 8080 CP/M
systems, avoid imposing Z80 as an accidental prerequisite for generic CP/M 2.2
testing, and permit differential execution of the same binary in 8080 and Z80
environments.

Processor-profile tests that inherently exercise later instruction sets are
the exception. They must be isolated in explicitly named companion
executables, declare their minimum processor, and be selected only when their
profile applies. The exception does not permit Z80-only convenience code in a
generic module.

Every executable and report records `PROCESSOR_REQUIRED`. Generic modules use
`8080`. Release validation audits emitted opcodes and runs generic binaries in
both 8080 and Z80 environments. This implementation constraint does not alter
the frozen RC1 oracles or constrain the candidate system's internal design.

## ADR-002 — Explicit capability manifest

Status: Accepted  
Decision date: 2026-08-20

Development runs on incomplete implementations may use an explicit capability
manifest. It names the BDOS functions, BIOS routines, drives and report sinks
that the implementor authorizes the suite to call. A selected case requiring
an undeclared facility is reported `BLOCKED` without invoking it.

Capability declarations are safety controls, not conformance evidence. They
cannot produce a pass, alter an oracle, or make a development subset eligible
for certification. Their purpose is to avoid entering unfinished code that may
hang, restart or corrupt the environment.

## ADR-003 — Portable, per-utility fixture media

Status: Accepted  
Decision date: 2026-08-20

The project maintains reproducibly generated, nonbootable IBM 3740 test media
for z80pack. The candidate implementation supplies and boots its own system
disk on drive A. A per-utility disk on drive B carries one independently
runnable executable, its configuration and its primary fixtures; a drive C
disk carries fixtures that must be on a distinct drive. Thus no target CP/M
must be copied into, or supplied by, the portable test distribution.

Every suite executable is independently deployable. It must not require other
suite executables to be present unless an exceptional dependency is declared
in its manifest. The maintained distribution provides both per-utility images
for focused work and, when capacity permits, a complete-suite convenience
image. A user may mount only the utility image needed for a run. A complete
suite image changes packaging only; it does not introduce run-time coupling
between utilities.

Bootable z80pack images may be generated as explicitly labeled reference-run
conveniences. They are validation artifacts, not the portable distribution,
and never define the candidate CP/M. Environment adapters assemble a run from
the candidate's A image plus unchanged suite B/C images and record the hashes
of all three.

Loose utilities, configuration, fixture payloads, directory listings and
content hashes are distributed beside the images. On systems with only two
drives, tests needing two independent fixture drives are run with a documented
media swap/adapter, or are reported `BLOCKED`; the suite must not silently
rewrite the candidate system disk.

The generator starts from pinned pristine z80pack images and verifies required
files, negative fixtures and attributes. The IBM 3740 representation is a
distribution convenience, not a conformance requirement; other systems may
install the same logical fixture by another controlled method.

## ADR-004 — Maintained physical-media families

Status: Accepted  
Decision date: 2026-08-20

The project maintains two reproducibly generated physical-media families from
the same logical utility and fixture manifests:

- IBM 3740 images for z80pack;
- native DMK images for TRS-80 Model 4/4P Montezuma Micro CP/M.

The default Montezuma per-utility and secondary-fixture media use its standard
40-track, single-sided, double-density 200K DATA format. Its standard 400K
double-sided DATA format is used when a declared payload does not fit, and may
also be offered as a complete-suite convenience. Physical geometry is adapter
metadata and does not change case identity or expected behavior. Capacity and
disk-parameter cases record the selected geometry as evidence.

Both families preserve the candidate-supplied A system disk and place portable
suite media on B and C. Their manifests must name the same logical payloads;
format-specific generators verify directory contents, attributes, negative
fixtures, image structure and hashes.

## ADR-005 — FILE/DIR/DISK executable ownership

Status: Accepted  
Decision date: 2026-08-20

The preliminary assignment of 205 cases to FILETEST is retired. The frozen
627-case catalog assigns file-related propositions according to their public
subject: FILETEST owns FCB lifecycle and record I/O; DIRTEST owns search,
directory enumeration, user namespaces, Delete, Rename and directory
attributes; DISKTEST owns reset/vector/protection and allocation or capacity
contracts. Fatal or injected BDOS file errors belong to ERRTEST, and direct
BIOS operations belong to BIOSTEST.

The resulting authoritative counts are FILETEST 142, DIRTEST 72 and DISKTEST
20. Seven propositions formerly grouped with ordinary BDOS file behavior are
assigned to ERRTEST. Generator rules use frozen ledger identities and complete
parent families rather than mutable requirement-text keywords. Every release
must validate unique ownership of all 627 ledger entries and these module
counts. Any later ownership change requires another architecture decision.

## ADR-006 — DPB-aware multi-entry directory fixtures

Status: Accepted  
Decision date: 2026-08-21

Directory enumeration cases must distinguish a 16K logical extent from a
physical CP/M directory entry. A directory entry can describe `EXM+1` logical
extents; therefore a fixed 129-record file does not portably force two
directory entries. In particular, it does so on IBM 3740 media with `EXM=0`,
but not on Montezuma Micro 200K DATA media with `EXM=1`.

Cases 0542 and 0543 read the selected drive's DPB through BDOS Function 31 and
create `(EXM+1)*128+1` records. This is one record beyond the capacity
represented by one directory entry and therefore forces a second entry
without assuming a particular geometry. Their oracle counts matching physical
directory entries returned by Search First/Next. The requirement is generic
CP/M 2.2 behavior; no TRS-80 or Montezuma-specific exception is introduced.

Any future case whose setup depends on extent packing, allocation-block size,
directory capacity, or another DPB field must derive its fixture boundary from
the target DPB or explicitly constrain the supported disk formats.
