; Investigation 021 transient-entry observation probe.
; Prints the CCP-produced page-zero drive byte, two default FCB identity
; regions, and command tail. Build with z80asm -fb.
        ORG 0100H
        LD SP,STACKTOP
        LD DE,HDR
        LD C,9
        CALL 5
        LD A,(0004H)
        CALL HEX
        LD DE,F1
        LD C,9
        CALL 5
        LD HL,005CH
        LD B,16
        CALL DUMP
        LD DE,F2
        LD C,9
        CALL 5
        LD HL,006CH
        LD B,16
        CALL DUMP
        LD DE,TL
        LD C,9
        CALL 5
        LD A,(0080H)
        CALL HEX
        LD E,' '
        CALL PUTC
        LD A,(0080H)
        LD B,A
        LD HL,0081H
        CALL DUMP
        RET
DUMP:  LD A,B
        OR A
        JP Z,CRLF
DLOOP: LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEX
        LD E,' '
        CALL PUTC
        POP BC
        POP HL
        DJNZ DLOOP
        JP CRLF
HEX:   PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:   AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,OUT
        ADD A,7
OUT:   LD E,A
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
HDR:   DB 'PARSE21 DRIVE=$'
F1:    DB 13,10,'FCB1 00-0F: $'
F2:    DB 'FCB2 00-0F: $'
TL:    DB 'TAIL COUNT/BYTES: $'
        DS 96
STACKTOP:
        END
