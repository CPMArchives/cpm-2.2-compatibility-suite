        org     0100h
        ld      de,banner
        ld      c,9
        call    5
        ld      c,12
        call    5
        ld      a,l
        cp      22h
        jr      nz,bad
        ld      de,okmsg
        jr      print
bad:    ld      de,badmsg
print:  ld      c,9
        call    5
        ret
banner: db      'BASE051: public BDOS control',13,10,'$'
okmsg:  db      'VERSION=22 PASS',13,10,'$'
badmsg: db      'VERSION MISMATCH',13,10,'$'
