; Investigation 017: disk state, allocation vector, and DPB probe.
; Build: z80asm -fb -oSTATE017.COM STATE017.ASM
        ORG 0100H
START:  LD SP,STACKTOP
        LD DE,BANNER
        LD C,9
        CALL 5
        LD C,13
        CALL 5
        LD HL,L_RESET
        CALL SNAP

        LD E,1
        LD C,14
        CALL 5
        LD HL,L_SELB
        CALL SNAP
        LD E,0
        LD C,14
        CALL 5
        LD HL,L_SELA
        CALL SNAP

        ; Reset B while A is current. Then reset unlogged B+C.
        LD DE,0002H
        LD C,37
        CALL 5
        LD HL,L_RSTB
        CALL SNAP
        LD DE,0006H
        LD C,37
        CALL 5
        LD HL,L_RSTBC0
        CALL SNAP

        ; Make B logged and read-only, return to A, then reset B.
        LD E,1
        LD C,14
        CALL 5
        LD C,28
        CALL 5
        LD HL,L_BROSEL
        CALL SNAP
        LD E,0
        LD C,14
        CALL 5
        LD HL,L_BRO
        CALL SNAP
        LD DE,0002H
        LD C,37
        CALL 5
        LD HL,L_RSTBRO
        CALL SNAP

        ; Reset both logged A+B simultaneously. Current remains A.
        LD E,1
        LD C,14
        CALL 5
        LD E,0
        LD C,14
        CALL 5
        LD DE,0003H
        LD C,37
        CALL 5
        LD HL,L_RSTMUL
        CALL SNAP
        LD C,13
        CALL 5
        LD HL,L_SYSRST
        CALL SNAP

        ; Controlled allocation lifecycle on A.
        LD HL,L_PREMAKE
        CALL SNAP
        CALL MODTEST
        LD DE,FCB
        LD C,22
        CALL 5
        LD (RCMAKE),A
        LD HL,L_MAKE
        CALL SNAP
        LD DE,DMA
        LD C,26
        CALL 5
        LD DE,FCB
        LD C,21
        CALL 5
        LD (RCWRITE),A
        LD HL,L_WRITE
        CALL SNAP
        LD DE,FCB
        LD C,16
        CALL 5
        LD (RCCLOSE),A
        LD HL,L_CLOSE
        CALL SNAP
        LD DE,FCBDEL
        LD C,19
        CALL 5
        LD (RCDELETE),A
        LD HL,L_DELETE
        CALL SNAP

        LD HL,RCLABEL
        CALL PUTS
        LD A,(RCMAKE)
        CALL HEXBYTE
        CALL SPACE
        LD A,(RCWRITE)
        CALL HEXBYTE
        CALL SPACE
        LD A,(RCCLOSE)
        CALL HEXBYTE
        CALL SPACE
        LD A,(RCDELETE)
        CALL HEXBYTE
        CALL CRLF
        RET

; Temporarily change one byte through each returned pointer, re-query, print,
; and restore before any disk operation. This diagnoses live storage only.
MODTEST:
        LD HL,L_MOD
        CALL PUTS
        LD C,27
        CALL 5
        LD (ALVP),HL
        LD A,(HL)
        LD (ALVOLD),A
        XOR 01H
        LD (HL),A
        LD C,27
        CALL 5
        LD A,H
        CALL HEXBYTE
        LD A,L
        CALL HEXBYTE
        CALL SPACE
        LD A,(HL)
        CALL HEXBYTE
        LD HL,(ALVP)
        LD A,(ALVOLD)
        LD (HL),A
        CALL SPACE
        LD C,31
        CALL 5
        LD (DPBP),HL
        LD A,(HL)
        LD (DPBOLD),A
        XOR 01H
        LD (HL),A
        LD C,31
        CALL 5
        LD A,H
        CALL HEXBYTE
        LD A,L
        CALL HEXBYTE
        CALL SPACE
        LD A,(HL)
        CALL HEXBYTE
        LD HL,(DPBP)
        LD A,(DPBOLD)
        LD (HL),A
        JP CRLF

; Print label; current; login; ro; alloc ptr + 31 bytes; DPB ptr + 15 bytes.
SNAP:   CALL PUTS
        LD C,25
        CALL 5
        CALL HEXBYTE
        CALL SPACE
        LD C,24
        CALL 5
        PUSH HL
        LD A,H
        CALL HEXBYTE
        LD A,L
        CALL HEXBYTE
        CALL SPACE
        POP HL
        LD C,29
        CALL 5
        PUSH HL
        LD A,H
        CALL HEXBYTE
        LD A,L
        CALL HEXBYTE
        CALL SPACE
        POP HL
        LD C,27
        CALL 5
        PUSH HL
        LD A,H
        CALL HEXBYTE
        LD A,L
        CALL HEXBYTE
        CALL SPACE
        POP HL
        LD B,31
S_ALV: LD A,(HL)
        INC HL
        CALL HEXBYTE
        DJNZ S_ALV
        CALL SPACE
        LD C,31
        CALL 5
        PUSH HL
        LD A,H
        CALL HEXBYTE
        LD A,L
        CALL HEXBYTE
        CALL SPACE
        POP HL
        LD B,15
S_DPB: LD A,(HL)
        INC HL
        CALL HEXBYTE
        DJNZ S_DPB
        JP CRLF

PUTS:  LD A,(HL)
        INC HL
        OR A
        RET Z
        LD E,A
        CALL PUTC
        JR PUTS
PUTC:  PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD C,2
        CALL 5
        POP HL
        POP DE
        POP BC
        POP AF
        RET
SPACE: LD E,' '
        JP PUTC
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
        CALL NIBBLE
        POP AF
NIBBLE: AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,NIBOUT
        ADD A,7
NIBOUT: LD E,A
        JP PUTC

BANNER: DB 'STATE017: label cur login ro alvptr alv[31] dpbptr dpb[15]',13,10,'$'
L_RESET: DB 'RESET   ',0
L_SELB: DB 'SELECTB ',0
L_SELA: DB 'SELECTA ',0
L_RSTB: DB 'RESET-B ',0
L_RSTBC0: DB 'RST-B+C ',0
L_BRO: DB 'B-RO    ',0
L_BROSEL: DB 'B-ROSEL ',0
L_RSTBRO: DB 'RST-BRO ',0
L_RSTMUL: DB 'RST-A+B ',0
L_SYSRST: DB 'SYSRESET ',0
L_PREMAKE: DB 'PREMAKE ',0
L_MAKE: DB 'MAKE    ',0
L_WRITE: DB 'WRITE   ',0
L_CLOSE: DB 'CLOSE   ',0
L_DELETE: DB 'DELETE  ',0
RCLABEL: DB 'RC make write close delete ',0
L_MOD: DB 'MOD alvptr/value dpbptr/value ',0
RCMAKE: DB 0
RCWRITE: DB 0
RCCLOSE: DB 0
RCDELETE: DB 0
ALVP: DW 0
DPBP: DW 0
ALVOLD: DB 0
DPBOLD: DB 0
FCB:    DB 0
        DB 'ST017   DAT'
        DS 24,0
FCBDEL: DB 0
        DB 'ST017   DAT'
        DS 24,0
DMA:    DS 128,0A7H
        DS 128
STACKTOP:
        END START
