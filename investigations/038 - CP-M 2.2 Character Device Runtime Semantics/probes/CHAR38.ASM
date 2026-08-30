; Investigation 018 deterministic BDOS character-device/IOBYTE probe.
; z80asm -fb -oCHAR018.COM CHAR018.ASM
        ORG 0100H
START:  LD SP,STACKTOP
        LD A,(0003H)
        LD (IOORIG),A
        LD DE,ALTDMA
        LD C,26
        CALL 5
        LD A,0A5H
        LD (0080H),A
        LD A,05AH
        LD (ALTDMA),A
        CALL PATCH

        ; Put Z into DRI console pending state, then call Reader returning C1.
        LD A,'Z'
        LD (INCHAR),A
        LD A,1
        LD (READY),A
        LD C,11
        CALL 5
        LD (STATRC),A
        LD C,3
        CALL 5
        LD (RDRRC),A
        LD C,1
        CALL 5
        LD (PENDRC),A

        ; Raw PUNCH bytes.
        LD HL,OUTBYTES
        LD B,4
PLOOP: LD E,(HL)
        INC HL
        PUSH HL
        PUSH BC
        LD C,4
        CALL 5
        POP BC
        POP HL
        DJNZ PLOOP

        ; Raw LIST bytes, including Ctrl-P; then formatted X must not be copied.
        LD HL,OUTBYTES
        LD B,4
LLOOP: LD E,(HL)
        INC HL
        PUSH HL
        PUSH BC
        LD C,5
        CALL 5
        POP BC
        POP HL
        DJNZ LLOOP
        LD E,'X'
        LD C,2
        CALL 5

        ; Function 5/4 TABs must not alter formatted console column.
        LD E,10
        LD C,2
        CALL 5
        XOR A
        LD (CONLEN),A
        LD E,'A'
        LD C,2
        CALL 5
        LD E,9
        LD C,4
        CALL 5
        LD E,9
        LD C,5
        CALL 5
        LD E,9
        LD C,2
        CALL 5

        ; IOBYTE register/location round trip and BIOS-observed routing value.
        LD C,7
        CALL 5
        LD (GET0),A
        LD E,0A5H
        LD C,8
        CALL 5
        LD A,(0003H)
        LD (LOC1),A
        LD C,7
        CALL 5
        LD (GET1),A
        LD E,'Q'
        LD C,4
        CALL 5
        LD A,(IOORIG)
        LD E,A
        LD C,8
        CALL 5
        LD A,(0003H)
        LD (LOCR),A
        LD A,(0080H)
        LD (RESULTS+10),A
        LD A,(ALTDMA)
        LD (RESULTS+11),A
        LD A,(PLEN)
        LD (RESULTS+12),A
        LD A,(LLEN)
        LD (RESULTS+13),A
        LD A,(CONLEN)
        LD (RESULTS+14),A

        CALL RESTORE
        LD DE,HEADER
        LD C,9
        CALL 5
        LD HL,RESULTS
        LD B,15
RPRINT: LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
        POP BC
        POP HL
        DJNZ RPRINT
        CALL CRLF
        LD DE,PLAB
        LD C,9
        CALL 5
        LD HL,PBUF
        LD A,(PLEN)
        CALL PRINTBUF
        LD DE,LLAB
        LD C,9
        CALL 5
        LD HL,LBUF
        LD A,(LLEN)
        CALL PRINTBUF
        LD DE,CLAB
        LD C,9
        CALL 5
        LD HL,CBUF
        LD A,(CONLEN)
        CALL PRINTBUF
        RET

PRINTBUF:
        LD B,A
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
PBLOOP: LD A,B
        OR A
        JP Z,CRLF
        LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
        POP BC
        POP HL
        DJNZ PBLOOP
        JP CRLF

PATCH: LD HL,(0001H)
        DEC HL
        DEC HL
        DEC HL
        LD DE,6
        ADD HL,DE
        LD (VBASE),HL
        LD DE,SAVED
        LD BC,18
        LDIR
        LD HL,(VBASE)
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
        LD DE,(VBASE)
        LD BC,18
        LDIR
        RET

HCONST: LD A,(READY)
        OR A
        RET Z
        LD A,0FFH
        RET
HCONIN: XOR A
        LD (READY),A
        LD A,(INCHAR)
        RET
HREADER:
        LD HL,RDRCOUNT
        INC (HL)
        LD A,0C1H
        RET
HCONOUT:
        LD HL,CBUF
        LD A,(CONLEN)
        CALL CAPTURE
        LD (CONLEN),A
        RET
HPUNCH: LD HL,PBUF
        LD A,(PLEN)
        CALL CAPTURE
        LD (PLEN),A
        LD A,(0003H)
        LD (PUNCHIO),A
        RET
HLIST: LD HL,LBUF
        LD A,(LLEN)
        CALL CAPTURE
        LD (LLEN),A
        RET
; A=count, HL=buffer, C=byte; returns incremented count.
CAPTURE:
        CP 32
        JR NC,CAPCNT
        PUSH AF
        LD E,A
        LD D,0
        ADD HL,DE
        LD (HL),C
        POP AF
CAPCNT: INC A
        RET

PUTC:  PUSH BC
        PUSH DE
        PUSH HL
        LD C,2
        CALL 5
        POP HL
        POP DE
        POP BC
        RET
CRLF:  LD E,13
        CALL PUTC
        LD E,10
        JP PUTC
HEXBYTE:
        PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:   AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,NOUT
        ADD A,7
NOUT:  LD E,A
        JP PUTC

HEADER: DB 13,10,'CHAR018 stat rdr pend rdrcnt io0 get0 loc1 get1 locrest punchio dma80 dmaalt plen llen conlen',13,10,'$'
PLAB: DB 'PUNCH len/bytes $'
LLAB: DB 'LIST len/bytes $'
CLAB: DB 'CON len/bytes $'
OUTBYTES: DB 41H,09H,10H,80H
RESULTS:
STATRC: DB 0
RDRRC: DB 0
PENDRC: DB 0
RDRCOUNT: DB 0
IOORIG: DB 0
GET0: DB 0
LOC1: DB 0
GET1: DB 0
LOCR: DB 0
; filled just before report through fixed aliases below
        DB 0,0,0,0,0,0
PUNCHIO: EQU RESULTS+9
READY: DB 0
INCHAR: DB 0
VBASE: DW 0
SAVED: DS 18
PLEN: DB 0
LLEN: DB 0
CONLEN: DB 0
PBUF: DS 32
LBUF: DS 32
CBUF: DS 32
ALTDMA: DS 128,05AH
        DS 128
STACKTOP:
        END START
