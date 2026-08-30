; SPDX-License-Identifier: GPL-2.0-or-later
;
;***********************************************************************
;*                                                                     *
;*              B I O S T E S T   --   RELEASE DEV32                  *
;*                                                                     *
;*          CP/M 2.2 BIOS CONFORMANCE AND EXERCISE PROGRAM             *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev32 - item 0426 DPB/ALV diagnostic evidence
;
; ASSEMBLY: ZSM4, THEN DIGITAL RESEARCH LINK.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:   0100H
;
; This is not a collection of entry-point calls.  A PASS is entered only
; when the complete test has been made.  Tests which require a special disk,
; a device connection, or loss of the transient are left '-' until their
; prescribed run has been completed.
;
;------------------------- PROGRAMMER'S NOTES --------------------------
;
; Several tests must see the arguments which arrive at the BIOS, yet must
; still allow the resident BIOS to do the work.  The disk trace therefore
; substitutes the address fields of selected BIOS JMPs with addresses of
; small routines in this transient.  Each routine saves its arguments and
; then jumps through a private transfer instruction to the old address.
; Thus the added code is in series with, and not in place of, the BIOS.
;
; PATCHONE will touch a vector only if its opcode is JMP and both bytes of
; the new address can be written and read back.  The old address is saved
; before alteration.  PATCHCNT is also an unwind count: if installation
; stops half way, only those JMPs already changed are put back.  Do not put
; a BDOS call between changing a disk vector and putting it back.
;
; The character test uses a different kind of intercept.  CONOUT, LIST,
; PUNCH and READER are counting stubs and normally do NOT pass the call on.
; This observes BDOS logical routing without sending test characters to an
; unknown device.  SETDMA is passed on, since suppressing it would disturb
; the disk system.  The original READER address is kept in JOREADER for the
; separate, operator-arranged reader test.
;
; BOOT and WBOOT cannot return to the caller.  BTBOOT.DAT is consequently a
; one-record continuation card.  A pending operation is written before the
; transfer; the next copy of BIOSTEST checks the rebuilt low memory and turns
; the pending bit into a completed bit.  The final /ALL merely reads these
; completed bits.  This is why the three boot selections are run twice.
;
; BTRDR.DAT performs the same office for the two READER arrangements.  The
; first run records the normal-reader byte and returns to the CCP so STAT may
; change the assignment.  The second run records the absent-reader byte.
;
; The disk tests use three further dodges worth noting:
;   (1) Known bytes are placed at 0080H and at ALTDMA.  Calls are then made
;       through the character intercepts.  Damage to either set detects an
;       illicit DMA selection or use.
;   (2) The trace calculates the expected track from the FCB allocation
;       entry, record number, DPB and translation result.  It does not use
;       the captured SETTRK value to predict itself.
;   (3) The write-protect test requires a real failing WRITE.  Its non-zero
;       return is saved as test data and removed from IOFAIL; a failure after
;       the disk is made writable again is still an ordinary trace failure.
;
; All altered vectors, DPB bytes, DMA addresses and command-tail bytes have
; a matching restore path.  When adding a test, provide the restore path
; first.  A test program which leaves the machine changed proves very little.
;
;***********************************************************************

; LINK establishes the CP/M transient load address at 0100h.
BDOS    EQU     0005H
NCASES  EQU     46

START:  LD      SP,STACKTOP
        XOR     A
        LD      (FAULTREQ),A
        LD      (READERREQ),A
        LD      HL,0
        PUSH    HL
        LD      A,(0080H)
        OR      A
        JP      Z,HELP
        CALL    GETARG
        JP      NZ,BADCOMMAND
        LD      DE,SH
        CALL    ARGIS
        JP      Z,HELP
        LD      DE,SHELP
        CALL    ARGIS
        JP      Z,HELP
        LD      DE,SLIST
        CALL    ARGIS
        JP      Z,LIST
        LD      DE,SALL
        CALL    ARGIS
        JP      Z,RUNALL
        LD      DE,SSAFE
        CALL    ARGIS
        JP      Z,RUNSAFE
        LD      DE,SINFO
        CALL    ARGIS
        JP      Z,INFO
        LD      DE,SVER
        CALL    ARGIS
        JP      Z,VERSION
        LD      DE,SVERSION
        CALL    ARGIS
        JP      Z,VERSION
        LD      DE,SGLIST
        CALL    ARGIS
        JP      Z,GROUPLIST
        LD      DE,SGREQ
        CALL    ARGIS
        JP      Z,RUNREQUIRED
        LD      DE,SGOBS
        CALL    ARGIS
        JP      Z,RUNOBSERVATION
        LD      DE,SGMAN
        CALL    ARGIS
        JP      Z,RUNMANUAL
        LD      DE,SGALLOC
        CALL    ARGIS
        JP      Z,RUNALLOCATION
        LD      DE,SGDEV
        CALL    ARGIS
        JP      Z,RUNDEVICES
        LD      DE,SGDISK
        CALL    ARGIS
        JP      Z,RUNDISK
        LD      DE,SGBOOT
        CALL    ARGIS
        JP      Z,RUNBOOT
        LD      DE,SGCHAR
        CALL    ARGIS
        JP      Z,RUNCHARACTER
        LD      DE,SGCPU
        CALL    ARGIS
        JP      Z,RUNPROCESSOR
        LD      DE,SHR
        CALL    ARGIS
        JP      Z,HRESULTS
        LD      DE,SHP
        CALL    ARGIS
        JP      Z,HPROFILES
        CALL    ITEMARG
        JP      Z,RUNONE
BADCOMMAND:
        LD      DE,BADSEL
        JP      PUTS

; Decode command tail.
; Exit: A=1 HELP, 2 LIST, 3 ALL, 4 NUMBER, 5 INFO,
;       A=6 RESULTS, 7 PROFILES, 8 SAFE.
GETARG:XOR     A
        LD      (ARGBUF),A
        LD      A,(0080H)
        OR      A
        RET     Z
        LD      B,A
        LD      HL,0081H
PSKIP: LD      A,(HL)
        CP      ' '
        JP      NZ,PSTART
        INC     HL
        DEC     B
        JP      NZ,PSKIP
        XOR     A
        RET
PSTART:LD      DE,ARGBUF
PCOPY: LD      A,B
        OR      A
        JP      Z,PDONE
        LD      A,(HL)
        CP      ' '
        JP      Z,PTRAIL
        CP      'a'
        JP      C,PSTORE
        CP      'z'+1
        JP      NC,PSTORE
        SUB     20H
PSTORE:LD      (DE),A
        INC     DE
        INC     HL
        DEC     B
        JP      PCOPY
PTRAIL:INC     HL
        DEC     B
PTRLP: LD      A,B
        OR      A
        JP      Z,PDONE
        LD      A,(HL)
        CP      ' '
        JP      NZ,PBAD
        INC     HL
        DEC     B
        JP      PTRLP
PDONE: XOR     A
        LD      (DE),A
        CP      A
        RET
PBAD:  OR      1
        RET

ARGIS: LD      HL,ARGBUF
PACMP: LD      A,(DE)
        CP      (HL)
        RET     NZ
        OR      A
        RET     Z
        INC     DE
        INC     HL
        JP      PACMP

ITEMARG:
        XOR     A
        LD      (REPORTMODE),A
        LD      HL,ARGBUF
        LD      A,(HL)
        CP      '/'
        RET     NZ
        INC     HL
        LD      DE,SELBUF
        LD      B,4
PNUM:  LD      A,(HL)
        CP      '0'
        JP      C,PIBAD
        CP      '9'+1
        JP      NC,PIBAD
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,PNUM
        LD      A,(HL)
        OR      A
        RET     Z
        LD      DE,SREPORT
PIRPT: LD      A,(DE)
        CP      (HL)
        JP      NZ,PIBAD
        OR      A
        JP      Z,PIROK
        INC     DE
        INC     HL
        JP      PIRPT
PIROK: LD      A,1
        LD      (REPORTMODE),A
        XOR     A
        RET
PIBAD: OR      1
        RET

HELP:  LD      DE,HLPMSG
        CALL    PUTS
        RET
LIST:  LD      DE,LSTMSG
        CALL    PUTS
        RET
INFO:  LD      DE,INFMSG
        CALL    PUTS
        RET
VERSION:LD     DE,VERMSG
        JP      PUTS
GROUPLIST:LD   DE,GRPLIST
        JP      PUTS
HRESULTS:
        LD      DE,RESMSG
        CALL    PUTS
        RET
HPROFILES:
        LD      DE,PRFMSG
        CALL    PUTS
        RET

RUNALL:LD      A,1
        LD      (FAULTREQ),A
        LD      (READERREQ),A
        CALL    AUTOTESTS
        CALL    LOADBPASS
        CALL    LOADRDPASS
        CALL    CONTROLGATE
        CALL    CHARGATE
        JP      RUNROWS
RUNSAFE:
        CALL    AUTOTESTS
RUNROWS:
        LD      DE,HEADMSG
        CALL    PUTS
        LD      HL,CASES
        LD      B,NCASES
RALOOP:PUSH    BC
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RALOOP
        JP      SUMMARY

; Functional groups are contiguous views of the catalog.  Only the five safe
; returning checks run automatically; provider, scratch-media, and boot work
; remains selected and explicit.
RUNALLOCATION:
        LD      HL,CASES
        LD      B,13
        JP      RUNRANGE
RUNDEVICES:
        LD      HL,CASES+104
        LD      B,7
        JP      RUNRANGE
RUNDISK:
        LD      HL,CASES+160
        LD      B,15
        JP      RUNRANGE
RUNBOOT:
        LD      HL,CASES+280
        LD      B,4
        JP      RUNRANGE
RUNCHARACTER:
        LD      HL,CASES+312
        LD      B,6
        JP      RUNRANGE
RUNPROCESSOR:
        LD      HL,CASES+360
        LD      B,1
RUNRANGE:
        PUSH    HL
        PUSH    BC
        CALL    AUTOTESTS
        LD      DE,HEADMSG
        CALL    PUTS
        POP     BC
        POP     HL
RGRLP: PUSH    BC
        PUSH    HL
        CALL    PRINTROW
        POP     HL
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RGRLP
        LD      DE,GRPSUM
        JP      PUTS

RUNREQUIRED:
        XOR     A
        LD      (FILTERMODE),A
        JP      RUNFILTER
RUNOBSERVATION:
        LD      A,1
        LD      (FILTERMODE),A
        JP      RUNFILTER
RUNMANUAL:
        LD      A,2
        LD      (FILTERMODE),A
RUNFILTER:
        CALL    AUTOTESTS
        LD      DE,HEADMSG
        CALL    PUTS
        LD      HL,CASES
        LD      B,NCASES
RFLP:  LD      (CARDPTR),HL
        PUSH    BC
        LD      DE,4
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      A,(FILTERMODE)
        OR      A
        JP      Z,RFREQ
        CP      1
        JP      Z,RFOBS
        LD      HL,CLREQ
        CALL    DEISEQ
        JP      Z,RFMSTAT
        LD      HL,CLOPT
        CALL    DEISEQ
        JP      NZ,RFSKIP
RFMSTAT:
        LD      HL,(CARDPTR)
        INC     HL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      HL,STOUT
        CALL    DEISEQ
        JP      NZ,RFSKIP
        JP      RFPRINT
RFREQ: LD      HL,CLREQ
        CALL    DEISEQ
        JP      NZ,RFSKIP
        JP      RFPRINT
RFOBS: LD      HL,CLNG
        CALL    DEISEQ
        JP      NZ,RFSKIP
RFPRINT:
        LD      HL,(CARDPTR)
        CALL    PRINTROW
RFSKIP:
        LD      HL,(CARDPTR)
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RFLP
        LD      A,(FILTERMODE)
        OR      A
        LD      DE,REQSUM
        JP      Z,PUTS
        CP      1
        LD      DE,OBSSUM
        JP      Z,PUTS
        LD      DE,MANSUM
        JP      PUTS

; Z means the pointer in DE equals the pointer in HL.
DEISEQ:LD      A,L
        CP      E
        RET     NZ
        LD      A,H
        CP      D
        RET

RUNONE:
        CALL    ISFAULT
        LD      (FAULTREQ),A
        CALL    ISREADER
        LD      (READERREQ),A
        CALL    AUTOTESTS
        CALL    LOADBPASS
        CALL    LOADRDPASS
        CALL    ISCONTROL
        OR      A
        CALL    NZ,CONTROLGATE
        CALL    ISCHAR
        OR      A
        CALL    NZ,CHARGATE
        CALL    ISBOOT
        OR      A
        CALL    NZ,BOOTGATE
        LD      HL,CASES
        LD      B,NCASES
ROLOOP:PUSH    BC
        PUSH    HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      DE,SELBUF
        LD      C,4
ROCMP: LD      A,(DE)
        CP      (HL)
        JP      NZ,RONEXT
        INC     DE
        INC     HL
        DEC     C
        JP      NZ,ROCMP
        POP     HL
        POP     BC
        LD      DE,HEADMSG
        CALL    PUTS
        CALL    PRINTROW
        LD      A,(REPORTMODE)
        OR      A
        JP      Z,ROSHORT
        CALL    SHOWDETAIL
ROSHORT:
        LD      DE,ONESUM
        CALL    PUTS
        RET
RONEXT:POP     HL
        LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,ROLOOP
        LD      DE,BADSEL
        CALL    PUTS
        RET

;--------------------------- PRINT A ROW -------------------------------
; HL points to four words: item, status, class and explanation.
; The first three fields are fixed width; the explanation gets the rest of
; the 80-column line.
PRINTROW:
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      B,4
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      B,1
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        LD      B,1
        CALL    PUTFIELD
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS

; Print $ string at DE in a field B characters wide.
; Clip on the right, or fill the unused part with spaces.
PUTFIELD:
        PUSH    HL
        PUSH    BC
        EX      DE,HL
PFCHAR:LD      A,B
        OR      A
        JP      Z,PFDONE
        LD      A,(HL)
        CP      '$'
        JP      Z,PFSPACE
        INC     HL
        LD      E,A
        LD      C,2
        PUSH    HL
        PUSH    BC
        CALL    BDOS
        POP     BC
        POP     HL
        DEC     B
        JP      PFCHAR
PFSPACE:
        LD      E,' '
        LD      C,2
        PUSH    HL
        PUSH    BC
        CALL    BDOS
        POP     BC
        POP     HL
        DEC     B
        JP      NZ,PFSPACE
PFDONE:POP     BC
        POP     HL
        RET

PUTS:  PUSH    HL
        PUSH    BC
        LD      C,9
        CALL    BDOS
        POP     BC
        POP     HL
        RET

; A=1 if selected item belongs to the controlled disk group.
ISCONTROL:
        LD      A,(SELBUF)
        CP      '0'
        JP      NZ,ICNO
        LD      A,(SELBUF+1)
        CP      '4'
        JP      NZ,ICNO
        LD      A,(SELBUF+2)
        CP      '2'
        JP      Z,IC42
        CP      '3'
        JP      Z,IC43
        CP      '4'
        JP      Z,IC44
        CP      '5'
        JP      Z,IC45
ICNO:  XOR     A
        RET
IC42:  LD      A,(SELBUF+3)
        CP      '4'
        JP      C,ICNO
        CP      '8'
        JP      NC,ICNO
        LD      A,1
        RET
IC43:  LD      A,(SELBUF+3)
        CP      '1'
        JP      C,ICNO
        CP      '4'
        JP      NC,ICNO
        LD      A,1
        RET
IC44:  LD      A,(SELBUF+3)
        CP      '9'
        JP      NZ,ICNO
        LD      A,1
        RET
IC45:  LD      A,(SELBUF+3)
        CP      '0'
        JP      Z,ICYES
        CP      '3'
        JP      Z,ICYES
        CP      '4'
        JP      Z,ICYES
        CP      '6'
        JP      Z,ICYES
        CP      '7'
        JP      Z,ICYES
        CP      '8'
        JP      NZ,ICNO
ICYES: LD      A,1
        RET

ISFAULT:
        LD      HL,SELBUF
        LD      DE,I0457
        LD      B,4
IFLOOP:LD      A,(DE)
        CP      (HL)
        JP      NZ,IFNO
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,IFLOOP
        LD      A,1
        RET
IFNO:  XOR     A
        RET

; A=1 if selected item belongs to the character group.
ISCHAR:LD      A,(SELBUF)
        CP      '0'
        JP      NZ,ICNO
        LD      A,(SELBUF+1)
        CP      '4'
        JP      NZ,ICNO
        LD      A,(SELBUF+2)
        CP      '3'
        JP      Z,ICH3
        CP      '4'
        JP      Z,ICH4
        CP      '6'
        JP      Z,ICH6
        CP      '7'
        JP      Z,ICH7
        XOR     A
        RET
ICH3:  LD      A,(SELBUF+3)
        CP      '9'
        JP      Z,ICYES
        JP      ICNO
ICH4:  LD      A,(SELBUF+3)
        CP      '5'
        JP      Z,ICYES
        CP      '8'
        JP      Z,ICYES
        JP      ICNO
ICH6:  LD      A,(SELBUF+3)
        CP      '8'
        JP      Z,ICYES
        CP      '9'
        JP      Z,ICYES
        JP      ICNO
ICH7:  LD      A,(SELBUF+3)
        CP      '0'
        JP      Z,ICYES
        CP      '1'
        JP      Z,ICYES
        CP      '3'
        JP      Z,ICYES
        JP      ICNO

ISREADER:
        LD      HL,SELBUF
        LD      DE,I0471
        LD      B,4
IRLOOP:LD      A,(DE)
        CP      (HL)
        JP      NZ,IRNO
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,IRLOOP
        LD      A,1
        RET
IRNO:  XOR     A
        RET

ISBOOT:LD      A,(SELBUF)
        CP      '0'
        JP      NZ,ICNO
        LD      A,(SELBUF+1)
        CP      '4'
        JP      NZ,ICNO
        LD      A,(SELBUF+2)
        CP      '6'
        JP      NZ,ICNO
        LD      A,(SELBUF+3)
        CP      '4'
        JP      C,ICNO
        CP      '7'
        JP      NC,ICNO
        JP      ICYES

;---------------------- GET THE SCRATCH DRIVE --------------------------
; Ask here, rather than in the command decoder, since the following work
; makes and erases BTBIO.TMP.  Q leaves the group unrun.
CONTROLGATE:
        CALL    SAVEENV
CGASK: LD      DE,CGMSG
        CALL    PUTS
        CALL    GETKEY
        CP      'Q'
        RET     Z
        CP      'B'
        JP      C,CGBAD
        CP      'P'+1
        JP      NC,CGBAD
        SUB     'A'
        LD      B,A
        LD      A,(OLDDRV)
        CP      B
        JP      Z,CGSAME
        LD      A,B
        LD      (SCRDRV),A
        INC     A
        LD      (TESTFCB),A
        LD      DE,CGCONF
        CALL    PUTS
        CALL    GETKEY
        CP      'Y'
        RET     NZ
        CALL    RUNCONTROL
        RET
CGBAD: LD      DE,CGBADMSG
        CALL    PUTS
        JP      CGASK
CGSAME:LD      DE,CGSAMEMSG
        CALL    PUTS
        JP      CGASK

SAVEENV:
        LD      C,25
        CALL    BDOS
        LD      (OLDDRV),A
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        LD      (OLDUSR),A
        RET
RESTENV:
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      C,13
        CALL    BDOS
        LD      A,(OLDUSR)
        LD      E,A
        LD      C,32
        CALL    BDOS
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        RET
GETKEY:LD      C,1
        CALL    BDOS
        AND     5FH
        RET

;---------------------- CHARACTER TEST CONTROL -------------------------
; CONST and CONIN are called at their real entries with the operator's K.
; The logical-output calls are made with the temporary vectors installed.
; No result is entered until the old vectors and DMA have been restored.
CHARGATE:
        LD      DE,CHGMSG
        CALL    PUTS
        CALL    GETKEY
        CP      'Y'
        RET     NZ
        XOR     A
        LD      (CHCOUNT),A
        CALL    CONSOLETEST
        LD      HL,CASES+312       ; 0468
        LD      DE,V0468
        LD      A,(CSTRES)
        CALL    SETRESULT
        LD      HL,CASES+320       ; 0469
        LD      DE,V0469
        LD      A,(CINRES)
        CALL    SETRESULT
        LD      A,2
        LD      (CHCOUNT),A
        CALL    PREPSENT
        CALL    CHARINSTALL
        OR      A
        JP      NZ,CHNTRACE
        CALL    CHARWORK
        CALL    CHARRESTORE
        CALL    CHJUDGE
        LD      A,(READERREQ)
        OR      A
        CALL    NZ,READERWORK
        JP      CHDONE
CHNTRACE:
        CALL    CHARRESTORE
        LD      DE,CHARBAD
        CALL    PUTS
CHDONE:CALL    RESTSENT
        LD      A,(CHCOUNT)
        LD      B,A
        LD      A,(REMCNT)
        SUB     B
        LD      (REMCNT),A
        RET

; Test the real status/input pair.  First status must be empty.  Two ready
; polls must not eat the K, and CONIN must return that same character.
CONSOLETEST:
        LD      A,1
        LD      (CSTRES),A
        LD      (CINRES),A
        CALL    BIOSADDR
        LD      DE,6
        ADD     HL,DE
        CALL    CALLHL             ; CONST before controlled input
        OR      A
        JP      NZ,CSWAIT
        XOR     A
        LD      (CSTRES),A
CSWAIT:LD      DE,CKEYMSG
        CALL    PUTS
CSLOOP:CALL    BIOSADDR
        LD      DE,6
        ADD     HL,DE
        CALL    CALLHL
        OR      A
        JP      Z,CSLOOP
        CP      0FFH
        JP      NZ,CSIN
        CALL    BIOSADDR
        LD      DE,6
        ADD     HL,DE
        CALL    CALLHL
        CP      0FFH
        JP      NZ,CSIN
        LD      A,(CSTRES)
        OR      A
        JP      NZ,CSIN
        XOR     A
        LD      (CSTRES),A
CSIN:  CALL    BIOSADDR
        LD      DE,9
        ADD     HL,DE
        CALL    CALLHL             ; CONIN
        AND     07FH
        CP      'K'
        JP      NZ,CSPOST
        XOR     A
        LD      (CINRES),A
CSPOST:CALL    BIOSADDR
        LD      DE,6
        ADD     HL,DE
        CALL    CALLHL
        OR      A
        RET     Z
        LD      A,1                ; extra pending byte invalidates status row
        LD      (CSTRES),A
        RET

BIOSADDR:
        LD      HL,(0001H)
        DEC     HL
        DEC     HL
        DEC     HL
        RET

;--------------------------- DMA CANARIES -------------------------------
; Save four bytes at 0080H.  Put one pattern there and another at ALTDMA,
; then select ALTDMA.  RESTSENT selects 0080H again and restores its bytes.
PREPSENT:
        LD      HL,0080H
        LD      DE,DMASAVE
        LD      B,4
        CALL    COPY4
        LD      HL,DMAPAT1
        LD      DE,0080H
        LD      B,4
        CALL    COPY4
        LD      HL,DMAPAT2
        LD      DE,ALTDMA
        LD      B,4
        CALL    COPY4
        LD      DE,ALTDMA
        LD      C,26
        CALL    BDOS
        RET
RESTSENT:
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      HL,DMASAVE
        LD      DE,0080H
        LD      B,4
        CALL    COPY4
        RET

;----------------------- READER CONTINUATION ---------------------------
; BTRDR.DAT carries the first READER result across the return to CCP which
; is needed for the intervening STAT assignment.
LOADRDPASS:
        CALL    LOADRDREC
        LD      A,(RDSTAGE)
        CP      2
        RET     NZ
        XOR     A
        LD      HL,CASES+336
        LD      DE,V0471
        CALL    SETRESULT
        LD      A,(REMCNT)
        DEC     A
        LD      (REMCNT),A
        RET

LOADRDREC:
        XOR     A
        LD      (RDSTAGE),A
        CALL    INITRDFCB
        LD      DE,RDFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        RET     Z
        LD      DE,RDBUF
        LD      C,26
        CALL    BDOS
        LD      DE,RDFCB
        LD      C,20
        LD      (RDIO),A
        CALL    BDOS
        LD      (RDIO),A
        LD      DE,RDFCB
        LD      C,16
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      A,(RDIO)
        OR      A
        RET     NZ
        LD      HL,RDMAGIC
        LD      DE,RDBUF
        LD      B,4
        CALL    CMPEQ
        OR      A
        RET     NZ
        LD      A,(RDBUF+4)
        LD      (RDSTAGE),A
        RET

SAVERDREC:
        LD      HL,RDBUF
        LD      B,128
        XOR     A
SRDCLR:LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,SRDCLR
        LD      HL,RDMAGIC
        LD      DE,RDBUF
        LD      B,4
        CALL    COPY4
        LD      A,(RDSTAGE)
        LD      (RDBUF+4),A
        CALL    INITRDFCB
        LD      DE,RDFCB
        LD      C,19
        CALL    BDOS
        CALL    INITRDFCB
        LD      DE,RDFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,SRDFAIL
        LD      DE,RDBUF
        LD      C,26
        CALL    BDOS
        LD      DE,RDFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,SRDFAIL
        LD      DE,RDFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,SRDFAIL
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        XOR     A
        RET
SRDFAIL:
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      A,1
        RET

INITRDFCB:
        LD      HL,RDFCB
        LD      B,36
        XOR     A
IRFCLR:LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IRFCLR
        LD      HL,RDNAME
        LD      DE,RDFCB+1
        LD      B,11
IRFNAME:
        LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,IRFNAME
        RET

;------------------------- BOOT CONTINUATION ---------------------------
; BTBOOT.DAT contains a pending operation, completed bits, and enough of the
; old gateway layout to reject a record belonging to another system image.
; Comes here after reloading BIOSTEST.  Only a completed bit earns a PASS.
; ERA BTBOOT.DAT starts the sequence over.
LOADBPASS:
        CALL    LOADBREC
        OR      A
        RET     NZ
        CALL    BOOTMATCH
        OR      A
        RET     NZ                 ; record is for some other BIOS
        XOR     A
        LD      (BOOTCOUNT),A
        LD      A,(BOOTBITS)
        AND     1
        JP      Z,LBP65
        XOR     A
        LD      HL,CASES+280
        LD      DE,V0464
        CALL    SETRESULT
        LD      A,(BOOTCOUNT)
        INC     A
        LD      (BOOTCOUNT),A
LBP65: LD      A,(BOOTBITS)
        AND     2
        JP      Z,LBP66
        XOR     A
        LD      HL,CASES+288
        LD      DE,V0465
        CALL    SETRESULT
        LD      A,(BOOTCOUNT)
        INC     A
        LD      (BOOTCOUNT),A
LBP66: LD      A,(BOOTBITS)
        AND     4
        JP      Z,LBPDONE
        XOR     A
        LD      HL,CASES+296
        LD      DE,V0466
        CALL    SETRESULT
        LD      A,(BOOTCOUNT)
        INC     A
        LD      (BOOTCOUNT),A
LBPDONE:
        LD      A,(BOOTCOUNT)
        LD      B,A
        LD      A,(REMCNT)
        SUB     B
        LD      (REMCNT),A
        RET

BOOTMATCH:
        LD      A,(0000H)
        CP      0C3H
        JP      NZ,TFAIL
        LD      A,(0005H)
        CP      0C3H
        JP      NZ,TFAIL
        LD      HL,(0001H)
        PUSH    HL
        LD      HL,(BOOTWBOOT)
        POP     DE
        LD      A,H
        CP      D
        JP      NZ,TFAIL
        LD      A,L
        CP      E
        JP      NZ,TFAIL
        LD      HL,(0006H)
        PUSH    HL
        LD      HL,(BOOTBDOS)
        POP     DE
        LD      A,H
        CP      D
        JP      NZ,TFAIL
        LD      A,L
        CP      E
        JP      NZ,TFAIL
        XOR     A
        RET

BOOTGATE:
        ; Comes here on both halves of a boot test.  No pending byte means
        ; arm the continuation record and transfer control.  A matching
        ; pending byte means this is the copy loaded after that transfer.
        CALL    LOADBREC
        LD      A,(SELBUF+3)
        SUB     '3'
        LD      (BOOTSEL),A         ; 1=BOOT, 2=WBOOT, 3=gateway damage
        CALL    BOOTMASK
        LD      B,A
        LD      A,(BOOTBITS)
        AND     B
        RET     NZ                  ; retained PASS was loaded above
        LD      A,(BOOTPEND)
        OR      A
        JP      Z,BOOTSTART
        LD      B,A
        LD      A,(BOOTSEL)
        CP      B
        JP      Z,BOOTVERIFY
        LD      DE,BPENDMSG
        CALL    PUTS
        RET

BOOTSTART:
        LD      DE,BSTARTMSG
        CALL    PUTS
        CALL    GETKEY
        CP      'Y'
        RET     NZ
        LD      C,25
        CALL    BDOS
        LD      (BOOTDRV),A
        LD      HL,(0001H)
        LD      (BOOTWBOOT),HL
        LD      HL,(0006H)
        LD      (BOOTBDOS),HL
        LD      A,(BOOTSEL)
        LD      (BOOTPEND),A
        CALL    SAVEBOOT
        OR      A
        JP      NZ,BOOTSTOREBAD
        LD      DE,BTRANSFER
        CALL    PUTS
        LD      A,(BOOTSEL)
        CP      1
        JP      Z,DOBOOT
        CP      2
        JP      Z,DOWBOOT
        ; Gateway-repair test: spoil only the JMP opcodes.  Leave operands
        ; intact so WBOOT itself can still be entered through the saved word.
        XOR     A
        LD      (0000H),A
        LD      (0005H),A
DOWBOOT:
        LD      A,(BOOTDRV)
        LD      C,A
        LD      HL,(BOOTWBOOT)
        JP      (HL)
DOBOOT:LD      C,0
        CALL    BIOSADDR
        JP      (HL)

BOOTVERIFY:
        ; We are running after BOOT/WBOOT.  Check the public low-memory state,
        ; current drive where applicable, and the two repaired gateways.
        CALL    CHECKPUBLIC
        LD      (BOOTRES),A
        LD      A,(BOOTSEL)
        CP      1
        JP      NZ,BVDRIVE
        LD      DE,BCOLDMSG
        CALL    PUTS
        CALL    GETKEY
        CP      'Y'
        JP      Z,BVFINISH
        LD      A,1
        LD      (BOOTRES),A
        JP      BVFINISH
BVDRIVE:
        LD      C,25
        CALL    BDOS
        LD      HL,BOOTDRV
        CP      (HL)
        JP      Z,BVGATE
        LD      A,1
        LD      (BOOTRES),A
BVGATE:LD      A,(BOOTSEL)
        CP      3
        JP      NZ,BVFINISH
        LD      HL,(0001H)
        PUSH    HL
        LD      HL,(BOOTWBOOT)
        POP     DE
        LD      A,H
        CP      D
        JP      NZ,BVBAD
        LD      A,L
        CP      E
        JP      NZ,BVBAD
        LD      HL,(0006H)
        PUSH    HL
        LD      HL,(BOOTBDOS)
        POP     DE
        LD      A,H
        CP      D
        JP      NZ,BVBAD
        LD      A,L
        CP      E
        JP      Z,BVFINISH
BVBAD: LD      A,1
        LD      (BOOTRES),A
BVFINISH:
        XOR     A
        LD      (BOOTPEND),A
        LD      A,(BOOTRES)
        OR      A
        JP      NZ,BVSAVE
        CALL    BOOTMASK
        LD      B,A
        LD      A,(BOOTBITS)
        OR      B
        LD      (BOOTBITS),A
BVSAVE:CALL    SAVEBOOT
        OR      A
        JP      Z,BVRESULT
        LD      A,1
        LD      (BOOTRES),A
BVRESULT:
        LD      A,(BOOTSEL)
        CP      1
        JP      Z,BVR64
        CP      2
        JP      Z,BVR65
        LD      HL,CASES+296
        LD      DE,V0466
        JP      BVRSET
BVR64: LD      HL,CASES+280
        LD      DE,V0464
        JP      BVRSET
BVR65: LD      HL,CASES+288
        LD      DE,V0465
BVRSET:LD      A,(BOOTRES)
        CALL    SETRESULT
        LD      A,(REMCNT)
        DEC     A
        LD      (REMCNT),A
        LD      A,(BOOTRES)
        OR      A
        RET     NZ
        LD      DE,BRETAINMSG
        CALL    PUTS
        RET

BOOTMASK:
        LD      A,(BOOTSEL)
        CP      1
        LD      A,1
        RET     Z
        LD      A,(BOOTSEL)
        CP      2
        LD      A,2
        RET     Z
        LD      A,4
        RET

CHECKPUBLIC:
        LD      A,(0000H)
        CP      0C3H
        JP      NZ,TFAIL
        LD      A,(0005H)
        CP      0C3H
        JP      NZ,TFAIL
        LD      HL,(0001H)
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      HL,(0006H)
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      C,12
        CALL    BDOS
        CP      022H
        JP      NZ,TFAIL
        XOR     A
        RET

BOOTSTOREBAD:
        LD      DE,BSTOREMSG
        CALL    PUTS
        RET

LOADBREC:
        XOR     A
        LD      (BOOTBITS),A
        LD      (BOOTPEND),A
        CALL    INITBOOTFCB
        LD      DE,BOOTFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        JP      Z,LBNONE
        LD      DE,BOOTBUF
        LD      C,26
        CALL    BDOS
        LD      DE,BOOTFCB
        LD      C,20
        CALL    BDOS
        LD      (BOOTIO),A
        LD      DE,BOOTFCB
        LD      C,16
        CALL    BDOS
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      A,(BOOTIO)
        OR      A
        JP      NZ,LBNONE
        LD      HL,BOOTMAGIC
        LD      DE,BOOTBUF
        LD      B,4
        CALL    CMPEQ
        OR      A
        JP      NZ,LBNONE
        LD      A,(BOOTBUF+4)
        LD      (BOOTBITS),A
        LD      A,(BOOTBUF+5)
        LD      (BOOTPEND),A
        LD      A,(BOOTBUF+6)
        LD      (BOOTDRV),A
        LD      HL,(BOOTBUF+7)
        LD      (BOOTWBOOT),HL
        LD      HL,(BOOTBUF+9)
        LD      (BOOTBDOS),HL
        XOR     A
        RET
LBNONE:LD      A,1
        RET

SAVEBOOT:
        ; Rewrite, rather than update, the continuation record.  A magic word
        ; and saved gateway addresses keep stale evidence from earning PASS.
        LD      HL,BOOTBUF
        LD      B,128
        XOR     A
SBCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,SBCLR
        LD      HL,BOOTMAGIC
        LD      DE,BOOTBUF
        LD      B,4
        CALL    COPY4
        LD      A,(BOOTBITS)
        LD      (BOOTBUF+4),A
        LD      A,(BOOTPEND)
        LD      (BOOTBUF+5),A
        LD      A,(BOOTDRV)
        LD      (BOOTBUF+6),A
        LD      HL,(BOOTWBOOT)
        LD      (BOOTBUF+7),HL
        LD      HL,(BOOTBDOS)
        LD      (BOOTBUF+9),HL
        CALL    INITBOOTFCB
        LD      DE,BOOTFCB
        LD      C,19
        CALL    BDOS
        CALL    INITBOOTFCB
        LD      DE,BOOTFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,SBFAIL
        LD      DE,BOOTBUF
        LD      C,26
        CALL    BDOS
        LD      DE,BOOTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,SBFAIL
        LD      DE,BOOTFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,SBFAIL
        LD      DE,0080H
        LD      C,26
        CALL    BDOS
        XOR     A
        RET
SBFAIL:LD      DE,0080H
        LD      C,26
        CALL    BDOS
        LD      A,1
        RET

INITBOOTFCB:
        LD      HL,BOOTFCB
        LD      B,36
        XOR     A
IBFCLR:LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IBFCLR
        LD      HL,BOOTNAME
        LD      DE,BOOTFCB+1
        LD      B,11
IBFNAME:
        LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,IBFNAME
        RET

;----------------------- CONTROLLED DISK RUN ---------------------------
; Order is important.  Look at the blank ALV before making a file.  Keep the
; make/write/erase test next to the trace; selecting other media after the
; directory has changed may make a removable disk read-only.  SETRESULT is
; called only after the complete check has returned.
RUNCONTROL:
        XOR     A
        LD      E,A
        LD      C,32
        CALL    BDOS
        ; Throw away old disk state before looking at ALV or DPB.  The
        ; operator may have changed or protected the scratch disk.
        LD      C,13
        CALL    BDOS
        CALL    SELECTSCR
        ; Remove our work file if a former run was interrupted.
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        LD      DE,R0424
        CALL    PUTS
        CALL    T0424
        LD      HL,CASES+8
        LD      DE,V0424
        CALL    SETRESULT
        LD      DE,R0425
        CALL    PUTS
        CALL    T0425
        LD      HL,CASES+16
        LD      DE,V0425
        CALL    SETRESULT
        LD      DE,R0426
        CALL    PUTS
        CALL    T0426
        CALL    SHOW0426
        LD      HL,CASES+24
        LD      DE,V0426
        CALL    SETRESULT
        LD      DE,R0431
        CALL    PUTS
        CALL    T0431
        LD      HL,CASES+64
        LD      DE,V0431
        CALL    SETRESULT
        LD      DE,R0432
        CALL    PUTS
        CALL    T0432
        LD      HL,CASES+72
        LD      DE,V0432
        CALL    SETRESULT
        LD      DE,R0433
        CALL    PUTS
        CALL    T0433
        LD      HL,CASES+80
        LD      DE,V0433
        CALL    SETRESULT
        LD      DE,R0427
        CALL    PUTS
        CALL    T0427
        LD      HL,CASES+32
        LD      DE,V0427
        CALL    SETRESULT
        LD      DE,RTRACE
        CALL    PUTS
        CALL    RUNTRACE
        OR      A
        LD      B,7
        JP      NZ,RCREM
        LD      A,(TRACECOUNT)
        ADD     A,B
        LD      B,A
RCREM:  LD      A,(REMCNT)
        SUB     B
        LD      (REMCNT),A
        CALL    RESTENV
        RET

SELECTSCR:
        LD      A,(SCRDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        RET

; Save current DPB and ALV addresses.  Null or malformed objects fail here.
GETMETA:
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (DPBPTR),HL
        CALL    VALIDDPB
        OR      A
        RET     NZ
        LD      C,27
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (ALVPTR),HL
        XOR     A
        RET

;---------------------------- CHECK DPB --------------------------------
; Entry: HL -> 15-byte DPB.  No particular disk size is assumed.  Check SPT,
; BSH/BLM, DSM, DRM and the directory reservation mask for agreement.
; Exit: A=0 good, A=1 bad.  HL preserved.
VALIDDPB:
        PUSH    HL
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,VDFAIL
        INC     HL
        LD      B,(HL)             ; BSH
        LD      A,B
        CP      8
        JP      NC,VDFAIL
        LD      A,1
VDSH:  DEC     B
        JP      M,VDSHDONE
        ADD     A,A
        JP      VDSH
VDSHDONE:
        DEC     A
        INC     HL
        CP      (HL)               ; BLM
        JP      NZ,VDFAIL
        INC     HL                 ; EXM
        INC     HL                 ; DSM low
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,VDFAIL
        INC     HL                 ; DRM low
        LD      A,(HL)
        INC     HL
        OR      (HL)
        JP      Z,VDFAIL
        INC     HL                 ; AL0
        LD      A,(HL)
        INC     HL                 ; AL1
        OR      (HL)
        JP      Z,VDFAIL
        POP     HL
        XOR     A
        RET
VDFAIL:POP     HL
TFAIL: LD      A,1
        RET

T0424: CALL    SELECTSCR
        CALL    GETMETA
        RET

;---------------------------- CHECK ALV --------------------------------
; A SCRATCH /BLANK disk has only its directory blocks in use.  First see that
; all following ALV bytes are zero; then compare the first two with AL0/AL1.
T0425: CALL    SELECTSCR
        CALL    GETMETA
        OR      A
        RET     NZ
        CALL    ALVLENGTH
        LD      A,D
        OR      A
        JP      NZ,TFAIL
        LD      A,E
        CP      2
        JP      C,TFAIL
        LD      B,A
        LD      HL,(ALVPTR)
        INC     HL
        INC     HL
        DEC     B
        DEC     B
T25LP: LD      A,B
        OR      A
        JP      Z,TPASS
        LD      A,(HL)
        OR      A
        JP      NZ,TFAIL
        INC     HL
        DEC     B
        JP      T25LP

T0426: CALL    SELECTSCR
        XOR     A
        LD      (T26AL0),A
        LD      (T26AL1),A
        LD      (T26AV0),A
        LD      (T26AV1),A
        CALL    GETMETA
        OR      A
        RET     NZ
        LD      HL,(DPBPTR)
        LD      DE,9
        ADD     HL,DE
        LD      B,(HL)             ; AL0
        LD      A,B
        LD      (T26AL0),A
        INC     HL
        LD      C,(HL)             ; AL1
        LD      A,C
        LD      (T26AL1),A
        LD      HL,(ALVPTR)
        LD      A,(HL)
        LD      (T26AV0),A
        CP      B
        JP      NZ,TFAIL
        INC     HL
        LD      A,(HL)
        LD      (T26AV1),A
        CP      C
        JP      NZ,TFAIL
TPASS: XOR     A
        RET

; Preserve the test result in A while exposing the exact 0426 operands.
SHOW0426:
        PUSH    AF
        LD      DE,T26MSG1
        CALL    PUTS
        LD      A,(T26AL0)
        CALL    PUTHEX8
        LD      A,(T26AL1)
        CALL    PUTHEX8
        LD      DE,T26MSG2
        CALL    PUTS
        LD      A,(T26AV0)
        CALL    PUTHEX8
        LD      A,(T26AV1)
        CALL    PUTHEX8
        LD      DE,CRLF
        CALL    PUTS
        POP     AF
        RET

; Return DE=(DSM/8)+1, number of bytes occupied by this ALV.
ALVLENGTH:
        LD      HL,(DPBPTR)
        LD      DE,5
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        XOR     A
        LD      A,D
        RRA
        LD      D,A
        LD      A,E
        RRA
        LD      E,A
        XOR     A
        LD      A,D
        RRA
        LD      D,A
        LD      A,E
        RRA
        LD      E,A
        XOR     A
        LD      A,D
        RRA
        LD      D,A
        LD      A,E
        RRA
        LD      E,A
        INC     DE
        RET

;----------------------- ONE-BLOCK ALV TEST ----------------------------
; Make BTBIO.TMP and write one record.  Decode its first allocation entry
; from the FCB and see that the corresponding ALV bit came on.  Erase the
; file, obtain the ALV again, and see that the same bit went off.
T0427: CALL    SELECTSCR
        CALL    GETMETA
        OR      A
        RET     NZ
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS                ; remove stale interrupted-run fixture
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        LD      DE,E27MAKE
        JP      Z,T27ABORT
        LD      DE,TESTDMA
        LD      C,26
        CALL    BDOS
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        LD      DE,E27WRITE
        JP      NZ,T27ABORT
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        LD      DE,E27CLOSE
        JP      Z,T27ABORT
        CALL    FCBLOCK
        EX      DE,HL
        LD      (TESTBLK),HL
        EX      DE,HL
        LD      A,D
        OR      E
        JP      NZ,T27HAVE
        LD      DE,E27BLOCK
        JP      T27ABORT
T27HAVE:
        PUSH    DE
        LD      DE,D27BLOCK
        CALL    PUTS
        POP     DE
        CALL    ALVBIT
        OR      A
        LD      DE,E27SET
        JP      Z,T27ABORT
        LD      DE,D27SET
        CALL    PUTS
        LD      A,1
        LD      (T27WROTE),A
        JP      T27DELETE
T27DELETE:
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        CP      0FFH
        LD      DE,E27DELETE
        JP      Z,T27ERR
        LD      DE,D27DELETE
        CALL    PUTS
        LD      C,27
        CALL    BDOS
        LD      (ALVPTR),HL
        LD      HL,(TESTBLK)
        EX      DE,HL
        CALL    ALVBIT
        LD      B,A
        LD      A,(T27WROTE)
        OR      A
        LD      DE,E27STATE
        JP      Z,T27ERR
        LD      A,B
        OR      A
        LD      DE,E27CLEAR
        JP      NZ,T27ERR
        XOR     A
        RET
T27ABORT:
        PUSH    DE
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        POP     DE
T27ERR:CALL    PUTS
        JP      TFAIL

INITFCB:
        LD      HL,TESTFCB+1
        LD      B,35
        XOR     A
IFCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,IFCLR
        LD      HL,TNAME
        LD      DE,TESTFCB+1
        LD      B,11
IFNAME:LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,IFNAME
        RET

; Return first FCB allocation entry in DE.  DSM selects byte or word form.
FCBLOCK:
        LD      HL,(DPBPTR)
        LD      DE,6
        ADD     HL,DE
        LD      A,(HL)             ; DSM high
        OR      A
        LD      HL,TESTFCB+16
        JP      NZ,FBWORD
        LD      E,(HL)
        LD      D,0
        RET
FBWORD:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        RET

; Test allocation block DE in current ALV.  Exit A=0 clear, A<>0 set.
ALVBIT:LD      HL,(ALVPTR)
ABBYTE:LD      A,D
        OR      A
        JP      NZ,ABSUB
        LD      A,E
        CP      8
        JP      C,ABMASK
ABSUB: LD      A,E
        SUB     8
        LD      E,A
        LD      A,D
        SBC     A,0
        LD      D,A
        INC     HL
        JP      ABBYTE
ABMASK:LD      B,E
        LD      C,080H
ABSHIFT:
        LD      A,B
        OR      A
        JP      Z,ABTEST
        LD      A,C
        OR      A
        RRA
        LD      C,A
        DEC     B
        JP      ABSHIFT
ABTEST:LD      A,(HL)
        AND     C
        RET

T0431: CALL    CAPTURE2
        RET
T0432: CALL    CAPTURE2
        RET

; Check complete DPBs for old and scratch drives.  Shared DPBs are permitted;
; a bad pointer or bad contents are not.
CAPTURE2:
        LD      A,(OLDDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (DPBOLD),HL
        CALL    VALIDDPB
        OR      A
        RET     NZ
        LD      DE,DPBCOPY1
        CALL    COPY15
        CALL    SELECTSCR
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      (DPBSCR),HL
        CALL    VALIDDPB
        OR      A
        RET     NZ
        LD      DE,DPBCOPY2
        CALL    COPY15
        XOR     A
        RET
COPY15:LD      B,15
C15LP: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,C15LP
        RET

;------------------------- LIVE DPB TEST -------------------------------
; Change OFF high in the live DPB, ask for the DPB again, and verify the
; changed byte through the returned address.  Restore the byte BEFORE making
; another disk call.  MODPTR is kept solely for this immediate restoration.
T0433: CALL    SELECTSCR
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        JP      Z,TFAIL
        LD      DE,14
        ADD     HL,DE
        LD      (MODPTR),HL
        LD      A,(HL)
        LD      (MODORIG),A
        XOR     1
        LD      (MODNEW),A
        LD      (HL),A
        LD      C,31
        CALL    BDOS
        LD      DE,14
        ADD     HL,DE
        LD      A,(HL)
        LD      B,A
        LD      HL,(MODPTR)
        LD      A,(MODORIG)
        LD      (HL),A
        LD      A,(MODNEW)
        CP      B
        JP      NZ,TFAIL
        XOR     A
        RET

;========================== DISK TRACE ================================
;
; Put seven shims in series with SELDSK, SETTRK, SETSEC, SETDMA, READ,
; WRITE and SECTRAN.  Only the two address bytes of each public JMP are
; changed.  PREPTRAMP puts the saved addresses into private CALLs or JMPs
; below; this avoids calling through a vector which now points back at us.
;
; TRACEINSTALL may fail after any patch.  PATCHCNT tells TRACERESTORE how
; much must be undone.  RUNTRACE has no exit which bypasses restoration.
;
RUNTRACE:
        CALL    TRACEINSTALL
        OR      A
        RET     NZ
        CALL    TRACEWORK
        CALL    TESTSEL
        CALL    TRACERESTORE
        CALL    TRACEJUDGE
        RET

TRACEINSTALL:
        XOR     A
        LD      (PATCHCNT),A
        LD      HL,(0001H)
        DEC     HL
        DEC     HL
        DEC     HL
        LD      (BIOSBASE),HL
        LD      DE,28
        ADD     HL,DE
        LD      DE,WRSEL
        LD      BC,ORGSEL
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,31
        ADD     HL,DE
        LD      DE,WRTRK
        LD      BC,ORGTRK
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,34
        ADD     HL,DE
        LD      DE,WRSEC
        LD      BC,ORGSEC
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,37
        ADD     HL,DE
        LD      DE,WRDMA
        LD      BC,ORGDMA
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,40
        ADD     HL,DE
        LD      DE,WRREAD
        LD      BC,ORGREAD
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,43
        ADD     HL,DE
        LD      DE,WRWRITE
        LD      BC,ORGWRITE
        CALL    PATCHONE
        OR      A
        JP      NZ,TIBAD
        LD      HL,(BIOSBASE)
        LD      DE,49
        ADD     HL,DE
        LD      DE,WRXLT
        LD      BC,ORGXLT
        CALL    PATCHONE
        OR      A
        RET     NZ
        CALL    PREPTRAMP
        XOR     A
        RET
TIBAD: CALL    TRACERESTORE
        LD      DE,TRACEBAD
        CALL    PUTS
        LD      A,1
        RET

;-------------------------- PATCH ONE JMP ------------------------------
; Entry: HL -> low address byte of public JMP
;        DE = address of shim
;        BC -> word which receives old address
; Exit:  A=0 installed, A=1 refused
;
; Check opcode, save old word, install new word, then read it back.  On a
; read-only or otherwise unsuitable vector, replace the old word at once.
PATCHONE:
        LD      (PATCHLOC),HL
        EX      DE,HL
        LD      (PATCHNEW),HL
        LD      H,B
        LD      L,C
        LD      (PATCHSAVE),HL
        LD      HL,(PATCHLOC)
        DEC     HL
        LD      A,(HL)
        CP      0C3H
        JP      NZ,TFAIL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      HL,(PATCHSAVE)
        LD      (HL),E
        INC     HL
        LD      (HL),D
        LD      HL,(PATCHNEW)
        EX      DE,HL
        LD      HL,(PATCHLOC)
        LD      (HL),E
        INC     HL
        LD      (HL),D
        DEC     HL
        LD      A,(HL)
        CP      E
        JP      NZ,POREST
        INC     HL
        LD      A,(HL)
        CP      D
        JP      NZ,POREST
        LD      A,(PATCHCNT)
        INC     A
        LD      (PATCHCNT),A
        XOR     A
        RET
POREST:LD      HL,(PATCHSAVE)
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      HL,(PATCHLOC)
        LD      A,E
        LD      (HL),A
        INC     HL
        LD      A,D
        LD      (HL),A
        JP      TFAIL

PREPTRAMP:
        ; Fill the address fields of our private transfers.  These are the
        ; escape route from each shim to the original BIOS routine.
        LD      HL,ORGSEL
        LD      DE,CSEL+1
        CALL    COPYWORD
        LD      HL,ORGTRK
        LD      DE,JTRK+1
        CALL    COPYWORD
        LD      HL,ORGSEC
        LD      DE,JSEC+1
        CALL    COPYWORD
        LD      HL,ORGDMA
        LD      DE,JDMA+1
        CALL    COPYWORD
        LD      HL,ORGREAD
        LD      DE,CREAD+1
        CALL    COPYWORD
        LD      HL,ORGWRITE
        LD      DE,CWRITE+1
        CALL    COPYWORD
        LD      HL,ORGXLT
        LD      DE,CXLT+1
COPYWORD:
        LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        LD      A,(HL)
        LD      (DE),A
        RET

TRACERESTORE:
        ; Unwind in reverse order.  PATCHCNT also makes a partial install safe.
        LD      A,(PATCHCNT)
        CP      7
        CALL    NC,RXLT
        LD      A,(PATCHCNT)
        CP      6
        CALL    NC,RWRITE
        LD      A,(PATCHCNT)
        CP      5
        CALL    NC,RREAD
        LD      A,(PATCHCNT)
        CP      4
        CALL    NC,RDMA
        LD      A,(PATCHCNT)
        CP      3
        CALL    NC,RSEC
        LD      A,(PATCHCNT)
        CP      2
        CALL    NC,RTRK
        LD      A,(PATCHCNT)
        OR      A
        CALL    NZ,RSEL
        XOR     A
        LD      (PATCHCNT),A
        RET
RXLT:  LD      DE,49
        LD      BC,ORGXLT
        JP      RESTONE
RWRITE:LD      DE,43
        LD      BC,ORGWRITE
        JP      RESTONE
RREAD: LD      DE,40
        LD      BC,ORGREAD
        JP      RESTONE
RDMA:  LD      DE,37
        LD      BC,ORGDMA
        JP      RESTONE
RSEC:  LD      DE,34
        LD      BC,ORGSEC
        JP      RESTONE
RTRK:  LD      DE,31
        LD      BC,ORGTRK
        JP      RESTONE
RSEL:  LD      DE,28
        LD      BC,ORGSEL
RESTONE:
        LD      HL,(BIOSBASE)
        ADD     HL,DE
        LD      A,(BC)
        LD      (HL),A
        INC     BC
        INC     HL
        LD      A,(BC)
        LD      (HL),A
        RET

;====================== CHARACTER INTERCEPT ===========================
;
; CONOUT, LIST, PUNCH and READER are replaced by counting stubs.  They do
; not call the old device routine: the object here is to see which logical
; entry BDOS selected and what byte it supplied.  This also keeps test bytes
; away from an unknown printer, punch or modem.  WREADER returns ^Z.
;
; SETDMA is different.  WCDMA counts the call and jumps on to the old SETDMA;
; otherwise a later BDOS operation would run with a false DMA address.
; JOREADER holds a separate path to the real READER for test 0471.
CHARINSTALL:
        XOR     A
        LD      (PATCHCNT),A
        CALL    BIOSADDR
        LD      (BIOSBASE),HL
        LD      DE,13
        ADD     HL,DE
        LD      DE,WCONOUT
        LD      BC,ORGCO
        CALL    PATCHONE
        OR      A
        JP      NZ,CIBAD
        LD      HL,(BIOSBASE)
        LD      DE,16
        ADD     HL,DE
        LD      DE,WLIST
        LD      BC,ORGLIST
        CALL    PATCHONE
        OR      A
        JP      NZ,CIBAD
        LD      HL,(BIOSBASE)
        LD      DE,19
        ADD     HL,DE
        LD      DE,WPUNCH
        LD      BC,ORGPUNCH
        CALL    PATCHONE
        OR      A
        JP      NZ,CIBAD
        LD      HL,(BIOSBASE)
        LD      DE,22
        ADD     HL,DE
        LD      DE,WREADER
        LD      BC,ORGREADER
        CALL    PATCHONE
        OR      A
        JP      NZ,CIBAD
        LD      HL,(BIOSBASE)
        LD      DE,37
        ADD     HL,DE
        LD      DE,WCDMA
        LD      BC,ORGCDMA
        CALL    PATCHONE
        OR      A
        RET     NZ
        LD      HL,ORGCDMA
        LD      DE,JCDMA+1
        CALL    COPYWORD
        LD      HL,ORGREADER
        LD      DE,JOREADER+1
        CALL    COPYWORD
        XOR     A
        RET
CIBAD: CALL    CHARRESTORE
        LD      A,1
        RET

CHARRESTORE:
        LD      A,(PATCHCNT)
        CP      5
        CALL    NC,RCDMA
        LD      A,(PATCHCNT)
        CP      4
        CALL    NC,RCREADER
        LD      A,(PATCHCNT)
        CP      3
        CALL    NC,RCPUNCH
        LD      A,(PATCHCNT)
        CP      2
        CALL    NC,RCLIST
        LD      A,(PATCHCNT)
        OR      A
        CALL    NZ,RCCO
        XOR     A
        LD      (PATCHCNT),A
        RET
RCDMA: LD      DE,37
        LD      BC,ORGCDMA
        JP      RESTONE
RCREADER:
        LD      DE,22
        LD      BC,ORGREADER
        JP      RESTONE
RCPUNCH:
        LD      DE,19
        LD      BC,ORGPUNCH
        JP      RESTONE
RCLIST:LD      DE,16
        LD      BC,ORGLIST
        JP      RESTONE
RCCO:  LD      DE,13
        LD      BC,ORGCO
        JP      RESTONE

; The output stubs save the first two bytes and a total count.  Do not use A
; as the character; C must be sampled before doing the bookkeeping.
WCONOUT:
        LD      A,(COCNT)
        OR      A
        JP      NZ,WCO2
        LD      A,C
        LD      (COBYTE1),A
        JP      WCOFLAG
WCO2:  CP      1
        JP      NZ,WCOFLAG
        LD      A,C
        LD      (COBYTE2),A
WCOFLAG:
        LD      A,C
        CP      9
        JP      NZ,WCOCNT
        LD      A,1
        LD      (COTAB),A
WCOCNT:LD      A,(COCNT)
        INC     A
        LD      (COCNT),A
        RET
WLIST: LD      A,(LISTCNT)
        OR      A
        JP      NZ,WLI2
        LD      A,C
        LD      (LIST1),A
        JP      WLICNT
WLI2:  CP      1
        JP      NZ,WLICNT
        LD      A,C
        LD      (LIST2),A
WLICNT:LD      A,C
        LD      (LASTLIST),A
        LD      A,(LISTCNT)
        INC     A
        LD      (LISTCNT),A
        RET
WPUNCH:
        LD      A,(PUNCHCNT)
        OR      A
        JP      NZ,WPU2
        LD      A,C
        LD      (PUNCH1),A
        JP      WPUCNT
WPU2:  CP      1
        JP      NZ,WPUCNT
        LD      A,C
        LD      (PUNCH2),A
WPUCNT:LD      A,(PUNCHCNT)
        INC     A
        LD      (PUNCHCNT),A
        RET
WREADER:
        LD      A,(READERCNT)
        INC     A
        LD      (READERCNT),A
        LD      A,01AH
        RET
WCDMA: LD      A,(CDMACNT)
        INC     A
        LD      (CDMACNT),A
JCDMA: JP      0000H
JOREADER:
        JP      0000H

CHARWORK:
        ; Clear the notebook and assume failure.  Each section clears only
        ; its own result byte after every count and saved character agrees.
        LD      HL,CHARLOG
        LD      B,CHAREND-CHARLOG
        XOR     A
CWCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,CWCLR
        LD      A,1
        LD      (R0439),A
        LD      (R0445),A
        LD      (R0448),A
        LD      (R0470),A
        LD      (R0473),A
        LD      C,7
        CALL    BDOS
        LD      (CHIOBORIG),A

        ; 0439 -- Function 4 must deliver E unchanged in BIOS register C.
        LD      E,'G'
        LD      C,4
        CALL    BDOS
        LD      E,9
        LD      C,4
        CALL    BDOS
        LD      A,(PUNCHCNT)
        CP      2
        JP      NZ,CW45
        LD      A,(PUNCH1)
        CP      'G'
        JP      NZ,CW45
        LD      A,(PUNCH2)
        CP      9
        JP      NZ,CW45
        XOR     A
        LD      (R0439),A

        ; 0445 -- Three IOBYTE values must still dispatch functions 3/4/5 to
        ; the fixed logical READER/PUNCH/LIST public entries.
CW45:  XOR     A
        LD      (READERCNT),A
        LD      (PUNCHCNT),A
        LD      (LISTCNT),A
        LD      A,00H
        CALL    ROUTESET
        LD      A,0A5H
        CALL    ROUTESET
        LD      A,0FFH
        CALL    ROUTESET
        LD      A,(CHIOBORIG)
        LD      E,A
        LD      C,8
        CALL    BDOS
        LD      A,(READERCNT)
        CP      3
        JP      NZ,CW73
        LD      A,(PUNCHCNT)
        CP      3
        JP      NZ,CW73
        LD      A,(LISTCNT)
        CP      3
        JP      NZ,CW73
        XOR     A
        LD      (R0445),A

        ; 0470 -- Every logical output vector receives a graphic byte and
        ; a control byte unchanged in C.  The temporary entries are the exact
        ; logical boundary and deliberately suppress physical device output.
CW70:  XOR     A
        LD      (COCNT),A
        LD      (LISTCNT),A
        LD      (PUNCHCNT),A
        CALL    BIOSADDR
        PUSH    HL
        LD      DE,12
        ADD     HL,DE
        LD      C,'O'
        CALL    CALLHL
        POP     HL
        PUSH    HL
        LD      DE,12
        ADD     HL,DE
        LD      C,7
        CALL    CALLHL
        POP     HL
        PUSH    HL
        LD      DE,15
        ADD     HL,DE
        LD      C,'L'
        CALL    CALLHL
        POP     HL
        PUSH    HL
        LD      DE,15
        ADD     HL,DE
        LD      C,12
        CALL    CALLHL
        POP     HL
        PUSH    HL
        LD      DE,18
        ADD     HL,DE
        LD      C,'P'
        CALL    CALLHL
        POP     HL
        LD      DE,18
        ADD     HL,DE
        LD      C,27
        CALL    CALLHL
        LD      A,(COCNT)
        CP      2
        JP      NZ,CW73
        LD      A,(COBYTE1)
        CP      'O'
        JP      NZ,CW73
        LD      A,(COBYTE2)
        CP      7
        JP      NZ,CW73
        LD      A,(LISTCNT)
        CP      2
        JP      NZ,CW73
        LD      A,(LIST1)
        CP      'L'
        JP      NZ,CW73
        LD      A,(LIST2)
        CP      12
        JP      NZ,CW73
        LD      A,(PUNCHCNT)
        CP      2
        JP      NZ,CW73
        LD      A,(PUNCH1)
        CP      'P'
        JP      NZ,CW73
        LD      A,(PUNCH2)
        CP      27
        JP      NZ,CW73
        XOR     A
        LD      (R0470),A

        ; 0473: direct CONOUT receives raw TAB; BDOS Function 2 expands it
        ; into one or more spaces before the same logical BIOS boundary.
CW73:  XOR     A
        LD      (COCNT),A
        LD      (COTAB),A
        CALL    BIOSADDR
        LD      DE,12
        ADD     HL,DE
        LD      C,9
        CALL    CALLHL
        LD      A,(COCNT)
        CP      1
        JP      NZ,CWSENT
        LD      A,(COBYTE1)
        CP      9
        JP      NZ,CWSENT
        XOR     A
        LD      (COCNT),A
        LD      (COTAB),A
        LD      E,9
        LD      C,2
        CALL    BDOS
        LD      A,(COCNT)
        OR      A
        JP      Z,CWSENT
        LD      A,(COTAB)
        OR      A
        JP      NZ,CWSENT
        XOR     A
        LD      (R0473),A

        ; 0448: no character operation may select or overwrite DMA.
CWSENT:CALL    CHECKSENT
        LD      (R0448),A
        RET

ROUTESET:
        LD      E,A
        LD      C,8
        CALL    BDOS
        LD      C,3
        CALL    BDOS
        LD      E,'P'
        LD      C,4
        CALL    BDOS
        LD      E,'L'
        LD      C,5
        CALL    BDOS
        RET

CHECKSENT:
        LD      A,(CDMACNT)
        OR      A
        JP      NZ,TFAIL
        LD      HL,DMAPAT1
        LD      DE,0080H
        LD      B,4
        CALL    CMPEQ
        OR      A
        RET     NZ
        LD      HL,DMAPAT2
        LD      DE,ALTDMA
        LD      B,4
CMPEQ: LD      A,(DE)
        CP      (HL)
        JP      NZ,TFAIL
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,CMPEQ
        XOR     A
        RET

CHJUDGE:
        LD      A,(R0439)
        LD      HL,CASES+112
        LD      DE,V0439
        CALL    SETRESULT
        LD      A,(R0445)
        LD      HL,CASES+136
        LD      DE,V0445
        CALL    SETRESULT
        LD      A,(R0448)
        LD      HL,CASES+152
        LD      DE,V0448
        CALL    SETRESULT
        LD      A,(R0470)
        LD      HL,CASES+328
        LD      DE,V0470
        CALL    SETRESULT
        LD      A,(R0473)
        LD      HL,CASES+352
        LD      DE,V0473
        CALL    SETRESULT
        LD      A,7
        LD      (CHCOUNT),A
        RET

;---------------------- TWO-PASS READER TEST ---------------------------
; Pass one calls the saved real READER with the normal assignment and writes
; BTRDR.DAT.  Pass two, after the operator changes STAT, calls it again for
; the absent-device result.  JOREADER bypasses our ^Z intercept.
READERWORK:
        CALL    LOADRDREC
        LD      A,(RDSTAGE)
        CP      2
        RET     Z
        CP      1
        JP      Z,RWAASK
RWNASK:LD      DE,RDNORMAL
        CALL    PUTS
        CALL    GETKEY
        PUSH    AF
        LD      DE,CRLF
        CALL    PUTS
        POP     AF
        CP      'Q'
        RET     Z
        CP      'Y'
        JP      NZ,RWNASK
        CALL    JOREADER
        LD      (RDNBYTE),A
        CP      'R'
        JP      NZ,RWNFAIL
        LD      A,1
        LD      (RDSTAGE),A
        CALL    SAVERDREC
        OR      A
        JP      NZ,RDSTOREBAD
        LD      DE,RDNEXT
        CALL    PUTS
        RET
RWNFAIL:
        LD      A,1
        LD      HL,CASES+336
        LD      DE,V0471
        CALL    SETRESULT
        LD      A,(CHCOUNT)
        INC     A
        LD      (CHCOUNT),A
        RET
RWAASK:LD      DE,RDABSENT
        CALL    PUTS
        CALL    GETKEY
        PUSH    AF
        LD      DE,CRLF
        CALL    PUTS
        POP     AF
        CP      'Q'
        RET     Z
        CP      'Y'
        JP      NZ,RWAASK
        CALL    JOREADER
        LD      (RDABYTE),A
        LD      A,1
        LD      (R0471),A
        LD      A,(RDABYTE)
        CP      01AH
        JP      NZ,RWJUDGE
        XOR     A
        LD      (R0471),A
        LD      A,2
        LD      (RDSTAGE),A
        CALL    SAVERDREC
        OR      A
        JP      NZ,RDSTOREBAD
RWJUDGE:
        LD      A,(R0471)
        LD      HL,CASES+336
        LD      DE,V0471
        CALL    SETRESULT
        LD      A,(CHCOUNT)
        INC     A
        LD      (CHCOUNT),A
        RET
RDSTOREBAD:
        LD      DE,RDSTORE
        CALL    PUTS
        RET

TRACEWORK:
        ; Make the ordinary file traffic which drives the shims.  BTBIO.TMP
        ; is erased on entry and on every useful exit.
        LD      HL,TRACELOG
        LD      B,TRACEEND-TRACELOG
        XOR     A
TWCLR: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,TWCLR
        CALL    SELECTSCR
        LD      DE,TWMAKE
        CALL    PUTS
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        CALL    INITFCB
        LD      DE,TESTFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,TWFAIL
        LD      DE,TWWR1
        CALL    PUTS
        LD      DE,TESTDMA
        LD      C,26
        CALL    BDOS
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,TWFAIL
        LD      DE,TWWR2
        CALL    PUTS
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,TWFAIL
        CALL    BOUNDARYWORK
        CALL    TRANSFERWORK
        LD      DE,TWCLOSE
        CALL    PUTS
        LD      DE,TESTFCB
        LD      C,16
        CALL    BDOS
        CP      0FFH
        JP      Z,TWFAIL
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        CP      0FFH
        JP      Z,TWFAIL
        XOR     A
        RET
TWFAIL:LD      A,1
        LD      (IOFAIL),A
        LD      DE,TESTFCB
        LD      C,19
        CALL    BDOS
        RET

;---------------------- TRACK BOUNDARY TEST ----------------------------
; Extend the open file until SETTRK advances.  Before each write, decode the
; FCB allocation entry and record position and calculate:
;
;       TRACK = ((BLOCK << BSH) + RECORD-IN-BLOCK) / SPT + OFF
;
; Compare this independent value with the last value caught by WRTRK.  Stop
; after SPT+1 writes if no adjacent-track change is seen.  A zero OFF cannot
; exercise the reserved-track addition and leaves 0453 unrun.
BOUNDARYWORK:
        LD      A,1
        LD      (OFFRESULT),A
        XOR     A
        LD      (OFFAVAIL),A
        LD      (PREVVALID),A
        LD      C,31
        CALL    BDOS
        LD      A,H
        OR      L
        RET     Z
        LD      A,(HL)
        LD      (BWSPT),A
        INC     HL
        LD      A,(HL)
        LD      (BWSPT+1),A
        INC     HL
        LD      A,(HL)
        LD      (BWBSH),A
        INC     HL
        LD      A,(HL)
        LD      (BWBLM),A
        INC     HL
        INC     HL
        INC     HL
        LD      A,(HL)             ; DSM high selects byte/word allocation
        LD      (BWDSMH),A
        LD      DE,7
        ADD     HL,DE              ; OFF low at DPB offset 13
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (BWOFF),HL
        EX      DE,HL
        LD      A,D
        OR      E
        RET     Z                  ; fixture has no reserved-track offset
        LD      HL,(BWSPT)
        LD      A,H
        OR      L
        RET     Z
        LD      A,1
        LD      (OFFAVAIL),A
        INC     HL                 ; at most SPT+1 writes reach a boundary
        LD      (WRLEFT),HL
BWLOOP:LD      A,(TESTFCB+32)
        LD      (RINDEX),A
        LD      DE,TESTFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,BWIOFAIL
        CALL    EXPECTTRACK
        OR      A
        RET     NZ
        LD      HL,(CURRENTTRK)
        PUSH    HL
        LD      HL,(LASTTRK)
        EX      DE,HL
        POP     HL
        LD      A,H
        CP      D
        JP      NZ,BWMAPFAIL
        LD      A,L
        CP      E
        JP      NZ,BWMAPFAIL
        LD      A,(PREVVALID)
        OR      A
        JP      Z,BWSTORE
        LD      HL,(PREVTRK)
        INC     HL
        PUSH    HL
        LD      HL,(CURRENTTRK)
        EX      DE,HL
        POP     HL
        LD      A,H
        CP      D
        JP      NZ,BWSTORE
        LD      A,L
        CP      E
        JP      NZ,BWSTORE
        XOR     A
        LD      (OFFRESULT),A
        RET
BWSTORE:
        LD      HL,(CURRENTTRK)
        LD      (PREVTRK),HL
        LD      A,1
        LD      (PREVVALID),A
        LD      HL,(WRLEFT)
        DEC     HL
        LD      (WRLEFT),HL
        LD      A,H
        OR      L
        JP      NZ,BWLOOP
        LD      DE,BWNOMSG
        CALL    PUTS
        RET
BWIOFAIL:
        LD      A,1
        LD      (IOFAIL),A
        RET
BWMAPFAIL:
        LD      DE,BWMAPMSG
        CALL    PUTS
        LD      HL,(CURRENTTRK)
        CALL    PUTHEX16
        LD      DE,BWACTMSG
        CALL    PUTS
        LD      HL,(LASTTRK)
        CALL    PUTHEX16
        LD      DE,CRLF
        CALL    PUTS
        LD      A,1
        RET

;---------------------- REAL TRANSFER TEST -----------------------------
; Fill one sector with 00,01,...7F and WRITE it through the saved BIOS entry.
; Clear memory, READ it back and compare all 128 bytes.  If /ALL requested
; the fault test, ask the operator to protect the disk and repeat the WRITE.
; The failing status must come from the BIOS--it is never manufactured here.
TRANSFERWORK:
        XOR     A
        LD      (XFERGOOD),A
        LD      (FAVAIL),A
        LD      HL,TESTDMA
        LD      B,128
TFILL: LD      (HL),A
        INC     A
        INC     HL
        DEC     B
        JP      NZ,TFILL
        LD      BC,TESTDMA
        CALL    JDMA
        LD      C,1               ; directory class requires immediate write
        CALL    CWRITE
        OR      A
        RET     NZ
        LD      HL,TESTDMA
        LD      B,128
        XOR     A
TZERO: LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,TZERO
        LD      BC,TESTDMA
        CALL    JDMA
        CALL    CREAD
        OR      A
        RET     NZ
        LD      HL,TESTDMA
        LD      B,128
        LD      C,0
TCMP:  LD      A,(HL)
        CP      C
        RET     NZ
        INC     C
        INC     HL
        DEC     B
        JP      NZ,TCMP
        LD      A,1
        LD      (XFERGOOD),A
        LD      A,(FAULTREQ)
        OR      A
        RET     Z
TFPROMPT:
        LD      DE,FAULTASK
        CALL    PUTS
        CALL    GETKEY
        PUSH    AF
        LD      DE,CRLF
        CALL    PUTS
        POP     AF
        CP      'Q'
        RET     Z
        CP      'Y'
        JP      NZ,TFPROMPT
        LD      BC,TESTDMA
        CALL    JDMA
        LD      C,1               ; force the protected physical transfer
        CALL    CWRITE
        LD      (FSTATUS),A
        ; This failure is the wanted result of 0457.  CWRITE quite properly
        ; put it in IOFAIL; remove it so it does not also fail trace 0449.
        XOR     A
        LD      (IOFAIL),A
TFREST:LD      DE,FAULTREST
        CALL    PUTS
        CALL    GETKEY
        PUSH    AF
        LD      DE,CRLF
        CALL    PUTS
        POP     AF
        CP      'Y'
        JP      NZ,TFREST
        LD      BC,TESTDMA
        CALL    JDMA
        LD      C,1               ; confirm physical writes work after restore
        CALL    CWRITE
        LD      (RSTATUS),A
        LD      A,1
        LD      (FAVAIL),A
        LD      DE,FSTATMSG
        CALL    PUTS
        LD      A,(FSTATUS)
        CALL    PUTHEX8
        LD      DE,RSTATMSG
        CALL    PUTS
        LD      A,(RSTATUS)
        CALL    PUTHEX8
        LD      DE,CRLF
        CALL    PUTS
        LD      A,(FSTATUS)
        OR      A
        JP      Z,TFFAIL
        LD      A,(RSTATUS)
        OR      A
        JP      NZ,TFFAIL
        XOR     A
        LD      (FRESULT),A
        RET
TFFAIL:LD      A,1
        LD      (FRESULT),A
        RET

EXPECTTRACK:
        ; Work out expected track without consulting LASTTRK.  RINDEX selects
        ; an allocation slot; DSM high says whether that slot is 8 or 16 bits.
        ; Repeated subtraction is used for the 16-bit divide by SPT so this
        ; remains plain 8080 code.
        LD      A,(RINDEX)
        LD      B,A
        LD      A,(BWBLM)
        AND     B
        LD      (RECPOS),A
        LD      A,(RINDEX)
        LD      B,A
        LD      A,(BWBSH)
        LD      C,A
        LD      A,B
ETSLOT:LD      B,A
        LD      A,C
        OR      A
        LD      A,B
        JP      Z,ETHAVESLOT
        OR      A
        RRA
        DEC     C
        JP      ETSLOT
ETHAVESLOT:
        LD      E,A
        LD      D,0
        LD      A,(BWDSMH)
        OR      A
        JP      Z,ETPTR
        LD      A,E
        ADD     A,A
        LD      E,A
ETPTR: LD      HL,TESTFCB+16
        ADD     HL,DE
        LD      E,(HL)
        LD      D,0
        LD      A,(BWDSMH)
        OR      A
        JP      Z,ETBLOCK
        INC     HL
        LD      D,(HL)
ETBLOCK:
        EX      DE,HL              ; HL = allocation block number
        LD      A,(BWBSH)
        LD      B,A
ETSHIFT:
        LD      A,B
        OR      A
        JP      Z,ETPOS
        ADD     HL,HL
        DEC     B
        JP      ETSHIFT
ETPOS: LD      A,(RECPOS)
        LD      E,A
        LD      D,0
        ADD     HL,DE              ; absolute logical sector after OFF
        PUSH    HL
        LD      HL,(BWSPT)
        LD      B,H
        LD      C,L
        POP     HL
        LD      DE,0               ; quotient track before OFF
ETDIV:
        LD      A,H
        CP      B
        JP      C,ETDIVDONE
        JP      NZ,ETSUB
        LD      A,L
        CP      C
        JP      C,ETDIVDONE
ETSUB: LD      A,L
        SUB     C
        LD      L,A
        LD      A,H
        SBC     A,B
        LD      H,A
        INC     DE
        JP      ETDIV
ETDIVDONE:
        LD      HL,(BWOFF)
        ADD     HL,DE
        LD      (CURRENTTRK),HL
        XOR     A
        RET

TRACEJUDGE:
        ; Comes here only after all public vectors have been restored.  Turn
        ; the trace notebook into individual report rows.
        LD      A,4
        LD      (TRACECOUNT),A
        LD      A,(TRKCNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(SECCNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(DMACNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(WRITECNT)
        OR      A
        JP      Z,TJ49F
        LD      A,(IOFAIL)
        OR      A
        JP      NZ,TJ49F
        XOR     A
        JP      TJ49S
TJ49F: LD      A,1
TJ49S: LD      HL,CASES+160
        LD      DE,V0449
        CALL    SETRESULT
        LD      A,(CONFSEL)
        LD      B,A
        LD      A,(ABSENTSEL)
        AND     B
        JP      Z,TJ50SKIP
        XOR     A
        LD      HL,CASES+168
        LD      DE,V0450
        CALL    SETRESULT
        LD      A,5
        LD      (TRACECOUNT),A
TJ50SKIP:
        LD      A,(OFFAVAIL)
        OR      A
        JP      Z,TJ53SKIP
        LD      A,(OFFRESULT)
        LD      HL,CASES+192
        LD      DE,V0453
        CALL    SETRESULT
        LD      A,(TRACECOUNT)
        INC     A
        LD      (TRACECOUNT),A
TJ53SKIP:
        LD      A,(XLTCHAIN)
        XOR     1
        LD      HL,CASES+200
        LD      DE,V0454
        CALL    SETRESULT
        LD      A,(APPDMA)
        LD      B,A
        LD      A,(DIRDMA)
        AND     B
        XOR     1
        LD      HL,CASES+216
        LD      DE,V0456
        CALL    SETRESULT
        LD      A,(FAVAIL)
        OR      A
        JP      Z,TJ57SKIP
        LD      A,(FRESULT)
        LD      B,A
        LD      A,(XFERGOOD)
        XOR     1
        OR      B
        LD      HL,CASES+224
        LD      DE,V0457
        CALL    SETRESULT
        LD      A,(TRACECOUNT)
        INC     A
        LD      (TRACECOUNT),A
TJ57SKIP:
        LD      A,(WRTYPES)
        CP      7
        LD      A,0
        JP      Z,TJ58S
        INC     A
TJ58S: LD      HL,CASES+232
        LD      DE,V0458
        CALL    SETRESULT
        XOR     A
        RET

; Call old SELDSK through CSEL.  Scratch drive must return a DPH; at least
; one other A-P number must be refused.  Re-select scratch before returning.
TESTSEL:
        LD      A,(SCRDRV)
        LD      C,A
        CALL    CSEL
        LD      A,H
        OR      L
        JP      Z,TSABS
        LD      A,1
        LD      (CONFSEL),A
TSABS: LD      C,15
TSLOOP:LD      A,C
        LD      B,A
        LD      A,(SCRDRV)
        CP      B
        JP      Z,TSNEXT
        CALL    CSEL
        LD      A,H
        OR      L
        JP      NZ,TSNEXT
        LD      A,1
        LD      (ABSENTSEL),A
        JP      TSREST
TSNEXT:DEC     C
        JP      P,TSLOOP
TSREST:CALL    SELECTSCR
        RET

;---------------------------- TRACE SHIMS ------------------------------
; Save arguments, counts and return status, then continue at the old BIOS
; routine.  JTRK/JSEC/JDMA are JMPs so the old routine returns directly to
; its original caller.  CSEL/CREAD/CWRITE/CXLT are CALLs because their return
; values must also be recorded.
WRSEL: LD      A,C
        LD      (LASTSEL),A
CSEL:  CALL    0000H
        LD      (SELRESULT),HL
        LD      A,(SELCNT)
        INC     A
        LD      (SELCNT),A
        RET
WRTRK: PUSH    HL
        LD      H,B
        LD      L,C
        LD      (LASTTRK),HL
        POP     HL
        PUSH    AF
        LD      A,(TRKCNT)
        INC     A
        LD      (TRKCNT),A
        POP     AF
JTRK:  JP      0000H
WRSEC: PUSH    HL
        LD      H,B
        LD      L,C
        LD      (LASTSEC),HL
        ; A valid SECTRAN result must be the value next handed to SETSEC.
        LD      A,(XLTOUT)
        CP      C
        JP      NZ,WSNO
        LD      A,(XLTOUT+1)
        CP      B
        JP      NZ,WSNO
        LD      A,(XLTVALID)
        OR      A
        JP      Z,WSNO
        LD      A,1
        LD      (XLTCHAIN),A
WSNO:  XOR     A
        LD      (XLTVALID),A
        POP     HL
        PUSH    AF
        LD      A,(SECCNT)
        INC     A
        LD      (SECCNT),A
        POP     AF
JSEC:  JP      0000H
WRDMA: PUSH    HL
        LD      H,B
        LD      L,C
        LD      (LASTDMA),HL
        ; Distinguish our application buffer from BDOS directory buffers.
        LD      HL,TESTDMA
        LD      A,L
        CP      C
        JP      NZ,WDOTHER
        LD      A,H
        CP      B
        LD      A,1
        JP      Z,WDAPP
WDOTHER:
        LD      A,1
        LD      (DIRDMA),A
        JP      WDDONE
WDAPP: LD      (APPDMA),A
WDDONE:POP     HL
        PUSH    AF
        LD      A,(DMACNT)
        INC     A
        LD      (DMACNT),A
        POP     AF
JDMA:  JP      0000H
WRREAD:
CREAD: CALL    0000H
        OR      A
        JP      Z,WRROK
        LD      (IOFAIL),A
WRROK: LD      (WRSTATUS),A
        LD      A,(READCNT)
        INC     A
        LD      (READCNT),A
        LD      A,(WRSTATUS)
        RET
WRWRITE:
        ; Keep one bit for each WRITE type seen: 0, 1 and 2.
        PUSH    BC
        PUSH    AF
        LD      A,C
        CP      1
        JP      Z,WW1
        CP      2
        JP      Z,WW2
        LD      A,1
        JP      WWSET
WW1:   LD      A,2
        JP      WWSET
WW2:   LD      A,4
WWSET: LD      B,A
        LD      A,(WRTYPES)
        OR      B
        LD      (WRTYPES),A
        POP     AF
        POP     BC
CWRITE:CALL    0000H
        OR      A
        JP      Z,WWOK
        LD      (IOFAIL),A
WWOK:  LD      (WRSTATUS),A
        LD      A,(WRITECNT)
        INC     A
        LD      (WRITECNT),A
        LD      A,(WRSTATUS)
        RET
WRXLT: PUSH    HL
        ; Save both input words and the translated sector returned in HL.
        LD      H,B
        LD      L,C
        LD      (XLTIN),HL
        EX      DE,HL
        LD      (XLTPTR),HL
        EX      DE,HL
        POP     HL
CXLT:  CALL    0000H
        LD      (XLTOUT),HL
        LD      A,1
        LD      (XLTVALID),A
        LD      A,(XLTCNT)
        INC     A
        LD      (XLTCNT),A
        RET

;--------------------------- SAFE TESTS --------------------------------
; These five checks need no scratch disk, device arrangement or loss of the
; transient.  CASES is in writable TPA; SETRESULT replaces its initial '-'
; pointer and explanatory pointer with the result of this particular run.
AUTOTESTS:
        XOR     A
        LD      (PASSCNT),A
        LD      (FAILCNT),A
        LD      A,30
        LD      (REMCNT),A
        CALL    P0443
        LD      HL,CASES+128
        LD      DE,V0443
        CALL    SETRESULT
        CALL    P0451
        LD      HL,CASES+176
        LD      DE,V0451
        CALL    SETRESULT
        CALL    P0461
        LD      HL,CASES+256
        LD      DE,V0461
        CALL    SETRESULT
        CALL    P0463
        LD      HL,CASES+272
        LD      DE,V0463
        CALL    SETRESULT
        CALL    P0622
        LD      HL,CASES+360
        LD      DE,V0622
        CALL    SETRESULT
        RET

; Enter one result in CASES.
; Entry: A=0 pass, A<>0 fail; HL -> row; DE -> success explanation.
SETRESULT:
        PUSH    AF
        PUSH    HL
        LD      BC,6
        ADD     HL,BC
        LD      (HL),E
        INC     HL
        LD      (HL),D
        POP     HL
        INC     HL
        INC     HL
        POP     AF
        OR      A
        LD      DE,STPASS
        JP      NZ,SRFAIL
        LD      A,(PASSCNT)
        INC     A
        LD      (PASSCNT),A
        JP      SRSTORE
SRFAIL:LD      A,(FAILCNT)
        INC     A
        LD      (FAILCNT),A
        LD      DE,STFAIL
        PUSH    HL
        LD      BC,4
        ADD     HL,BC
        LD      BC,VFAIL
        LD      (HL),C
        INC     HL
        LD      (HL),B
        POP     HL
SRSTORE:LD     (HL),E
        INC     HL
        LD      (HL),D
        RET

; Print totals accumulated by SETRESULT.  Nothing is pre-counted as a PASS.
SUMMARY:LD     DE,SUMA
        CALL    PUTS
        LD      A,(PASSCNT)
        CALL    PUTDEC
        LD      DE,SUMB
        CALL    PUTS
        LD      A,(FAILCNT)
        CALL    PUTDEC
        LD      DE,SUMC1
        CALL    PUTS
        LD      A,(REMCNT)
        CALL    PUTDEC
        LD      DE,SUMC2
        CALL    PUTS
        LD      A,(FAILCNT)
        OR      A
        RET     Z
        LD      DE,FAILMSG
        CALL    PUTS
        LD      HL,CASES
        LD      B,NCASES
FSLP:  PUSH    BC
        PUSH    HL
        INC     HL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        LD      HL,STFAIL
        CALL    DEISEQ
        POP     HL
        JP      NZ,FSNEXT
        PUSH    HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      DE,FSSPACE
        CALL    PUTS
        POP     HL
FSNEXT:LD      DE,8
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,FSLP
        LD      DE,CRLF
        JP      PUTS
PUTDEC:LD      B,0
PD10:  CP      10
        JP      C,PDDONE
        SUB     10
        INC     B
        JP      PD10
PDDONE:LD      (DECTMP),A
        LD      A,B
        OR      A
        JP      Z,PDONES
        ADD     A,'0'
        LD      E,A
        LD      C,2
        CALL    BDOS
PDONES:LD      A,(DECTMP)
        ADD     A,'0'
        LD      E,A
        LD      C,2
        JP      BDOS

PUTHEX16:
        LD      A,H
        CALL    PUTHEX8
        LD      A,L
PUTHEX8:PUSH   AF
        RRCA
        RRCA
        RRCA
        RRCA
        AND     0FH
        CALL    PUTNIB
        POP     AF
        AND     0FH
PUTNIB:CP      10
        JP      C,PNDIGIT
        ADD     A,7
PNDIGIT:
        ADD     A,'0'
        LD      E,A
        LD      C,2
        JP      BDOS

; Print operating notes for a selected manual test.  The table row says what
; must agree; these messages say how to arrange and restore the equipment.
SHOWDETAIL:
        LD      A,(REPORTMODE)
        OR      A
        JP      NZ,DETSTART
        CALL    ISBOOT
        OR      A
        JP      Z,DETCHARCHK
        CALL    BOOTMASK
        LD      B,A
        LD      A,(BOOTBITS)
        AND     B
        RET     NZ                 ; retained boot test already completed
DETCHARCHK:
        CALL    ISCHAR
        OR      A
        JP      Z,DETDISKCHK
        LD      A,(CHCOUNT)
        OR      A
        RET     NZ                 ; selected character test already ran
DETDISKCHK:
        CALL    ISCONTROL
        OR      A
        JP      Z,DETSTART
        LD      A,(REMCNT)
        CP      23
        RET     Z                  ; selected controlled test already ran
DETSTART:
        LD      A,(SELBUF)
        CP      '0'
        RET     NZ
        LD      A,(SELBUF+1)
        CP      '6'
        JP      Z,DET06
        CP      '4'
        RET     NZ
        LD      A,(SELBUF+2)
        CP      '2'
        JP      Z,DET42
        CP      '3'
        JP      Z,DET43
        CP      '4'
        JP      Z,DET44
        CP      '5'
        JP      Z,DET45
        CP      '6'
        JP      Z,DET46
        CP      '7'
        JP      Z,DETDEV
        RET
DET06: LD      A,(SELBUF+2)
        CP      '2'
        RET     NZ
        JP      DETGEN
DET42: LD      A,(SELBUF+3)
        CP      '4'
        RET     C
        CP      '8'
        JP      C,DETDISK
        RET
DET43: LD      A,(SELBUF+3)
        CP      '1'
        JP      Z,DETDPB
        CP      '2'
        JP      Z,DETDPB
        CP      '3'
        JP      Z,DETDPB
        CP      '5'
        JP      Z,DETFN37
        CP      '7'
        JP      Z,DETDEV
        CP      '9'
        JP      Z,DETDEV
        RET
DET44: LD      A,(SELBUF+3)
        CP      '5'
        JP      Z,DETDEV
        CP      '8'
        JP      Z,DETDEV
        CP      '9'
        JP      Z,DETDISK
        JP      DETGEN
DET45: LD      A,(SELBUF+3)
        CP      '3'
        RET     C
        CP      '9'
        JP      C,DETDISK
        RET
DET46: LD      A,(SELBUF+3)
        CP      '4'
        JP      C,DETGEN
        CP      '7'
        JP      C,DETBOOT
        CP      '8'
        JP      Z,DETDEV
        CP      '9'
        JP      Z,DETDEV
        JP      DETGEN
DETDISK:LD     DE,DISKPROC
        JP      PUTS
DETDPB:LD      DE,DPBPROC
        JP      PUTS
DETBOOT:LD     DE,BOOTPROC
        JP      PUTS
DETDEV:LD      DE,DEVPROC
        JP      PUTS
DETFN37:LD     DE,FN37PROC
        JP      PUTS
DETGEN:LD      DE,GENPROC
        JP      PUTS

;--------------------------- IOBYTE TEST -------------------------------
; Read with 7, complement one bit, write with 8, and compare function 7 with
; location 0003H.  The entry value is always written back before return.
P0443: LD      C,7
        CALL    BDOS
        LD      (IOBORIG),A
        XOR     1
        LD      (IOBNEW),A
        LD      E,A
        LD      C,8
        CALL    BDOS
        LD      C,7
        CALL    BDOS
        LD      HL,IOBNEW
        CP      (HL)
        XOR     A
        LD      (PROBERES),A
        JP      Z,P43MEM
        INC     A
        LD      (PROBERES),A
P43MEM:LD      A,(0003H)
        LD      HL,IOBNEW
        CP      (HL)
        JP      Z,P43REST
        LD      A,(PROBERES)
        INC     A
        LD      (PROBERES),A
P43REST:LD     A,(IOBORIG)
        LD      E,A
        LD      C,8
        CALL    BDOS
        LD      A,(PROBERES)
        RET

;--------------------------- DPH TEST ----------------------------------
; Call public SELDSK for the current drive.  Check the DPH pointers and see
; that its DPB address is the same address returned by function 31.
P0451: LD      C,25
        CALL    BDOS
        LD      C,A
        LD      HL,(0001H)
        LD      DE,24             ; WBOOT entry + (8 * 3) = SELDSK
        ADD     HL,DE
        LD      E,0
        CALL    CALLHL
        LD      A,H
        OR      L
        RET     Z
        LD      (DPHPTR),HL
        LD      DE,8
        ADD     HL,DE
        LD      A,(HL)
        INC     HL
        OR      (HL)            ; directory buffer pointer
        RET     Z
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)          ; public DPB pointer
        LD      A,D
        OR      E
        RET     Z
        PUSH    DE
        LD      C,31
        CALL    BDOS
        POP     DE
        LD      A,H
        CP      D
        JP      NZ,PFAIL
        LD      A,L
        CP      E
        JP      NZ,PFAIL
        LD      HL,(DPHPTR)
        LD      DE,14
        ADD     HL,DE
        LD      A,(HL)
        INC     HL
        OR      (HL)            ; allocation-vector pointer
        JP      Z,PFAIL
        XOR     A
        RET

; Find BIOS from the WBOOT address at 0001H.  There must be seventeen adjacent
; three-byte JMP entries.  No assembled-in BIOS address is used.
P0461: LD      HL,(0001H)
        DEC     HL
        DEC     HL
        DEC     HL
        LD      B,17
P61LP: LD      A,(HL)
        CP      0C3H
        JP      NZ,PFAIL
        INC     HL
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,P61LP
        XOR     A
        RET
P0463: JP      P0461

;---------------------- SELF-MODIFYING TPA TEST ------------------------
; Copy "LD A,n / RET" to two work areas, alter n in each copy, and CALL the
; work areas.  Both instruction fetches must see the bytes just stored.
P0622: LD      HL,SMCODE
        LD      DE,SMBUF1
        LD      B,4
        CALL    COPY4
        LD      HL,SMCODE
        LD      DE,SMBUF2
        LD      B,4
        CALL    COPY4
        LD      A,05AH
        LD      (SMBUF1+1),A
        LD      A,0A5H
        LD      (SMBUF2+1),A
        LD      HL,SMBUF1
        CALL    CALLHL
        CP      05AH
        JP      NZ,PFAIL
        LD      HL,SMBUF2
        CALL    CALLHL
        CP      0A5H
        JP      NZ,PFAIL
        XOR     A
        RET
COPY4: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,COPY4
        RET
; Call address in HL without a self-modifying CALL instruction.
CALLHL:LD      DE,CALLRET
        PUSH    DE
        JP      (HL)
CALLRET:RET
PFAIL: LD      A,1
        RET

HLPMSG:DB 13,10,'BIOSTEST 0.1.0-dev32',13,10,13,10
        DB '  BIOSTEST /NNNN[:REPORT]     Run, explain, or report one item',13,10
        DB '  BIOSTEST /ALL               Run checks and report all items',13,10
        DB '  BIOSTEST /SAFE              Run checks requiring no destructive media',13,10
        DB '  BIOSTEST /LIST              List ledger items by useful group',13,10
        DB '  BIOSTEST /GROUP:LIST        List all available groupings',13,10
        DB '  BIOSTEST /GROUP:name        Run a tool-specific group',13,10
        DB '                              (run /GROUP:LIST for available groups)',13,10
        DB '  BIOSTEST /H, /HELP          Show concise command help',13,10
        DB '  BIOSTEST /INFO              Show build information',13,10
        DB '  BIOSTEST /VER, /VERSION     Show name and version',13,10,'$'
VERMSG:DB 13,10,'BIOSTEST 0.1.0-dev32',13,10,'$'
INFMSG:DB 13,10,'BIOSTEST 0.1.0-dev32',13,10
        DB 'Catalog: BIO-001 through BIO-046 (46 rows)',13,10
        DB 'Processor required: Intel 8080',13,10
        DB 'Returning checks: 5 safe, 14 disk, 8 character, 3 boot',13,10
        DB '0457 requires operator-controlled scratch-disk write protection.',13,10
        DB 'Delete BTBOOT.DAT to reset retained boot evidence.',13,10,'$'
RESMSG:DB 13,10,'PASS and FAIL are emitted only after the complete oracle runs.',13,10
        DB 'UNTESTED identifies a required procedure not yet automated.',13,10
        DB 'OBSERVED records a permitted variation without claiming PASS.',13,10,'$'
PRFMSG:DB 13,10,'OPT-FN37: optional undocumented Function 37 compatibility.',13,10
        DB 'Device-dependent rows require a declared hardware provider.',13,10,'$'
BADSEL:DB 13,10,'BIOSTEST: unknown selector. Use BIOSTEST /HELP.',13,10
        DB 'Use BIOSTEST /GROUP:LIST for available groups.',13,10,'$'
HEADMSG:DB 13,10,'STATUS: P=Pass F=Fail -=Not-run O=Observed',13,10
        DB 'CLASS:  R=Required N=Not-guaranteed S=Out-of-scope X=Optional',13,10,13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  -------------------------------------------------------------------',13,10,'$'
SUMA:   DB 'Summary: $'
SUMB:   DB ' pass, $'
SUMC1:  DB ' fail, 0 error, 11 observations',13,10,'$'
SUMC2:  DB ' scope/required/profile procedures remain untested.',13,10,'$'
FAILMSG:DB 'Failed items: $'
FSSPACE:DB ' $'
T26MSG1:DB '0426 evidence: DPB AL0/AL1=$'
T26MSG2:DB '; ALV[0/1]=$'
ONESUM:DB 'Summary: selected row reported above.',13,10,'$'
GRPSUM:DB 'Group rows shown; safe returning checks ran where applicable.',13,10,'$'
REQSUM:DB '30 REQUIRED items shown: 5 safe checks ran; 25 require providers.',13,10,'$'
OBSSUM:DB '11 NOT GUARANTEED observations shown.',13,10,'$'
MANSUM:DB '27 manual/provider procedures listed; none executed.',13,10,'$'
SP2:    DB '  $'
CRLF:   DB 13,10,'$'
BWNOMSG:DB '0453: no adjacent track boundary reached.',13,10,'$'
BWMAPMSG:DB '0453: expected SETTRK $'
BWACTMSG:DB ', observed $'

; Keep catalog entries within an 80-column display.
LSTMSG:DB 13,10,'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile',13,10
        DB 13,10,'ALLOCATION AND DPB (13)',13,10
        DB '  0423 S Function 34 is not Compute File Size',13,10
        DB '  0424 R Function 27 allocation-vector pointer',13,10
        DB '  0425 R Allocation-vector length and bit mapping',13,10
        DB '  0426 R Reserved directory allocation bits',13,10
        DB '  0427 R Live allocation state',13,10
        DB '  0428 N Allocation-pointer address and lifetime',13,10
        DB '  0429 N Application modification of allocation vector',13,10
        DB '  0430 N Read-only allocation information',13,10
        DB '  0431 R Function 31 DPB pointer and layout',13,10
        DB '  0432 R DPB configuration and sharing',13,10
        DB '  0433 R Documented DPB modification',13,10
        DB '  0434 N DPB address and lifetime',13,10
        DB '  0435 X Function 37 compatibility status',13,10
        DB 13,10,'LOGICAL DEVICES (7)',13,10
        DB '  0437 N Reader completion and optional-device behavior',13,10
        DB '  0439 R Function 4 Punch convention',13,10
        DB '  0441 N Character-output result values',13,10
        DB '  0443 R Function 8 IOBYTE set',13,10
        DB '  0445 R IOBYTE routing boundary',13,10
        DB '  0447 N IOBYTE set has no initialization contract',13,10
        DB '  0448 R Character-device DMA independence',13,10
        DB 13,10,'DISK I/O (15)',13,10
        DB '  0449 R Stateful BIOS disk setup',13,10
        DB '  0450 R SELDSK result and deferral',13,10
        DB '  0451 R Public DPH layout',13,10
        DB '  0452 N DPH address and private workspace',13,10
        DB '  0453 R Track mapping and OFF',13,10
        DB '  0454 R Sector translation chain',13,10
        DB '  0455 N Translation implementation freedom',13,10
        DB '  0456 R BIOS DMA state',13,10
        DB '  0457 R BIOS logical-sector transfer',13,10
        DB '  0458 R BIOS WRITE type codes',13,10
        DB '  0459 S Physical storage freedom',13,10
        DB '  0460 N BIOS disk-call reentrancy',13,10
        DB '  0461 R BIOS jump-vector structure',13,10
        DB '  0462 N BIOS vector address freedom',13,10
        DB '  0463 R BIOS-base discovery through WBOOT gateway',13,10
        DB 13,10,'BOOT AND RESTART (4)',13,10
        DB '  0464 R BOOT control contract',13,10
        DB '  0465 R WBOOT control contract',13,10
        DB '  0466 R Warm-start gateway reconstruction',13,10
        DB '  0467 S Boot implementation freedom',13,10
        DB 13,10,'CHARACTER BIOS (6)',13,10
        DB '  0468 R BIOS console status contract',13,10
        DB '  0469 R BIOS console input contract',13,10
        DB '  0470 R BIOS character output contracts',13,10
        DB '  0471 R BIOS reader contract',13,10
        DB '  0472 X LISTST result policy',13,10
        DB '  0473 R Direct BIOS call layering',13,10
        DB 13,10,'PROCESSOR INTERACTION (1)',13,10
        DB '  0622 R Self-modifying transient execution',13,10
        DB 13,10,'TOTAL: 46 ITEMS',13,10,'$'

GRPLIST:DB 13,10,'BIOSTEST GROUPS',13,10,13,10
        DB 'FUNCTIONAL',13,10
        DB '  ALLOCATION  13  Allocation vector and DPB behavior',13,10
        DB '  DEVICES      7  Logical-device and IOBYTE behavior',13,10
        DB '  DISK        15  DPH, tracing, translation, and transfers',13,10
        DB '  BOOT         4  BOOT, WBOOT, and reconstruction',13,10
        DB '  CHARACTER    6  Console, reader, output, and layering',13,10
        DB '  PROCESSOR    1  Transient execution behavior',13,10
        DB 13,10,'UNIVERSAL',13,10
        DB '  REQUIRED    30  REQUIRED catalog items',13,10
        DB '  OBSERVATION 11  NOT GUARANTEED observations',13,10
        DB '  MANUAL      27  Manual/provider procedures (lists only)',13,10,'$'

STOUT: DB '-$'
STOBS: DB 'O$'
STPASS:DB 'P$'
STFAIL:DB 'F$'
CLREQ: DB 'R$'
CLNG:  DB 'N$'
CLOUT: DB 'S$'
CLOPT: DB 'X$'

I0423: DB '0423$'
I0424: DB '0424$'
I0425: DB '0425$'
I0426: DB '0426$'
I0427: DB '0427$'
I0428: DB '0428$'
I0429: DB '0429$'
I0430: DB '0430$'
I0431: DB '0431$'
I0432: DB '0432$'
I0433: DB '0433$'
I0434: DB '0434$'
I0435: DB '0435$'
I0437: DB '0437$'
I0439: DB '0439$'
I0441: DB '0441$'
I0443: DB '0443$'
I0445: DB '0445$'
I0447: DB '0447$'
I0448: DB '0448$'
I0449: DB '0449$'
I0450: DB '0450$'
I0451: DB '0451$'
I0452: DB '0452$'
I0453: DB '0453$'
I0454: DB '0454$'
I0455: DB '0455$'
I0456: DB '0456$'
I0457: DB '0457$'
I0458: DB '0458$'
I0459: DB '0459$'
I0460: DB '0460$'
I0461: DB '0461$'
I0462: DB '0462$'
I0463: DB '0463$'
I0464: DB '0464$'
I0465: DB '0465$'
I0466: DB '0466$'
I0467: DB '0467$'
I0468: DB '0468$'
I0469: DB '0469$'
I0470: DB '0470$'
I0471: DB '0471$'
I0472: DB '0472$'
I0473: DB '0473$'
I0622: DB '0622$'

O0423: DB 'No baseline Function 34 assertion$'
O0424: DB 'Use SCRATCH /BLANK and two controlled disks$'
O0425: DB 'Needs DPB-derived ALV and controlled files$'
O0426: DB 'Needs controlled empty disk$'
O0427: DB 'Needs controlled one-record lifecycle$'
O0428: DB 'Fixed address/lifetime is not portable$'
O0429: DB 'Applications must not depend on ALV writes$'
O0430: DB 'Post-Function-28 ALV accuracy may vary$'
O0431: DB 'Needs two configured drives and DPB decode$'
O0432: DB 'Shared or distinct valid DPBs accepted$'
O0433: DB 'Needs guarded modify, re-query, and restore$'
O0434: DB 'Fixed DPB address/lifetime is not portable$'
O0435: DB 'Run only when OPT-FN37 is claimed$'
O0437: DB 'Reader/device provider behavior may vary$'
O0439: DB 'Needs declared punch provider$'
O0441: DB 'Character-output return values may vary$'
O0443: DB 'Needs set/query/restore IOBYTE round trip$'
O0445: DB 'Needs declared routes at multiple IOBYTE values$'
O0447: DB 'No initialization side effect is guaranteed$'
O0448: DB 'Needs device provider and DMA sentinels$'
O0449: DB 'Needs direct BIOS disk-call sequence$'
O0450: DB 'Needs configured/absent drives and deferred I/O$'
O0451: DB 'Needs current-drive DPH pointer validation$'
O0452: DB 'Fixed DPH/private workspace is not portable$'
O0453: DB 'Needs boundary tracks with nonzero OFF$'
O0454: DB 'Needs controlled nonidentity XLT$'
O0455: DB 'Table or equivalent algorithm is accepted$'
O0456: DB 'Needs application/directory DMA tracing$'
O0457: DB 'Needs successful and injected-fault transfers$'
O0458: DB 'Needs controlled WRITE type-code lifecycle$'
O0459: DB 'Physical mapping is outside the public contract$'
O0460: DB 'Nested disk-call state is not guaranteed$'
O0461: DB 'Needs independent jump-vector validation$'
O0462: DB 'No fixed BIOS vector address is portable$'
O0463: DB 'Needs page-zero-only BIOS-base discovery$'
O0464: DB 'Needs cold-start state validation$'
O0465: DB 'Needs programmed warm-restart validation$'
O0466: DB 'Needs controlled gateway reconstruction test$'
O0467: DB 'Boot implementation is outside public contract$'
O0468: DB 'Needs queued character and status transitions$'
O0469: DB 'Needs controlled raw console input$'
O0470: DB 'Needs captured bytes at each output vector$'
O0471: DB 'Needs reader and absent-device provider$'
O0472: DB 'Needs declared LISTST result profile$'
O0473: DB 'Needs direct/BDOS character comparison$'
O0622: DB 'Needs patch/execute at multiple TPA placements$'
V0443: DB 'Function 7/8 and 0003h were coherent; restored$'
V0424: DB 'Function 27 returned current scratch-disk ALV$'
V0425: DB 'DPB-derived ALV length and bits matched blank disk$'
V0426: DB 'AL0/AL1 matched reserved ALV directory bits$'
V0427: DB 'One-record block set then cleared its ALV bit$'
V0431: DB 'Decoded valid 15-byte DPBs for both drives$'
V0432: DB 'Both configured DPBs valid; sharing accepted$'
V0433: DB 'DPB field changed, re-queried, and restored$'
V0439: DB 'Function 4 delivered graphic/control bytes to PUNCH$'
V0445: DB 'Functions 3/4/5 kept fixed logical dispatch$'
V0448: DB 'Character calls preserved DMA selection and sentinels$'
V0449: DB 'Traced persistent track/sector/DMA write context$'
V0450: DB 'SELDSK accepted scratch and rejected absent drive$'
V0453: DB 'Traced boundary SETTRK equaled logical track plus OFF$'
V0454: DB 'SECTRAN result was passed to SETSEC$'
V0456: DB 'Traced application and directory DMA addresses$'
V0457: DB '128-byte transfer passed; physical fault returned nonzero$'
V0458: DB 'Observed WRITE type codes 0, 1, and 2$'
V0451: DB 'Current DPH pointers and Function 31 agreed$'
V0461: DB 'Found 17 consecutive public JMP vectors$'
V0463: DB 'BIOS base derived only from WBOOT gateway$'
V0464: DB 'BOOT resumed CCP with reconstructed public state$'
V0465: DB 'WBOOT resumed CCP on the requested drive$'
V0466: DB 'WBOOT reconstructed both damaged gateway opcodes$'
V0468: DB 'CONST reported empty/ready/ready/empty without consume$'
V0469: DB 'CONIN returned the controlled zero-parity K byte$'
V0470: DB 'CONOUT/LIST/PUNCH accepted graphic and control C bytes$'
V0471: DB 'READER returned R; absent READER returned Ctrl-Z$'
V0473: DB 'Direct TAB stayed raw; BDOS TAB was formatted$'
V0622: DB 'Modified code executed at two TPA locations$'
VFAIL: DB 'Returning oracle check failed$'

DISKPROC:DB 13,10,'SETUP: use an empty, expendable disk and a declared BIOS',13,10
        DB 'trace/fault provider when the selected row requires one.',13,10
        DB '0453 requires a freshly formatted SYSTEM disk with nonzero OFF.',13,10
        DB 'SCRATCH /BLANK is only needed to clear previously used media.',13,10
        DB 'ACTION: run the selected operation and capture its exact BIOS calls.',13,10
        DB 'SUCCESS: the trace and result match the selected ledger oracle.',13,10
        DB 'FAILURE: any wrong argument, order, transfer, or result is FAIL.',13,10
        DB 'RESTORE: discard/remount the scratch disk and reset the disk system.',13,10,'$'
DPBPROC:DB 13,10,'SETUP: mount two configured disks with declared geometries.',13,10
        DB 'ACTION: obtain and decode each DPH/DPB/ALV without fixed addresses.',13,10
        DB 'SUCCESS: every public field and selected-drive relationship agrees.',13,10
        DB 'FAILURE: a null, incoherent, or incorrectly shared object is FAIL.',13,10
        DB 'RESTORE: restore any guarded field before another BDOS disk call.',13,10,'$'
BOOTPROC:DB 13,10,'TERMINAL TEST: preserve the current gateways and capture CCP output.',13,10
        DB 'Perform the selected BOOT/WBOOT action exactly as named above.',13,10
        DB 'SUCCESS: CCP resumes and documented page-zero/DMA state is rebuilt.',13,10
        DB 'FAILURE: return to caller, hang, or invalid public state is FAIL.',13,10
        DB 'RESTORE: cold boot the pristine system image after recording evidence.',13,10,'$'
DEVPROC:DB 13,10,'SETUP: declare and connect the required reader/punch/list/console',13,10
        DB 'capture or loopback provider; record its ready/not-ready encodings.',13,10
        DB 'ACTION: run the selected raw BIOS and mediated BDOS operations.',13,10
        DB 'SUCCESS: bytes, status, nonconsumption, and layering match the oracle.',13,10
        DB 'FAILURE: transformed, lost, consumed, or misrouted data is FAIL.',13,10
        DB 'RESTORE: restore IOBYTE and drain only provider-supplied input.',13,10,'$'
FN37PROC:DB 13,10,'OPTIONAL PROFILE: select OPT-FN37 only when the candidate',13,10
        DB 'claims the undocumented Function 37 compatibility behavior.',13,10
        DB 'Test inactive, current, multiple, and read-only-vector inputs.',13,10
        DB 'SUCCESS: every declared state effect matches the profile.',13,10
        DB 'RESTORE: reset the disk system and remount pristine test media.',13,10,'$'
GENPROC:DB 13,10,'REPORT: the returning oracle executed through public CP/M and BIOS',13,10
        DB 'interfaces; the result row above records its complete verdict.',13,10
        DB 'No provider, destructive medium, or retained restart state was used.',13,10,'$'
CGMSG: DB 13,10,'Controlled tests require an empty, expendable disk.',13,10
        DB 'For 0453 use a freshly formatted SYSTEM disk with nonzero OFF.',13,10
        DB 'Use SCRATCH /BLANK only to clear a previously used disk.',13,10
        DB 'Enter its configured drive letter, or Q to skip (B-P or Q): $'
CGBADMSG:DB 13,10,'Enter a configured drive B through P, or Q.',13,10,'$'
CGSAMEMSG:DB 13,10,'The scratch drive must differ from the utility drive.',13,10,'$'
CGCONF:DB 13,10,'BIOSTEST will create and delete BTBIO.TMP, then leave the',13,10
        DB 'scratch disk empty. Continue (Y/N)? $'
FAULTASK:DB 13,10,'0457 fault stage: make the scratch disk WRITE-PROTECTED.',13,10
        DB 'Press Y when protected, or Q to leave 0457 UNTESTED: $'
FAULTREST:DB 13,10,'Make the scratch disk writable again, then press Y: $'
FSTATMSG:DB '0457 protected WRITE status: $'
RSTATMSG:DB '; restored WRITE status: $'
CHGMSG:DB 13,10,'Run controlled console/logical-device tests (Y/N)? $'
CKEYMSG:DB 13,10,'Type one uppercase K now: $'
CHARBAD:DB 13,10,'Character trace unavailable: BIOS JMP operands are not writable.',13,10,'$'
RDNORMAL:DB 13,10,'0471 stage 1: before this run assign RDR:=PTR: with STAT.',13,10
        DB 'Y calls READER; type uppercase R when it waits. Y=call, Q=skip: $'
RDNEXT:DB 13,10,'0471 stage 1 saved. Stage 2 needs a separately configured',13,10
        DB 'READER provider known to return Ctrl-Z immediately.',13,10
        DB 'Return to the CCP, configure/verify it, then rerun /0471.',13,10,'$'
RDABSENT:DB 13,10,'0471 stage 2 needs READER to return Ctrl-Z immediately.',13,10
        DB 'STAT assignment names are standard; their drivers are BIOS-specific.',13,10
        DB 'Montezuma UR1:/UR2: may block. Use Q unless a provider is verified.',13,10
        DB 'Y=call verified provider, Q=leave 0471 UNTESTED: $'
RDSTORE:DB 13,10,'Unable to retain 0471 evidence in BTRDR.DAT.',13,10,'$'
BSTARTMSG:DB 13,10,'This test transfers control to BOOT/WBOOT and cannot return.',13,10
        DB 'BIOSTEST will save BTBOOT.DAT; rerun this selector after CCP resumes.',13,10
        DB 'Run tests in this order: 1) /0465 two times; 2) /0466 two times;',13,10
        DB '3) /0464 two times. Then run /ALL. Then ERA BTBOOT.DAT.',13,10
        DB 'Continue (Y/N)? $'
BTRANSFER:DB 13,10,'Evidence saved. Transferring control now...',13,10,'$'
BPENDMSG:DB 13,10,'Another boot selector is pending. Rerun that selector first,',13,10
        DB 'or delete BTBOOT.DAT to reset retained boot evidence.',13,10,'$'
BCOLDMSG:DB 13,10,'Did cold BOOT first resume at the CCP on drive A (Y/N)? $'
BSTOREMSG:DB 13,10,'Unable to write BTBOOT.DAT; boot transfer cancelled.',13,10,'$'
BRETAINMSG:DB 13,10,'BTBOOT.DAT is retained so /ALL can include this result.',13,10
        DB 'After the final /ALL, ERA BTBOOT.DAT resets the boot tests.',13,10,'$'
R0424: DB 13,10,'Running controlled item 0424...',13,10,'$'
R0425: DB 'Running controlled item 0425...',13,10,'$'
R0426: DB 'Running controlled item 0426...',13,10,'$'
R0427: DB 'Running controlled item 0427...',13,10,'$'
R0431: DB 'Running controlled item 0431...',13,10,'$'
R0432: DB 'Running controlled item 0432...',13,10,'$'
R0433: DB 'Running controlled item 0433...',13,10,'$'
RTRACE:DB 'Installing guarded BIOS disk trace...',13,10,'$'
TRACEBAD:DB 'Trace unavailable: BIOS JMP operands are not safely writable.',13,10,'$'
TWMAKE:DB 'Trace: Make...',13,10,'$'
TWWR1: DB 'Trace: first sequential write...',13,10,'$'
TWWR2: DB 'Trace: second sequential write...',13,10,'$'
TWCLOSE:DB 'Trace: Close/Delete...',13,10,'$'
E27MAKE:DB '0427 FAIL: could not create BTBIO.TMP.',13,10,'$'
E27WRITE:DB '0427 FAIL: one-record write was rejected.',13,10,'$'
E27CLOSE:DB '0427 FAIL: close was rejected.',13,10,'$'
E27BLOCK:DB '0427 FAIL: no allocation block appeared in the FCB.',13,10,'$'
E27SET: DB '0427 FAIL: allocated block was not set in the ALV.',13,10,'$'
E27DELETE:DB '0427 FAIL: delete was rejected.',13,10,'$'
E27STATE:DB '0427 FAIL: lifecycle did not reach allocated state.',13,10,'$'
E27CLEAR:DB '0427 FAIL: released block remained set in the ALV.',13,10,'$'
D27BLOCK:DB '0427: allocation block decoded.',13,10,'$'
D27SET:DB '0427: allocation bit set after write.',13,10,'$'
D27DELETE:DB '0427: temporary file deleted.',13,10,'$'

CASES: DW I0423,STOUT,CLOUT,O0423
       DW I0424,STOUT,CLREQ,O0424
       DW I0425,STOUT,CLREQ,O0425
       DW I0426,STOUT,CLREQ,O0426
       DW I0427,STOUT,CLREQ,O0427
       DW I0428,STOBS,CLNG,O0428
       DW I0429,STOBS,CLNG,O0429
       DW I0430,STOBS,CLNG,O0430
       DW I0431,STOUT,CLREQ,O0431
       DW I0432,STOUT,CLREQ,O0432
       DW I0433,STOUT,CLREQ,O0433
       DW I0434,STOBS,CLNG,O0434
       DW I0435,STOUT,CLOPT,O0435
       DW I0437,STOBS,CLNG,O0437
       DW I0439,STOUT,CLREQ,O0439
       DW I0441,STOBS,CLNG,O0441
       DW I0443,STOUT,CLREQ,O0443
       DW I0445,STOUT,CLREQ,O0445
       DW I0447,STOBS,CLNG,O0447
       DW I0448,STOUT,CLREQ,O0448
       DW I0449,STOUT,CLREQ,O0449
       DW I0450,STOUT,CLREQ,O0450
       DW I0451,STOUT,CLREQ,O0451
       DW I0452,STOBS,CLNG,O0452
       DW I0453,STOUT,CLREQ,O0453
       DW I0454,STOUT,CLREQ,O0454
       DW I0455,STOBS,CLNG,O0455
       DW I0456,STOUT,CLREQ,O0456
       DW I0457,STOUT,CLREQ,O0457
       DW I0458,STOUT,CLREQ,O0458
       DW I0459,STOUT,CLOUT,O0459
       DW I0460,STOBS,CLNG,O0460
       DW I0461,STOUT,CLREQ,O0461
       DW I0462,STOBS,CLNG,O0462
       DW I0463,STOUT,CLREQ,O0463
       DW I0464,STOUT,CLREQ,O0464
       DW I0465,STOUT,CLREQ,O0465
       DW I0466,STOUT,CLREQ,O0466
       DW I0467,STOUT,CLOUT,O0467
       DW I0468,STOUT,CLREQ,O0468
       DW I0469,STOUT,CLREQ,O0469
       DW I0470,STOUT,CLREQ,O0470
       DW I0471,STOUT,CLREQ,O0471
       DW I0472,STOUT,CLOPT,O0472
       DW I0473,STOUT,CLREQ,O0473
       DW I0622,STOUT,CLREQ,O0622

SELBUF:DS 4
REPORTMODE:DB 0
FILTERMODE:DB 0
CARDPTR:DW 0
ARGBUF:DS 32
SH:     DB '/H',0
SHELP:  DB '/HELP',0
SLIST:  DB '/LIST',0
SALL:   DB '/ALL',0
SSAFE:  DB '/SAFE',0
SINFO:  DB '/INFO',0
SVER:   DB '/VER',0
SVERSION:DB '/VERSION',0
SGLIST: DB '/GROUP:LIST',0
SGREQ:  DB '/GROUP:REQUIRED',0
SGOBS:  DB '/GROUP:OBSERVATION',0
SGMAN:  DB '/GROUP:MANUAL',0
SGALLOC:DB '/GROUP:ALLOCATION',0
SGDEV:  DB '/GROUP:DEVICES',0
SGDISK: DB '/GROUP:DISK',0
SGBOOT: DB '/GROUP:BOOT',0
SGCHAR: DB '/GROUP:CHARACTER',0
SGCPU:  DB '/GROUP:PROCESSOR',0
SHR:    DB '/H:RESULTS',0
SHP:    DB '/H:PROFILES',0
SREPORT:DB ':REPORT',0
PASSCNT:DB 0
FAILCNT:DB 0
REMCNT: DB 30
DECTMP: DB 0
T26AL0: DB 0
T26AL1: DB 0
T26AV0: DB 0
T26AV1: DB 0
DPHPTR:DW 0
DPBPTR:DW 0
ALVPTR:DW 0
DPBOLD:DW 0
DPBSCR:DW 0
MODPTR:DW 0
TESTBLK:DW 0
BIOSBASE:DW 0
PATCHLOC:DW 0
PATCHNEW:DW 0
PATCHSAVE:DW 0
PATCHCNT:DB 0
ORGSEL: DW 0
ORGTRK: DW 0
ORGSEC: DW 0
ORGDMA: DW 0
ORGREAD:DW 0
ORGWRITE:DW 0
ORGXLT: DW 0
ORGCO:  DW 0
ORGLIST:DW 0
ORGPUNCH:DW 0
ORGREADER:DW 0
ORGCDMA:DW 0
TRACELOG:
SELCNT: DB 0
TRKCNT: DB 0
SECCNT: DB 0
DMACNT: DB 0
READCNT:DB 0
WRITECNT:DB 0
XLTCNT: DB 0
WRTYPES:DB 0
APPDMA: DB 0
DIRDMA: DB 0
XLTVALID:DB 0
XLTCHAIN:DB 0
IOFAIL: DB 0
WRSTATUS:DB 0
CONFSEL:DB 0
ABSENTSEL:DB 0
TRACECOUNT:DB 0
OFFAVAIL:DB 0
OFFRESULT:DB 0
BWBSH:  DB 0
BWBLM:  DB 0
BWDSMH: DB 0
RINDEX: DB 0
RECPOS: DB 0
PREVVALID:DB 0
BWSPT:  DW 0
BWOFF:  DW 0
WRLEFT: DW 0
PREVTRK:DW 0
CURRENTTRK:DW 0
XFERGOOD:DB 0
FAVAIL: DB 0
FRESULT:DB 1
FSTATUS:DB 0
RSTATUS:DB 0
LASTSEL:DB 0
SELRESULT:DW 0
LASTTRK:DW 0
LASTSEC:DW 0
LASTDMA:DW 0
XLTIN:  DW 0
XLTPTR: DW 0
XLTOUT: DW 0
TRACEEND:
FAULTREQ:DB 0
READERREQ:DB 0
CHARLOG:
COCNT:  DB 0
COBYTE1:DB 0
COBYTE2:DB 0
COTAB:  DB 0
LISTCNT:DB 0
LASTLIST:DB 0
LIST1:  DB 0
LIST2:  DB 0
PUNCHCNT:DB 0
PUNCH1:DB 0
PUNCH2:DB 0
READERCNT:DB 0
CDMACNT:DB 0
CHIOBORIG:DB 0
R0439:  DB 1
R0445:  DB 1
R0448:  DB 1
R0470:  DB 1
R0473:  DB 1
CHAREND:
CHCOUNT:DB 0
R0471:  DB 1
RDNBYTE:DB 0
RDABYTE:DB 0
CSTRES: DB 1
CINRES: DB 1
OLDDRV:DB 0
OLDUSR:DB 0
SCRDRV:DB 0
MODORIG:DB 0
MODNEW:DB 0
T27WROTE:DB 0
IOBORIG:DB 0
IOBNEW: DB 0
PROBERES:DB 0
BOOTBITS:DB 0
BOOTPEND:DB 0
BOOTSEL: DB 0
BOOTDRV: DB 0
BOOTRES: DB 0
BOOTIO:  DB 0
BOOTCOUNT:DB 0
BOOTWBOOT:DW 0
BOOTBDOS:DW 0
BOOTMAGIC:DB 'BTB8'
BOOTNAME:DB 'BTBOOT  DAT'
BOOTFCB: DB 0
        DS 35
BOOTBUF:DS 128
RDSTAGE:DB 0
RDIO:   DB 0
RDMAGIC:DB 'BTR1'
RDNAME: DB 'BTRDR   DAT'
RDFCB:  DB 0
        DS 35
RDBUF:  DS 128
DMASAVE:DS 4
DMAPAT1:DB 055H,0AAH,033H,0CCH
DMAPAT2:DB 012H,034H,056H,078H
ALTDMA: DS 128
SMCODE:DB 03EH,00H,0C9H,00H
SMBUF1:DS 4
SMBUF2:DS 4
DPBCOPY1:DS 15
DPBCOPY2:DS 15
TESTFCB:DB 0
        DS 35
TNAME:  DB 'BTBIO   TMP'
TESTDMA:DB 'BIOSTEST-CONTROLLED-RECORD'
        DS 102
        DS 128
STACKTOP:
        END     START
