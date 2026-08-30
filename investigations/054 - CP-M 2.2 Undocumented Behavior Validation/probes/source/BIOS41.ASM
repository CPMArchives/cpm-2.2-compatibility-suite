; Investigation 041 deterministic direct-BIOS vector/mutation probe.
; Derived from accepted Investigation 020 fixture.
; Build: z80asm -fb -oBIOS41.COM BIOS41.ASM
        ORG 0100H
START:  LD SP,STACKTOP
        LD DE,HDR
        LD C,9
        CALL 5
        LD HL,0
        LD B,8
        CALL DUMP

        ; Derive BIOS base from the documented WBOOT vector at 0000h.
        LD HL,(0001H)
        DEC HL
        DEC HL
        DEC HL
        LD (BBASE),HL
        LD DE,BLAB
        LD C,9
        CALL 5
        LD HL,(BBASE)
        CALL HEXWORD
        CALL CRLF

        ; Emit all 17 vector rows: index, opcode, target.
        LD DE,VLAB
        LD C,9
        CALL 5
        LD HL,(BBASE)
        LD B,17
        XOR A
VLOOP: PUSH AF
        PUSH BC
        PUSH HL
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
        POP HL
        LD A,(HL)
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
        INC HL
        LD E,(HL)
        INC HL
        LD D,(HL)
        PUSH HL
        EX DE,HL
        CALL HEXWORD
        CALL CRLF
        POP HL
        INC HL
        POP BC
        POP AF
        INC A
        DJNZ VLOOP

        CALL PATCH
        ; Direct calls through the public vector entries.
        LD HL,(BBASE)
        LD DE,6
        ADD HL,DE
        CALL ICALL
        LD (RESULTS+0),A          ; CONST empty = 00
        LD A,1
        LD (READY),A
        LD HL,(BBASE)
        LD DE,6
        ADD HL,DE
        CALL ICALL
        LD (RESULTS+1),A          ; CONST ready = FF
        LD HL,(BBASE)
        LD DE,9
        ADD HL,DE
        CALL ICALL
        LD (RESULTS+2),A          ; CONIN = 41
        LD C,09H
        LD HL,(BBASE)
        LD DE,12
        ADD HL,DE
        CALL ICALL
        LD C,10H
        LD HL,(BBASE)
        LD DE,15
        ADD HL,DE
        CALL ICALL
        LD C,1AH
        LD HL,(BBASE)
        LD DE,18
        ADD HL,DE
        CALL ICALL
        LD HL,(BBASE)
        LD DE,21
        ADD HL,DE
        CALL ICALL
        LD (RESULTS+3),A          ; READER = 52
        LD HL,(BBASE)
        LD DE,45
        ADD HL,DE
        CALL ICALL
        LD (RESULTS+4),A          ; LISTST first = 00
        LD HL,(BBASE)
        LD DE,45
        ADD HL,DE
        CALL ICALL
        LD (RESULTS+5),A          ; LISTST second = FF
        LD A,(OUTN)
        LD (RESULTS+6),A
        CALL RESTORE

        LD DE,RLAB
        LD C,9
        CALL 5
        LD HL,RESULTS
        LD B,7
        CALL DUMP
        LD DE,OLAB
        LD C,9
        CALL 5
        LD HL,OUTBUF
        LD A,(OUTN)
        LD B,A
        CALL DUMP
        RET

; Call address in HL without relying on a fixed BIOS address.
ICALL:  LD (ICDEST+1),HL
ICDEST: CALL 0000H
        RET

PATCH:  LD HL,(BBASE)
        LD DE,6
        ADD HL,DE
        LD (VPTR),HL
        LD DE,SAVED
        LD BC,18                 ; CONST..READER, six vectors
        LDIR
        LD HL,(BBASE)
        LD DE,45
        ADD HL,DE
        LD DE,SAVED+18
        LD BC,3                  ; LISTST
        LDIR
        LD HL,(VPTR)
        LD DE,HCONST
        CALL PUTJP
        LD DE,HCONIN
        CALL PUTJP
        LD DE,HCONOUT
        CALL PUTJP
        LD DE,HLIST
        CALL PUTJP
        LD DE,HPUNCH
        CALL PUTJP
        LD DE,HREADER
        CALL PUTJP
        LD HL,(BBASE)
        LD DE,45
        ADD HL,DE
        LD DE,HLISTST
        JP PUTJP
PUTJP: LD (HL),0C3H
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        RET
RESTORE:
        LD HL,SAVED
        LD DE,(VPTR)
        LD BC,18
        LDIR
        LD HL,SAVED+18
        LD DE,(BBASE)
        EX DE,HL
        LD BC,45
        ADD HL,BC
        EX DE,HL
        LD BC,3
        LDIR
        RET

HCONST: LD A,(READY)
        OR A
        RET Z
        LD A,0FFH
        RET
HCONIN:XOR A
        LD (READY),A
        LD A,41H
        RET
HCONOUT:
        LD A,43H                 ; C marker
        JP CAP
HLIST: LD A,4CH                 ; L marker
        JP CAP
HPUNCH:LD A,50H                 ; P marker
        JP CAP
HREADER:LD A,52H
        RET
HLISTST:
        LD A,(LSTN)
        INC A
        LD (LSTN),A
        CP 1
        LD A,0
        RET Z
        DEC A                    ; FF
        RET
CAP:    LD HL,OUTBUF
        PUSH AF
        LD A,(OUTN)
        LD E,A
        LD D,0
        ADD HL,DE
        POP AF
        LD (HL),A
        INC HL
        LD (HL),C
        LD A,(OUTN)
        ADD A,2
        LD (OUTN),A
        RET

DUMP:   LD A,B
        OR A
        JP Z,CRLF
DLOOP:  LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
        POP BC
        POP HL
        DJNZ DLOOP
        JP CRLF
HEXWORD:PUSH HL
        LD A,H
        CALL HEXBYTE
        POP HL
        LD A,L
HEXBYTE:PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:    AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,NIBO
        ADD A,7
NIBO:   LD E,A
PUTC:   PUSH BC
        PUSH DE
        PUSH HL
        LD C,2
        CALL 5
        POP HL
        POP DE
        POP BC
        RET
CRLF:   LD E,13
        CALL PUTC
        LD E,10
        JP PUTC

HDR:    DB 'BIOS41 PZ00-07: $'
BLAB:   DB 'BIOS BASE: $'
VLAB:   DB 'VECTORS index opcode target:',13,10,'$'
RLAB:   DB 'DIRECT CONST0 CONST1 CONIN READER LISTST0 LISTST1 OUTN: $'
OLAB:   DB 'OUTPUT PAIRS device-byte: $'
BBASE:  DW 0
VPTR:   DW 0
READY:  DB 0
LSTN:   DB 0
OUTN:   DB 0
RESULTS:DS 7
OUTBUF: DS 16
SAVED:  DS 21
        DS 128
STACKTOP:
        END
