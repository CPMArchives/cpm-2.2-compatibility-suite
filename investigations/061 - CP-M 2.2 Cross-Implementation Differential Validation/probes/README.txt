Investigation 061 differential-validation artifacts
===================================================

Primary comparison environments
--------------------------------

1. Digital Research CP/M 2.2, Cromemco Z-1 target, from z80pack image
   cromemcosim/disks/library/cpm22.dsk.
2. Cromemco CDOS 2.58 from z80pack image
   cromemcosim/disks/library/cdos258_8.dsk.

CDOS 2.36 was screened as a third historical image. Its Function 12 result,
missing Function 32, and failure to run the DRI PIP workflow exclude it from
the primary CP/M 2.2 comparison; its transcript is retained as boundary
evidence.

The z80pack source revision was
91fd28eb04e675c2127df88ed3f40675e15282e2. The Cromemco simulator identified
itself as Z80SIM 1.39 / Cromemco Z-1 simulation 1.19. It was built in an
isolated /tmp copy with FRONTPANEL=NO and INFOPANEL=NO, using x86_64 objects
because the installed X11 library was x86_64. Source archives were untouched.

Probe roles
-----------

VECTOR41  - read public page-zero gateway bytes.
ZERO41    - read gateways, default FCB prefix, command-tail prefix and F12.
BASE61    - non-mutating F12/F25/F32/F24/F29 and entry-stack snapshot.
STATE61   - BASE61 plus isolated out-of-range selector 41.
EDGE43    - entry stack, private ceiling, self-modification and F12.
BIOS41    - derive/inspect BIOS vector and test character-vector conventions.
BDOS41    - older ABI probe retained for isolated IOBYTE-routing evidence.
PIP.COM   - identical DRI utility binary used for a controlled file copy.

VECTOR41, ZERO41, BDOS41 and BIOS41 are copied from I041. EDGE43 is copied
from I043. Their sources are preserved here and build.sh verifies byte identity.
STATE61 and BASE61 are I061 probes. The rejected-pilot and bind-failure
transcripts are retained and explicitly excluded from behavioral conclusions.

Reproduction
------------

1. Build z80pack/cromemcosim in an isolated full-tree copy. On this host:
     make -C cromemcosim/srcsim clean all FRONTPANEL=NO INFOPANEL=NO
   The installed X11 architecture required CC='clang -arch x86_64' and a
   matching clean rebuild of webfrontend/civetweb.
2. Copy each pristine IBM-3740 image to a case directory as
   disks/drivea.dsk; copy conf_2d as conf and the Cromemco ROM directory.
3. Insert the listed COM files and SRC61.TXT with cpmcp -f ibm-3740.
4. Run run061.exp against DRI and CDOS 2.58. Run run061-single.exp for BASE61.
5. Extract COPY61.TXT with cpmcp and compare length/content.

No run depends on manually typed input. The simulator's two local console
sockets (4010/4011) require permission in the managed execution environment.

