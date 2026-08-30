; Investigation 023 transient-entry environment probe.
; Build: z80asm -fb ENTRY23.ASM
;
; Before its first BDOS call the probe records the main/alternate registers,
; SP, a 16-byte entry-stack window, and all 256 bytes of page zero.  It then
; queries live drive/user state and opens/reads DMACHK.DAT without calling
; Function 26.  A successful read into 0080h demonstrates the inherited DMA.

        ORG     0100H

START:
        LD      (INIT_SP),SP
        LD      (INIT_BC),BC
        LD      (INIT_DE),DE
        LD      (INIT_HL),HL
        LD      (INIT_IX),IX
        LD      (INIT_IY),IY
        PUSH    AF
        POP     HL
        LD      (INIT_AF),HL
        EXX
        LD      (ALT_BC),BC
        LD      (ALT_DE),DE
        LD      (ALT_HL),HL
        EXX
        EX      AF,AF'
        PUSH    AF
        POP     HL
        LD      (ALT_AF),HL
        EX      AF,AF'
        LD      A,I
        LD      (INIT_I),A
        PUSH    AF
        POP     HL
        LD      (I_FLAGS),HL
        LD      A,R
        LD      (INIT_R),A

        LD      HL,0000H
        LD      DE,PAGE0
        LD      BC,0100H
        LDIR
        LD      HL,(INIT_SP)
        LD      DE,STACK16
        LD      BC,16
        LDIR
        ; The CCP-supplied stack is sufficient for the entry RET contract but
        ; has no promised spare depth. Use private space for probe subroutines.
        LD      SP,STACKTOP

        LD      C,25
        CALL    0005H
        LD      (LIVE_DRIVE),A
        LD      E,0FFH
        LD      C,32
        CALL    0005H
        LD      (LIVE_USER),A

        LD      DE,DMAFCB
        LD      C,15
        CALL    0005H
        LD      (OPEN_RC),A
        INC     A
        JR      Z,NO_READ
        LD      DE,DMAFCB
        LD      C,20
        CALL    0005H
        LD      (READ_RC),A
        JR      AFTER_READ
NO_READ:
        LD      A,0FFH
        LD      (READ_RC),A
AFTER_READ:
        LD      HL,0080H
        LD      DE,DMA16
        LD      BC,16
        LDIR

        LD      DE,HDR
        CALL    PSTR
        LD      DE,REGMSG
        CALL    PSTR
        LD      DE,REGREC
        LD      BC,REGEND-REGREC
        CALL    DUMP
        LD      DE,PZMSG
        CALL    PSTR
        LD      DE,PAGE0
        LD      BC,8
        CALL    DUMP
        LD      DE,FCBMSG
        CALL    PSTR
        LD      DE,PAGE0+005CH
        LD      BC,36
        CALL    DUMP
        LD      DE,TAILMSG
        CALL    PSTR
        LD      DE,PAGE0+0080H
        LD      BC,128
        CALL    DUMP
        LD      DE,STKMSG
        CALL    PSTR
        LD      DE,STACK16
        LD      BC,16
        CALL    DUMP
        LD      DE,LIVEMSG
        CALL    PSTR
        LD      A,(LIVE_DRIVE)
        CALL    HEXBYTE
        LD      E,' '
        CALL    PUTC
        LD      A,(LIVE_USER)
        CALL    HEXBYTE
        CALL    CRLF
        LD      DE,DMAMSG
        CALL    PSTR
        LD      A,(OPEN_RC)
        CALL    HEXBYTE
        LD      E,' '
        CALL    PUTC
        LD      A,(READ_RC)
        CALL    HEXBYTE
        LD      E,' '
        CALL    PUTC
        LD      DE,DMA16
        LD      BC,16
        CALL    DUMP
        LD      SP,(INIT_SP)
        RET

PSTR:  LD      C,9
        JP      0005H

; Dump BC bytes at DE as contiguous uppercase hexadecimal and CR/LF.
DUMP:  LD      A,(DE)
        PUSH    BC
        PUSH    DE
        CALL    HEXBYTE
        POP     DE
        POP     BC
        INC     DE
        DEC     BC
        LD      A,B
        OR      C
        JR      NZ,DUMP
        JP      CRLF

HEXBYTE:
        PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL    HEXNIB
        POP     AF
HEXNIB:
        AND     0FH
        ADD     A,'0'
        CP      '9'+1
        JR      C,HEXOUT
        ADD     A,7
HEXOUT:
        LD      E,A
PUTC:  PUSH    BC
        PUSH    DE
        PUSH    HL
        LD      C,2
        CALL    0005H
        POP     HL
        POP     DE
        POP     BC
        RET
CRLF:  LD      E,13
        CALL    PUTC
        LD      E,10
        JP      PUTC

HDR:    DB 'ENTRY23 FORMAT=01',13,10,'$'
REGMSG: DB 'REGREC=$'
PZMSG:  DB 'PZ0000-0007=$'
FCBMSG: DB 'FCB005C-007F=$'
TAILMSG:DB 'TAIL0080-00FF=$'
STKMSG: DB 'STACK16=$'
LIVEMSG:DB 'LIVE DRIVE USER=$'
DMAMSG: DB 'DMA OPEN READ DATA=$'

; Little-endian pairs. I_FLAGS is AF immediately after LD A,I; P/V is IFF2.
REGREC:
INIT_SP:        DW 0
INIT_AF:        DW 0
INIT_BC:        DW 0
INIT_DE:        DW 0
INIT_HL:        DW 0
INIT_IX:        DW 0
INIT_IY:        DW 0
ALT_AF:         DW 0
ALT_BC:         DW 0
ALT_DE:         DW 0
ALT_HL:         DW 0
INIT_I:         DB 0
INIT_R:         DB 0
I_FLAGS:        DW 0
ENTRY_PC:       DW 0100H
FORMAT_VERSION: DB 1
REGEND:

LIVE_DRIVE: DB 0
LIVE_USER:  DB 0
OPEN_RC:    DB 0
READ_RC:    DB 0
PAGE0:      DS 256
STACK16:    DS 16
DMA16:      DS 16

DMAFCB: DB 0,'DMACHK  ','DAT',0,0,0,0
        DS 16
        DB 0,0,0,0

        DS 128
STACKTOP:

        END
