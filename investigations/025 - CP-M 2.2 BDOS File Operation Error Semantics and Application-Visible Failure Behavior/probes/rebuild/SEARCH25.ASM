; Search failure/exhaustion and DMA aftermath.
        ORG 100H
        LD DE,DMA
        LD C,26
        CALL 5
        CALL FILL
        LD DE,MISS
        LD C,17
        CALL 5
        LD DE,L_FIRST
        CALL SHOW
        LD C,18
        CALL 5
        LD DE,L_NEXT0
        CALL SHOW
        CALL FILL
        LD DE,ONE
        LD C,17
        CALL 5
        LD DE,L_MATCH
        CALL SHOW
        LD C,18
        CALL 5
        LD DE,L_EXHAUST
        CALL SHOW
        RET
FILL:   LD HL,DMA
        LD B,128
F0:     LD (HL),0A5H
        INC HL
        DJNZ F0
        RET
SHOW:   PUSH AF
        LD C,9
        CALL 5
        POP AF
        CALL HEX
        LD DE,DMA
        LD BC,32
        JP DUMP
DUMP:   LD A,(DE)
        PUSH BC
        PUSH DE
        CALL HEX
        POP DE
        POP BC
        INC DE
        DEC BC
        LD A,B
        OR C
        JR NZ,DUMP
        LD E,13
        CALL OUT
        LD E,10
        JP OUT
HEX:    PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:    AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,HOUT
        ADD A,7
HOUT:   LD E,A
OUT:    PUSH BC
        LD C,2
        CALL 5
        POP BC
        RET
L_FIRST:DB 'SEARCH-FIRST-NOMATCH RC/DMA=','$'
L_NEXT0:DB 'SEARCH-NEXT-AFTER-NOMATCH RC/DMA=','$'
L_MATCH:DB 'SEARCH-FIRST-ONE25 RC/DMA=','$'
L_EXHAUST:DB 'SEARCH-NEXT-EXHAUST RC/DMA=','$'
MISS:   DB 0,'ZZZZZZZZ','ZZZ',0,0,0,0
        DS 20
ONE:    DB 0,'ONE25   ','DAT',0,0,0,0
        DS 20
DMA:    DS 128
        END
