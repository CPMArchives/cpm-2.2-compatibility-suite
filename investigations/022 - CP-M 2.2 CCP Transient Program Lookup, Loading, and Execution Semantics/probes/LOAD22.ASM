; Three-record patterned loader probe. Record 0 executes and inspects records
; 1 and 2 at their expected addresses.
        ORG 0100H
        LD DE,MSG
        LD C,9
        CALL 5
        LD A,(0100H)
        CALL HEX
        LD E,' '
        CALL PUTC
        LD A,(0180H)
        CALL HEX
        LD E,' '
        CALL PUTC
        LD A,(0200H)
        CALL HEX
        CALL CRLF
        RET
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
MSG:   DB 'LOAD22 bytes at 0100/0180/0200: $'
        DS 0180H-$,0A1H
        DB 0B2H
        DS 0200H-$,0B2H
        DB 0C3H
        DS 0280H-$,0C3H
        END
