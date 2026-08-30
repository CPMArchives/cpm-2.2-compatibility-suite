Investigation 011 probe artifacts
=================================

WRITE011.ASM exercises BDOS functions 22, 21, and 16, with functions 15,
17, 20, 25, and 26 used only for lifecycle verification. It uses no keyboard
input, patches, or timing dependencies.

Build:

  z80asm -fb -oWRITE011.COM WRITE011.ASM

WRITE011.COM SHA-256:

  e6b82840d94f65b856da73fcd5c16a810b4d8e169d63f4ae32194974def60060

The four accepted pre-run disk images are preserved in images-before/. They
contain the probe on A, 63 empty directory entries on B, 64 on C, and an
allocation-full but directory-available D. Restore and run with:

  ./reset-images.sh
  ./capture011.exp

observed-output.txt is the decoded evidence record. observed-raw.txt is the
complete terminal capture. The console-read diagnostic after the final A>
prompt is caused by terminating cpmsim after the probe has returned and is not
a probe failure.

Each ordinary report line contains the operation result, current default drive,
FCB bytes 0-32, DMA bytes 0-3, and DMA byte 127. Search report lines contain the
result and the matching 32-byte directory entry.

reset-images.sh is the self-contained reproduction path using the preserved
pre-run images. observed011-before.txt retains the original image-construction
hashes and controlled-capacity listings.
