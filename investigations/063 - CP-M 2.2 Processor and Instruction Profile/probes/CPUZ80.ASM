; Investigation 063: documented Z80-extension probe.
        org     0100h
bdos    equ     0005h

start:  ld      sp,stack
        ld      ix,word1
        ld      iy,word2
        ld      a,(ix+1)
        cp      22h
        jr      nz,fail
        ld      a,(iy+0)
        cp      33h
        jr      nz,fail
        ld      bc,0102h
        exx
        ld      bc,0304h
        exx
        ld      a,b
        cp      01h
        jr      nz,fail
        ld      b,2
loop:   djnz    loop
        ld      a,01h
        bit     0,a
        jr      z,fail
        ld      hl,src
        ld      de,dst
        ld      bc,3
        ldir
        ld      a,(dst+2)
        cp      0c3h
        jr      nz,fail
        ld      de,passmsg
        jr      print
fail:   ld      de,failmsg
print:  ld      c,9
        call    bdos
        jp      0000h
word1:  db      11h,22h
word2:  db      33h,44h
src:    db      0a1h,0b2h,0c3h
dst:    ds      3
passmsg:db      'CPUZ80 PASS$'
failmsg:db      'CPUZ80 FAIL$'
        ds      32
stack:
        end
