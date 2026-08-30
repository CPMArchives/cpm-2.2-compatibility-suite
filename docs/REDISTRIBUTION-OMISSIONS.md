# Historical software omitted from the public repository

Some investigations used preserved commercial CP/M software as compatibility
fixtures. The observations, test procedures, transcripts, directory listings,
and hashes remain part of the published research record, but the proprietary
programs and disk images containing them are not distributed by this project.

The omitted local-only material comprises:

- Microsoft Macro-80 family files (`CREF80`, `LIB80`, and disk images that also
  contained `M80` or `L80`);
- Microsoft BASIC-80 and fixture images containing it;
- Microsoft FORTRAN-80, `FORLIB`, and fixture images containing them;
- MicroPro WordStar and fixture images containing it;
- Borland Turbo Pascal and fixture images containing it; and
- QTERM 4.3e, its supplied documentation and patch material, and fixture images
  containing it. The preserved QTERM executable identifies itself as
  copyright DPG 1991, all rights reserved.

These omissions do not invalidate the recorded compatibility observations.
They mean that reproducing the affected experiments requires the researcher to
supply a lawfully obtained copy of the corresponding historical software.

The files remain in the maintainers' private research archive. Exact-path
ignore rules prevent them from being added inadvertently to the public Git
repository.

Several investigations reused a common CP/M fixture disk. Consequently, an
image can contain an omitted program even when the image belongs to a test of
an unrelated operating-system behavior. Those embedded copies are omitted as
well. The affected image paths are recorded in `.gitignore`, while their
published hashes and textual observations continue to identify the original
research evidence.
