; Open/read R/F/JOPEN24.DAT and print return codes, RC and first 20 bytes.
        ORG 100H
        LD A,(0082H)
        LD (FNAME),A
        LD DE,DATA
        LD C,26
        CALL 5
        LD DE,FCB
        LD C,15
        CALL 5
        LD (ORC),A
        CP 0FFH
        JR Z,SHOW
        LD DE,FCB
        LD C,20
        CALL 5
        LD (RRC),A
SHOW:   LD DE,MSG
        LD C,9
        CALL 5
        LD A,(ORC)
        CALL HEX
        LD A,(RRC)
        CALL HEX
        LD A,(FCB+15)
        CALL HEX
        LD HL,DATA
        LD B,20
LOOP:   LD A,(HL)
        CALL HEX
        INC HL
        DJNZ LOOP
        LD E,13
        CALL OUT
        LD E,10
        CALL OUT
        RET
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
MSG:    DB 'CHECK24 OPEN/READ/RC/DATA=','$'
ORC:    DB 0
RRC:    DB 0FFH
FCB:    DB 0
FNAME:  DB 'ROPEN24 '
        DB 'DAT',0,0,0,0
        DS 16
        DB 0,0,0,0
DATA:   DS 128
        END
