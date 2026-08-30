; Investigation 019 BIOS disk-boundary trace fixture.
; Patches BIOS jump operands only, delegates every call to original routines.
; Build: z80asm -fb -oBIOS019.COM BIOS019.ASM
        ORG 0100H
START:  LD SP,STACKTOP
        CALL PATCH
        LD C,13
        CALL 5

        LD HL,L_SEARCH
        CALL NEWCASE
        LD DE,FCBWILD
        LD C,17
        CALL 5
        CALL SHOWCASE

        LD DE,FCBREAD
        LD C,15
        CALL 5
        LD HL,L_SEQREAD
        CALL NEWCASE
        LD DE,FCBREAD
        LD C,20
        CALL 5
        CALL SHOWCASE

        LD DE,FCBDEL
        LD C,19
        CALL 5
        LD HL,L_MAKE
        CALL NEWCASE
        LD DE,FCBNEW
        LD C,22
        CALL 5
        CALL SHOWCASE

        LD DE,DMA1
        LD C,26
        CALL 5
        LD HL,L_WRITE1
        CALL NEWCASE
        LD DE,FCBNEW
        LD C,21
        CALL 5
        CALL SHOWCASE

        LD HL,L_WRITE2
        CALL NEWCASE
        LD DE,FCBNEW
        LD C,21
        CALL 5
        CALL SHOWCASE

        LD HL,L_CLOSE
        CALL NEWCASE
        LD DE,FCBNEW
        LD C,16
        CALL 5
        CALL SHOWCASE

        ; Reopen and random update record zero: allocated-data write type.
        LD DE,FCBNEW
        LD C,15
        CALL 5
        XOR A
        LD (FCBNEW+33),A
        LD (FCBNEW+34),A
        LD (FCBNEW+35),A
        LD HL,L_RANDR
        CALL NEWCASE
        LD DE,FCBNEW
        LD C,33
        CALL 5
        CALL SHOWCASE
        LD HL,L_RANDW
        CALL NEWCASE
        LD DE,FCBNEW
        LD C,34
        CALL 5
        CALL SHOWCASE

        LD DE,FCBNEW
        LD C,16
        CALL 5
        LD HL,L_DELETE
        CALL NEWCASE
        LD DE,FCBDEL
        LD C,19
        CALL 5
        CALL SHOWCASE

        CALL XLTEST
        CALL RESTORE
        JP 0

NEWCASE:
        LD (CASELABEL),HL
        XOR A
        LD (NREC),A
        RET
SHOWCASE:
        LD DE,CASEHDR
        LD C,9
        CALL 5
        LD HL,(CASELABEL)
        CALL PUTS
        CALL CRLF
        LD HL,TRACE
        LD A,(NREC)
        LD B,A
SHLOOP:
        LD A,B
        OR A
        RET Z
        PUSH BC
        LD B,10
SHBYTE: LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
        POP BC
        POP HL
        DJNZ SHBYTE
        CALL CRLF
        POP BC
        DJNZ SHLOOP
        RET

; record = event, drive, track lo/hi, sec lo/hi, dma lo/hi, aux, result
LOG:
        PUSH AF
        PUSH BC
        PUSH DE
        PUSH HL
        LD A,(NREC)
        CP 100
        JR NC,LOGDONE
        LD L,A
        LD H,0
        ADD HL,HL
        LD D,H
        LD E,L
        ADD HL,HL
        ADD HL,HL
        ADD HL,DE
        LD DE,TRACE
        ADD HL,DE
        LD A,(EVENT)
        LD (HL),A
        INC HL
        LD A,(CURDRV)
        LD (HL),A
        INC HL
        LD DE,(CURTRK)
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD DE,(CURSEC)
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD DE,(CURDMA)
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        LD A,(AUX)
        LD (HL),A
        INC HL
        LD A,(RES)
        LD (HL),A
        LD HL,NREC
        INC (HL)
LOGDONE:
        POP HL
        POP DE
        POP BC
        POP AF
        RET

; BIOS wrappers. Setup calls log before delegating; I/O logs after result.
WSEL:  LD A,C
        LD (CURDRV),A
        LD A,E
        LD (AUX),A
        LD A,'S'
        LD (EVENT),A
        XOR A
        LD (RES),A
        CALL LOG
        LD HL,(OSEL)
        JP CALLHL
WTRK:  LD (CURTRK),BC
        LD A,'T'
        JR WSET
WSEC:  LD (CURSEC),BC
        LD A,'C'
        JR WSET
WDMA:  LD (CURDMA),BC
        LD A,'M'
WSET:  LD (EVENT),A
        XOR A
        LD (AUX),A
        LD (RES),A
        CALL LOG
        CP 'T'
        LD HL,(OTRK)
        JR Z,WCALL
        LD A,(EVENT)
        CP 'C'
        LD HL,(OSEC)
        JR Z,WCALL
        LD HL,(ODMA)
WCALL: JP CALLHL
WREAD: LD HL,(OREAD)
        CALL CALLHL
        PUSH AF
        LD (RES),A
        LD A,'R'
        LD (EVENT),A
        XOR A
        LD (AUX),A
        CALL LOG
        POP AF
        RET
WWRITE:
        LD A,C
        LD (AUX),A
        LD HL,(OWRITE)
        CALL CALLHL
        PUSH AF
        LD (RES),A
        LD A,'W'
        LD (EVENT),A
        CALL LOG
        POP AF
        RET
WXLT:  LD (CURSEC),BC
        LD (XLTPTR),DE
        LD HL,(OXLT)
        CALL CALLHL
        PUSH AF
        PUSH HL
        LD (XLTOUT),HL
        LD A,L
        LD (AUX),A
        LD A,H
        LD (RES),A
        LD A,'X'
        LD (EVENT),A
        CALL LOG
        POP HL
        POP AF
        RET
CALLHL:
        LD (INDJMP+1),HL
        CALL INDJMP
        RET
INDJMP: JP 0

PATCH: LD HL,(0001H)
        DEC HL
        DEC HL
        DEC HL
        LD DE,27
        ADD HL,DE
        LD (VBASE),HL
        ; Save 8 vectors (SELDSK through SECTRAN).
        LD DE,SAVED
        LD BC,24
        LDIR
        LD HL,(VBASE)
        LD DE,OSEL
        LD B,8
GETOPS: INC HL
        LD A,(HL)
        LD (DE),A
        INC HL
        INC DE
        LD A,(HL)
        LD (DE),A
        INC HL
        INC DE
        DJNZ GETOPS
        LD HL,(VBASE)
        LD DE,WSEL
        CALL PUTJP
        LD DE,WTRK
        CALL PUTJP
        LD DE,WSEC
        CALL PUTJP
        LD DE,WDMA
        CALL PUTJP
        LD DE,WREAD
        CALL PUTJP
        LD DE,WWRITE
        CALL PUTJP
        ; Skip LISTST, patch SECTRAN.
        INC HL
        INC HL
        INC HL
        LD DE,WXLT
        JP PUTJP
PUTJP: LD (HL),0C3H
        INC HL
        LD (HL),E
        INC HL
        LD (HL),D
        INC HL
        RET
RESTORE:
        LD HL,SAVED
        LD DE,(VBASE)
        LD BC,24
        LDIR
        RET

; Direct BIOS identity/nonidentity translation and reads at track 2.
XLTEST:
        XOR A
        LD (NREC),A
        LD C,0
        LD E,0
        CALL WSEL
        LD BC,2
        CALL WTRK
        LD BC,2
        LD DE,0
        CALL WXLT
        LD B,H
        LD C,L
        CALL WSEC
        LD BC,IDBUF
        CALL WDMA
        CALL WREAD
        LD BC,2
        LD DE,XTABLE
        CALL WXLT
        LD B,H
        LD C,L
        CALL WSEC
        LD BC,XLBUF
        CALL WDMA
        CALL WREAD
        LD HL,L_XLT
        LD (CASELABEL),HL
        CALL SHOWCASE
        LD DE,BUFLAB
        LD C,9
        CALL 5
        LD HL,IDBUF
        LD B,16
        CALL PRINTN
        LD HL,XLBUF
        LD B,16
        CALL PRINTN
        RET
PRINTN: LD A,(HL)
        INC HL
        PUSH HL
        PUSH BC
        CALL HEXBYTE
        LD E,' '
        CALL PUTC
        POP BC
        POP HL
        DJNZ PRINTN
        JP CRLF

PUTS:  LD A,(HL)
        INC HL
        OR A
        RET Z
        LD E,A
        CALL PUTC
        JR PUTS
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
HEXBYTE:
        PUSH AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL NIB
        POP AF
NIB:   AND 0FH
        ADD A,'0'
        CP '9'+1
        JR C,NOUT
        ADD A,7
NOUT:  LD E,A
        JP PUTC

CASEHDR: DB 13,10,'CASE $'
BUFLAB: DB 'IDENTITY[16] then XLT[16]',13,10,'$'
L_SEARCH: DB 'SEARCH',0
L_SEQREAD: DB 'SEQREAD',0
L_MAKE: DB 'MAKE',0
L_WRITE1: DB 'WRITE1',0
L_WRITE2: DB 'WRITE2',0
L_CLOSE: DB 'CLOSE',0
L_RANDR: DB 'RANDREAD',0
L_RANDW: DB 'RANDWRITE',0
L_DELETE: DB 'DELETE',0
L_XLT: DB 'XLT-DIRECT',0

FCBWILD: DB 0,'???????????'
        DS 24,0
FCBREAD: DB 0,'DSKFILE DAT'
        DS 24,0
FCBNEW: DB 0,'BIOS019 DAT'
        DS 24,0
FCBDEL: DB 0,'BIOS019 DAT'
        DS 24,0
XTABLE: DB 1,2,10,4,5,6,7,8,9,3,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26
NREC: DB 0
CASELABEL: DW 0
EVENT: DB 0
CURDRV: DB 0
CURTRK: DW 0
CURSEC: DW 0
CURDMA: DW 0080H
AUX: DB 0
RES: DB 0
XLTPTR: DW 0
XLTOUT: DW 0
VBASE: DW 0
OSEL: DW 0
OTRK: DW 0
OSEC: DW 0
ODMA: DW 0
OREAD: DW 0
OWRITE: DW 0
OLISTST: DW 0
OXLT: DW 0
SAVED: DS 24
TRACE: DS 1000
DMA1: DS 128,0A5H
IDBUF: DS 128
XLBUF: DS 128
        DS 256
STACKTOP:
        END START
