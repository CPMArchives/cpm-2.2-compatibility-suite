Investigation 062 conformance-pilot artifacts
=============================================

This pilot executes nine selected I059 test identifiers on two implementations:
DRI CP/M 2.2 and Cromemco CDOS 2.58, both on the same 64K Cromemco Z-1
z80pack environment. It is a development pilot, not certification.

Primary evidence:

- conformance-pilot-records.tsv: I059-schema result records.
- transcripts/dri-pilot.txt and transcripts/cdos258-pilot.txt: raw sessions.
- images-before and images-after: restored input and resulting disk images.
- extracted: COPY62 outputs produced by the identical DRI PIP binary.
- pilot-summary.txt: outcome counts.
- traceability-audit.txt: ledger-to-test mapping audit.
- reference: immutable copies of the I059 inventory, schema, rules and mapping.

Probe provenance:

- VECTOR41, ZERO41, BIOS41: Investigation 041.
- EDGE43, ZRET43, FN043: Investigation 043.
- BASE61 and STATE61: Investigation 061.
- PIP.COM: DRI utility extracted from the DRI Cromemco CP/M image.

build.sh rebuilds every source-backed probe byte-identically. run062.exp
supplies deterministic commands and requires no manually typed input.

The simulator was built in an isolated /tmp copy during I061 from z80pack git
revision 91fd28eb04e675c2127df88ed3f40675e15282e2. It reports Z80SIM 1.39 and
Cromemco Z-1 simulation 1.19. The managed environment requires permission for
the simulator's localhost console sockets 4010/4011.

BLOCKED record meaning
----------------------

BLOCKED is used exactly as the I059 schema permits. It means the selected
compound test could not be completed from the specified pilot fixture or
criterion. Passing a sampled subcase is recorded in actual_observation but is
not promoted to PASS.

