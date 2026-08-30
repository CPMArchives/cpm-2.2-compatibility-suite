        ORG 100H
        LD E,1
        LD C,14
        CALL 5
        LD E,7
        LD C,32
        CALL 5
        LD DE,0300H
        LD C,26
        CALL 5
        LD A,(0082H)
        CP 'F'
        JR Z,F0
        CP 'J'
        JP Z,0000H
        RET
F0:     LD C,0
        JP 5
        END

