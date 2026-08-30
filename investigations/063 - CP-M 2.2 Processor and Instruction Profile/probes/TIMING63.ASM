; Investigation 063: semantic control under different configured CPU rates.
        org     0100h
bdos    equ     0005h
start:  ld      b,5
outer:  ld      hl,0ffffh
inner:  dec     hl
        ld      a,h
        or      l
        jr      nz,inner
        djnz    outer
        ld      de,done
        ld      c,9
        call    bdos
        jp      0000h
done:   db      'TIMING63 DONE$'
        end
