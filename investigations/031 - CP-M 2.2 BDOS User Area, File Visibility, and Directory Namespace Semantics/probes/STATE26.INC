        ORG 100H
        LD SP,STACK
        LD HL,BAN
        CALL PUTS
        CALL SNAP
        LD E,1
        LD C,14
        CALL 5
        LD E,7
        LD C,32
        CALL 5
        LD DE,DMA
        LD C,26
        CALL 5
        LD HL,AFTER
        CALL PUTS
        CALL SNAP
        LD C,12
        CALL 5
        PUSH HL
        LD HL,VERS
        CALL PUTS
        POP HL
        CALL HEXW
        CALL CRLF
        LD DE,FCB
        LD C,17
        CALL 5
        PUSH AF
        LD HL,DMAL
        CALL PUTS
        POP AF
        CALL HEXB
        CALL SPACE
        LD A,(DMA)
        CALL HEXB
        CALL SPACE
        LD A,(0080H)
        CALL HEXB
        CALL CRLF
        LD C,0
        JP 5
SNAP:   LD C,25
        CALL 5
        CALL HEXB
        CALL SPACE
        LD E,0FFH
        LD C,32
        CALL 5
        CALL HEXB
        CALL SPACE
        LD C,24
        CALL 5
        CALL HEXW
        CALL SPACE
        LD C,29
        CALL 5
        CALL HEXW
        JP CRLF
BAN:    DB 'STATE26 cur user login ro',13,10,0
AFTER:  DB 'AFTER ',0
VERS:   DB 'VERSION ',0
DMAL:   DB 'SEARCH rc dma[0] 0080[0] ',0
FCB:    DB 0,'???????????',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
DMA:    DS 128,0A5H
        DS 128
STACK:
        INCLUDE "COMMON26.INC"
        END
