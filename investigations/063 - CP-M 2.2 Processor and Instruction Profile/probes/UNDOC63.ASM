; Investigation 063: isolated undocumented-Z80 SLL opcode probe.
        org     0100h
bdos    equ     0005h
start:  ld      sp,stack
        ld      b,03h
        db      0cbh,030h       ; undocumented SLL B: expected 07h on tested Z80
        ld      a,b
        cp      07h
        jr      nz,fail
        ld      de,passmsg
        jr      print
fail:   ld      de,failmsg
print:  ld      c,9
        call    bdos
        jp      0000h
passmsg:db      'UNDOC63 OBSERVED$'
failmsg:db      'UNDOC63 DIFFERENT$'
        ds      32
stack:
        end
