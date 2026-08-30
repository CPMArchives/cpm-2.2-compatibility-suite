; Investigation 063: Intel 8080-compatible instruction and flag probe.
        org     0100h
bdos    equ     0005h

start:  lxi     sp,stack
        mvi     a,09h
        adi     09h
        daa
        cpi     18h
        jnz     fail
        mvi     a,0ffh
        adi     01h
        jnc     fail
        jnz     fail
        mvi     a,03h
        ani     03h
        jpo     fail
        lxi     h,1234h
        push    h
        pop     d
        mov     a,d
        cpi     12h
        jnz     fail
        mov     a,e
        cpi     34h
        jnz     fail
        call    subtest
        jnz     fail
        lxi     d,passmsg
        jmp     print
subtest:mvi     a,55h
        xri     55h
        ret
fail:   lxi     d,failmsg
print:  mvi     c,9
        call    bdos
        jmp     0000h
passmsg:db      'CPU8080 PASS$'
failmsg:db      'CPU8080 FAIL$'
        ds      32
stack:
        end
