CP/M 2.2 Compatibility Suite - Native Source Build

M80 and L80 are the conventional CP/M assembler/linker tool set.  This
distribution uses ZSM4 with Digital Research LINK instead.  ZSM4 is a
redistributable GPL macro assembler that produces standard REL files accepted
by LINK, allowing the source disk to carry its complete native build toolchain.

The build tools require a Z80-compatible system.  The utilities they produce
use the Intel 8080 instruction subset and run on either 8080 or Z80 CP/M 2.2.

The MAC sources are relocatable LINK inputs.  They deliberately do not use
ORG 0100H: LINK supplies the standard CP/M transient load origin.  Adding an
ORG would apply the origin twice and insert an unwanted 256-byte gap.

Files:
  NAME.MZC   Crunched source for one utility
  CRUNCH.COM Standard CRUNCH 2.4 compressor
  UNCR.COM   Standard CRUNCH 2.4 uncruncher
  ZSM4.COM   Z80 macro assembler
  LINK.COM   Digital Research relocatable linker
  BUILD.SUB  Build-and-clean command file
  NOTICE.TXT Third-party copyright and redistribution summary
  COPYING.TXT GNU GPL version 2 license for the suite sources

Build one utility on a working copy of the disk:
  SUBMIT BUILD NAME

Example:
  SUBMIT BUILD CPUTEST

BUILD.SUB creates NAME.COM, then removes the temporary NAME.MAC and NAME.REL.
The original NAME.MZC remains on the disk.  Use UNCR NAME.MZC /Q when a plain
NAME.MAC source copy is wanted without building it.  CRUNCH is also included
so edited source can be recompressed with CRUNCH NAME.MAC /Q.

Read NOTICE.TXT before redistributing this disk.  See
THIRD-PARTY-NOTICES.md and COMPRESSION-TOOLS.md in the host distribution for
complete terms, versions, hashes, licenses, and provenance.
