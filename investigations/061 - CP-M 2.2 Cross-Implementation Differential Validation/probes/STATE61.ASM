; Investigation 061 non-mutating public-state differential probe.
        ORG 0100H

        LD (ENTSP),SP
        LD HL,0
        ADD HL,SP
        LD E,(HL)
        INC HL
        LD D,(HL)
        LD (RETWORD),DE

        LD C,12
        CALL 5
        LD (VERSION),HL

        LD C,25
        CALL 5
        LD (DRIVE),A

        LD E,0FFH
        LD C,32
        CALL 5
        LD (USER),A

        LD C,24
        CALL 5
        LD (LOGIN),HL

        LD C,29
        CALL 5
        LD (ROVEC),HL

        LD DE,06161H
        LD C,41
        CALL 5
        LD (F41),HL

        LD DE,HEADER
        CALL PRINT
        LD HL,(VERSION)
        CALL HEXHL
        CALL SPACE
        LD A,(DRIVE)
        CALL HEX
        CALL SPACE
        LD A,(USER)
        CALL HEX
        CALL SPACE
        LD HL,(LOGIN)
        CALL HEXHL
        CALL SPACE
        LD HL,(ROVEC)
        CALL HEXHL
        CALL SPACE
        LD HL,(F41)
        CALL HEXHL
        CALL SPACE
        LD HL,(ENTSP)
        CALL HEXHL
        CALL SPACE
        LD HL,(RETWORD)
        CALL HEXHL
        CALL CRLF
        RET

PRINT:  LD C,9
        JP 5
SPACE:  LD E,' '
        JP OUT
CRLF:   LD E,13
        CALL OUT
        LD E,10
        JP OUT
HEXHL:  PUSH HL
        LD A,H
        CALL HEX
        POP HL
        LD A,L
        JP HEX
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
        JR C,OUTA
        ADD A,7
OUTA:   LD E,A
OUT:    PUSH BC
        LD C,2
        CALL 5
        POP BC
        RET

HEADER: DB 'STATE61 VER DRIVE USER LOGIN RO F41 ENTRYSP RET $'
VERSION: DW 0
DRIVE:   DB 0
USER:    DB 0
LOGIN:   DW 0
ROVEC:   DW 0
F41:     DW 0
ENTSP:   DW 0
RETWORD: DW 0
        END
