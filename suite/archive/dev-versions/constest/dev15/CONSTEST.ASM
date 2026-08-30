;***********************************************************************
;*                                                                     *
;*              C O N S T E S T   --   RELEASE DEV15                  *
;*                                                                     *
;*         BETTER CP/M CONSOLE CONFORMANCE TEST PROGRAM                *
;*                                                                     *
;***********************************************************************
;
; Version 0.1.0-dev15 - period-style programmer's commentary
;
; ASSEMBLY: M80 IN .Z80 MODE, THEN L80.  ONLY 8080 OPERATIONS ARE USED.
; LOAD AT:  0100H
;
;------------------------- PROGRAMMER'S NOTES --------------------------
;
; A console test has a peculiar difficulty: the program cannot stand outside
; the console and watch itself.  CONSTEST therefore prints a frame, makes the
; call under test, prints the literal expectation, and lets the operator or a
; capture rig answer Y or N.  No returned register is allowed to certify what
; appeared on a screen or printer.
;
; The frame is not sent through the function under test.  Function 2 bytes
; are bracketed by Function 9 strings, and Function 9 strings by separate
; reporter strings.  Thus a missing dollar, an unwanted dollar, a TAB, or an
; extra control byte cannot be mistaken for punctuation supplied by CONSTEST.
;
; Calls which need a key are individual cards.  The prompt is printed first,
; and GETF6 or GET11 waits by using the very status/input path being examined.
; A general console read in that interval would steal the test byte.  Where a
; pending key is used only to start an asynchronous trial, WAITRDY consumes it
; without echo before the output stream begins.
;
; Function 10 has its own tell-tale.  F10INIT clears the returned count and
; fills sixteen data bytes with A5H before every call.  Reports are rebuilt
; solely from the returned count and buffer; registers left by BDOS are never
; treated as saved work.  Cards which inspect the first byte beyond returned
; data are observations only--the A5H is bait, not a required result.
;
; Scrolling, printer echo, DEL injection, READER input and IOBYTE routing need
; equipment or timing which may not exist.  Their readiness offices accept U
; and leave the row untested before touching the device.  Absence of a printer
; capture or Reader byte is not evidence against the system.
;
; Some correct operations do not return.  Initial control-C during Function
; 10 may warm boot, so item 0117 belongs to a terminal-outcome transcript.
; Reaching its POST117 line is the bad evidence.  Aggregate runs print the
; card but never enter a blocking or nonreturning arrangement unattended.
;
; DRI console behavior has its own class.  Those cards may confirm the named
; profile, but they do not enlarge the generic CP/M claim.  Likewise, an
; unspecified value in A is printed as an observation and can never add to
; either the PASS or FAIL count.
;
; Each nine-byte CASES card holds the ledger number, probe address, short
; observation, long record and class.  RUNENT is the switchboard.  Keep the
; class decision there; individual probes should only arrange and display
; evidence, then return through the common reporting office.
;
;***********************************************************************

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     87

START:  LD      SP,STACKTOP
        LD      HL,0
        ; Bottom return enters the page-zero warm boot after our private stack.
        PUSH    HL
        CALL    SCANFULL
        CALL    PARSE
        CP      1
        JP      Z,HELP
        CP      2
        JP      Z,LIST
        CP      3
        JP      Z,RUNSET
        CP      4
        JP      Z,RUNSET
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

;------------------------ DECODE COMMAND TAIL -------------------------
; Exit A selects the command; a decimal selector is accumulated in ITEMNO.
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
PARSEH:LD      A,1
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

; A second scan finds /REPORT or /VERBOSE without disturbing the first token.
SCANFULL:
        XOR     A
        LD      (FULLMODE),A
        LD      A,(0080H)
        LD      B,A
        LD      HL,0081H
SFLOOP:LD      A,B
        CP      7
        RET     C
        PUSH    BC
        PUSH    HL
        LD      DE,SREPORT
        CALL    PREFIX
        POP     HL
        POP     BC
        JP      Z,SFYES
        PUSH    BC
        PUSH    HL
        LD      DE,SVERBOSE
        CALL    PREFIX
        POP     HL
        POP     BC
        JP      Z,SFYES
        INC     HL
        DEC     B
        JP      SFLOOP
SFYES: LD      A,1
        LD      (FULLMODE),A
        RET

PREFIX:LD      A,(DE)
        OR      A
        RET     Z
        CP      (HL)
        RET     NZ
        INC     DE
        INC     HL
        JP      PREFIX

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

;------------------------- RUN CARD DECK ------------------------------
; AGGMODE makes a probe return to the deck instead of ending the command.
RUNSET: LD      A,1
        LD      (AGGMODE),A
        CALL    BEGIN
        LD      HL,CASES
        LD      B,NCASES
RSLOOP:PUSH    BC
        PUSH    HL
        CALL    RUNENT
        POP     HL
        LD      DE,9
        ADD     HL,DE
        POP     BC
        DEC     B
        JP      NZ,RSLOOP
        JP      SUMMARY

RUNONE:XOR     A
        LD      (AGGMODE),A
        LD      HL,CASES
        LD      B,NCASES
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
ROADV: LD      DE,7
        ADD     HL,DE
        DEC     B
        JP      NZ,ROLOOP
        LD      DE,BADSEL
        CALL    PUTS
        RET
ROFOUND:
        DEC     HL
        DEC     HL
        ; BEGIN uses BDOS, so save the card pointer across it.
        PUSH    HL
        CALL    BEGIN
        POP     HL
        CALL    RUNENT
        JP      SUMMARY

BEGIN:  XOR     A
        LD      (PASSCT),A
        LD      (FAILCT),A
        LD      (OBSCT),A
        LD      A,(FULLMODE)
        OR      A
        RET     NZ
        LD      DE,HEADER
        JP      PUTS

; Nine-byte card: item, probe, short observation, long record and class.
; Class 0 is required, 1 observation, 3 manual required, 4 manual profile,
; 5 manual observation and 6 outside this executable.  A manual card is only
; announced during an aggregate; selected alone, it runs and asks the outside
; observer for Y or N.
RUNENT:LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (CURITEM),HL
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (PROCPTR),HL
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (OBSPTR),HL
        EX      DE,HL
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        EX      DE,HL
        LD      (RECPTR),HL
        EX      DE,HL
        LD      A,(HL)
        LD      (CASECLS),A
        CP      6
        JP      Z,OOSROW
        CP      3
        JP      C,RUNPROBE
        LD      A,(AGGMODE)
        OR      A
        JP      Z,RUNPROBE
        LD      HL,MANOBS
        LD      (OBSPTR),HL
        LD      A,(CASECLS)
        CP      4
        JP      Z,RETMANP
        CP      5
        JP      Z,RETMANNG
        LD      DE,SMAN
        JP      ROWOUT
RETMANP:
        LD      DE,SMANP
        JP      ROWOUT
RETMANNG:
        LD      DE,SMANNG
        JP      ROWOUT
; OUTSIDE SCOPE is a catalog place, not a result.  Print it without calling a
; probe and without adding to a verdict or observation counter.
OOSROW: LD      HL,OOSOBS
        LD      (OBSPTR),HL
        LD      DE,SOOS
        JP      ROWOUT
RUNPROBE:
        XOR     A
        LD      (SKIPREQ),A
        LD      HL,PRNUNAV
        LD      (SKIPMSG),HL
        LD      HL,(PROCPTR)
        CALL    CALLHL
        LD      A,(SKIPREQ)
        OR      A
        JP      NZ,UNTESTROW
        LD      A,(CASECLS)
        CP      1
        JP      Z,DIAGROW
        CP      5
        JP      NZ,ASKCONF
DIAGROW:
        LD      A,(OBSCT)
        INC     A
        LD      (OBSCT),A
        LD      DE,SOBS
        JP      ROWOUT
; A readiness office may decline before touching absent equipment.  Such a
; row stays untested and leaves every result counter alone.
UNTESTROW:
        LD      HL,(SKIPMSG)
        LD      (OBSPTR),HL
        LD      A,(CASECLS)
        CP      4
        LD      DE,SUNTEST
        JP      NZ,ROWOUT
        LD      DE,SUNTESTP
        JP      ROWOUT
ASKCONF:
        LD      DE,CONFIRM
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        AND     5FH
        LD      (ANSWER),A
        LD      DE,CRLF
        CALL    PUTS
        LD      A,(ANSWER)
        CP      'Y'
        JP      NZ,ROWFAIL
        LD      A,(PASSCT)
        INC     A
        LD      (PASSCT),A
        LD      A,(CASECLS)
        CP      4
        LD      DE,SPASS
        JP      NZ,ROWOUT
        LD      DE,SPASSP
        JP      ROWOUT
ROWFAIL:
        LD      A,(FAILCT)
        INC     A
        LD      (FAILCT),A
        LD      A,(CASECLS)
        CP      4
        LD      DE,SFAIL
        JP      NZ,ROWOUT
        LD      DE,SFAILP
ROWOUT: EX      DE,HL
        LD      (STATUSPTR),HL
        EX      DE,HL
        LD      A,(FULLMODE)
        OR      A
        JP      NZ,FULLROW
        CALL    PUTITEM
        LD      DE,TWO
        CALL    PUTS
        LD      HL,(STATUSPTR)
        EX      DE,HL
        CALL    PUTS
        LD      HL,(OBSPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS
FULLROW:
        LD      HL,(RECPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,RSLABEL
        CALL    PUTS
        LD      HL,(STATUSPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,OBSLABEL
        CALL    PUTS
        LD      HL,(OBSPTR)
        EX      DE,HL
        CALL    PUTS
        LD      DE,ENDCASE
        JP      PUTS

CALLHL:JP      (HL)

;--------------------- FORMATTED OUTPUT CARDS -------------------------
; Reporter framing and test bytes travel by different calls, so the transcript
; plainly shows which function supplied every bracket, dollar and control.
P0052: LD      DE,PRE52
        CALL    PUTS
        LD      E,'A'
        LD      C,2
        CALL    BDOS
        LD      DE,POSTA
        JP      PUTS
P0053: LD      DE,PRE53
        CALL    PUTS
        LD      E,'$'
        LD      C,2
        CALL    BDOS
        LD      DE,POSTD1
        CALL    PUTS
        LD      E,'$'
        LD      C,2
        CALL    BDOS
        LD      DE,POSTD2
        JP      PUTS
P0054: LD      DE,PRE54
        CALL    PUTS
        LD      DE,F9ADDR
        CALL    F9
        LD      DE,POSTADDR
        JP      PUTS
P0055: LD      DE,PRE55
        CALL    PUTS
        LD      DE,F9TERM
        CALL    F9
        LD      DE,POSTLEFT
        JP      PUTS
P0056: LD      DE,PRE56
        CALL    PUTS
        LD      DE,F9ONE
        CALL    F9
        LD      DE,POSTX
        JP      PUTS
P0057: LD      DE,PRE57
        CALL    PUTS
        LD      DE,F9EMPTY
        CALL    F9
        LD      DE,POSTEMPTY
        JP      PUTS
P0058: LD      DE,PRE58
        CALL    PUTS
        LD      DE,F9CTRL
        CALL    F9
        LD      DE,POSTCTRL
        JP      PUTS
P0059: LD      DE,PRE59
        CALL    PUTS
        LD      E,'A'
        LD      C,2
        CALL    BDOS
        LD      E,9
        LD      C,2
        CALL    BDOS
        LD      E,'B'
        LD      C,2
        CALL    BDOS
        LD      DE,POSTTAB
        JP      PUTS
P0060: LD      DE,PRE60
        CALL    PUTS
        LD      DE,F9TAB
        CALL    F9
        LD      DE,POSTTAB
        JP      PUTS
P0061: LD      DE,PRE61
        CALL    PUTS
        LD      E,'A'
        LD      C,2
        CALL    BDOS
        LD      DE,F9TABONLY
        CALL    F9
        LD      DE,POSTTAB
        JP      PUTS

P0062: LD      DE,PRE62
        CALL    PUTS
        LD      E,'A'
        LD      C,2
        CALL    BDOS
        LD      E,9
        LD      C,2
        CALL    BDOS
        LD      E,'B'
        LD      C,2
        CALL    BDOS
        LD      DE,POST62
        JP      PUTS

; Scrolling and printer echo need an operator at the proper instant.  They run
; only when selected, never in an aggregate which might finish before control-S
; or control-P can be supplied.
P0063: LD      DE,PRE63
        CALL    PUTS
        LD      B,40
P63L:  PUSH    BC
        LD      DE,SCROLL2
        CALL    PUTS
        POP     BC
        DEC     B
        JP      NZ,P63L
        LD      DE,POST63
        JP      PUTS
P0064: LD      DE,PRE64
        CALL    PUTS
        LD      B,40
P64L:  PUSH    BC
        LD      DE,SCROLL9
        CALL    F9
        POP     BC
        DEC     B
        JP      NZ,P64L
        LD      DE,POST64
        JP      PUTS
P0065: LD      DE,PRE65
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      DE,DO65
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,PRINT2A
        CALL    PUTS
        LD      E,'2'
        LD      C,2
        CALL    BDOS
        LD      DE,PRINT2B
        CALL    PUTS
        LD      DE,MID65
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,POST65
        JP      PUTS
P0066: LD      DE,PRE66
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      DE,DO66
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,PRINT9
        CALL    F9
        LD      DE,MID65
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,POST66
        JP      PUTS

; 0067 and 0068 print A as found.  No value is required, so neither card can
; increment PASS or FAIL.
P0067: LD      DE,PRE67
        CALL    PUTS
        LD      E,'R'
        LD      C,2
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,MIDA
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POSTNG
        JP      PUTS
P0068: LD      DE,PRE68
        CALL    PUTS
        LD      DE,F9RET
        CALL    F9
        LD      (RETVAL),A
        LD      DE,MIDA
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POSTNG
        JP      PUTS

; These three cards belong to the named DRI console profile.  Selected alone,
; they ask the operator to compare the layout with a literal specimen.
P0069: LD      DE,PRE69
        CALL    PUTS
        LD      DE,DRICOLS
        CALL    F9
        LD      DE,POST69
        JP      PUTS
P0070: LD      DE,PRE70
        CALL    PUTS
        LD      DE,DRILF
        CALL    F9
        LD      DE,POST70
        JP      PUTS
P0071: LD      DE,PRE71
        CALL    PUTS
        LD      DE,DRICR
        CALL    F9
        LD      DE,POST71
        JP      PUTS

; Pending-key and post-pause timing are observations.  A control-C may warm
; boot before a row can be printed, hence these cards require a transcript.
P0072: LD      DE,PRE72
        CALL    PUTS
        CALL    WAITRDY
        LD      B,40
P72L:  PUSH    BC
        LD      DE,SCROLL72
        CALL    F9
        POP     BC
        DEC     B
        JP      NZ,P72L
        LD      E,0FFH
        LD      C,6
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST72
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POST72B
        JP      PUTS
P0073: LD      DE,PRE73
        CALL    PUTS
        CALL    WAITRDY
        LD      B,40
P73L:  PUSH    BC
        LD      DE,SCROLL73
        CALL    F9
        POP     BC
        DEC     B
        JP      NZ,P73L
        LD      DE,POST73
        JP      PUTS

;----------------------- DIRECT I/O CARDS -----------------------------
; Direct output takes its byte from E.  Function 9 supplies the surrounding
; frame, keeping the direct byte apart from the reporter.
P0075: LD      DE,PRE75
        CALL    PUTS
        LD      E,'D'
        LD      C,6
        CALL    BDOS
        LD      DE,POST75
        JP      PUTS
P0076: LD      DE,PRE76
        CALL    PUTS
        LD      E,'Q'
        LD      C,6
        CALL    BDOS
        LD      DE,POST76
        JP      PUTS
P0077: LD      DE,PRE77
        CALL    PUTS
        LD      E,'A'
        LD      C,6
        CALL    BDOS
        LD      E,9
        LD      C,6
        CALL    BDOS
        LD      E,'B'
        LD      C,6
        CALL    BDOS
        LD      DE,POST77
        JP      PUTS
P0078: LD      DE,PRE78
        CALL    PUTS
        CALL    WAITRDY
        ; Give the operator 8192 real output calls in which to try control-S.
        ; A delay loop would test processor speed, not the direct-output path.
        LD      HL,8192
P78L:  PUSH    HL
        LD      E,'.'
        LD      C,6
        CALL    BDOS
        POP     HL
        DEC     HL
        LD      A,H
        OR      L
        JP      NZ,P78L
        ; Drain the pending key through direct input before formatted reporting.
        LD      E,0FFH
        LD      C,6
        CALL    BDOS
        LD      DE,POST78
        JP      PUTS
P0079: LD      DE,PRE79
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      DE,DO79
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,MARK79A
        CALL    PUTS
        LD      E,'N'
        LD      C,6
        CALL    BDOS
        LD      DE,MARK79B
        CALL    PUTS
        LD      DE,MID79
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,POST79
        JP      PUTS
P0080: LD      DE,PRE80
        CALL    PUTS
        LD      E,'R'
        LD      C,6
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,MIDA
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POSTNG
        JP      PUTS
P0081: LD      DE,PRE81
        CALL    PUTS
        LD      E,0FFH
        LD      C,6
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST81
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POST81B
        JP      PUTS
P0082: LD      DE,PRE82
        CALL    PUTS
        LD      E,0FFH
        LD      C,6
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST82
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POST82B
        JP      PUTS

;------------------------- INPUT CARDS --------------------------------
; These cards need a key at a known point.  GETF6 waits through Function 6;
; no reporter read is permitted to steal the byte which supplies the evidence.
P0083: LD      DE,PRE83
        CALL    PUTS
        CALL    GETF6
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP4B
        JP      PUTS
P0084: LD      DE,PRE84
        CALL    PUTS
        CALL    GETF6
        LD      (RETVAL),A
        LD      DE,CLOSEBR
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP55
        JP      PUTS
P0085: LD      DE,PRE85
        CALL    PUTS
        CALL    WAITRDY
        LD      C,11
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP00
        JP      PUTS
P0086: LD      DE,PRE86
        CALL    PUTS
        CALL    GET11
        LD      (RETVAL),A
        ; Sample pending input once.  A loop would ask for a second key and
        ; destroy the very residue this observation is meant to record.
        LD      E,0FFH
        LD      C,6
        CALL    BDOS
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POSTNG
        JP      PUTS
P0087: LD      DE,PRE87
        CALL    PUTS
        CALL    GET11
        LD      (RETVAL),A
        LD      E,0FFH
        LD      C,6
        CALL    BDOS
        LD      (RETVAL2),A
        LD      DE,POST87
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POST87B
        CALL    PUTS
        LD      A,(RETVAL2)
        CALL    PUTHEX
        LD      DE,POSTNG
        JP      PUTS
P0088: LD      DE,PRE88
        CALL    PUTS
        CALL    GET11
        LD      E,0FFH
        LD      C,6
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST88
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POSTNG
        JP      PUTS

P0091: LD      DE,PRE91
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP51
        JP      PUTS
P0092: LD      DE,PRE92
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP42
        JP      PUTS
P0093: LD      DE,PRE93
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP52
        JP      PUTS
P0094: LD      DE,PRE94
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,CLOSEBR
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP47
        JP      PUTS
P0095: LD      DE,PRE95
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP0D
        JP      PUTS
P0096: LD      DE,PRE96
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP0A
        JP      PUTS
P0097: LD      DE,PRE97
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      E,'X'
        LD      C,2
        CALL    BDOS
        LD      DE,POST97
        JP      PUTS
P0098: LD      DE,PRE98
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      E,'B'
        LD      C,2
        CALL    BDOS
        LD      DE,POST98
        JP      PUTS
P0099: LD      DE,PRE99
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,CLOSEBR
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,EXP01
        JP      PUTS
P0100: LD      DE,PRE100
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      E,'B'
        LD      C,2
        CALL    BDOS
        LD      DE,POST100
        JP      PUTS
P0101: LD      DE,PRE101
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST101
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POST101B
        JP      PUTS
P0102: LD      DE,PRE102
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      DE,DO102
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      DE,POST102
        JP      PUTS

; DRI-profile cards remain separate from the required deck.  A good profile
; result does not strengthen the generic claim.
P0103: LD      DE,PRE103
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      DE,DO103
        CALL    PUTS
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST103
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POST103B
        JP      PUTS
P0104: LD      DE,PRE104
        CALL    PUTS
        CALL    GET11
        LD      C,1
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST104
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POST104B
        JP      PUTS

;---------------------- LINE INPUT CARDS ------------------------------
; Function 10 returns its evidence in F10BUF.  Rebuild every report from that
; buffer; DE, HL and loop registers are not expected to survive BDOS.
P0106: LD      DE,PRE106
        LD      A,8
        JP      F10RUN
P0107: LD      DE,PRE107
        LD      A,1
        CALL    F10RUN
        LD      DE,PRE107B
        LD      A,0FFH
        JP      F10RUN
P0108: LD      DE,PRE108
        LD      A,8
        JP      F10RUN
P0109: LD      DE,PRE109
        LD      A,8
        JP      F10RUN
P0110: LD      DE,PRE110
        LD      A,8
        CALL    F10RUN
; 0110 shows the first byte beyond returned data but does not judge it.
        LD      A,(F10BUF+1)
        LD      L,A
        LD      H,0
        LD      DE,F10BUF+2
        ADD     HL,DE
        LD      A,(HL)
        LD      (RETVAL),A
        LD      DE,F10NEXT
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,CRLF
        JP      PUTS
P0111: LD      DE,PRE111
        LD      A,8
        JP      F10RUN
P0112: LD      DE,PRE112
        LD      A,8
        JP      F10RUN
P0113: LD      DE,PRE113
        LD      A,1
        JP      F10RUN
P0114: LD      DE,PRE114
        LD      A,8
        JP      F10RUN
P0115: LD      DE,PRE115
        LD      A,8
        JP      F10RUN
P0116: LD      DE,PRE116
        CALL    PUTS
        CALL    DELREADY
        RET     C
        LD      DE,DO116
        LD      A,8
        JP      F10RUN
P0118: LD      DE,PRE118
        LD      A,8
        JP      F10RUN
P0119: LD      DE,PRE119
        LD      A,8
        JP      F10RUN
P0120: LD      DE,PRE120
        LD      A,8
        JP      F10RUN
P0121: LD      DE,PRE121
        LD      A,8
        JP      F10RUN
P0122: LD      DE,PRE122
        LD      A,8
        JP      F10RUN

; The remaining editor cards need display, printer or injected-byte evidence
; which this transient cannot observe by itself.
P0123: LD      DE,PRE123
        LD      A,8
        CALL    F10RUN
        LD      A,(F10BUF+1)
        LD      L,A
        LD      H,0
        LD      DE,F10BUF+2
        ADD     HL,DE
        LD      A,(HL)
        LD      (RETVAL),A
        LD      DE,POST123
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,CRLF
        JP      PUTS
P0124: LD      DE,PRE124
        CALL    PUTS
        LD      A,8
        CALL    F10INIT
        LD      DE,F10BUF
        LD      C,10
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST124
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,POSTNG
        JP      PUTS
P0125: LD      DE,PRE125
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      DE,DO125
        LD      A,8
        CALL    F10RUN
        LD      DE,REST125
        LD      A,1
        JP      F10RUN
P0126: LD      DE,PRE126
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      DE,DO126
        LD      A,8
        CALL    F10RUN
        LD      DE,REST125
        LD      A,1
        JP      F10RUN
P0127: LD      DE,PRE127
        LD      A,8
        JP      F10RUN
P0128: LD      DE,PRE128
        LD      A,8
        JP      F10RUN
P0129: LD      DE,PRE129
        LD      A,8
        JP      F10RUN

;--------------------- LOGICAL DEVICE CARDS ---------------------------
; These require the named READER, LIST or IOBYTE arrangement.  Console traffic
; is never substituted merely to make a card easy to run.
P0436: LD      DE,PRE436
        CALL    PUTS
        CALL    RDRREADY
        RET     C
        LD      C,3
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POSTAHEX
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,CRLF
        JP      PUTS
P0438: LD      DE,PRE438
        CALL    PUTS
        CALL    RDRREADY
        RET     C
        LD      C,3
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST438
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,CRLF
        JP      PUTS
P0440: LD      DE,PRE440
        CALL    PUTS
        CALL    PRNREADY
        RET     C
        LD      E,'L'
        LD      C,5
        CALL    BDOS
        LD      DE,POST440
        JP      PUTS
P0442: LD      DE,PRE442
        CALL    PUTS
        LD      C,7
        CALL    BDOS
        LD      (RETVAL),A
        JP      SHOWIO
P0444: LD      DE,PRE444
        CALL    PUTS
        LD      C,7
        CALL    BDOS
        LD      (RETVAL),A
        LD      DE,POST444
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,IOFIELDS
        CALL    PUTS
        LD      A,(RETVAL)
        AND     3
        CALL    PUTDIG
        LD      DE,IORDR
        CALL    PUTS
        LD      A,(RETVAL)
        RRCA
        RRCA
        AND     3
        CALL    PUTDIG
        LD      DE,IOPUN
        CALL    PUTS
        LD      A,(RETVAL)
        RRCA
        RRCA
        RRCA
        RRCA
        AND     3
        CALL    PUTDIG
        LD      DE,IOLST
        CALL    PUTS
        LD      A,(RETVAL)
        RLCA
        RLCA
        AND     3
        CALL    PUTDIG
        LD      DE,IOEXP
        CALL    PUTS
        LD      A,(0003H)
        CALL    PUTHEX
        LD      DE,CRLF
        JP      PUTS
P0446: LD      DE,PRE446
        CALL    PUTS
        CALL    ROUTEREADY
        RET     C
        LD      C,7
        CALL    BDOS
        LD      (RETVAL),A
        CALL    SHOWIO
        LD      DE,POST446
        JP      PUTS

SHOWIO:LD      DE,IOOBS
        CALL    PUTS
        LD      A,(RETVAL)
        CALL    PUTHEX
        LD      DE,IOEXP
        CALL    PUTS
        LD      A,(0003H)
        CALL    PUTHEX
        LD      DE,CRLF
        JP      PUTS

;--------------------- TERMINAL OUTCOME CARD --------------------------
; A correct 0117 run warm boots on initial control-C.  Reaching POST117 is the
; negative evidence.  Aggregates announce this card but never enter it.
P0117: LD      DE,PRE117
        CALL    PUTS
        CALL    WAITRDY
        LD      A,8
        CALL    F10INIT
        LD      DE,F10BUF
        LD      C,10
        CALL    BDOS
        LD      DE,POST117
        JP      PUTS

; F10RUN prints the prompt, makes the blocking call, then prints exactly the
; returned count of bytes.  It never searches for a terminator of its own.
F10RUN:LD      (F10MAX),A
        CALL    PUTS
        LD      A,(F10MAX)
        CALL    F10INIT
        LD      DE,F10BUF
        LD      C,10
        CALL    BDOS
        LD      DE,F10OBS
        CALL    PUTS
        LD      A,(F10BUF+1)
        CALL    PUTHEX
        LD      DE,F10DATA
        CALL    PUTS
        LD      HL,F10BUF+2
        LD      A,(F10BUF+1)
        LD      (F10LEFT),A
F10SHOW:LD      A,(F10LEFT)
        OR      A
        JP      Z,F10DONE
        LD      A,(HL)
        PUSH    HL
        LD      E,A
        LD      C,2
        CALL    BDOS
        POP     HL
        INC     HL
        LD      A,(F10LEFT)
        DEC     A
        LD      (F10LEFT),A
        JP      F10SHOW
F10DONE:LD      DE,F10END
        JP      PUTS

; Set maximum, clear count and lay A5H in the sixteen-byte work area.
F10INIT:
        LD      (F10BUF),A
        XOR     A
        LD      (F10BUF+1),A
        LD      HL,F10BUF+2
        LD      B,16
F10FILL:LD      (HL),0A5H
        INC     HL
        DEC     B
        JP      NZ,F10FILL
        RET

GETF6: LD      E,0FFH
        LD      C,6
        CALL    BDOS
        OR      A
        JP      Z,GETF6
        RET
GET11: LD      C,11
        CALL    BDOS
        OR      A
        JP      Z,GET11
        RET

;---------------------- EQUIPMENT READINESS ---------------------------
; Ask before toggling control-P.  U leaves the card untested when LIST output
; cannot be inspected.
PRNREADY:
        LD      DE,PRNASK
        CALL    PUTS
PRNASKL:
        LD      C,1
        CALL    BDOS
        AND     5FH
        CP      'Y'
        JP      Z,PRNYES
        CP      'U'
        JP      NZ,PRNASKL
        LD      A,1
        LD      (SKIPREQ),A
        LD      DE,CRLF
        CALL    PUTS
        SCF
        RET
PRNYES: LD      DE,CRLF
        CALL    PUTS
        OR      A
        RET

; DEL means byte 7FH.  If the keyboard cannot send it, the test instrument is
; missing; that is not a failed BDOS result.
DELREADY:
        LD      HL,DELUNAV
        LD      (SKIPMSG),HL
        LD      DE,DELASK
        CALL    PUTS
DELASKL:
        LD      C,1
        CALL    BDOS
        AND     5FH
        CP      'Y'
        JP      Z,DELYES
        CP      'U'
        JP      NZ,DELASKL
        LD      A,1
        LD      (SKIPREQ),A
        LD      DE,CRLF
        CALL    PUTS
        SCF
        RET
DELYES: LD      DE,CRLF
        CALL    PUTS
        OR      A
        RET

; Function 3 blocks and the console cannot release it.  Do not enter until a
; distinct Reader has a byte already waiting.
RDRREADY:
        LD      HL,RDRUNAV
        LD      (SKIPMSG),HL
        LD      DE,RDRASK
        CALL    PUTS
RDRASKL:
        LD      C,1
        CALL    BDOS
        AND     5FH
        CP      'Y'
        JP      Z,RDRYES
        CP      'U'
        JP      NZ,RDRASKL
        LD      A,1
        LD      (SKIPREQ),A
        LD      DE,CRLF
        CALL    PUTS
        SCF
        RET
RDRYES: LD      DE,CRLF
        CALL    PUTS
        OR      A
        RET

ROUTEREADY:
        LD      HL,ROUTEUN
        LD      (SKIPMSG),HL
        LD      DE,ROUTEASK
        CALL    PUTS
ROUTEAL:
        LD      C,1
        CALL    BDOS
        AND     5FH
        CP      'Y'
        JP      Z,ROUTEYES
        CP      'U'
        JP      NZ,ROUTEAL
        LD      A,1
        LD      (SKIPREQ),A
        LD      DE,CRLF
        CALL    PUTS
        SCF
        RET
ROUTEYES:
        LD      DE,CRLF
        CALL    PUTS
        OR      A
        RET

F9:     LD      C,9
        JP      BDOS

; Consume the ready key by direct input, without echo or formatted controls,
; leaving a clean input state for the asynchronous trial which follows.
WAITRDY:LD      E,0FFH
        LD      C,6
        CALL    BDOS
        OR      A
        JP      Z,WAITRDY
        LD      DE,CRLF
        JP      PUTS

PUTHEX:PUSH    AF
        RRCA
        RRCA
        RRCA
        RRCA
        AND     0FH
        CALL    PUTNIB
        POP     AF
        AND     0FH
PUTNIB:CP      10
        JP      C,PNDIG
        ADD     A,'A'-10
        JP      PNHAVE
PNDIG: ADD     A,'0'
PNHAVE:LD      E,A
        LD      C,2
        JP      BDOS

SUMMARY:
        LD      DE,SUM1
        CALL    PUTS
        LD      A,(PASSCT)
        CALL    PUTNUM
        LD      DE,SUM2
        CALL    PUTS
        LD      A,(FAILCT)
        CALL    PUTNUM
        LD      DE,SUM3
        CALL    PUTS
        LD      A,(OBSCT)
        CALL    PUTNUM
        LD      DE,SUM4
        JP      PUTS

PUTITEM:
        LD      HL,(CURITEM)
        LD      DE,1000
        LD      B,0
PI1:   OR      A
        CALL    SUBHLDE
        JP      C,PI1D
        INC     B
        JP      PI1
PI1D:  ADD     HL,DE
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      DE,100
        LD      B,0
PI2:   OR      A
        CALL    SUBHLDE
        JP      C,PI2D
        INC     B
        JP      PI2
PI2D:  ADD     HL,DE
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      DE,10
        LD      B,0
PI3:   OR      A
        CALL    SUBHLDE
        JP      C,PI3D
        INC     B
        JP      PI3
PI3D:  ADD     HL,DE
        LD      A,B
        PUSH    HL
        CALL    PUTDIG
        POP     HL
        LD      A,L
        JP      PUTDIG

; Sixteen-bit subtract for the decimal printer.  Carry means HL underflow.
; Use two 8080 byte operations; SBC HL,DE would quietly make this a Z80 file.
SUBHLDE:
        LD      A,L
        SUB     E
        LD      L,A
        LD      A,H
        SBC     A,D
        LD      H,A
        RET

PUTNUM:CP      10
        JP      C,PUTDIG
        LD      B,0
PN1:   SUB     10
        INC     B
        CP      10
        JP      NC,PN1
        PUSH    AF
        LD      A,B
        CALL    PUTDIG
        POP     AF
PUTDIG:ADD     A,'0'
        LD      E,A
        LD      C,2
        JP      BDOS
PUTS:  LD      C,9
        JP      BDOS

CASES:
        DW 51,P0052,OOSOBS,R0051
        DB 6
        DW 52,P0052,O0052,R0052
        DB 0
        DW 53,P0053,O0053,R0053
        DB 0
        DW 54,P0054,O0054,R0054
        DB 0
        DW 55,P0055,O0055,R0055
        DB 0
        DW 56,P0056,O0056,R0056
        DB 0
        DW 57,P0057,O0057,R0057
        DB 0
        DW 58,P0058,O0058,R0058
        DB 0
        DW 59,P0059,O0059,R0059
        DB 0
        DW 60,P0060,O0060,R0060
        DB 0
        DW 61,P0061,O0061,R0061
        DB 0
        DW 62,P0062,O0062,R0062
        DB 0
        DW 63,P0063,O0063,R0063
        DB 3
        DW 64,P0064,O0064,R0064
        DB 3
        DW 65,P0065,O0065,R0065
        DB 3
        DW 66,P0066,O0066,R0066
        DB 3
        DW 67,P0067,O0067,R0067
        DB 1
        DW 68,P0068,O0068,R0068
        DB 1
        DW 69,P0069,O0069,R0069
        DB 4
        DW 70,P0070,O0070,R0070
        DB 4
        DW 71,P0071,O0071,R0071
        DB 4
        DW 72,P0072,O0072,R0072
        DB 5
        DW 73,P0073,O0073,R0073
        DB 5
        DW 74,P0052,OOSOBS,R0074
        DB 6
        DW 75,P0075,O0075,R0075
        DB 0
        DW 76,P0076,O0076,R0076
        DB 0
        DW 77,P0077,O0077,R0077
        DB 3
        DW 78,P0078,O0078,R0078
        DB 3
        DW 79,P0079,O0079,R0079
        DB 3
        DW 80,P0080,O0080,R0080
        DB 1
        DW 81,P0081,O0081,R0081
        DB 0
        DW 82,P0082,O0082,R0082
        DB 0
        DW 83,P0083,O0083,R0083
        DB 3
        DW 84,P0084,O0084,R0084
        DB 3
        DW 85,P0085,O0085,R0085
        DB 3
        DW 86,P0086,O0086,R0086
        DB 5
        DW 87,P0087,O0087,R0087
        DB 5
        DW 88,P0088,O0088,R0088
        DB 5
        DW 89,P0083,OOSOBS,R0089
        DB 6
        DW 90,P0083,OOSOBS,R0090
        DB 6
        DW 91,P0091,O0091,R0091
        DB 3
        DW 92,P0092,O0092,R0092
        DB 3
        DW 93,P0093,O0093,R0093
        DB 3
        DW 94,P0094,O0094,R0094
        DB 3
        DW 95,P0095,O0095,R0095
        DB 3
        DW 96,P0096,O0096,R0096
        DB 3
        DW 97,P0097,O0097,R0097
        DB 3
        DW 98,P0098,O0098,R0098
        DB 3
        DW 99,P0099,O0099,R0099
        DB 3
        DW 100,P0100,O0100,R0100
        DB 3
        DW 101,P0101,O0101,R0101
        DB 3
        DW 102,P0102,O0102,R0102
        DB 3
        DW 103,P0103,O0103,R0103
        DB 4
        DW 104,P0104,O0104,R0104
        DB 4
        DW 105,P0083,OOSOBS,R0105
        DB 6
        DW 106,P0106,O0106,R0106
        DB 3
        DW 107,P0107,O0107,R0107
        DB 3
        DW 108,P0108,O0108,R0108
        DB 3
        DW 109,P0109,O0109,R0109
        DB 3
        DW 110,P0110,O0110,R0110
        DB 5
        DW 111,P0111,O0111,R0111
        DB 3
        DW 112,P0112,O0112,R0112
        DB 3
        DW 113,P0113,O0113,R0113
        DB 3
        DW 114,P0114,O0114,R0114
        DB 3
        DW 115,P0115,O0115,R0115
        DB 3
        DW 116,P0116,O0116,R0116
        DB 3
        DW 117,P0117,O0117,R0117
        DB 3
        DW 118,P0118,O0118,R0118
        DB 3
        DW 119,P0119,O0119,R0119
        DB 3
        DW 120,P0120,O0120,R0120
        DB 3
        DW 121,P0121,O0121,R0121
        DB 3
        DW 122,P0122,O0122,R0122
        DB 3
        DW 123,P0123,O0123,R0123
        DB 3
        DW 124,P0124,O0124,R0124
        DB 5
        DW 125,P0125,O0125,R0125
        DB 4
        DW 126,P0126,O0126,R0126
        DB 4
        DW 127,P0127,O0127,R0127
        DB 4
        DW 128,P0128,O0128,R0128
        DB 4
        DW 129,P0129,O0129,R0129
        DB 4
        DW 130,P0123,OOSOBS,R0130
        DB 6
        DW 421,P0123,OOSOBS,R0421
        DB 6
        DW 436,P0436,O0436,R0436
        DB 3
        DW 438,P0438,O0438,R0438
        DB 3
        DW 440,P0440,O0440,R0440
        DB 3
        DW 442,P0442,O0442,R0442
        DB 3
        DW 444,P0444,O0444,R0444
        DB 3
        DW 446,P0446,O0446,R0446
        DB 4

SREPORT: DB '/REPORT',0
SVERBOSE:DB '/VERBOSE',0
BADSEL: DB 'CONSTEST: unknown selector. Use CONSTEST /LIST.',13,10,'$'
HLPMSG:DB 13,10,'CONSTEST 0.1.0-dev15 - CP/M console conformance tests',13,10,13,10
        DB '  CONSTEST /NNNN           Run one ledger item',13,10
        DB '  CONSTEST /SAFE           Run all implemented REQUIRED items',13,10
        DB '  CONSTEST /ALL            Show implemented and OOS items',13,10
        DB '  CONSTEST /NNNN /REPORT   Show full contextual evidence',13,10
        DB '  CONSTEST /LIST           List ledger entries',13,10
        DB '  CONSTEST /GROUP:LIST  List all available groupings',13,10
        DB '  CONSTEST /GROUP:name  Run a named group; see /GROUP:LIST',13,10
        DB '  CONSTEST /INFO           Show version and coverage totals',13,10
        DB '  CONSTEST /VER, /VERSION  Show name and version',13,10
        DB '  CONSTEST /H, /HELP  Show concise command help',13,10
        DB '  CONSTEST /H:RESULTS      Explain results and classes',13,10
        DB '  CONSTEST /H:PROFILES     Explain named profiles and equipment',13,10,'$'
RESMSG:DB 13,10,'CONSTEST result terminology',13,10,13,10
        DB 'STATUS: P=Pass F=Fail -=Not-run O=Observed.',13,10
        DB 'PASS=completed and matched; FAIL=completed and mismatched.',13,10
        DB 'CLASS: R=Required N=Not-guaranteed S=Out-of-scope X=Profile.',13,10
        DB 'PROFILE=required only when its named profile is claimed.',13,10
        DB 'OUT SCOPE=CONSTEST cannot execute or judge the catalog item.',13,10
        DB 'OBSERVED gives evidence or the command still required.',13,10
        DB '/REPORT adds complete expected and observed context.',13,10,'$'
PRFMSG:DB 13,10,'CONSTEST profiles and equipment',13,10,13,10
        DB 'DRI-CONSOLE: strict DRI console behavior (0069-0071,0103-0104,',13,10
        DB '0125-0129). IOBYTE routing profile: item 0446.',13,10
        DB 'Printer capture is needed for 0065-0066,0079,0102-0103,',13,10
        DB '0125-0126,0440. Answer unavailable when capture is absent.',13,10
        DB 'Run a numbered item for exact setup and expected behavior.',13,10,'$'
INFMSG:DB 'BetterCP/M CONSTEST 0.1.0-dev15',13,10
        DB 'Implemented: all 80 executable catalog rows',13,10
        DB 'Outside scope: 7; catalog rows represented: 87 of 87',13,10
        DB 'Executable coverage: 80 of 80; remaining 0',13,10,'$'
LSTMSG:DB 13,10,'BetterCP/M CONSTEST ledger entries',13,10
        DB '0051  Observed BDOS return flags',13,10
        DB '0052  Function 2 character source',13,10
        DB '0053  Function 2 treats dollar as ordinary data',13,10
        DB '0054  Function 9 string address',13,10
        DB '0055  Function 9 dollar termination',13,10
        DB '0056  Function 9 terminator is not emitted',13,10
        DB '0057  Function 9 empty string',13,10
        DB '0058  Function 9 scans across ordinary control characters',13,10
        DB '0059  Function 2 uses formatted console output',13,10
        DB '0060  Function 9 uses formatted console output',13,10
        DB '0061  Shared formatted-output state',13,10
        DB '0062  TAB expansion',13,10
        DB '0063  Function 2 participates in scrolling control',13,10
        DB '0064  Function 9 participates in scrolling control',13,10
        DB '0065  Function 2 participates in active printer echo',13,10
        DB '0066  Function 9 participates in active printer echo',13,10
        DB '0067  Function 2 has no function-specific return value',13,10
        DB '0068  Function 9 has no function-specific return value',13,10
        DB '0069  Exact logical-column update rules',13,10
        DB '0070  LF resets DRI logical column',13,10
        DB '0071  CR does not reset DRI logical column',13,10
        DB '0072  Pending-key buffering during formatted output',13,10
        DB '0073  Ctrl-C behavior after output pause',13,10
        DB '0074  DRI private formatted-output implementation state',13,10
        DB '0075  Function 6 direct-output selection',13,10
        DB '0076  Function 6 direct-output character source',13,10
        DB '0077  Function 6 direct output does not expand TAB',13,10
        DB '0078  Function 6 direct output bypasses Ctrl-S scrolling control',13,10
        DB '0079  Function 6 direct output bypasses Ctrl-P printer echo',13,10
        DB '0080  Function 6 direct output has no function-specific result',13,10
        DB '0081  Function 6 nonblocking-input selection',13,10
        DB '0082  Function 6 no-input result',13,10
        DB '0083  Function 6 ready-input result',13,10
        DB '0084  Function 6 input is unadorned',13,10
        DB '0085  Function 11 not-ready result',13,10
        DB '0086  Exact function 11 ready result',13,10
        DB '0087  Function 11 pending-byte retention',13,10
        DB '0088  DRI function 6 ignores retained pending byte',13,10
        DB '0089  DRI function 6 E=FEh behavior',13,10
        DB '0090  DRI private pending-byte representation',13,10
        DB '0091  Function 1 selector',13,10
        DB '0092  Function 1 blocking behavior',13,10
        DB '0093  Function 1 result character',13,10
        DB '0094  Function 1 echoes graphic characters',13,10
        DB '0095  Function 1 echoes CR',13,10
        DB '0096  Function 1 echoes LF',13,10
        DB '0097  Function 1 echoes backspace',13,10
        DB '0098  Function 1 TAB echo expansion',13,10
        DB '0099  Function 1 ordinary controls are not echoed',13,10
        DB '0100  Function 1 echo uses shared formatted-console state',13,10
        DB '0101  Function 1 echo participates in scrolling control',13,10
        DB '0102  Function 1 echo participates in active printer echo',13,10
        DB '0103  Function-1 Ctrl-P printer-echo state change',13,10
        DB '0104  Function 1 consumes function-11-retained input',13,10
        DB '0105  DRI private function-1 implementation details',13,10
        DB '0106  Function 10 selector and buffer address',13,10
        DB '0107  Function 10 maximum byte',13,10
        DB '0108  Function 10 returned count',13,10
        DB '0109  Function 10 returned data location',13,10
        DB '0110  Bytes beyond function-10 returned count',13,10
        DB '0111  Function 10 CR termination',13,10
        DB '0112  Function 10 LF termination',13,10
        DB '0113  Function 10 capacity termination',13,10
        DB '0114  Function 10 ordinary-character storage and echo',13,10
        DB '0115  Function 10 backspace editing',13,10
        DB '0116  Function 10 DEL editing',13,10
        DB '0117  Function 10 initial Ctrl-C warm restart',13,10
        DB '0118  Function 10 Ctrl-E line continuation',13,10
        DB '0119  Function 10 Ctrl-R redisplay',13,10
        DB '0120  Function 10 Ctrl-U line deletion',13,10
        DB '0121  Function 10 Ctrl-X line deletion',13,10
        DB '0122  Function 10 starting-column-relative editing',13,10
        DB '0123  Function 10 stores no line terminator',13,10
        DB '0124  Function 10 has no function-specific register result',13,10
        DB '0125  Function 10 Ctrl-P exclusion and printer-echo toggle',13,10
        DB '0126  Function 10 post-Ctrl-P echo state',13,10
        DB '0127  Function 10 seven-bit input masking',13,10
        DB '0128  Function 10 exact correction-display bytes',13,10
        DB '0129  Function 10 noninitial Ctrl-C behavior',13,10
        DB '0130  DRI private function-10 editor organization',13,10
        DB '0421  DRI private console polling implementation',13,10
        DB '0436  Function 3 Reader convention',13,10
        DB '0438  Reader separation from console',13,10
        DB '0440  Function 5 List convention',13,10
        DB '0442  Function 7 IOBYTE query',13,10
        DB '0444  IOBYTE field encoding',13,10
        DB '0446  Active IOBYTE routing policy',13,10
        DB '$'
HEADER: DB 13,10,'CONSTEST',13,10
        DB 'ITEM  S  C  OBSERVED',13,10
        DB '----  -  -  ----------------------------------------------------------',13,10,'$'
CONFIRM:DB 'Do OBSERVED and EXPECTED match? (Y/N; no Enter) $'
SPASS:  DB 'P  R  $'
SFAIL:  DB 'F  R  $'
SPASSP: DB 'P  X  $'
SFAILP: DB 'F  X  $'
SOBS:   DB 'O  N  $'
SMAN:   DB '-  R  $'
SMANP:  DB '-  X  $'
SMANNG: DB '-  N  $'
SOOS:   DB '-  S  $'
SUNTEST:DB '-  R  $'
SUNTESTP:DB '-  X  $'
MANOBS: DB 'Run item individually; interactive setup required$'
OOSOBS: DB 'Not tested; outside executable scope$'
PRNUNAV:DB 'Logical printer unavailable; not tested$'
PRNASK: DB 'Is logical-printer output inspectable? (Y/U; U=untested) $'
DELASK: DB 'Can this keyboard send ASCII DEL (7Fh)? (Y/U; U=untested) $'
DELUNAV:DB 'ASCII DEL unavailable; not tested$'
RDRASK: DB 'Is a Reader byte configured and already pending? (Y/U; U=untested) $'
RDRUNAV:DB 'Reader provider unavailable; not tested$'
ROUTEASK:DB 'Is a nondefault IOBYTE route configured and verified? (Y/U) $'
ROUTEUN:DB 'Nondefault IOBYTE route unavailable; not tested$'
TWO:    DB '  $'
CRLF:   DB 13,10,'$'
SUM1:   DB 13,10,'Summary: $'
SUM2:   DB ' pass, $'
SUM3:   DB ' fail, 0 error, $'
SUM4:   DB ' observations',13,10
        DB 'Details: CONSTEST /item /REPORT   Help: CONSTEST /H',13,10,'$'
RSLABEL:DB 'RESULT $'
OBSLABEL:DB 13,10,'OBSERVED $'
ENDCASE:DB 13,10,'END_CASE',13,10,13,10,'$'

PRE52: DB 13,10,'Probe 0052: Function 2 character source',13,10,'OBSERVED: [$'
PRE53: DB 13,10,'Probe 0053: Function 2 dollar as data',13,10,'OBSERVED: [$'
PRE54: DB 13,10,'Probe 0054: Function 9 DE address',13,10,'OBSERVED: [$'
PRE55: DB 13,10,'Probe 0055: Function 9 termination',13,10,'OBSERVED: [$'
PRE56: DB 13,10,'Probe 0056: terminator not emitted',13,10,'OBSERVED: [$'
PRE57: DB 13,10,'Probe 0057: Function 9 empty string',13,10,'OBSERVED: [$'
PRE58: DB 13,10,'Probe 0058: controls before terminator',13,10,'OBSERVED:',13,10,'$'
PRE59: DB 13,10,'Probe 0059: Function 2 formatted TAB',13,10,'OBSERVED:',13,10,'$'
PRE60: DB 13,10,'Probe 0060: Function 9 formatted TAB',13,10,'OBSERVED:',13,10,'$'
PRE61: DB 13,10,'Probe 0061: shared formatted state',13,10,'OBSERVED:',13,10,'$'
POSTA: DB ']',13,10,'EXPECTED: [A]',13,10,'$'
; Print the dollar separately by Function 2; inside the reporter string it
; would end the message and hide the rest of the specimen.
POSTD1:DB ']',13,10,'EXPECTED: [$'
POSTD2:DB '] (one dollar-sign character)',13,10,'$'
POSTADDR:DB ']',13,10,'EXPECTED: [F9ADDR]',13,10,'$'
POSTLEFT:DB ']',13,10,'EXPECTED: [LEFT]',13,10,'$'
POSTX: DB ']',13,10,'EXPECTED: [X]',13,10,'$'
POSTEMPTY:DB ']',13,10,'EXPECTED: []',13,10,'$'
POSTCTRL:DB 13,10,'EXPECTED:',13,10,'A',13,10,'B',13,10,'$'
POSTTAB:DB 13,10,'EXPECTED:',13,10,'A       B',13,10,'$'
F9ADDR:DB 'F9ADDR$'
F9TERM:DB 'LEFT$RIGHT'
F9ONE: DB 'X$'
F9EMPTY:DB '$'
F9CTRL:DB 'A',13,10,'B$'
F9TAB: DB 'A',9,'B$'
F9TABONLY:DB 9,'B$'

PRE62: DB 13,10,'Probe 0062: TAB reaches next eight-column stop',13,10
       DB 'OBSERVED:',13,10,'$'
POST62:DB 13,10,'EXPECTED:',13,10,'A       B',13,10,'$'
PRE63: DB 13,10,'Probe 0063: Function 2 scrolling control',13,10
       DB 'OBSERVED: press Ctrl-S during the stream; then another key.',13,10,'$'
POST63:DB 'EXPECTED: output pauses at Ctrl-S and resumes after the next key.',13,10,'$'
PRE64: DB 13,10,'Probe 0064: Function 9 scrolling control',13,10
       DB 'OBSERVED: press Ctrl-S during the stream; then another key.',13,10,'$'
POST64:DB 'EXPECTED: output pauses at Ctrl-S and resumes after the next key.',13,10,'$'
SCROLL2:DB 'Function-2 scrolling-control stream 0123456789',13,10,'$'
SCROLL9:DB 'Function-9 scrolling-control stream 0123456789',13,10,'$'
PRE65: DB 13,10,'Probe 0065: Function 2 active printer echo',13,10,'$'
DO65:  DB 'Press Ctrl-P to enable printer echo: $'
MID65: DB 13,10,'Press Ctrl-P to disable printer echo: $'
POST65:DB 13,10,'OBSERVED: inspect logical printer output.',13,10
       DB 'EXPECTED: printer contains [F2PRINT2].',13,10,'$'
PRE66: DB 13,10,'Probe 0066: Function 9 active printer echo',13,10,'$'
DO66:  DB 'Press Ctrl-P to enable printer echo: $'
POST66:DB 13,10,'OBSERVED: inspect logical printer output.',13,10
       DB 'EXPECTED: printer contains [F9PRINT].',13,10,'$'
PRINT2A:DB 13,10,'OBSERVED console target: [F2PRINT$'
PRINT2B:DB ']',13,10,'$'
PRINT9: DB 13,10,'OBSERVED console target: [F9PRINT]',13,10,'$'
PRE67: DB 13,10,'Probe 0067: Function 2 unspecified return',13,10
       DB 'OBSERVED output: [$'
PRE68: DB 13,10,'Probe 0068: Function 9 unspecified return',13,10
       DB 'OBSERVED output: [$'
MIDA:  DB '] return A=$'
POSTNG:DB 13,10,'EXPECTED: no portable function-specific value.',13,10,'$'
F9RET: DB 'R$'
PRE69: DB 13,10,'Probe 0069: DRI logical-column state machine',13,10
       DB 'OBSERVED:',13,10,'$'
DRICOLS:DB 'A',9,'B',13,10,'ABC',9,'D',13,10,'ABCDEFG',9,'H$'
POST69:DB 13,10,'EXPECTED:',13,10,'A       B',13,10
       DB 'ABC     D',13,10,'ABCDEFG H',13,10,'$'
PRE70: DB 13,10,'Probe 0070: DRI LF resets logical column',13,10
       DB 'OBSERVED (LF without CR, then TAB):',13,10,'$'
DRILF: DB 'A',10,9,'B$'
POST70:DB 13,10,'EXPECTED: TAB uses column zero after LF.',13,10,'$'
PRE71: DB 13,10,'Probe 0071: DRI CR preserves logical column',13,10
       DB 'OBSERVED (ABC, CR, then TAB and B):',13,10,'$'
DRICR: DB 'ABC',13,9,'B$'
POST71:DB 13,10,'EXPECTED: TAB uses prior logical column three.',13,10,'$'

PRE72: DB 13,10,'Probe 0072: pending key during formatted output',13,10
       DB 'During the stream, press K exactly once.',13,10
       DB 'Press any key to start the test: $'
SCROLL72:DB 'Pending-key diagnostic stream 0123456789',13,10,'$'
POST72:DB 'OBSERVED: post-stream Function 6 input returned A=$'
POST72B:DB 13,10,'EXPECTED: no portable retained-key behavior.',13,10,'$'
PRE73: DB 13,10,'Probe 0073: Ctrl-C after Ctrl-S pause',13,10
       DB 'During the stream, press Ctrl-S, then Ctrl-C.',13,10
       DB 'CP/M may abort CONSTEST and return directly to the CCP.',13,10
       DB 'Press any key to start the test: $'
SCROLL73:DB 'Post-pause Ctrl-C diagnostic stream 0123456789',13,10,'$'
POST73:DB 'OBSERVED: stream returned to CONSTEST.',13,10
       DB 'EXPECTED: exact timing/state is not portable.',13,10,'$'
PRE75: DB 13,10,'Probe 0075: Function 6 direct-output selection',13,10
       DB 'OBSERVED: [$'
POST75:DB ']',13,10,'EXPECTED: [D]',13,10,'$'
PRE76: DB 13,10,'Probe 0076: Function 6 character source',13,10
       DB 'OBSERVED: [$'
POST76:DB ']',13,10,'EXPECTED: [Q]',13,10,'$'
PRE77: DB 13,10,'Probe 0077: Function 6 passes TAB directly',13,10
       DB 'OBSERVED bytes/display: [$'
POST77:DB ']',13,10,'EXPECTED: console receives A, TAB byte, B; BDOS adds no spaces.',13,10,'$'
PRE78: DB 13,10,'Probe 0078: Function 6 bypasses Ctrl-S',13,10
       DB 'During the dots, press Ctrl-S; direct output must not pause.',13,10
       DB 'Press any key to start the test: $'
POST78:DB 13,10,'OBSERVED: direct stream completed without formatted pause.',13,10
       DB 'EXPECTED: Ctrl-S does not control Function 6 output.',13,10,'$'
PRE79: DB 13,10,'Probe 0079: Function 6 bypasses printer echo',13,10
       DB 'Direct output must appear on console but not in LIST capture.',13,10,'$'
DO79:  DB 'Open or clear printer capture; press Ctrl-P to enable echo: $'
MARK79A:DB 13,10,'TEST MARKER: [$'
MARK79B:DB ']',13,10,'$'
MID79: DB 'Console should show [N]. Press Ctrl-P to disable printer echo: $'
POST79:DB 13,10,'OBSERVED: console marker was [N].',13,10
       DB 'EXPECTED: printer capture contains TEST MARKER: [] (no N).',13,10,'$'
PRE80: DB 13,10,'Probe 0080: Function 6 unspecified direct-output return',13,10
       DB 'OBSERVED output: [$'
PRE81: DB 13,10,'Probe 0081: Function 6 nonblocking-input selection',13,10
       DB 'Do not type a key while this probe runs.',13,10,'$'
POST81:DB 'OBSERVED: E=FF returned immediately with A=$'
POST81B:DB 13,10,'EXPECTED: call selects nonblocking input and returns.',13,10,'$'
PRE82: DB 13,10,'Probe 0082: Function 6 no-input result',13,10
       DB 'Do not type a key while this probe runs.',13,10,'$'
POST82:DB 'OBSERVED: no-input return A=$'
POST82B:DB 13,10,'EXPECTED: A=00 when no key is ready.',13,10,'$'

PRE83: DB 13,10,'Probe 0083: Function 6 ready-input result',13,10
       DB 'Press K now: $'
PRE84: DB 13,10,'Probe 0084: Function 6 input is unadorned',13,10
       DB 'Press U; nothing should appear between these brackets: [$'
PRE85: DB 13,10,'Probe 0085: Function 11 not-ready result',13,10
       DB 'Press any key to start with an empty input queue: $'
PRE86: DB 13,10,'Probe 0086: exact Function 11 ready value',13,10
       DB 'Press K now: $'
PRE87: DB 13,10,'Probe 0087: Function 11 pending-byte retention',13,10
       DB 'Press K now: $'
PRE88: DB 13,10,'Probe 0088: DRI Function 6 pending-byte behavior',13,10
       DB 'Press K now: $'
POSTAHEX:DB 13,10,'OBSERVED: return A=$'
CLOSEBR:DB ']',13,10,'OBSERVED: return A=$'
EXP4B: DB 13,10,'EXPECTED: A=4B (K).',13,10,'$'
EXP55: DB 13,10,'EXPECTED: empty brackets and A=55 (U).',13,10,'$'
EXP00: DB 13,10,'EXPECTED: A=00.',13,10,'$'
POST87:DB 13,10,'OBSERVED: Function 11 A=$'
POST87B:DB '; following Function 6 A=$'
POST88:DB 13,10,'OBSERVED: Function 6 returned A=$'

PRE91: DB 13,10,'Probe 0091: Function 1 selector',13,10,'Press Q now: $'
PRE92: DB 13,10,'Probe 0092: Function 1 blocks for input',13,10
       DB 'Wait briefly, then press B: $'
PRE93: DB 13,10,'Probe 0093: Function 1 result character',13,10,'Press R now: $'
PRE94: DB 13,10,'Probe 0094: Function 1 echoes graphic input',13,10
       DB 'Press G; it should appear between brackets: [$'
PRE95: DB 13,10,'Probe 0095: Function 1 echoes CR',13,10
       DB 'Press Enter; cursor should return to column zero: $'
PRE96: DB 13,10,'Probe 0096: Function 1 echoes LF',13,10
       DB 'Press Ctrl-J; cursor should advance one line: $'
PRE97: DB 13,10,'Probe 0097: Function 1 echoes backspace',13,10
       DB 'After ABC, press Backspace; X should overwrite C:',13,10,'ABC$'
PRE98: DB 13,10,'Probe 0098: Function 1 expands TAB',13,10
       DB 'After A, press TAB; B should land at next tab stop:',13,10,'A$'
PRE99: DB 13,10,'Probe 0099: ordinary control is not echoed',13,10
       DB 'Press Ctrl-A; nothing should appear between brackets: [$'
PRE100:DB 13,10,'Probe 0100: Function 1 shares formatted column state',13,10
       DB 'After A, press TAB; B should use the shared next tab stop:',13,10,'A$'
PRE101:DB 13,10,'Probe 0101: Function 1 scrolling control',13,10
       DB 'Press Ctrl-S, then Ctrl-Q, then X.',13,10
       DB 'The input call must pause until resumed and finally return X: $'
PRE102:DB 13,10,'Probe 0102: Function 1 active printer echo',13,10
       DB 'Function 1 input must echo to console and LIST.',13,10,'$'
DO102: DB 'Enable printer echo with Ctrl-P, then type G: $'
POST97:DB 13,10,'EXPECTED: display ends as ABX.',13,10,'$'
POST98:DB 13,10,'EXPECTED: TAB was expanded to the next eight-column stop.',13,10,'$'
POST100:DB 13,10,'EXPECTED: Function 1 TAB used the column established by Function 9.',13,10,'$'
POST101:DB 13,10,'OBSERVED: final return A=$'
POST101B:DB 13,10,'EXPECTED: pause/resume occurred and A=58 (X).',13,10,'$'
POST102:DB 13,10,'Disable printer echo with Ctrl-P.',13,10
        DB 'OBSERVED: inspect logical printer output.',13,10
        DB 'EXPECTED: printer contains the echoed G.',13,10,'$'
PRE103:DB 13,10,'Probe 0103: DRI Function 1 Ctrl-P handling',13,10,'$'
DO103: DB 'With printer echo off, press Ctrl-P once.',13,10
        DB 'It may display as a control character but must not toggle echo: $'
POST103:DB 13,10,'OBSERVED: Function 1 returned A=$'
POST103B:DB 13,10,'EXPECTED: A=10; printer echo remains off.',13,10,'$'
PRE104:DB 13,10,'Probe 0104: DRI retained Function 11 input',13,10
        DB 'Press K once. Function 11 must detect it; Function 1 must consume it: $'
POST104:DB 13,10,'OBSERVED: Function 1 returned A=$'
POST104B:DB 13,10,'EXPECTED: K echoed once and A=4B.',13,10,'$'

; Function-10 prompts give the keystrokes and specimen together.  Count and
; data come from the buffer; editing and physical-line behavior remain with
; the outside observer.
PRE106:DB 13,10,'Probe 0106: Function 10 selector/buffer',13,10
       DB 'Type AB then Enter. Expect count 02 and data [AB]: $'
PRE107:DB 13,10,'Probe 0107: Function 10 maximum byte',13,10
       DB 'Maximum is 1. Type Z only; call must return without Enter: $'
PRE107B:DB 13,10,'Maximum is now 255. Type Q then Enter.',13,10
       DB 'Expect count 01 and data [Q]: $'
PRE108:DB 13,10,'Probe 0108: Function 10 returned count',13,10
       DB 'Type ABC then Enter. Expect count 03: $'
PRE109:DB 13,10,'Probe 0109: Function 10 data location',13,10
       DB 'Type XYZ then Enter. Expect data [XYZ] at buffer+2: $'
PRE110:DB 13,10,'Probe 0110: bytes beyond returned count',13,10
       DB 'Type Q then Enter. Extra bytes have no portable meaning: $'
F10NEXT:DB 13,10,'OBSERVED: first byte beyond returned data=$'
PRE111:DB 13,10,'Probe 0111: CR termination',13,10
       DB 'Type AB then Enter. Expect count 02/data [AB], no CR stored: $'
PRE112:DB 13,10,'Probe 0112: LF termination',13,10
       DB 'Type AB then Ctrl-J. Expect count 02/data [AB], no LF stored: $'
PRE113:DB 13,10,'Probe 0113: capacity termination',13,10
       DB 'Maximum is 1. Type Z only; no additional character is required: $'
PRE114:DB 13,10,'Probe 0114: ordinary input storage/echo',13,10
       DB 'Type M then Enter. Expect M echoed, count 01, data [M]: $'
PRE115:DB 13,10,'Probe 0115: backspace editing',13,10
       DB 'Type AB, Backspace, C, Enter. Expect count 02/data [AC]: $'
PRE116:DB 13,10,'Probe 0116: DEL editing',13,10
       DB 'This requires byte 7Fh, not Backspace (08h).',13,10,'$'
DO116: DB 'Type AB, DEL, C, Enter. Expect count 02/data [AC]: $'
PRE117:DB 13,10,'Probe 0117: initial Ctrl-C warm restart',13,10
       DB 'At the empty input line press Ctrl-C.',13,10
       DB 'PASS means CP/M returns directly to the CCP; no PASS row follows.',13,10
       DB 'Press any key to start the test: $'
POST117:DB 13,10,'OBSERVED: Function 10 returned to CONSTEST.',13,10
        DB 'EXPECTED: initial Ctrl-C warm-restarts to the CCP.',13,10,'$'
PRE118:DB 13,10,'Probe 0118: Ctrl-E line continuation',13,10
       DB 'Type AB, Ctrl-E, CD, Enter. Expect new line and data [ABCD]: $'
PRE119:DB 13,10,'Probe 0119: Ctrl-R redisplay',13,10
       DB 'Type AB, Ctrl-R, CD, Enter. Expect redisplay and data [ABCD]: $'
PRE120:DB 13,10,'Probe 0120: Ctrl-U line deletion',13,10
       DB 'Type AB, Ctrl-U, CD, Enter. Expect new line and data [CD]: $'
PRE121:DB 13,10,'Probe 0121: Ctrl-X line deletion',13,10
       DB 'Type AB, Ctrl-X, CD, Enter. Expect erased line and data [CD]: $'
PRE122:DB 13,10,'Probe 0122: starting-column-relative editing',13,10
       DB 'Type AB, Backspace, C, Enter. Editing must respect this prompt column.',13,10
       DB 'Expect count 02/data [AC]: $'
PRE123:DB 13,10,'Probe 0123: no stored line terminator',13,10
       DB 'Type AB then Enter. Expect count 02/data [AB]: $'
POST123:DB 'OBSERVED: byte after returned data=$'
PRE124:DB 13,10,'Probe 0124: Function 10 register result',13,10
       DB 'Type Q then Enter. The returned register has no portable value: $'
POST124:DB 13,10,'OBSERVED: return A=$'
PRE125:DB 13,10,'Probe 0125: DRI Function 10 Ctrl-P handling',13,10
       DB 'Requires inspectable LIST capture and restores echo before exit.',13,10,'$'
DO125: DB 'Type Ctrl-P, A, Enter. Expect data [A], with Ctrl-P excluded: $'
PRE126:DB 13,10,'Probe 0126: DRI post-Ctrl-P echo state',13,10
       DB 'Requires inspectable LIST capture and restores echo before exit.',13,10,'$'
DO126: DB 'Type Ctrl-P, A, Enter. Expect A echoed to console and LIST: $'
REST125:DB 13,10,'Restore state: type Ctrl-P then Enter: $'
PRE127:DB 13,10,'Probe 0127: DRI seven-bit input masking',13,10
       DB 'Inject byte C1h then Enter. Expect count 01/data [A]: $'
PRE128:DB 13,10,'Probe 0128: DRI correction-display bytes',13,10
       DB 'Type AB, Backspace, C, Enter; inspect exact erase/redisplay bytes.',13,10
       DB 'Expect count 02/data [AC]: $'
PRE129:DB 13,10,'Probe 0129: DRI noninitial Ctrl-C behavior',13,10
       DB 'Type A, Ctrl-C, B, Enter.',13,10
       DB 'EXPECTED: noninitial Ctrl-C does not perform a warm boot.',13,10
       DB 'EXPECTED: Function 10 returns count 03; data is A, Ctrl-C, B.',13,10,'$'
PRE436:DB 13,10,'Probe 0436: Function 3 Reader convention',13,10
       DB 'Configure READER with a known byte; Function 3 now blocks for it.',13,10,'$'
PRE438:DB 13,10,'Probe 0438: Reader is separate from console',13,10
       DB 'Queue distinct READER and console bytes; Function 3 consumes READER.',13,10,'$'
POST438:DB 13,10,'OBSERVED: Function 3 returned A=$'
PRE440:DB 13,10,'Probe 0440: Function 5 List convention',13,10
       DB 'The LIST device must receive one L byte.',13,10,'$'
POST440:DB 13,10,'OBSERVED: inspect LIST capture.',13,10
       DB 'EXPECTED: exactly one L byte was emitted by Function 5.',13,10,'$'
PRE442:DB 13,10,'Probe 0442: Function 7 IOBYTE query',13,10
       DB 'EXPECTED: Function 7 return equals the IOBYTE at address 0003h.',13,10,'$'
PRE444:DB 13,10,'Probe 0444: IOBYTE field encoding',13,10
       DB 'EXPECTED: CON=bits 1-0, RDR=3-2, PUN=5-4, LST=7-6.',13,10
       DB 'EXPECTED: packed value equals the IOBYTE stored at 0003h.',13,10,'$'
POST444:DB 'OBSERVED: packed IOBYTE=$'
IOFIELDS:DB '; decoded CON=$'
IORDR:  DB ' RDR=$'
IOPUN:  DB ' PUN=$'
IOLST:  DB ' LST=$'
IOOBS:  DB 'OBSERVED: Function 7 return=$'
IOEXP:  DB 13,10,'EXPECTED: memory[0003h]=$'
PRE446:DB 13,10,'Probe 0446: active IOBYTE routing policy',13,10
       DB 'Configure and verify a nondefault logical-device route first.',13,10
       DB 'EXPECTED: Function 7 returns that configured IOBYTE value.',13,10,'$'
POST446:DB 'EXPECTED: traffic uses the selected physical-device provider.',13,10,'$'
F10OBS:DB 13,10,'OBSERVED: count=$'
F10DATA:DB '; data=[$'
F10END:DB ']',13,10,'$'
EXP51: DB 13,10,'EXPECTED: A=51 (Q).',13,10,'$'
EXP42: DB 13,10,'EXPECTED: call waited and returned A=42 (B).',13,10,'$'
EXP52: DB 13,10,'EXPECTED: A=52 (R).',13,10,'$'
EXP47: DB 13,10,'EXPECTED: [G] and A=47.',13,10,'$'
EXP0D: DB 13,10,'EXPECTED: CR was echoed and A=0D.',13,10,'$'
EXP0A: DB 13,10,'EXPECTED: LF was echoed and A=0A.',13,10,'$'
EXP01: DB 13,10,'EXPECTED: empty brackets and A=01.',13,10,'$'

O0052: DB 'Operator confirmed Function 2 emitted A$'
O0053: DB 'Operator confirmed Function 2 emitted dollar sign$'
O0054: DB 'Operator confirmed Function 9 used DE string address$'
O0055: DB 'Operator confirmed Function 9 stopped at dollar sign$'
O0056: DB 'Operator confirmed terminator was not emitted$'
O0057: DB 'Operator confirmed empty string emitted no bytes$'
O0058: DB 'Operator confirmed controls were scanned before terminator$'
O0059: DB 'Operator confirmed Function 2 formatted TAB$'
O0060: DB 'Operator confirmed Function 9 formatted TAB$'
O0061: DB 'Operator confirmed shared formatted-output state$'
O0062: DB 'Operator confirmed eight-column TAB expansion$'
O0063: DB 'Operator confirmed Function 2 pause/resume behavior$'
O0064: DB 'Operator confirmed Function 9 pause/resume behavior$'
O0065: DB 'Operator confirmed Function 2 logical-printer echo$'
O0066: DB 'Operator confirmed Function 9 logical-printer echo$'
O0067: DB 'Function 2 return byte recorded; no portable oracle$'
O0068: DB 'Function 9 return byte recorded; no portable oracle$'
O0069: DB 'DRI-CONSOLE: logical-column transitions$'
O0070: DB 'DRI-CONSOLE: LF column reset$'
O0071: DB 'DRI-CONSOLE: CR preserves column$'
O0072: DB 'Pending-key result recorded; no portable oracle$'
O0073: DB 'Post-pause Ctrl-C behavior recorded; no portable oracle$'
O0075: DB 'Operator confirmed E not FF selected direct output$'
O0076: DB 'Operator confirmed Function 6 emitted E unchanged$'
O0077: DB 'Operator confirmed direct TAB byte without BDOS expansion$'
O0078: DB 'Operator confirmed direct output bypassed Ctrl-S$'
O0079: DB 'Operator confirmed direct output absent from LIST echo$'
O0080: DB 'Function 6 direct-output return recorded; no portable oracle$'
O0081: DB 'Operator confirmed E=FF selected nonblocking input$'
O0082: DB 'Operator confirmed no-input result A=00$'
O0083: DB 'Operator confirmed ready Function 6 returned input byte$'
O0084: DB 'Operator confirmed Function 6 input had no echo or editing$'
O0085: DB 'Operator confirmed Function 11 not-ready result A=00$'
O0086: DB 'Exact Function 11 ready value recorded; no portable oracle$'
O0087: DB 'Pending-byte retention behavior recorded; no portable oracle$'
O0088: DB 'DRI pending-byte behavior recorded; no portable oracle$'
O0091: DB 'Operator confirmed Function 1 selected console input$'
O0092: DB 'Operator confirmed Function 1 blocked until input$'
O0093: DB 'Operator confirmed Function 1 returned input character$'
O0094: DB 'Operator confirmed Function 1 echoed graphic input$'
O0095: DB 'Operator confirmed Function 1 echoed CR$'
O0096: DB 'Operator confirmed Function 1 echoed LF$'
O0097: DB 'Operator confirmed Function 1 echoed backspace$'
O0098: DB 'Operator confirmed Function 1 expanded TAB$'
O0099: DB 'Operator confirmed ordinary control was not echoed$'
O0100: DB 'Operator confirmed Function 1 shared formatted state$'
O0101: DB 'Operator confirmed Function 1 honored scrolling control$'
O0102: DB 'Operator confirmed Function 1 active printer echo$'
O0103: DB 'DRI-CONSOLE: Ctrl-P did not toggle echo$'
O0104: DB 'DRI-CONSOLE: retained input consumed$'
O0106: DB 'Operator confirmed Function 10 used DE buffer$'
O0107: DB 'Operator confirmed maximum-byte capacity termination$'
O0108: DB 'Operator confirmed returned count byte$'
O0109: DB 'Operator confirmed returned data at buffer+2$'
O0110: DB 'Post-count byte recorded; no portable rule$'
O0111: DB 'CR ended input; terminator excluded$'
O0112: DB 'Operator confirmed LF terminated and was excluded$'
O0113: DB 'Buffer capacity ended input$'
O0114: DB 'Operator confirmed ordinary input stored and echoed$'
O0115: DB 'Operator confirmed backspace removed prior character$'
O0116: DB 'DEL removed preceding character$'
O0117: DB 'Function 10 returned instead of warm restart$'
O0118: DB 'Operator confirmed Ctrl-E continued logical line$'
O0119: DB 'Operator confirmed Ctrl-R redisplayed retained line$'
O0120: DB 'Operator confirmed Ctrl-U discarded current line$'
O0121: DB 'Operator confirmed Ctrl-X discarded current line$'
O0122: DB 'Operator confirmed editing used starting column$'
O0123: DB 'Operator confirmed no CR or LF was stored$'
O0124: DB 'Function 10 return byte recorded; no portable oracle$'
O0125: DB 'DRI-CONSOLE: Ctrl-P exclusion/echo toggle$'
O0126: DB 'DRI-CONSOLE: post-Ctrl-P printer echo$'
O0127: DB 'DRI-CONSOLE: seven-bit input masking$'
O0128: DB 'DRI-CONSOLE: exact correction display$'
O0129: DB 'DRI-CONSOLE: noninitial Ctrl-C behavior$'
O0436: DB 'Operator confirmed Function 3 Reader convention$'
O0438: DB 'Operator confirmed Reader/console separation$'
O0440: DB 'Operator confirmed Function 5 LIST output$'
O0442: DB 'Operator confirmed Function 7 returned IOBYTE$'
O0444: DB 'Operator confirmed standard IOBYTE field encoding$'
O0446: DB 'IOBYTE-ROUTING: active route confirmed$'

; Long records retain their frozen identities.  Short rows report the actual
; confirmed evidence instead of repeating the requirement prose.
R0051: DB 'CASE BDOS-CON-001-P0051',13,10,'LEDGER 0051',13,10
       DB 'ORACLE OR-0051',13,10,'CLASSIFICATION OUTSIDE_SCOPE',13,10
       DB 'EXPECTED no runtime test; return flags are outside scope.',13,10,'$'
R0052: DB 'CASE BDOS-CON-001-P0052',13,10,'LEDGER 0052',13,10
       DB 'ORACLE OR-0052',13,10,'EXPECTED Function 2 emits character from E.',13,10,'$'
R0053: DB 'CASE BDOS-CON-001-P0053',13,10,'LEDGER 0053',13,10
       DB 'ORACLE OR-0053',13,10,'EXPECTED Function 2 emits dollar as ordinary data.',13,10,'$'
R0054: DB 'CASE BDOS-CON-001-P0054',13,10,'LEDGER 0054',13,10
       DB 'ORACLE OR-0054',13,10,'EXPECTED Function 9 emits string addressed by DE.',13,10,'$'
R0055: DB 'CASE BDOS-CON-001-P0055',13,10,'LEDGER 0055',13,10
       DB 'ORACLE OR-0055',13,10,'EXPECTED Function 9 stops at dollar terminator.',13,10,'$'
R0056: DB 'CASE BDOS-CON-001-P0056',13,10,'LEDGER 0056',13,10
       DB 'ORACLE OR-0056',13,10,'EXPECTED Function 9 does not emit terminator.',13,10,'$'
R0057: DB 'CASE BDOS-CON-001-P0057',13,10,'LEDGER 0057',13,10
       DB 'ORACLE OR-0057',13,10,'EXPECTED empty Function 9 string emits nothing.',13,10,'$'
R0058: DB 'CASE BDOS-CON-001-P0058',13,10,'LEDGER 0058',13,10
       DB 'ORACLE OR-0058',13,10,'EXPECTED Function 9 scans ordinary controls.',13,10,'$'
R0059: DB 'CASE BDOS-CON-001-P0059',13,10,'LEDGER 0059',13,10
       DB 'ORACLE OR-0059',13,10,'EXPECTED Function 2 uses formatted output.',13,10,'$'
R0060: DB 'CASE BDOS-CON-001-P0060',13,10,'LEDGER 0060',13,10
       DB 'ORACLE OR-0060',13,10,'EXPECTED Function 9 uses formatted output.',13,10,'$'
R0061: DB 'CASE BDOS-CON-001-P0061',13,10,'LEDGER 0061',13,10
       DB 'ORACLE OR-0061',13,10,'EXPECTED Functions 2 and 9 share output state.',13,10,'$'
R0062: DB 'CASE BDOS-CON-001-P0062',13,10,'LEDGER 0062',13,10
       DB 'ORACLE OR-0062',13,10,'EXPECTED TAB reaches next eight-column stop.',13,10,'$'
R0063: DB 'CASE BDOS-CON-001-P0063',13,10,'LEDGER 0063',13,10
       DB 'ORACLE OR-0063',13,10,'EXPECTED Function 2 honors scrolling control.',13,10,'$'
R0064: DB 'CASE BDOS-CON-001-P0064',13,10,'LEDGER 0064',13,10
       DB 'ORACLE OR-0064',13,10,'EXPECTED Function 9 honors scrolling control.',13,10,'$'
R0065: DB 'CASE BDOS-CON-001-P0065',13,10,'LEDGER 0065',13,10
       DB 'ORACLE OR-0065',13,10,'EXPECTED Function 2 participates in printer echo.',13,10,'$'
R0066: DB 'CASE BDOS-CON-001-P0066',13,10,'LEDGER 0066',13,10
       DB 'ORACLE OR-0066',13,10,'EXPECTED Function 9 participates in printer echo.',13,10,'$'
R0067: DB 'CASE BDOS-CON-001-P0067',13,10,'LEDGER 0067',13,10
       DB 'ORACLE OR-0067',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no function-specific Function 2 return.',13,10,'$'
R0068: DB 'CASE BDOS-CON-001-P0068',13,10,'LEDGER 0068',13,10
       DB 'ORACLE OR-0068',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no function-specific Function 9 return.',13,10,'$'
R0069: DB 'CASE BDOS-CON-001-P0069',13,10,'LEDGER 0069',13,10
       DB 'ORACLE OR-0069',13,10,'CLASSIFICATION PROFILE_REQUIRED DRI_CONSOLE',13,10
       DB 'EXPECTED exact DRI logical-column state transitions.',13,10,'$'
R0070: DB 'CASE BDOS-CON-001-P0070',13,10,'LEDGER 0070',13,10
       DB 'ORACLE OR-0070',13,10,'CLASSIFICATION PROFILE_REQUIRED DRI_CONSOLE',13,10
       DB 'EXPECTED LF resets DRI logical column.',13,10,'$'
R0071: DB 'CASE BDOS-CON-001-P0071',13,10,'LEDGER 0071',13,10
       DB 'ORACLE OR-0071',13,10,'CLASSIFICATION PROFILE_REQUIRED DRI_CONSOLE',13,10
       DB 'EXPECTED CR preserves DRI logical column.',13,10,'$'
R0072: DB 'CASE BDOS-CON-001-P0072',13,10,'LEDGER 0072',13,10
       DB 'ORACLE OR-0072',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no portable pending-key buffering behavior.',13,10,'$'
R0073: DB 'CASE BDOS-CON-001-P0073',13,10,'LEDGER 0073',13,10
       DB 'ORACLE OR-0073',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no exact portable post-pause Ctrl-C behavior.',13,10,'$'
R0074: DB 'CASE BDOS-CON-002-P0074',13,10,'LEDGER 0074',13,10
       DB 'ORACLE OR-0074',13,10,'CLASSIFICATION OUTSIDE_SCOPE',13,10
       DB 'EXPECTED no runtime test; DRI private state is outside scope.',13,10,'$'
R0075: DB 'CASE BDOS-CON-001-P0075',13,10,'LEDGER 0075',13,10
       DB 'ORACLE OR-0075',13,10,'EXPECTED E not FF selects Function 6 output.',13,10,'$'
R0076: DB 'CASE BDOS-CON-001-P0076',13,10,'LEDGER 0076',13,10
       DB 'ORACLE OR-0076',13,10,'EXPECTED Function 6 emits character from E.',13,10,'$'
R0077: DB 'CASE BDOS-CON-001-P0077',13,10,'LEDGER 0077',13,10
       DB 'ORACLE OR-0077',13,10,'EXPECTED Function 6 does not expand TAB.',13,10,'$'
R0078: DB 'CASE BDOS-CON-001-P0078',13,10,'LEDGER 0078',13,10
       DB 'ORACLE OR-0078',13,10,'EXPECTED Function 6 bypasses Ctrl-S.',13,10,'$'
R0079: DB 'CASE BDOS-CON-001-P0079',13,10,'LEDGER 0079',13,10
       DB 'ORACLE OR-0079',13,10,'EXPECTED Function 6 bypasses printer echo.',13,10,'$'
R0080: DB 'CASE BDOS-CON-001-P0080',13,10,'LEDGER 0080',13,10
       DB 'ORACLE OR-0080',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no function-specific direct-output return.',13,10,'$'
R0081: DB 'CASE BDOS-CON-001-P0081',13,10,'LEDGER 0081',13,10
       DB 'ORACLE OR-0081',13,10,'EXPECTED E=FF selects nonblocking input.',13,10,'$'
R0082: DB 'CASE BDOS-CON-001-P0082',13,10,'LEDGER 0082',13,10
       DB 'ORACLE OR-0082',13,10,'EXPECTED no-input result A=00.',13,10,'$'
R0083: DB 'CASE BDOS-CON-001-P0083',13,10,'LEDGER 0083',13,10
       DB 'ORACLE OR-0083',13,10,'EXPECTED ready Function 6 returns input byte.',13,10,'$'
R0084: DB 'CASE BDOS-CON-001-P0084',13,10,'LEDGER 0084',13,10
       DB 'ORACLE OR-0084',13,10,'EXPECTED Function 6 input is unadorned.',13,10,'$'
R0085: DB 'CASE BDOS-CON-001-P0085',13,10,'LEDGER 0085',13,10
       DB 'ORACLE OR-0085',13,10,'EXPECTED Function 11 not-ready result is zero.',13,10,'$'
R0086: DB 'CASE BDOS-CON-001-P0086',13,10,'LEDGER 0086',13,10
       DB 'ORACLE OR-0086',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no portable exact ready value.',13,10,'$'
R0087: DB 'CASE BDOS-CON-001-P0087',13,10,'LEDGER 0087',13,10
       DB 'ORACLE OR-0087',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no portable pending-byte retention behavior.',13,10,'$'
R0088: DB 'CASE BDOS-CON-001-P0088',13,10,'LEDGER 0088',13,10
       DB 'ORACLE OR-0088',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED DRI-specific behavior is diagnostic.',13,10,'$'
R0089: DB 'CASE BDOS-CON-002-P0089',13,10,'LEDGER 0089',13,10
       DB 'ORACLE OR-0089',13,10,'CLASSIFICATION OUTSIDE_SCOPE',13,10
       DB 'EXPECTED no runtime test; DRI E=FE behavior is outside scope.',13,10,'$'
R0090: DB 'CASE BDOS-CON-002-P0090',13,10,'LEDGER 0090',13,10
       DB 'ORACLE OR-0090',13,10,'CLASSIFICATION OUTSIDE_SCOPE',13,10
       DB 'EXPECTED no runtime test; private representation is outside scope.',13,10,'$'
R0091: DB 'CASE BDOS-CON-001-P0091',13,10,'LEDGER 0091',13,10
       DB 'ORACLE OR-0091',13,10,'EXPECTED Function 1 selects console input.',13,10,'$'
R0092: DB 'CASE BDOS-CON-001-P0092',13,10,'LEDGER 0092',13,10
       DB 'ORACLE OR-0092',13,10,'EXPECTED Function 1 blocks until input.',13,10,'$'
R0093: DB 'CASE BDOS-CON-001-P0093',13,10,'LEDGER 0093',13,10
       DB 'ORACLE OR-0093',13,10,'EXPECTED Function 1 returns input character.',13,10,'$'
R0094: DB 'CASE BDOS-CON-001-P0094',13,10,'LEDGER 0094',13,10
       DB 'ORACLE OR-0094',13,10,'EXPECTED Function 1 echoes graphic characters.',13,10,'$'
R0095: DB 'CASE BDOS-CON-001-P0095',13,10,'LEDGER 0095',13,10
       DB 'ORACLE OR-0095',13,10,'EXPECTED Function 1 echoes CR.',13,10,'$'
R0096: DB 'CASE BDOS-CON-001-P0096',13,10,'LEDGER 0096',13,10
       DB 'ORACLE OR-0096',13,10,'EXPECTED Function 1 echoes LF.',13,10,'$'
R0097: DB 'CASE BDOS-CON-001-P0097',13,10,'LEDGER 0097',13,10
       DB 'ORACLE OR-0097',13,10,'EXPECTED Function 1 echoes backspace.',13,10,'$'
R0098: DB 'CASE BDOS-CON-001-P0098',13,10,'LEDGER 0098',13,10
       DB 'ORACLE OR-0098',13,10,'EXPECTED Function 1 expands TAB.',13,10,'$'
R0099: DB 'CASE BDOS-CON-001-P0099',13,10,'LEDGER 0099',13,10
       DB 'ORACLE OR-0099',13,10,'EXPECTED ordinary controls are not echoed.',13,10,'$'
R0100: DB 'CASE BDOS-CON-001-P0100',13,10,'LEDGER 0100',13,10
       DB 'ORACLE OR-0100',13,10,'EXPECTED Function 1 shares formatted state.',13,10,'$'
R0101: DB 'CASE BDOS-CON-001-P0101',13,10,'LEDGER 0101',13,10
       DB 'ORACLE OR-0101',13,10,'EXPECTED Function 1 honors scrolling control.',13,10,'$'
R0102: DB 'CASE BDOS-CON-001-P0102',13,10,'LEDGER 0102',13,10
       DB 'ORACLE OR-0102',13,10,'EXPECTED Function 1 participates in printer echo.',13,10,'$'
R0103: DB 'CASE BDOS-CON-001-P0103',13,10,'LEDGER 0103',13,10
       DB 'ORACLE OR-0103',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED DRI Function 1 returns Ctrl-P without toggling echo.',13,10,'$'
R0104: DB 'CASE BDOS-CON-001-P0104',13,10,'LEDGER 0104',13,10
       DB 'ORACLE OR-0104',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED DRI Function 1 consumes Function-11-retained input.',13,10,'$'
R0105: DB 'CASE BDOS-CON-002-P0105',13,10,'LEDGER 0105',13,10
       DB 'ORACLE OR-0105',13,10,'CLASSIFICATION OUTSIDE_SCOPE',13,10
       DB 'EXPECTED no runtime test; private implementation is out of scope.',13,10,'$'
R0106: DB 'CASE BDOS-CON-001-P0106',13,10,'LEDGER 0106',13,10
       DB 'ORACLE OR-0106',13,10,'EXPECTED C=0A and DE designate input buffer.',13,10,'$'
R0107: DB 'CASE BDOS-CON-001-P0107',13,10,'LEDGER 0107',13,10
       DB 'ORACLE OR-0107',13,10,'EXPECTED buffer maximum controls capacity.',13,10,'$'
R0108: DB 'CASE BDOS-CON-001-P0108',13,10,'LEDGER 0108',13,10
       DB 'ORACLE OR-0108',13,10,'EXPECTED returned count is stored at DE+1.',13,10,'$'
R0109: DB 'CASE BDOS-CON-001-P0109',13,10,'LEDGER 0109',13,10
       DB 'ORACLE OR-0109',13,10,'EXPECTED returned data begins at DE+2.',13,10,'$'
R0110: DB 'CASE BDOS-CON-001-P0110',13,10,'LEDGER 0110',13,10
       DB 'ORACLE OR-0110',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED bytes beyond returned count have no portable value.',13,10,'$'
R0111: DB 'CASE BDOS-CON-001-P0111',13,10,'LEDGER 0111',13,10
       DB 'ORACLE OR-0111',13,10,'EXPECTED CR terminates input and is excluded.',13,10,'$'
R0112: DB 'CASE BDOS-CON-001-P0112',13,10,'LEDGER 0112',13,10
       DB 'ORACLE OR-0112',13,10,'EXPECTED LF terminates input and is excluded.',13,10,'$'
R0113: DB 'CASE BDOS-CON-001-P0113',13,10,'LEDGER 0113',13,10
       DB 'ORACLE OR-0113',13,10,'EXPECTED reaching capacity terminates input.',13,10,'$'
R0114: DB 'CASE BDOS-CON-001-P0114',13,10,'LEDGER 0114',13,10
       DB 'ORACLE OR-0114',13,10,'EXPECTED ordinary input is stored and echoed.',13,10,'$'
R0115: DB 'CASE BDOS-CON-001-P0115',13,10,'LEDGER 0115',13,10
       DB 'ORACLE OR-0115',13,10,'EXPECTED backspace removes prior character.',13,10,'$'
R0116: DB 'CASE BDOS-CON-001-P0116',13,10,'LEDGER 0116',13,10
       DB 'ORACLE OR-0116',13,10,'EXPECTED DEL removes prior character.',13,10,'$'
R0117: DB 'CASE BDOS-CON-001-P0117',13,10,'LEDGER 0117',13,10
       DB 'ORACLE OR-0117',13,10,'EXPECTED initial Ctrl-C performs warm restart.',13,10,'$'
R0118: DB 'CASE BDOS-CON-001-P0118',13,10,'LEDGER 0118',13,10
       DB 'ORACLE OR-0118',13,10,'EXPECTED Ctrl-E starts physical continuation.',13,10,'$'
R0119: DB 'CASE BDOS-CON-001-P0119',13,10,'LEDGER 0119',13,10
       DB 'ORACLE OR-0119',13,10,'EXPECTED Ctrl-R redisplays retained line.',13,10,'$'
R0120: DB 'CASE BDOS-CON-001-P0120',13,10,'LEDGER 0120',13,10
       DB 'ORACLE OR-0120',13,10,'EXPECTED Ctrl-U discards current line.',13,10,'$'
R0121: DB 'CASE BDOS-CON-001-P0121',13,10,'LEDGER 0121',13,10
       DB 'ORACLE OR-0121',13,10,'EXPECTED Ctrl-X discards current line.',13,10,'$'
R0122: DB 'CASE BDOS-CON-001-P0122',13,10,'LEDGER 0122',13,10
       DB 'ORACLE OR-0122',13,10,'EXPECTED editing is relative to starting column.',13,10,'$'
R0123: DB 'CASE BDOS-CON-004-P0123',13,10,'LEDGER 0123',13,10
       DB 'ORACLE OR-0123',13,10,'EXPECTED no CR or LF is stored in returned data.',13,10,'$'
R0124: DB 'CASE BDOS-CON-004-P0124',13,10,'LEDGER 0124',13,10
       DB 'ORACLE OR-0124',13,10,'CLASSIFICATION NOT_GUARANTEED',13,10
       DB 'EXPECTED no portable function-specific register result.',13,10,'$'
R0125: DB 'CASE BDOS-CON-004-P0125',13,10,'LEDGER 0125',13,10
       DB 'ORACLE OR-0125',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED DRI Ctrl-P toggles echo and is excluded from data.',13,10,'$'
R0126: DB 'CASE BDOS-CON-004-P0126',13,10,'LEDGER 0126',13,10
       DB 'ORACLE OR-0126',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED DRI post-Ctrl-P input echo reaches LIST.',13,10,'$'
R0127: DB 'CASE BDOS-CON-004-P0127',13,10,'LEDGER 0127',13,10
       DB 'ORACLE OR-0127',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED DRI Function 10 masks input to seven bits.',13,10,'$'
R0128: DB 'CASE BDOS-CON-004-P0128',13,10,'LEDGER 0128',13,10
       DB 'ORACLE OR-0128',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED exact DRI correction-display byte sequence.',13,10,'$'
R0129: DB 'CASE BDOS-CON-004-P0129',13,10,'LEDGER 0129',13,10
       DB 'ORACLE OR-0129',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED noninitial Ctrl-C follows DRI line-editor behavior.',13,10,'$'
R0130: DB 'CASE BDOS-CON-004-P0130',13,10,'LEDGER 0130',13,10
       DB 'ORACLE OR-0130',13,10,'CLASSIFICATION OUTSIDE_SCOPE',13,10
       DB 'EXPECTED private editor organization is outside scope.',13,10,'$'
R0421: DB 'CASE BDOS-CON-005-P0421',13,10,'LEDGER 0421',13,10
       DB 'ORACLE OR-0421',13,10,'CLASSIFICATION OUTSIDE_SCOPE',13,10
       DB 'EXPECTED private polling implementation is outside scope.',13,10,'$'
R0436: DB 'CASE COMM-002-P0436',13,10,'LEDGER 0436',13,10
       DB 'ORACLE OR-0436',13,10,'EXPECTED Function 3 reads configured READER.',13,10,'$'
R0438: DB 'CASE COMM-002-P0438',13,10,'LEDGER 0438',13,10
       DB 'ORACLE OR-0438',13,10,'EXPECTED Reader input is separate from console.',13,10,'$'
R0440: DB 'CASE COMM-002-P0440',13,10,'LEDGER 0440',13,10
       DB 'ORACLE OR-0440',13,10,'EXPECTED Function 5 emits E to LIST.',13,10,'$'
R0442: DB 'CASE COMM-002-P0442',13,10,'LEDGER 0442',13,10
       DB 'ORACLE OR-0442',13,10,'EXPECTED Function 7 returns current IOBYTE.',13,10,'$'
R0444: DB 'CASE COMM-002-P0444',13,10,'LEDGER 0444',13,10
       DB 'ORACLE OR-0444',13,10,'EXPECTED four two-bit logical-device fields.',13,10,'$'
R0446: DB 'CASE COMM-002-P0446',13,10,'LEDGER 0446',13,10
       DB 'ORACLE OR-0446',13,10,'CLASSIFICATION PROFILE_REQUIRED',13,10
       DB 'EXPECTED active routing follows the selected IOBYTE provider.',13,10,'$'

ITEMNO: DW 0
CURITEM:DW 0
PROCPTR:DW 0
OBSPTR: DW 0
RECPTR: DW 0
STATUSPTR:DW 0
PASSCT: DB 0
FAILCT: DB 0
OBSCT:  DB 0
SKIPREQ:DB 0
SKIPMSG:DW 0
FULLMODE:DB 0
ANSWER: DB 0
CASECLS:DB 0
AGGMODE:DB 0
RETVAL: DB 0
RETVAL2:DB 0
F10MAX: DB 0
F10LEFT:DB 0
F10BUF: DB 8,0
        DS 256
        DS      128
STACKTOP:
        END     START
