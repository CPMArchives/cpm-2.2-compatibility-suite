; Investigation 044 returning-failure and boundary probe.
        ORG 100H
        LD DE,TITLE
        CALL PRINT

        LD C,12
        CALL 5
        LD (VERHL),HL
        LD (VERA),A
        LD DE,LVER
        CALL PRINT
        LD A,(VERA)
        CALL HEX
        LD HL,(VERHL)
        LD A,H
        PUSH HL
        CALL HEX
        POP HL
        LD A,L
        CALL HEXCR

        LD DE,MISSING
        LD C,15
        CALL 5
        LD DE,LOPEN
        CALL SHOWA

        LD DE,EMPTY
        LD C,19
        CALL 5
        LD DE,EMPTY
        LD C,22
        CALL 5
        LD DE,EMPTY
        LD C,16
        CALL 5
        LD DE,EMPTY
        LD C,15
        CALL 5
        LD DE,EMPTY
        LD C,20
        CALL 5
        LD (EOF1),A
        LD DE,EMPTY
        LD C,20
        CALL 5
        LD (EOF2),A
        LD DE,LEOF
        CALL PRINT
        LD A,(EOF1)
        CALL HEX
        LD A,(EOF2)
        CALL HEXCR

        LD DE,ATTR
        LD C,15
        CALL 5
        LD A,4
        LD (ATTR+35),A
        LD DE,ATTR
        LD C,33
        CALL 5
        LD DE,LR2
        CALL SHOWA

        LD C,41
        CALL 5
        LD (SELHL),HL
        LD (SELA),A
        LD DE,LSEL
        CALL PRINT
        LD A,(SELA)
        CALL HEX
        LD HL,(SELHL)
        LD A,H
        PUSH HL
        CALL HEX
        POP HL
        LD A,L
        CALL HEXCR

        LD C,11
        CALL 5
        LD DE,LCON
        CALL SHOWA

        LD DE,EMPTY
        LD C,19
        CALL 5
        LD DE,DONE
        JP PRINT

SHOWHL: PUSH HL
        CALL PRINT
        POP HL
        LD A,H
        PUSH HL
        CALL HEX
        POP HL
        LD A,L
        JP HEXCR
SHOWA:  PUSH AF
        CALL PRINT
        POP AF
        JP HEXCR
HEXCR:  CALL HEX
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
PRINT:  LD C,9
        JP 5

TITLE:  DB 'FAIL44 RETURNING MATRIX',13,10,'$'
LVER:   DB 'NORMAL VERSION A/HL=','$'
LOPEN:  DB 'MISSING OPEN A=','$'
LEOF:   DB 'REPEATED EOF A=','$'
LR2:    DB 'RANDOM R2 OVERFLOW A=','$'
LSEL:   DB 'SELECTOR 41 A/HL=','$'
LCON:   DB 'CONSOLE STATUS NO INPUT A=','$'
DONE:   DB 'FAIL44 COMPLETE',13,10,'$'
EOF1:   DB 0
EOF2:   DB 0
VERA:   DB 0
VERHL:  DW 0
SELA:   DB 0
SELHL:  DW 0
MISSING: DB 0,'MISS44  ','DAT',0,0,0,0
        DS 20
EMPTY:  DB 0,'EMPTY44 ','DAT',0,0,0,0
        DS 20
ATTR:   DB 0,'ATTR    ','DAT',0,0,0,0
        DS 20
        END
