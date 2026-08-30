; Activate ONE25.DAT, corrupt its identity before Close, and dump failure state.
        ORG 100H
        LD DE,FCB
        LD C,15
        CALL 5
        LD (ORC),A
        LD A,'X'
        LD (FCB+1),A
        LD DE,FCB
        LD C,16
        CALL 5
        LD (CRC),A
        LD DE,MSG
        LD C,9
        CALL 5
        LD A,(ORC)
        CALL HEX
        LD A,(CRC)
        CALL HEX
        LD DE,FCB
        LD BC,36
        CALL DUMP
        RET
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
MSG:    DB 'OPEN/CORRUPT/CLOSE RC/FCB=','$'
ORC:    DB 0
CRC:    DB 0
FCB:    DB 0,'ONE25   ','DAT',0,0,0,0
        DS 20
        END
