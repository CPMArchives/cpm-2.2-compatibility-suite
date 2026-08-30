Investigation 013 probe artifacts
=================================

RAND013.ASM deterministically exercises BDOS functions 33-36, with Open,
Make, Close, Set DMA, and current-drive calls only for lifecycle verification.

Build:

  z80asm -fb -oRAND013.COM RAND013.ASM

RAND013.COM SHA-256:

  ffb2307721e310af88df7a1a33727d6d0088350c8e65be7e288ed3c209d5d431

Restore preserved pre-run images and run:

  ./reset-images.sh
  ./capture013.exp

observed-output.txt decodes the evidence; observed-raw.txt is the complete
transcript. Each line contains result, current drive, FCB bytes 0-35, and DMA
byte zero. The console diagnostic after the final A> is scripted shutdown.
