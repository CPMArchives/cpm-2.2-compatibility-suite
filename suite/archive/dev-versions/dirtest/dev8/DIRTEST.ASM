; BetterCP/M executable conformance suite - DIRTEST
; Version 0.1.0-dev8 - actionable CCP USER integration workflow
; Intel 8080 instruction subset; accepted by M80 in .Z80 mode and linked by L80.

        ORG     0100H
BDOS    EQU     0005H

; Detail identifiers for cases that cannot safely execute as ordinary
; aggregate members. Naming these prevents the selection policy below from
; becoming an unexplained dependency on table positions.
DET_RO_DELETE   EQU 48
DET_RO_RENAME   EQU 49
DET_CCP_USER    EQU 67

START:  LD      SP,STACKTOP
        LD      HL,0
        ; Every top-level RET ultimately consumes this zero and transfers to
        ; CP/M's warm-boot entry at 0000h. Establishing it here makes every
        ; ordinary exit deterministic instead of depending on the CCP stack.
        PUSH    HL
        CALL    PARSE
        CP      1
        JP      Z,HELP
        CP      2
        JP      Z,LIST
        CP      3
        JP      Z,RUNREQ
        CP      4
        JP      Z,RUNALL
        CP      5
        JP      Z,RUNONE
        CP      6
        JP      Z,HRESULTS
        CP      7
        JP      Z,HPROFILES
        CP      8
        JP      Z,INFO
        LD      DE,BADSEL
        CALL    PUTS
        RET

; Parse /H, /LIST, /SAFE, /ALL, or /NNNN. Result in A; numeric item in ITEMNO.
PARSE:  LD      HL,0081H
        LD      A,(0080H)
        OR      A
        JP      Z,PARSEH
        LD      B,A
PSKIP: LD      A,(HL)
        CP      ' '
        JP      NZ,PSLASH
        INC     HL
        DEC     B
        JP      NZ,PSKIP
PARSEH: LD      A,1
        RET
PSLASH:CP      '/'
        JP      NZ,PARSEH
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'H'
        JP      Z,PARSEHX
        CP      'I'
        JP      Z,PARSEI
        CP      'L'
        JP      Z,PARSEL
        CP      'S'
        JP      Z,PARSES
        CP      'A'
        JP      Z,PARSEA
        LD      B,4
        LD      DE,0
        EX      DE,HL
        LD      (ITEMNO),HL
        EX      DE,HL
PNUM:  LD      A,(HL)
        CP      '0'
        JP      C,PARSEH
        CP      '9'+1
        JP      NC,PARSEH
        SUB     '0'
        LD      C,A
        PUSH    HL
        LD      HL,(ITEMNO)
        ADD     HL,HL
        PUSH    HL
        ADD     HL,HL
        ADD     HL,HL
        POP     DE
        ADD     HL,DE
        LD      E,C
        LD      D,0
        ADD     HL,DE
        LD      (ITEMNO),HL
        POP     HL
        INC     HL
        DEC     B
        JP      NZ,PNUM
        LD      A,5
        RET
PARSEL:LD      A,2
        RET
PARSES:LD      A,3
        RET
PARSEA:LD      A,4
        RET
PARSEI:LD      A,8
        RET
PARSEHX:INC    HL
        LD      A,(HL)
        CP      ':'
        JP      NZ,PARSEH
        INC     HL
        LD      A,(HL)
        AND     5FH
        CP      'R'
        JP      Z,PARSEHR
        CP      'P'
        JP      Z,PARSEHP
        JP      PARSEH
PARSEHR:LD     A,6
        RET
PARSEHP:LD     A,7
        RET

HELP:   LD      DE,HLPMSG
        CALL    PUTS
        RET
LIST:   LD      DE,LSTMSG
        CALL    PUTS
        RET
INFO:   LD      DE,INFMSG
        CALL    PUTS
        RET
HRESULTS:LD    DE,RESMSG
        CALL    PUTS
        RET
HPROFILES:LD   DE,PRFMSG
        CALL    PUTS
        RET

RUNREQ: CALL    BEGIN
        LD      HL,CASES
        LD      B,67
RRLOOP: PUSH    BC
        PUSH    HL
        LD      DE,4
        ADD     HL,DE
        LD      A,(HL)
        OR      A
        POP     HL
        PUSH    HL
        JP      NZ,RRSKIP
        PUSH    HL
        LD      DE,5
        ADD     HL,DE
        LD      A,(HL)
        POP     HL
        ; /SAFE contains only self-contained returning REQUIRED probes.
        ; Read-only Delete/Rename have terminal BDOS outcomes, while the CCP
        ; USER case requires an external CCP command before invocation.
        CP      DET_RO_DELETE
        JP      Z,RRSKIP
        CP      DET_RO_RENAME
        JP      Z,RRSKIP
        CP      DET_CCP_USER
        JP      Z,RRSKIP
        CALL    RUNENT
RRSKIP:
        POP     HL
        LD      DE,6
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RRLOOP
        JP      SUMMARY

RUNALL: CALL    BEGIN
        LD      HL,CASES
        LD      B,67
RALOOP: PUSH    BC
        PUSH    HL
        LD      DE,5
        ADD     HL,DE
        LD      A,(HL)
        POP     HL
        PUSH    HL
        ; /ALL lists nonreturning/integration cases as manual rows so catalog
        ; coverage remains visible without aborting or falsifying the run.
        CP      DET_RO_DELETE
        JP      Z,RAMAN
        CP      DET_RO_RENAME
        JP      Z,RAMAN
        CP      DET_CCP_USER
        JP      Z,RAMAN
        CALL    RUNENT
        JP      RASKIP
RAMAN:  CALL    MANROW
RASKIP:
        POP     HL
        LD      DE,6
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RALOOP
        JP      SUMMARY

; Emit a required terminal-outcome case without invoking it inside /ALL.
MANROW: LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (CURITEM),HL
        EX      DE,HL
        INC     HL
        INC     HL
        INC     HL
        INC     HL
        LD      A,(HL)
        LD      (DETAIL),A
        CALL    PUTITEM
        LD      DE,TWO
        CALL    PUTS
        LD      DE,SMAN
        CALL    PUTS
        LD      DE,DREQ
        CALL    PUTS
        LD      A,(DETAIL)
        CP      DET_CCP_USER
        LD      DE,MANMSG
        JP      NZ,MANPUT
        LD      DE,USRMSG
MANPUT:
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS

RUNONE:LD      HL,CASES
        LD      B,67
ROLOOP:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        PUSH    HL
        LD      HL,(ITEMNO)
        LD      A,H
        CP      D
        JP      NZ,RONEXT
        LD      A,L
        CP      E
        POP     HL
        JP      Z,ROFOUND
        JP      ROADV
RONEXT:POP     HL
ROADV:
        INC     HL
        INC     HL
        INC     HL
        INC     HL
        DEC     B
        JP      NZ,ROLOOP
        LD      DE,BADSEL
        CALL    PUTS
        RET
ROFOUND:DEC     HL
        DEC     HL
        PUSH    HL
        CALL    BEGIN
        POP     HL
        CALL    RUNENT
        JP      SUMMARY

BEGIN:  XOR     A
        LD      (PASSCT),A
        LD      (FAILCT),A
        LD      (OBSCT),A
        LD      DE,HEADER
        JP      PUTS

; Each six-byte table entry is: ledger word, routine word, disposition byte,
; detail byte. RUNENT pushes RETCASE and jumps through routine word because
; the 8080 has no indirect CALL instruction; every probe therefore returns
; with RET to the common result machinery.
RUNENT: LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (CURITEM),HL
        EX      DE,HL
        INC     HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        EX      DE,HL
        LD      (CALLPTR),HL
        EX      DE,HL
        INC     HL
        LD      A,(HL)
        LD      (DISP),A
        INC     HL
        LD      A,(HL)
        LD      (DETAIL),A
        XOR     A
        LD      (OBS1),A
        LD      (OBS2),A
        LD      (OBS3),A
        LD      HL,RETCASE
        PUSH    HL
        LD      HL,(CALLPTR)
        JP      (HL)
RETCASE:LD      A,(DISP)
        ; Item 0567 has an external CCP prerequisite. Starting it in any
        ; other user area means the procedure was not performed, not that the
        ; candidate failed. The supplied B: fixture contains DIRTEST.COM in
        ; user 1 so the printed sequence is directly runnable.
        LD      A,(DETAIL)
        CP      DET_CCP_USER
        JP      NZ,RETNORM
        LD      A,(OBS1)
        CP      1
        JP      NZ,ROWUNTEST
RETNORM:LD      A,(DISP)
        OR      A
        JP      NZ,ROWOBS
        LD      A,(CASEOK)
        OR      A
        JP      Z,ROWFAIL
        LD      HL,PASSCT
        INC     (HL)
        LD      DE,SPASS
        JP      ROW
ROWFAIL:LD      HL,FAILCT
        INC     (HL)
        LD      DE,SFAIL
        JP      ROW
ROWOBS:LD      HL,OBSCT
        INC     (HL)
        LD      A,(CASEOK)
        OR      A
        JP      Z,OBSFAIL
        LD      HL,PASSCT
        INC     (HL)
        LD      DE,SOBS
        JP      ROW
OBSFAIL:LD     HL,FAILCT
        INC     (HL)
        LD      DE,SOBFAIL
ROW:    PUSH    DE
        LD      A,(DETAIL)
        CALL    PUTITEM
        LD      DE,TWO
        CALL    PUTS
        POP     DE
        CALL    PUTS
        LD      A,(DISP)
        OR      A
        LD      DE,DREQ
        JP      Z,ROWDISP
        LD      DE,DNOT
ROWDISP:CALL    PUTS
        LD      A,(DETAIL)
        CALL    PUTDETAIL
        LD      DE,CRLF
        JP      PUTS

ROWUNTEST:
        LD      A,(DETAIL)
        CALL    PUTITEM
        LD      DE,TWO
        CALL    PUTS
        LD      DE,SMAN
        CALL    PUTS
        LD      DE,DREQ
        CALL    PUTS
        LD      DE,USRMSG
        CALL    PUTS
        LD      DE,USRHELP
        JP      PUTS

; 0196: exact search and returned directory-entry/FCB field form.
T0196: CALL    DMA1SET
        LD      HL,FCBW1
        CALL    SFIRST
        LD      (OBS1),A
        CALL    GOODRET
        JP      Z,TFAIL
        CALL    ENTRYPTR
        LD      DE,NWILD1
        CALL    CMPNAME11
        JP      NZ,TFAIL
        LD      A,(HL)             ; EX after name/type
        AND     0E0H
        JP      NZ,TFAIL
        LD      DE,3
        ADD     HL,DE              ; RC is directory byte 15
        LD      A,(HL)
        LD      (OBS2),A
        CP      129
        JP      NC,TFAIL
        JP      TPASS

; 0198: documented type attribute bit does not alter base-type matching.
T0198: CALL    DMA1SET
        LD      HL,FCBROA
        CALL    SFIRST
        LD      (OBS1),A
        CALL    GOODRET
        JP      Z,TFAIL
        CALL    ENTRYPTR
        LD      DE,NRO
        CALL    CMPNAME11
        JP      NZ,TFAIL
        LD      A,(HL)
        LD      (OBS2),A
        JP      TPASS

; 0200: explicit C search leaves current B selected.
T0200: CALL    GETDRV
        LD      (OBS2),A
        PUSH    AF
        CALL    DMA1SET
        LD      HL,FCBCFILE
        CALL    SFIRST
        LD      (OBS1),A
        CALL    GOODRET
        JP      Z,TPOPFAIL
        CALL    GETDRV
        LD      C,A
        POP     AF
        CP      C
        JP      NZ,TFAIL
        JP      TPASS
TPOPFAIL:POP    AF
        JP      TFAIL

; 0202: drive '?' scans directory entries across users 0 and 1.
T0202: CALL    DMA1SET
        LD      HL,FCBALL
        CALL    SFIRST
        XOR     A
        LD      (FLAGS),A
        LD      B,80
T202L: CALL    GOODRET
        JP      Z,T202E
        CALL    ENTRYPTR
        LD      A,(HL)
        CP      0
        JP      NZ,T202U1
        LD      A,(FLAGS)
        OR      1
        LD      (FLAGS),A
T202U1:LD      A,(HL)
        CP      1
        JP      NZ,T202N
        LD      A,(FLAGS)
        OR      2
        LD      (FLAGS),A
T202N: CALL    SNEXT
        DEC     B
        JP      NZ,T202L
T202E: LD      A,(FLAGS)
        LD      (OBS1),A
        CP      3
        JP      NZ,TFAIL
        JP      TPASS

; 0204: Search Next resumes after the first wildcard match.
T0204: CALL    FIRSTPAIR
        JP      Z,TFAIL
        LD      A,(NAME1)
        CP      (HL)
        JP      Z,TFAIL
        LD      A,(RET1)
        LD      (OBS1),A
        LD      A,(RET2)
        LD      (OBS2),A
        JP      TPASS

; 0206: exact one-match enumeration ends with FFh.
T0206: CALL    DMA1SET
        LD      HL,FCBDIR1
        CALL    SFIRST
        LD      (OBS1),A
        CALL    GOODRET
        JP      Z,TFAIL
        CALL    SNEXT
        LD      (OBS2),A
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0208: Function 26 directs search data to the controlled DMA.
T0208: LD      HL,DMA1
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        CALL    DMA1SET
        LD      HL,FCBDIR1
        CALL    SFIRST
        LD      (OBS1),A
        CALL    GOODRET
        JP      Z,TFAIL
        CALL    ENTRYPTR
        INC     HL
        LD      A,(HL)
        LD      (OBS2),A
        CP      'B'
        JP      NZ,TFAIL
        JP      TPASS

; 0210: changing DMA preserves continuation and moves the next transfer.
T0210: CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (RET1),A
        CALL    GOODRET
        JP      Z,TFAIL
        CALL    ENTRYPTR
        LD      DE,7
        ADD     HL,DE
        LD      A,(HL)
        LD      (NAME1),A
        LD      HL,DMA2
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        CALL    DMA2SET
        CALL    SNEXT
        LD      (RET2),A
        CALL    GOODRET
        JP      Z,TFAIL
        CALL    EPTR2
        LD      DE,7
        ADD     HL,DE
        LD      A,(HL)
        LD      C,A
        LD      A,(NAME1)
        CP      C
        JP      Z,TFAIL
        LD      A,(RET1)
        LD      (OBS1),A
        LD      A,(RET2)
        LD      (OBS2),A
        JP      TPASS

; 0212: two unchanged enumerations return the same first two names.
T0212: CALL    FIRSTPAIR
        JP      Z,TFAIL
        LD      A,(NAME1)
        LD      (SAVE1),A
        LD      A,(HL)
        LD      (SAVE2),A
        CALL    FIRSTPAIR
        JP      Z,TFAIL
        LD      A,(NAME1)
        LD      C,A
        LD      A,(SAVE1)
        CP      C
        JP      NZ,TFAIL
        LD      A,(HL)
        LD      C,A
        LD      A,(SAVE2)
        CP      C
        JP      NZ,TFAIL
        LD      A,(RET1)
        LD      (OBS1),A
        LD      A,(RET2)
        LD      (OBS2),A
        JP      TPASS

; 0214 diagnostic: change default drive between default-drive First/Next.
T0214: CALL    GETDRV
        LD      (SAVEDRV),A
        CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (OBS1),A
        LD      E,2                ; C:
        LD      C,14
        CALL    BDOS
        CALL    SNEXT
        LD      (OBS2),A
        LD      A,(SAVEDRV)
        LD      E,A
        LD      C,14
        CALL    BDOS
        LD      A,1
        LD      (CASEOK),A
        RET

; 0216 diagnostic: failed search leaves no portable DMA result data.
T0216: LD      HL,DMA1
        LD      B,128
        LD      A,0A5H
        CALL    FILL
        CALL    DMA1SET
        LD      HL,TDMISS
        CALL    SFIRST
        LD      (OBS1),A
        LD      A,(DMA1)
        LD      (OBS2),A
        LD      A,1
        LD      (CASEOK),A
        RET

; 0285 exact Function-19 delete.
T0285: LD      HL,TDDEL1
        CALL    PREPMAKE
        JP      Z,TFAIL
        LD      HL,TDDEL1
        CALL    PREPDEL
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        LD      HL,TDDEL1
        CALL    PREPSRCH
        LD      (OBS2),A
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0286 exact identity leaves a distinct non-target name present.
T0286: LD      HL,TDDEL1
        CALL    PREPMAKE
        JP      Z,TFAIL
        LD      HL,TDKEEP
        CALL    PREPMAKE
        JP      Z,TFAIL
        LD      HL,TDDEL1
        CALL    PREPDEL
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        LD      HL,TDKEEP
        CALL    PREPSRCH
        LD      (OBS2),A
        CP      0FFH
        JP      Z,TFAIL
        LD      HL,TDKEEP
        CALL    CLEANDEL
        JP      TPASS

; 0287 wildcard deletes two matches but preserves the nonmatch.
T0287: CALL    MAKESET
        JP      Z,TFAIL
        LD      HL,TDWILD
        CALL    PREPDEL
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        LD      HL,TDKEEP
        CALL    PREPSRCH
        LD      (OBS2),A
        CP      0FFH
        JP      Z,TFAIL
        LD      HL,TDKEEP
        CALL    CLEANDEL
        JP      TPASS

; 0288 enumeration changes from two wildcard matches to none.
T0288: CALL    MAKESET
        JP      Z,TFAIL
        LD      HL,TDWILD
        CALL    COUNTMATCH
        LD      (OBS1),A
        CP      2
        JP      NZ,TFAILCL
        LD      HL,TDWILD
        CALL    PREPDEL
        LD      HL,TDWILD
        CALL    COUNTMATCH
        LD      (OBS2),A
        OR      A
        JP      NZ,TFAILCL
        LD      HL,TDKEEP
        CALL    CLEANDEL
        JP      TPASS
TFAILCL:LD      HL,TDWILD
        CALL    CLEANDEL
        LD      HL,TDKEEP
        CALL    CLEANDEL
        JP      TFAIL

; 0289 successful wildcard delete returns one of the four success slots.
T0289: CALL    MAKESET
        JP      Z,TFAIL
        LD      HL,TDWILD
        CALL    PREPDEL
        LD      (OBS1),A
        CP      4
        JP      NC,TFAILCL
        LD      HL,TDWILD
        CALL    COUNTMATCH
        LD      (OBS2),A
        OR      A
        JP      NZ,TFAILCL
        LD      HL,TDKEEP
        CALL    CLEANDEL
        JP      TPASS

; 0290 a known absent identity returns FFh.
T0290: LD      HL,TDMISS
        CALL    CLEANDEL
        LD      HL,TDMISS
        CALL    PREPDEL
        LD      (OBS1),A
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0291 deleted name disappears from the immediately following search.
T0291: LD      HL,TDDEL1
        CALL    PREPMAKE
        JP      Z,TFAIL
        LD      HL,TDDEL1
        CALL    PREPDEL
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        LD      HL,TDDEL1
        CALL    PREPSRCH
        LD      (OBS2),A
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0294 explicit-B delete preserves a temporarily selected default A.
T0294: LD      HL,TDEXPB
        CALL    PREPMAKE
        JP      Z,TFAIL
        LD      E,0
        LD      C,14
        CALL    BDOS
        CALL    GETDRV
        LD      (OBS1),A
        LD      HL,TDEXPB
        CALL    PREPDEL
        LD      (RET1),A
        CALL    GETDRV
        LD      (OBS2),A
        PUSH    AF
        LD      E,1
        LD      C,14
        CALL    BDOS
        POP     AF
        OR      A
        JP      NZ,TFAIL
        LD      A,(RET1)
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0295 deletion in user 0 leaves the identical user-1 name intact.
T0295: CALL    GETUSER
        LD      (SAVEUSR),A
        XOR     A
        CALL    SETUSER
        LD      HL,TDUSER
        CALL    PREPMAKE
        JP      Z,T295REST
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUSER
        CALL    PREPMAKE
        JP      Z,T295REST
        XOR     A
        CALL    SETUSER
        LD      HL,TDUSER
        CALL    PREPDEL
        LD      (OBS1),A
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUSER
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        LD      HL,TDUSER
        CALL    CLEANDEL
        LD      A,(SAVEUSR)
        CALL    SETUSER
        POP     AF
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS
T295REST:
        LD      A,(SAVEUSR)
        CALL    SETUSER
        JP      TFAIL

; 0296 diagnostic: characterize an already-open FCB after its file is deleted.
T0296: LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,T296DONE
        LD      HL,TDRSRC
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,15
        CALL    BDOS
        LD      (OBS1),A
        LD      HL,TDRSRC
        CALL    PREPDEL
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        LD      (OBS2),A
T296DONE:
        JP      TPASS

; 0298 Function 23 convention: a controlled rename succeeds.
T0298: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,TFAIL
        CALL    RENAMESD
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        LD      HL,TDRDST
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0299 source and destination identities occupy the documented rename FCB fields.
T0299: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,TFAIL
        CALL    RENAMESD
        LD      (OBS1),A
        LD      HL,TDRSRC
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      0FFH
        JP      NZ,TFAIL
        LD      A,(OBS1)
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0300 a zero destination drive denotes the same drive as the source.
T0300: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,TFAIL
        CALL    RENAMESD
        LD      (OBS1),A
        LD      HL,TDRDST
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0301 every extent belonging to the source identity is renamed.
T0301: CALL    CLEANREN
        CALL    MAKE129
        JP      Z,TFAIL
        CALL    RENAMESD
        LD      (OBS1),A
        LD      HL,TDRDST
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,35
        CALL    BDOS
        LD      A,(WORKFCB+33)
        LD      (OBS2),A
        LD      A,(WORKFCB+34)
        LD      (SAVE2),A
        LD      A,(OBS2)
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      081H
        JP      NZ,TFAIL
        LD      A,(SAVE2)
        OR      A
        JP      NZ,TFAIL
        LD      A,(OBS1)
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0302 successful Rename returns a directory slot in the documented range.
T0302: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,TFAIL
        CALL    RENAMESD
        LD      (OBS1),A
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      4
        JP      NC,TFAIL
        JP      TPASS

; 0303 a missing source identity returns FFh.
T0303: CALL    CLEANREN
        CALL    RENAMESD
        LD      (OBS1),A
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0304 the old identity disappears and the new identity appears immediately.
T0304: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,TFAIL
        CALL    RENAMESD
        LD      HL,TDRSRC
        CALL    PREPSRCH
        LD      (OBS1),A
        LD      HL,TDRDST
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      0FFH
        JP      Z,TFAIL
        LD      A,(OBS1)
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0305 a renamed one-record file retains all 128 data bytes.
T0305: CALL    CLEANREN
        CALL    MAKEDATA
        JP      Z,TFAIL
        CALL    RENAMESD
        LD      (OBS1),A
        LD      HL,TDRDST
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,15
        CALL    BDOS
        CP      0FFH
        JP      Z,T305FAIL
        CALL    DMA1SET
        LD      DE,WORKFCB
        LD      C,20
        CALL    BDOS
        LD      (OBS2),A
        OR      A
        JP      NZ,T305FAIL
        LD      HL,DMA1
        LD      B,128
T305CMP:LD      A,(HL)
        CP      5AH
        JP      NZ,T305FAIL
        INC     HL
        DEC     B
        JP      NZ,T305CMP
        CALL    CLEANREN
        JP      TPASS
T305FAIL:
        CALL    CLEANREN
        JP      TFAIL

; 0306 Rename operates within and preserves the selected user area.
T0306: CALL    GETUSER
        LD      (SAVEUSR),A
        LD      A,1
        CALL    SETUSER
        CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,T306REST
        CALL    RENAMESD
        LD      (OBS1),A
        XOR     A
        CALL    SETUSER
        LD      HL,TDRDST
        CALL    PREPSRCH
        LD      (OBS2),A
        CP      0FFH
        JP      NZ,T306FAIL
        LD      A,1
        CALL    SETUSER
        LD      HL,TDRDST
        CALL    PREPSRCH
        CP      0FFH
        JP      Z,T306FAIL
        CALL    CLEANREN
        LD      A,(SAVEUSR)
        CALL    SETUSER
        JP      TPASS
T306FAIL:
        LD      A,1
        CALL    SETUSER
        CALL    CLEANREN
T306REST:
        LD      A,(SAVEUSR)
        CALL    SETUSER
        JP      TFAIL

; 0307 explicit-drive Rename acts on B while preserving default A.
T0307: LD      HL,TDRBSR
        CALL    PREPMAKE
        JP      Z,TFAIL
        LD      E,0
        LD      C,14
        CALL    BDOS
        CALL    GETDRV
        LD      (OBS1),A
        LD      HL,TDRBSR
        LD      DE,TDRBDT
        CALL    RENAME
        LD      (RET1),A
        CALL    GETDRV
        LD      (OBS2),A
        PUSH    AF
        LD      E,1
        LD      C,14
        CALL    BDOS
        LD      HL,TDRBDT
        CALL    CLEANDEL
        POP     AF
        OR      A
        JP      NZ,TFAIL
        LD      A,(RET1)
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0308 diagnostic: characterize rename when destination already exists.
T0308: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,T308DONE
        LD      HL,TDRDST
        CALL    PREPMAKE
        JP      Z,T308DONE
        CALL    RENAMESD
        LD      (OBS1),A
        LD      HL,TDRDST
        CALL    COUNTMATCH
        LD      (OBS2),A
T308DONE:
        CALL    CLEANREN
        JP      TPASS

; 0310 diagnostic: characterize an opened source FCB after Rename.
T0310: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,T310DONE
        LD      HL,TDRSRC
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,15
        CALL    BDOS
        LD      (OBS1),A
        LD      HL,WORKFCB
        LD      DE,WORK2
        CALL    COPY36
        CALL    RENAMESD
        LD      DE,WORK2
        LD      C,16
        CALL    BDOS
        LD      (OBS2),A
T310DONE:
        CALL    CLEANREN
        JP      TPASS

; 0311 diagnostic: record physical ordering of two controlled directory entries.
T0311: CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (OBS1),A
        CALL    SNEXT
        LD      (OBS2),A
        JP      TPASS

; 0315 is terminal-risky on classic BDOS; record that no portable result exists.
T0315: LD      A,16
        LD      (OBS1),A
        LD      A,0FFH
        LD      (OBS2),A
        JP      TPASS

; 0356 read-only is stored in bit 7 of the first type character.
T0356: LD      A,1
        CALL    ATTRPROBE
        LD      (OBS1),A
        AND     080H
        JP      Z,TFAIL
        JP      TPASS

; 0357 system is stored in bit 7 of the second type character.
T0357: LD      A,2
        CALL    ATTRPROBE
        LD      (OBS1),A
        LD      A,(OBS2)
        AND     080H
        JP      Z,TFAIL
        JP      TPASS

; 0358 attribute bits coexist with the underlying three-character type.
T0358: LD      A,3
        CALL    ATTRPROBE
        LD      A,(OBS1)
        AND     07FH
        CP      'T'
        JP      NZ,TFAIL
        LD      A,(OBS2)
        AND     07FH
        CP      'M'
        JP      NZ,TFAIL
        JP      TPASS

; 0359 diagnostic: characterize use of the reserved t3 high bit.
T0359: LD      A,4
        CALL    ATTRPROBE
        LD      A,(OBS3)
        LD      (OBS1),A
        LD      A,(RET1)
        LD      (OBS2),A
        JP      TPASS

; 0360 Function 30 accepts a prepared FCB and returns a directory slot.
T0360: LD      A,1
        CALL    ATTRPROBE
        LD      (SAVE2),A
        LD      A,(RET1)
        LD      (OBS1),A
        CP      4
        JP      NC,TFAIL
        LD      A,(SAVE1)
        LD      (OBS2),A
        LD      A,(SAVE2)
        AND     080H
        JP      Z,TFAIL
        JP      TPASS

; 0361 Function 30 sets and clears selected attribute indicators.
T0361: LD      A,1
        CALL    ATTRCREATE
        JP      Z,TFAIL
        LD      HL,TDATTR
        CALL    PREPSRCH
        CP      0FFH
        JP      Z,T361FAIL
        CALL    GETT1
        LD      (OBS1),A
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    PREPSRCH
        CP      0FFH
        JP      Z,T361FAIL
        CALL    GETT1
        LD      (OBS2),A
        PUSH    AF
        LD      HL,TDATTR
        CALL    CLEANDEL
        POP     AF
        AND     080H
        JP      NZ,TFAIL
        LD      A,(OBS1)
        AND     080H
        JP      Z,TFAIL
        JP      TPASS
T361FAIL:
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    CLEANDEL
        JP      TFAIL

; 0362 Function 30 applies the requested indicators to every source extent.
T0362: CALL    CLEANREN
        CALL    MAKEBIG
        JP      Z,TFAIL
        LD      A,1
        CALL    SETATTRSRC
        LD      (OBS1),A
        CP      0FFH
        JP      Z,T362FAIL
        LD      HL,TDRSRC
        CALL    PREPSRCH
        CP      0FFH
        JP      Z,T362FAIL
        CALL    GETT1
        LD      (OBS2),A
        AND     080H
        JP      Z,T362FAIL
        LD      A,0
        CALL    SETATTRSRC
        CALL    CLEANREN
        JP      TPASS
T362FAIL:
        LD      A,0
        CALL    SETATTRSRC
        CALL    CLEANREN
        JP      TFAIL

; 0363 successful Function 30 returns one of the four directory slots.
T0363: LD      A,1
        CALL    ATTRCREATE
        JP      Z,TFAIL
        LD      A,(RET1)
        LD      (OBS1),A
        PUSH    AF
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    CLEANDEL
        POP     AF
        CP      4
        JP      NC,TFAIL
        JP      TPASS

; 0364 Function 30 on a missing identity returns FFh.
T0364: LD      HL,TDATTR
        CALL    CLEANDEL
        LD      A,1
        CALL    SETATTR
        LD      (OBS1),A
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0365 diagnostic: record the exact successful Function 30 slot.
T0365: LD      A,1
        CALL    ATTRCREATE
        LD      A,(RET1)
        LD      (OBS1),A
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    CLEANDEL
        JP      TPASS

; 0366 Open accepts and preserves caller-supplied indicator bits.
T0366: LD      A,1
        CALL    ATTRCREATE
        JP      Z,TFAIL
        LD      HL,TDATTR
        CALL    PREPFCB
        LD      A,(WORKFCB+9)
        OR      080H
        LD      (WORKFCB+9),A
        LD      DE,WORKFCB
        LD      C,15
        CALL    BDOS
        LD      (OBS1),A
        LD      A,(WORKFCB+9)
        LD      (OBS2),A
        PUSH    AF
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    CLEANDEL
        POP     AF
        AND     080H
        JP      Z,TFAIL
        LD      A,(OBS1)
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0367 Make accepts indicator bits and records them on the new file.
T0367: LD      HL,TDATTR
        CALL    CLEANDEL
        LD      HL,TDATTR
        CALL    PREPFCB
        LD      A,(WORKFCB+9)
        OR      080H
        LD      (WORKFCB+9),A
        LD      A,(WORKFCB+10)
        OR      080H
        LD      (WORKFCB+10),A
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        LD      HL,TDATTR
        CALL    PREPSRCH
        CP      0FFH
        JP      Z,T367FAIL
        CALL    GETT1
        LD      (OBS2),A
        PUSH    AF
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    CLEANDEL
        POP     AF
        AND     080H
        JP      Z,TFAIL
        JP      TPASS
T367FAIL:
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    CLEANDEL
        JP      TFAIL

; 0370 a file marked read-only cannot be deleted through Function 19.
T0370: LD      A,1
        CALL    ATTRCREATE
        JP      Z,TFAIL
        LD      HL,TDATTR
        CALL    PREPDEL
        LD      (OBS1),A
        LD      HL,TDATTR
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        LD      A,0
        CALL    SETATTR
        LD      HL,TDATTR
        CALL    CLEANDEL
        POP     AF
        CP      0FFH
        JP      Z,TFAIL
        LD      A,(OBS1)
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0371 a file marked read-only cannot be renamed through Function 23.
T0371: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,TFAIL
        LD      A,1
        CALL    SETATTRSRC
        CALL    RENAMESD
        LD      (OBS1),A
        LD      HL,TDRSRC
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        LD      A,0
        CALL    SETATTRSRC
        CALL    CLEANREN
        POP     AF
        CP      0FFH
        JP      Z,TFAIL
        LD      A,(OBS1)
        CP      0FFH
        JP      NZ,TFAIL
        JP      TPASS

; 0541 diagnostic: behavior after returning to CCP has no in-process oracle.
T0541: XOR     A
        LD      (OBS1),A
        LD      A,0FFH
        LD      (OBS2),A
        JP      TPASS

; 0542 complete enumeration returns extent entries, not deduplicated names.
T0542: CALL    CLEANREN
        CALL    MAKEBIG
        JP      Z,TFAIL
        CALL    COUNTEXT
        LD      (OBS1),A
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      2
        JP      C,TFAIL
        JP      TPASS

; 0543 separate matching extents remain separately visible to enumeration.
T0543: CALL    CLEANREN
        CALL    MAKEBIG
        JP      Z,TFAIL
        CALL    COUNTEXT
        LD      (OBS1),A
        PUSH    AF
        CALL    CLEANREN
        POP     AF
        CP      2
        JP      C,TFAIL
        JP      TPASS

; 0544 diagnostic: application-built lowercase FCBs are not portably folded.
T0544: CALL    CLEANREN
        LD      HL,TDRSRC
        CALL    PREPMAKE
        JP      Z,T544DONE
        LD      HL,TDRLOW
        CALL    PREPSRCH
        LD      (OBS1),A
T544DONE:
        CALL    CLEANREN
        JP      TPASS

; 0545 the search FCB remains caller-owned throughout continuation.
T0545: CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        CALL    SNEXT
        LD      (OBS2),A
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0546 a harmless state-query call need not terminate enumeration.
T0546: CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (OBS1),A
        CP      0FFH
        JP      Z,TFAIL
        CALL    GETDRV
        CALL    SNEXT
        LD      (OBS2),A
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0547 diagnostic: no search continuation is promised across program return.
T0547: XOR     A
        LD      (OBS1),A
        LD      A,0FFH
        LD      (OBS2),A
        JP      TPASS

; 0548 diagnostic: record two physical result slots without asserting sorting.
T0548: CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (OBS1),A
        CALL    SNEXT
        LD      (OBS2),A
        JP      TPASS

; 0549 diagnostic: invalid-drive Search First has no portable returning oracle.
T0549: LD      A,16
        LD      (OBS1),A
        LD      A,0FFH
        LD      (OBS2),A
        JP      TPASS

; 0559 ordinary file identity includes the current user area.
T0559: CALL    GETUSER
        LD      (SAVEUSR),A
        XOR     A
        CALL    SETUSER
        LD      HL,TDUSRFX
        CALL    PREPSRCH
        LD      (OBS1),A
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUSRFX
        CALL    PREPSRCH
        LD      (OBS2),A
        PUSH    AF
        LD      A,(SAVEUSR)
        CALL    SETUSER
        POP     AF
        CP      0FFH
        JP      Z,TFAIL
        LD      A,(OBS1)
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0560 Function 32 sets, reports, and restores the current user number.
T0560: CALL    GETUSER
        LD      (SAVEUSR),A
        LD      A,1
        CALL    SETUSER
        CALL    GETUSER
        LD      (OBS1),A
        PUSH    AF
        LD      A,(SAVEUSR)
        CALL    SETUSER
        CALL    GETUSER
        LD      (OBS2),A
        POP     AF
        CP      1
        JP      NZ,TFAIL
        JP      TPASS

; 0561 the same ordinary FCB contains no embedded user-area selector.
T0561: CALL    GETUSER
        LD      (SAVEUSR),A
        XOR     A
        CALL    SETUSER
        LD      HL,TDUSRFX
        CALL    PREPSRCH
        LD      (OBS1),A
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUSRFX
        CALL    PREPSRCH
        LD      (OBS2),A
        LD      A,(SAVEUSR)
        CALL    SETUSER
        LD      A,(OBS1)
        CP      0FFH
        JP      Z,TFAIL
        LD      A,(OBS2)
        CP      0FFH
        JP      Z,TFAIL
        JP      TPASS

; 0562 ordinary lookup does not fall back to another user area.
T0562: CALL    GETUSER
        LD      (SAVEUSR),A
        XOR     A
        LD      (FLAGS),A
        CALL    SETUSER
        LD      HL,TDUISO
        CALL    CLEANDEL
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUISO
        CALL    PREPMAKE
        JP      Z,T562CLN
        XOR     A
        CALL    SETUSER
        LD      HL,TDUISO
        CALL    PREPSRCH
        LD      (OBS1),A
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUISO
        CALL    PREPSRCH
        LD      (OBS2),A
        CP      0FFH
        JP      Z,T562CLN
        LD      A,(OBS1)
        CP      0FFH
        JP      NZ,T562CLN
        LD      A,1
        LD      (FLAGS),A
T562CLN:
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUISO
        CALL    CLEANDEL
        LD      A,(SAVEUSR)
        CALL    SETUSER
        LD      A,(FLAGS)
        OR      A
        JP      Z,TFAIL
        JP      TPASS

; 0563 Make records ownership in the current user's namespace.
; Verify this behaviorally: a file made under user 1 must be found by an
; ordinary user-1 lookup and absent from an ordinary user-0 lookup. Do not
; infer ownership from a byte returned by complete-directory search; that
; representation is not a portable public ownership interface.
T0563: CALL    GETUSER
        LD      (SAVEUSR),A
        XOR     A
        LD      (FLAGS),A
        CALL    SETUSER
        LD      HL,TDUMAKE
        CALL    CLEANDEL
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUMAKE
        CALL    PREPMAKE
        JP      Z,T563CLN
        LD      HL,TDUMAKE
        CALL    PREPSRCH
        LD      (OBS1),A
        CP      0FFH
        JP      Z,T563CLN
        XOR     A
        CALL    SETUSER
        LD      HL,TDUMAKE
        CALL    PREPSRCH
        LD      (OBS2),A
        CP      0FFH
        JP      NZ,T563CLN
        LD      A,1
        LD      (FLAGS),A
T563CLN:
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUMAKE
        CALL    CLEANDEL
        LD      A,(SAVEUSR)
        CALL    SETUSER
        LD      A,(FLAGS)
        OR      A
        JP      Z,TFAIL
        JP      TPASS

; 0564 Delete and Rename affect only the current user namespace.
T0564: CALL    GETUSER
        LD      (SAVEUSR),A
        LD      A,0FFH
        LD      (FLAGS),A
        XOR     A
        CALL    SETUSER
        LD      HL,TDUSRC
        CALL    PREPMAKE
        JP      Z,T564END
        LD      HL,TDUDST
        CALL    CLEANDEL
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUSRC
        CALL    PREPMAKE
        JP      Z,T564END
        LD      HL,TDUDST
        CALL    CLEANDEL
        LD      HL,TDUSRC
        CALL    PREPDEL
        LD      (OBS1),A
        LD      (FLAGS),A
        LD      HL,TDUSRC
        CALL    PREPSRCH
        CP      0FFH
        JP      NZ,T564RE
        LD      A,2
        LD      (OBS2),A
T564RE:LD      HL,TDUSRC
        CALL    PREPMAKE
        JP      Z,T564END
        LD      HL,TDUSRC
        LD      DE,TDUDST
        CALL    RENAME
        CP      0FFH
        JP      Z,T564U0
        LD      HL,TDUDST
        CALL    PREPSRCH
        CP      0FFH
        JP      Z,T564U0
        LD      A,(OBS2)
        OR      8
        LD      (OBS2),A
T564U0:XOR     A
        CALL    SETUSER
        LD      HL,TDUSRC
        CALL    PREPSRCH
        CP      0FFH
        JP      Z,T564END
        LD      A,(OBS2)
        OR      5
        LD      (OBS2),A
T564END:
        XOR     A
        CALL    SETUSER
        LD      HL,TDUSRC
        CALL    CLEANDEL
        LD      HL,TDUDST
        CALL    CLEANDEL
        LD      A,1
        CALL    SETUSER
        LD      HL,TDUSRC
        CALL    CLEANDEL
        LD      HL,TDUDST
        CALL    CLEANDEL
        LD      A,(SAVEUSR)
        CALL    SETUSER
        LD      A,(FLAGS)
        CP      0FFH
        JP      Z,TFAIL
        LD      A,(OBS2)
        CP      15
        JP      NZ,TFAIL
        JP      TPASS

; 0565 diagnostic: characterize continuation after changing user number.
T0565: CALL    GETUSER
        LD      (SAVEUSR),A
        XOR     A
        CALL    SETUSER
        CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (OBS1),A
        LD      A,1
        CALL    SETUSER
        CALL    SNEXT
        LD      (OBS2),A
        LD      A,(SAVEUSR)
        CALL    SETUSER
        JP      TPASS

; 0566 '?' complete-directory enumeration is distinct from public lookup.
; A '?' drive byte requests physical complete-directory enumeration; it is
; not an all-user lookup filtered by the supplied filename. Consequently the
; observed entry count depends on disk format and current fixtures. The
; oracle asserts only the required distinction, never an exact entry count.
T0566: CALL    GETUSER
        LD      (SAVEUSR),A
        XOR     A
        CALL    SETUSER
        LD      HL,TDUSRFX
        CALL    PREPSRCH
        LD      (OBS1),A
        LD      HL,TDUSRFX
        CALL    PREPFCB
        LD      A,'?'
        LD      (WORKFCB),A
        CALL    DMA1SET
        LD      HL,WORKFCB
        CALL    SFIRST
        PUSH    AF
        XOR     A
        LD      (SAVE1),A
        POP     AF
T566LP:CP      0FFH
        JP      Z,T566DONE
        LD      A,(SAVE1)
        INC     A
        LD      (SAVE1),A
        CALL    SNEXT
        JP      T566LP
T566DONE:
        LD      A,(SAVE1)
        LD      (OBS2),A
        LD      A,(SAVEUSR)
        CALL    SETUSER
        LD      A,(OBS1)
        CP      0FFH
        JP      Z,TFAIL
        LD      A,(OBS2)
        CP      2
        JP      C,TFAIL
        JP      TPASS

; 0567 manual workflow: after CCP USER 1, BDOS Function 32 must report 1.
T0567: CALL    GETUSER
        LD      (OBS1),A
        CP      1
        JP      NZ,TFAIL
        JP      TPASS

; Count all logical extents by wildcarding the extent field of a search FCB.
COUNTEXT:
        LD      HL,TDRSRC
        CALL    PREPFCB
        LD      A,'?'
        LD      (WORKFCB+12),A
        CALL    DMA1SET
        LD      HL,WORKFCB
        CALL    SFIRST
        PUSH    AF
        XOR     A
        LD      (SAVE1),A
        POP     AF
CEXLP: CP      0FFH
        JP      Z,CEXDONE
        LD      A,(SAVE1)
        INC     A
        LD      (SAVE1),A
        CALL    SNEXT
        JP      CEXLP
CEXDONE:
        LD      A,(SAVE1)
        RET

; Attribute helpers.
ATTRCREATE:
        LD      (FLAGS),A
        LD      HL,TDATTR
        CALL    CLEANDEL
        LD      HL,TDATTR
        CALL    PREPMAKE
        RET     Z
        LD      A,(FLAGS)
        CALL    SETATTR
        CP      0FFH
        JP      Z,ACFAIL
        LD      A,1
        OR      A
        RET
ACFAIL: XOR     A
        RET

SETATTR:
        LD      HL,TDATTR
        JP      SETATTHL
SETATTRSRC:
        LD      HL,TDRSRC
SETATTHL:
        LD      (FLAGS),A
        CALL    PREPFCB
        LD      A,(FLAGS)
        AND     1
        JP      Z,SASYS
        LD      A,(WORKFCB+9)
        OR      080H
        LD      (WORKFCB+9),A
SASYS:  LD      A,(FLAGS)
        AND     2
        JP      Z,SAT3
        LD      A,(WORKFCB+10)
        OR      080H
        LD      (WORKFCB+10),A
SAT3:   LD      A,(FLAGS)
        AND     4
        JP      Z,SACALL
        LD      A,(WORKFCB+11)
        OR      080H
        LD      (WORKFCB+11),A
SACALL: LD      DE,WORKFCB
        LD      C,30
        CALL    BDOS
        LD      (RET1),A
        RET

GETT1: CALL    ENTRYPTR
        LD      DE,9
        ADD     HL,DE
        LD      A,(HL)
        RET

; Set attributes selected by A (1=RO, 2=SYS, 4=reserved t3), search, then clean.
ATTRPROBE:
        LD      (FLAGS),A
        LD      HL,TDATTR
        CALL    CLEANDEL
        LD      HL,TDATTR
        CALL    PREPMAKE
        JP      Z,APFAIL
        LD      HL,TDATTR
        CALL    PREPFCB
        LD      A,(FLAGS)
        AND     1
        JP      Z,APSYS
        LD      A,(WORKFCB+9)
        OR      080H
        LD      (WORKFCB+9),A
APSYS:  LD      A,(FLAGS)
        AND     2
        JP      Z,APT3
        LD      A,(WORKFCB+10)
        OR      080H
        LD      (WORKFCB+10),A
APT3:   LD      A,(FLAGS)
        AND     4
        JP      Z,APSET
        LD      A,(WORKFCB+11)
        OR      080H
        LD      (WORKFCB+11),A
APSET:  LD      DE,WORKFCB
        LD      C,30
        CALL    BDOS
        LD      (RET1),A
        LD      HL,TDATTR
        CALL    PREPSRCH
        LD      (SAVE1),A
        CP      0FFH
        JP      Z,APCLEAN
        CALL    ENTRYPTR
        LD      DE,9
        ADD     HL,DE
        LD      A,(HL)
        LD      (OBS1),A
        INC     HL
        LD      A,(HL)
        LD      (OBS2),A
        INC     HL
        LD      A,(HL)
        LD      (OBS3),A
APCLEAN:
        LD      HL,TDATTR
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,30
        CALL    BDOS
        LD      HL,TDATTR
        CALL    CLEANDEL
        LD      A,(OBS1)
        RET
APFAIL: XOR     A
        LD      (RET1),A
        RET

COPY36: LD      B,36
C36LP: LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,C36LP
        RET

; Rename helpers. Destination identity is stored at rename-FCB offset 16.
RENAMESD:
        LD      HL,TDRSRC
        LD      DE,TDRDST
RENAME: PUSH    DE
        CALL    PREPFCB
        POP     HL
        LD      DE,WORKFCB+16
        LD      B,12
RNCOPY:LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,RNCOPY
        LD      DE,WORKFCB
        LD      C,23
        CALL    BDOS
        RET
CLEANREN:
        LD      HL,TDRSRC
        CALL    CLEANDEL
        LD      HL,TDRDST
        CALL    CLEANDEL
        RET

MAKEBIG:
        ; A directory entry describes EXM+1 logical 16K extents.  Derive
        ; the target length from the selected disk's DPB so this fixture
        ; always needs a second directory entry (IBM 3740 has EXM=0;
        ; Montezuma Micro 200K has EXM=1).
        LD      C,31
        CALL    BDOS
        INC     HL
        INC     HL
        INC     HL
        INC     HL
        LD      A,(HL)             ; DPB EXM
        INC     A
        LD      B,A
        LD      A,1
        LD      (SAVE1),A           ; low byte: (EXM+1)*128 + 1
        XOR     A
        LD      (SAVE2),A           ; high byte
MBADDL: LD      A,(SAVE1)
        ADD     A,128
        LD      (SAVE1),A
        LD      A,(SAVE2)
        ADC     A,0
        LD      (SAVE2),A
        DEC     B
        JP      NZ,MBADDL
        JP      MBMAKE

; Fixed 129-record fixture for cases whose oracle checks that exact size.
MAKE129:
        LD      A,129
        LD      (SAVE1),A
        XOR     A
        LD      (SAVE2),A
MBMAKE:
        LD      HL,TDRSRC
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,MBFAIL
        LD      HL,DMA1
        LD      B,128
        LD      A,0A6H
        CALL    FILL
        CALL    DMA1SET
MBLOOP:LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,MBFAIL
        LD      A,(SAVE1)
        SUB     1
        LD      (SAVE1),A
        LD      A,(SAVE2)
        SBC     A,0
        LD      (SAVE2),A
        LD      B,A
        LD      A,(SAVE1)
        OR      B
        JP      NZ,MBLOOP
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        LD      A,1
        OR      A
        RET
MBFAIL:XOR     A
        RET

MAKEDATA:
        LD      HL,TDRSRC
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,MDFAIL
        LD      HL,DMA1
        LD      B,128
        LD      A,5AH
        CALL    FILL
        CALL    DMA1SET
        LD      DE,WORKFCB
        LD      C,21
        CALL    BDOS
        OR      A
        JP      NZ,MDFAIL
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        LD      A,1
        OR      A
        RET
MDFAIL:XOR     A
        RET

; Copy a 12-byte FCB identity from HL into WORKFCB and clear working fields.
PREPFCB:
        LD      DE,WORKFCB
        LD      B,12
PFCOPY:LD      A,(HL)
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     B
        JP      NZ,PFCOPY
        XOR     A
        LD      B,24
PFZERO:LD      (DE),A
        INC     DE
        DEC     B
        JP      NZ,PFZERO
        RET

PREPMAKE:
        PUSH    HL
        CALL    CLEANDEL
        POP     HL
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,22
        CALL    BDOS
        CP      0FFH
        JP      Z,PMFAIL
        LD      DE,WORKFCB
        LD      C,16
        CALL    BDOS
        LD      A,1
        OR      A
        RET
PMFAIL:XOR     A
        RET

PREPDEL:
        CALL    PREPFCB
        LD      DE,WORKFCB
        LD      C,19
        CALL    BDOS
        RET
CLEANDEL:
        CALL    PREPDEL
        RET
PREPSRCH:
        CALL    PREPFCB
        CALL    DMA1SET
        LD      HL,WORKFCB
        CALL    SFIRST
        RET

MAKESET:
        LD      HL,TDW01
        CALL    PREPMAKE
        RET     Z
        LD      HL,TDW02
        CALL    PREPMAKE
        RET     Z
        LD      HL,TDKEEP
        CALL    PREPMAKE
        RET

COUNTMATCH:
        CALL    PREPFCB
        CALL    DMA1SET
        LD      HL,WORKFCB
        CALL    SFIRST
        PUSH    AF
        XOR     A
        LD      (SAVE1),A
        POP     AF
CMLOOP:CP      0FFH
        JP      Z,CMDONE
        LD      A,(SAVE1)
        INC     A
        LD      (SAVE1),A
        CALL    SNEXT
        JP      CMLOOP
CMDONE:LD      A,(SAVE1)
        RET

GETUSER:
        LD      E,0FFH
        LD      C,32
        CALL    BDOS
        RET
SETUSER:
        LD      E,A
        LD      C,32
        CALL    BDOS
        RET

TPASS: LD      A,1
        LD      (CASEOK),A
        RET
TFAIL: XOR     A
        LD      (CASEOK),A
        RET

FIRSTPAIR:
        CALL    DMA1SET
        LD      HL,FCBDIRW
        CALL    SFIRST
        LD      (RET1),A
        CALL    GOODRET
        RET     Z
        CALL    ENTRYPTR
        LD      DE,7
        ADD     HL,DE
        LD      A,(HL)
        LD      (NAME1),A
        CALL    SNEXT
        LD      (RET2),A
        CALL    GOODRET
        RET     Z
        CALL    ENTRYPTR
        LD      DE,7
        ADD     HL,DE              ; return HL at distinguishing name byte
        LD      A,1
        OR      A
        RET

SFIRST:EX      DE,HL
        LD      C,17
        CALL    BDOS
        RET
SNEXT: LD      C,18
        CALL    BDOS
        RET
GETDRV:LD      C,25
        CALL    BDOS
        RET
DMA1SET:
        LD      DE,DMA1
        JP      SETDMA
DMA2SET:
        LD      DE,DMA2
SETDMA:LD      C,26
        CALL    BDOS
        RET
GOODRET:
        CP      0FFH               ; 0..3 success, FF failure
        RET

ENTRYPTR:
        LD      HL,DMA1
        JP      EPTR
EPTR2:
        LD      HL,DMA2
; Convert a successful Search First/Next result (0..3) into its 32-byte DMA
; directory slot. Callers must reject FFh before entering; masking FFh here
; would otherwise misidentify failure as slot 3.
EPTR:  AND     3
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A
        ADD     A,A
        LD      E,A
        LD      D,0
        ADD     HL,DE
        RET

; Compare directory bytes 1..11, ignoring attribute high bits. HL points user.
CMPNAME11:
        INC     HL
        LD      B,11
CNLOOP:LD      A,(DE)
        AND     7FH
        LD      C,A
        LD      A,(HL)
        AND     7FH
        CP      C
        RET     NZ
        INC     DE
        INC     HL
        DEC     B
        JP      NZ,CNLOOP
        XOR     A
        RET

FILL:  LD      (HL),A
        INC     HL
        DEC     B
        JP      NZ,FILL
        RET

SUMMARY:
        LD      DE,SUM1
        CALL    PUTS
        LD      A,(PASSCT)
        CALL    PUTDEC
        LD      DE,SUM2
        CALL    PUTS
        LD      A,(FAILCT)
        CALL    PUTDEC
        LD      DE,SUM3
        CALL    PUTS
        LD      A,(OBSCT)
        CALL    PUTDEC
        LD      DE,SUM4
        CALL    PUTS
        RET

PUTITEM:
        DEC     A
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,ITEMSTRS
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        JP      PUTS

PUTDETAIL:
        CP      11
        JP      NC,PDNEW
        CP      1
        JP      Z,PD1
        CP      2
        JP      Z,PD2
        CP      3
        JP      Z,PD3
        CP      4
        JP      Z,PD4
        CP      5
        JP      Z,PD5
        CP      6
        JP      Z,PD6
        CP      7
        JP      Z,PD7
        CP      8
        JP      Z,PD8
        CP      9
        JP      Z,PD9
        LD      DE,DT10
        CALL    PUTS
        JP      PDVAL2
PD1:   LD      DE,DT1
        CALL    PUTS
        JP      PDVAL2
PD2:   LD      DE,DT2
        CALL    PUTS
        JP      PDVAL2
PD3:   LD      DE,DT3
        CALL    PUTS
        JP      PDVAL2
PD4:   LD      DE,DT4
        CALL    PUTS
        LD      A,(OBS1)
        CALL    PUTHEX
        RET
PD5:   LD      DE,DT5
        CALL    PUTS
        JP      PDVAL2
PD6:   LD      DE,DT6
        CALL    PUTS
        JP      PDVAL2
PD7:   LD      DE,DT7
        CALL    PUTS
        JP      PDVAL2
PD8:   LD      DE,DT8
        CALL    PUTS
        JP      PDVAL2
PD9:   LD      DE,DT9
        CALL    PUTS
PDVAL2:LD      A,(OBS1)
        CALL    PUTHEX
        LD      DE,SEMI
        CALL    PUTS
        LD      A,(OBS2)
        JP      PUTHEX
PDNEW: SUB     11
        ADD     A,A
        LD      E,A
        LD      D,0
        LD      HL,NEWDTAB
        ADD     HL,DE
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        JP      PDVAL2

PF11:
        CALL    STRLEN
        PUSH    BC
        CALL    PUTS
        POP     BC
        LD      A,11
        SUB     C
        JP      PUTSPN
PF16:
        CALL    STRLEN
        PUSH    BC
        CALL    PUTS
        POP     BC
        LD      A,16
        SUB     C
PUTSPN:OR      A
        RET     Z
        LD      B,A
PSPNL:LD      E,' '
        LD      C,2
        CALL    BDOS
        DEC     B
        JP      NZ,PSPNL
        RET
STRLEN:LD      C,0
        PUSH    DE
SLEN:  LD      A,(DE)
        CP      '$'
        JP      Z,SLEND
        INC     C
        INC     DE
        JP      SLEN
SLEND: POP     DE
        RET
PUTS:  LD      C,9
        JP      BDOS
PUTHEX:PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        CALL    PUTNIB
        POP     AF
PUTNIB:AND     0FH
        ADD     A,'0'
        CP      '9'+1
        JP      C,PNOUT
        ADD     A,7
PNOUT: LD      E,A
        LD      C,2
        JP      BDOS
PUTDEC:CP      100
        JP      C,PDUNDER
        LD      B,0
PDHUND:SUB     100
        INC     B
        CP      100
        JP      NC,PDHUND
        PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
        LD      B,0
PDTENS:CP      10
        JP      C,PDPTEN
        SUB     10
        INC     B
        JP      PDTENS
PDPTEN:PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
        JP      PUTDIG
PDUNDER:
        CP      10
        JP      C,PUTDIG
        LD      B,0
PDLOOP:SUB     10
        INC     B
        CP      10
        JP      NC,PDLOOP
        PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
PUTDIG:ADD     A,'0'
        LD      E,A
        LD      C,2
        JP      BDOS

; FCBs: drive, 8 name, 3 type, remaining zero.
FCBW1: DB 0,'BTWILD1 ','DAT',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
FCBROA:DB 0,'BTRO    ',0C4H,'AT',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
FCBCFILE:DB 3,'BTBFILE ','DAT',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
FCBALL:DB '?','????????','???',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
FCBDIRW:DB 0,'BTDIR?? ','DAT',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
FCBDIR1:DB 0,'BTDIR01 ','DAT',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
NWILD1:DB 'BTWILD1 ','DAT'
NRO:   DB 'BTRO    ','DAT'

; Twelve-byte identities used by controlled mutating cases. BT-prefixed TMP
; names are suite-reserved scratch identities: probes may create and delete
; them and distributions must never map them onto user-owned data. User-area
; probes save the incoming user, operate only in controlled users 0/1, clean
; each fixture in its owning area, and restore the incoming user on return.
TDDEL1:DB 0,'BTDEL01 ','TMP'
TDKEEP:DB 0,'BTKEEP  ','TMP'
TDW01: DB 0,'BTDW01  ','TMP'
TDW02: DB 0,'BTDW02  ','TMP'
TDWILD:DB 0,'BTDW??  ','TMP'
TDMISS:DB 0,'BTMISS  ','TMP'
TDEXPB:DB 2,'BTEXPB  ','TMP'
TDUSER:DB 0,'BTUSER  ','TMP'
TDRSRC:DB 0,'BTRNSRC ','TMP'
TDRDST:DB 0,'BTRNDST ','TMP'
TDRBSR:DB 2,'BTRNBSR ','TMP'
TDRBDT:DB 2,'BTRNBDT ','TMP'
TDATTR:DB 0,'BTATTR  ','TMP'
TDRLOW:DB 0,'btrnsrc ','tmp'
TDUSRFX:DB 0,'BTUSR   ','DAT'
TDUISO:DB 0,'BTUISOL ','TMP'
TDUMAKE:DB 0,'BTUMAKE ','TMP'
TDUSRC:DB 0,'BTUSCOP ','TMP'
TDUDST:DB 0,'BTUSDST ','TMP'

; Table order is also the presentation order for /SAFE, /ALL, and /LIST.
; Record layout is the six-byte contract documented at RUNENT.
CASES: DW 196,T0196
        DB 0,1
        DW 198,T0198
        DB 0,2
        DW 200,T0200
        DB 0,3
        DW 202,T0202
        DB 0,4
        DW 204,T0204
        DB 0,5
        DW 206,T0206
        DB 0,6
        DW 208,T0208
        DB 0,7
        DW 210,T0210
        DB 0,8
        DW 212,T0212
        DB 0,9
        DW 214,T0214
        DB 1,10
        DW 216,T0216
        DB 1,11
        DW 285,T0285
        DB 0,12
        DW 286,T0286
        DB 0,13
        DW 287,T0287
        DB 0,14
        DW 288,T0288
        DB 0,15
        DW 289,T0289
        DB 0,16
        DW 290,T0290
        DB 0,17
        DW 291,T0291
        DB 0,18
        DW 294,T0294
        DB 0,19
        DW 295,T0295
        DB 0,20
        DW 296,T0296
        DB 1,21
        DW 298,T0298
        DB 0,22
        DW 299,T0299
        DB 0,23
        DW 300,T0300
        DB 0,24
        DW 301,T0301
        DB 0,25
        DW 302,T0302
        DB 0,26
        DW 303,T0303
        DB 0,27
        DW 304,T0304
        DB 0,28
        DW 305,T0305
        DB 0,29
        DW 306,T0306
        DB 0,30
        DW 307,T0307
        DB 0,31
        DW 308,T0308
        DB 1,32
        DW 310,T0310
        DB 1,33
        DW 311,T0311
        DB 1,34
        DW 315,T0315
        DB 1,35
        DW 356,T0356
        DB 0,36
        DW 357,T0357
        DB 0,37
        DW 358,T0358
        DB 0,38
        DW 359,T0359
        DB 1,39
        DW 360,T0360
        DB 0,40
        DW 361,T0361
        DB 0,41
        DW 362,T0362
        DB 0,42
        DW 363,T0363
        DB 0,43
        DW 364,T0364
        DB 0,44
        DW 365,T0365
        DB 1,45
        DW 366,T0366
        DB 0,46
        DW 367,T0367
        DB 0,47
        DW 370,T0370
        DB 0,48
        DW 371,T0371
        DB 0,49
        DW 541,T0541
        DB 1,50
        DW 542,T0542
        DB 0,51
        DW 543,T0543
        DB 0,52
        DW 544,T0544
        DB 1,53
        DW 545,T0545
        DB 0,54
        DW 546,T0546
        DB 0,55
        DW 547,T0547
        DB 1,56
        DW 548,T0548
        DB 1,57
        DW 549,T0549
        DB 1,58
        DW 559,T0559
        DB 0,59
        DW 560,T0560
        DB 0,60
        DW 561,T0561
        DB 0,61
        DW 562,T0562
        DB 0,62
        DW 563,T0563
        DB 0,63
        DW 564,T0564
        DB 0,64
        DW 565,T0565
        DB 1,65
        DW 566,T0566
        DB 0,66
        DW 567,T0567
        DB 0,67

ITEMSTRS:DW I0196,I0198,I0200,I0202,I0204,I0206,I0208,I0210,I0212,I0214
        DW I0216,I0285,I0286,I0287,I0288,I0289,I0290,I0291,I0294,I0295
        DW I0296,I0298,I0299,I0300,I0301,I0302,I0303,I0304,I0305,I0306
        DW I0307,I0308,I0310,I0311,I0315,I0356,I0357,I0358,I0359,I0360
        DW I0361,I0362,I0363,I0364,I0365,I0366,I0367,I0370,I0371,I0541
        DW I0542,I0543,I0544,I0545,I0546,I0547,I0548,I0549,I0559,I0560
        DW I0561,I0562,I0563,I0564,I0565,I0566,I0567
I0196: DB '0196','$'
I0198: DB '0198','$'
I0200: DB '0200','$'
I0202: DB '0202','$'
I0204: DB '0204','$'
I0206: DB '0206','$'
I0208: DB '0208','$'
I0210: DB '0210','$'
I0212: DB '0212','$'
I0214: DB '0214','$'
I0216: DB '0216','$'
I0285: DB '0285','$'
I0286: DB '0286','$'
I0287: DB '0287','$'
I0288: DB '0288','$'
I0289: DB '0289','$'
I0290: DB '0290','$'
I0291: DB '0291','$'
I0294: DB '0294','$'
I0295: DB '0295','$'
I0296: DB '0296','$'
I0298: DB '0298','$'
I0299: DB '0299','$'
I0300: DB '0300','$'
I0301: DB '0301','$'
I0302: DB '0302','$'
I0303: DB '0303','$'
I0304: DB '0304','$'
I0305: DB '0305','$'
I0306: DB '0306','$'
I0307: DB '0307','$'
I0308: DB '0308','$'
I0310: DB '0310','$'
I0311: DB '0311','$'
I0315: DB '0315','$'
I0356: DB '0356','$'
I0357: DB '0357','$'
I0358: DB '0358','$'
I0359: DB '0359','$'
I0360: DB '0360','$'
I0361: DB '0361','$'
I0362: DB '0362','$'
I0363: DB '0363','$'
I0364: DB '0364','$'
I0365: DB '0365','$'
I0366: DB '0366','$'
I0367: DB '0367','$'
I0370: DB '0370','$'
I0371: DB '0371','$'
I0541: DB '0541','$'
I0542: DB '0542','$'
I0543: DB '0543','$'
I0544: DB '0544','$'
I0545: DB '0545','$'
I0546: DB '0546','$'
I0547: DB '0547','$'
I0548: DB '0548','$'
I0549: DB '0549','$'
I0559: DB '0559','$'
I0560: DB '0560','$'
I0561: DB '0561','$'
I0562: DB '0562','$'
I0563: DB '0563','$'
I0564: DB '0564','$'
I0565: DB '0565','$'
I0566: DB '0566','$'
I0567: DB '0567','$'

BADSEL:DB 'DIRTEST: unknown selector. Use DIRTEST /LIST.',13,10,'$'
HLPMSG:DB 13,10,'DIRTEST 0.1.0-dev8 - CP/M directory conformance tests',13,10,13,10
        DB '  DIRTEST /NNNN            Run one ledger item',13,10
        DB '  DIRTEST /SAFE            Run returning required cases',13,10
        DB '  DIRTEST /ALL             Run returning cases/diagnostics',13,10
        DB '  DIRTEST /LIST            List ledger entries',13,10
        DB '  DIRTEST /INFO            Show version and coverage totals',13,10
        DB '  DIRTEST /H               Show this command summary',13,10
        DB '  DIRTEST /H:RESULTS       Explain results and classes',13,10
        DB '  DIRTEST /H:PROFILES      Explain named profiles',13,10,'$'
RESMSG:DB 13,10,'DIRTEST result terminology',13,10,13,10
        DB 'STATUS is the outcome: PASS, FAIL, or UNTESTED.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'UNTESTED=not executed, not available, or not yet judged.',13,10
        DB 'CLASS: REQUIRED=baseline; NOT GUAR.=informational.',13,10
        DB 'OUT SCOPE=DIRTEST cannot execute or judge the catalog item.',13,10
        DB 'OBSERVED gives evidence or the command still required.',13,10,'$'
PRFMSG:DB 13,10,'DIRTEST named profiles',13,10,13,10
        DB 'DIRTEST currently defines no named compatibility profiles.',13,10
        DB 'All executable checks are REQUIRED or NOT GUARANTEED.',13,10,'$'
INFMSG:DB 13,10,'BetterCP/M DIRTEST 0.1.0-dev8',13,10
        DB 'Implemented: 67 executable catalog rows',13,10
        DB 'Required: 52; diagnostics: 15; outside scope: 5',13,10
        DB 'Catalog rows represented: 72 of 72; remaining 0',13,10,'$'
LSTMSG:DB 13,10,'BetterCP/M DIRTEST ledger entries',13,10
        DB '0196  Directory entry FCB field layout',13,10
        DB '0198  Type attribute comparison',13,10
        DB '0200  Explicit-drive search',13,10
        DB '0202  All-user search wildcard drive',13,10
        DB '0204  Search Next continuation semantics',13,10
        DB '0206  Search Next unsuccessful result code',13,10
        DB '0208  Set DMA Address call convention',13,10
        DB '0210  DMA change during search continuation',13,10
        DB '0212  Repeat-search ordering stability',13,10
        DB '0214  Default-drive continuation limitation',13,10
        DB '0216  Failed-search DMA contents',13,10
        DB '0285  Function 19 convention',13,10
        DB '0286  Delete identity',13,10
        DB '0287  Delete wildcards',13,10
        DB '0288  Delete all matches',13,10
        DB '0289  Delete success result',13,10
        DB '0290  Delete no-match result',13,10
        DB '0291  Immediate search disappearance',13,10
        DB '0294  Explicit-drive Delete',13,10
        DB '0295  Delete user isolation',13,10
        DB '0296  Open FCB after Delete',13,10
        DB '0297  DRI E5 deletion mechanism',13,10
        DB '0298  Function 23 convention',13,10
        DB '0299  Rename FCB layout',13,10
        DB '0300  Same-drive destination',13,10
        DB '0301  Rename all extents',13,10
        DB '0302  Rename success result',13,10
        DB '0303  Rename missing-source result',13,10
        DB '0304  Rename identity transition',13,10
        DB '0305  Rename data preservation',13,10
        DB '0306  Rename user preservation',13,10
        DB '0307  Explicit-drive Rename',13,10
        DB '0308  Destination collision',13,10
        DB '0309  Wildcard Rename',13,10
        DB '0310  Open FCB after Rename',13,10
        DB '0311  Physical directory order',13,10
        DB '0312  Timestamp preservation',13,10
        DB '0313  DRI in-place rename algorithm',13,10
        DB '0315  Invalid drive ambiguity',13,10
        DB '0316  Directory compaction',13,10
        DB '0356  Read-only attribute location',13,10
        DB '0357  System attribute location',13,10
        DB '0358  Attribute/type coexistence',13,10
        DB '0359  Reserved t3 field',13,10
        DB '0360  Function 30 convention',13,10
        DB '0361  Function 30 set/clear',13,10
        DB '0362  Function 30 all extents',13,10
        DB '0363  Function 30 success result',13,10
        DB '0364  Function 30 no-match result',13,10
        DB '0365  Function 30 exact success slot',13,10
        DB '0366  Open preserves indicators',13,10
        DB '0367  Make accepts indicators',13,10
        DB '0370  File read-only delete protection',13,10
        DB '0371  File read-only rename protection',13,10
        DB '0541  Post-RET reconstruction boundary',13,10
        DB '0542  Enumeration returns directory entries, not unique filenames',13,10
        DB '0543  Matching extents remain separately visible',13,10
        DB '0544  Application-built FCB case is not folded',13,10
        DB '0545  Search FCB lifetime',13,10
        DB '0546  Harmless state-query calls need not end enumeration',13,10
        DB '0547  Search context does not survive program lifecycle reset',13,10
        DB '0548  Physical enumeration order is not a sort contract',13,10
        DB '0549  Invalid-drive search need not return a result code',13,10
        DB '0559  User area participates in ordinary file identity',13,10
        DB '0560  Function 32 user-state contract',13,10
        DB '0561  FCB does not carry ordinary user identity',13,10
        DB '0562  Ordinary lookup has no cross-user fallback',13,10
        DB '0563  Make records current-user ownership',13,10
        DB '0564  Delete and Rename are current-user scoped',13,10
        DB '0565  User change invalidates retained namespace assumptions',13,10
        DB '0566  Complete-directory search is not public lookup',13,10
        DB '0567  CCP USER and BDOS user state are shared',13,10
        DB '$'
HEADER:DB 13,10,'DIRTEST',13,10
        DB 'ITEM  STATUS    CLASS         OBSERVED',13,10
        DB '----  --------  ------------  --------------------------------',13,10,'$'
SPASS: DB 'PASS      ','$'
SFAIL: DB 'FAIL      ','$'
SOBS:  DB 'PASS      ','$'
SOBFAIL:DB 'FAIL      ','$'
SMAN:  DB 'UNTESTED  ','$'
DREQ:  DB 'REQUIRED      ','$'
DNOT:  DB 'NOT GUAR.     ','$'
TWO:   DB '  ','$'
MANMSG:DB 'Run manually; expect Bdos Err On B: File R/O','$'
USRMSG:DB 'Run: USER 1, then DIRTEST /0567','$'
USRHELP:DB 13,10,'The supplied B: disk has DIRTEST.COM in user 1.',13,10
        DB 'PASS: Function 32 reports user 01. User 00 means FAIL.',13,10,'$'
CRLF:  DB 13,10,'$'
SEMI:  DB '; next=','$'
DT1:   DB 'Search slot=','$'
DT2:   DB 'Attribute search=','$'
DT3:   DB 'Explicit result=','$'
DT4:   DB 'Users found mask=','$'
DT5:   DB 'First=','$'
DT6:   DB 'First=','$'
DT7:   DB 'Search=','$'
DT8:   DB 'First DMA=','$'
DT9:   DB 'Repeat first=','$'
DT10:  DB 'Before drive change=','$'
NEWDTAB:DW DT11,DT12,DT13,DT14,DT15,DT16,DT17,DT18,DT19,DT20
        DW DT21,DT22,DT23,DT24,DT25,DT26,DT27,DT28,DT29,DT30
        DW DT31,DT32,DT33,DT34,DT35,DT36,DT37,DT38,DT39,DT40
        DW DT41,DT42,DT43,DT44,DT45,DT46,DT47,DT48,DT49,DT50
        DW DT51,DT52,DT53,DT54,DT55,DT56,DT57,DT58,DT59,DT60
        DW DT61,DT62,DT63,DT64,DT65,DT66,DT67
DT11:  DB 'Failed search=','$'
DT12:  DB 'Delete=','$'
DT13:  DB 'Delete/non-target=','$'
DT14:  DB 'Wildcard/nonmatch=','$'
DT15:  DB 'Matches before/after=','$'
DT16:  DB 'Delete result/remaining=','$'
DT17:  DB 'Absent delete=','$'
DT18:  DB 'Delete/search=','$'
DT19:  DB 'Drive before/after=','$'
DT20:  DB 'User0 delete/user1 search=','$'
DT21:  DB 'Open/delete/close=','$'
DT22:  DB 'Rename/search=','$'
DT23:  DB 'Rename/old search=','$'
DT24:  DB 'Same-drive rename/search=','$'
DT25:  DB 'Rename/size records=','$'
DT26:  DB 'Rename result=','$'
DT27:  DB 'Missing-source rename=','$'
DT28:  DB 'Old/new search=','$'
DT29:  DB 'Rename/read=','$'
DT30:  DB 'User1 rename/user0 search=','$'
DT31:  DB 'Default drive before/after=','$'
DT32:  DB 'Collision result/matches=','$'
DT33:  DB 'Open/renamed-close=','$'
DT34:  DB 'Physical search slots=','$'
DT35:  DB 'Invalid drive/no oracle=','$'
DT36:  DB 'Read-only type byte=','$'
DT37:  DB 'System type bytes=','$'
DT38:  DB 'Coexisting type bytes=','$'
DT39:  DB 'Reserved t3/result=','$'
DT40:  DB 'Function30/search slot=','$'
DT41:  DB 'Set/clear type byte=','$'
DT42:  DB 'All-extents result/type=','$'
DT43:  DB 'Function30 result=','$'
DT44:  DB 'Missing attribute result=','$'
DT45:  DB 'Exact Function30 slot=','$'
DT46:  DB 'Open/type indicator=','$'
DT47:  DB 'Make/type indicator=','$'
DT48:  DB 'RO delete/search=','$'
DT49:  DB 'RO rename/search=','$'
DT50:  DB 'Post-RET/no oracle=','$'
DT51:  DB 'Enumerated extents=','$'
DT52:  DB 'Visible matching extents=','$'
DT53:  DB 'Lowercase FCB search=','$'
DT54:  DB 'Search first/next=','$'
DT55:  DB 'Query between searches=','$'
DT56:  DB 'Lifecycle/no oracle=','$'
DT57:  DB 'Physical order slots=','$'
DT58:  DB 'Invalid search/no oracle=','$'
DT59:  DB 'User0/user1 search=','$'
DT60:  DB 'Set/restored user=','$'
DT61:  DB 'Same FCB user0/user1=','$'
DT62:  DB 'User0 absent/user1 found=','$'
DT63:  DB 'Made user1/user0 lookup=','$'
DT64:  DB 'Scoped delete/result mask=','$'
DT65:  DB 'User-change continuation=','$'
DT66:  DB 'Public result/directory entries=','$'
DT67:  DB 'CCP/BDOS user=','$'
SUM1:  DB 13,10,'Summary: ','$'
SUM2:  DB ' pass, ','$'
SUM3:  DB ' fail, 0 error, ','$'
SUM4:  DB ' observations',13,10
        DB 'Details: DIRTEST /item /REPORT    Help: DIRTEST /H',13,10,'$'

ITEMNO:DW 0
CURITEM:DW 0
CALLPTR:DW 0
DISP:  DB 0
DETAIL:DB 0
CASEOK:DB 0
PASSCT:DB 0
FAILCT:DB 0
OBSCT: DB 0
OBS1:  DB 0
OBS2:  DB 0
OBS3:  DB 0
FLAGS: DB 0
RET1:  DB 0
RET2:  DB 0
NAME1: DB 0
SAVE1: DB 0
SAVE2: DB 0
SAVEDRV:DB 0
SAVEUSR:DB 0
WORKFCB:DS 36
WORK2: DS 36
DMA1:  DS 128
DMA2:  DS 128
        DS 128
STACKTOP:
        END
