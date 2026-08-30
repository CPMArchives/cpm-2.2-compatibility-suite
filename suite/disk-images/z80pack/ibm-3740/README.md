# z80pack test support

`drivea.dsk` is the single preserved CP/M 2.2 IBM 3740 boot image required by
the existing cpmsim/Expect tests. Run `tools/prepare_z80pack_test_disks.py`
with a temporary directory to create disposable A/B/C/D test media; generated
test disks are not repository artifacts. The small IBM 3740 B: disk carries
the utilities and compact fixtures only; use `SCRATCH /DISK` on separate media
for the data-full `BTBND128.DAT`/`BTBIG130.DAT` profile.
