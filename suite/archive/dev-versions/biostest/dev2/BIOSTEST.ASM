; BetterCP/M executable conformance suite - BIOSTEST
; Version 0.1.0-dev2 - all 46 assigned BIOS ledger rows
; Intel 8080 instruction subset; accepted by z80asm and CP/M M80 in .Z80 mode.
;
; Dev1 established the public interface and BIO-001 through BIO-023.
; Dev2 completes the catalog with BIO-024 through BIO-046. It does not turn a
; shallow pointer/call smoke test into a conformance PASS.  Required rows name
; the controlled procedure still needed; portability and scope rows explain
; why no baseline PASS/FAIL is assigned.

        ORG     0100H
BDOS    EQU     0005H
NCASES  EQU     46

START:  LD      SP,STACKTOP
        LD      HL,0
        PUSH    HL
        CALL    PARSE
        CP      1
        JP      Z,HELP
        CP      2
        JP      Z,LIST
        CP      3
        JP      Z,RUNALL
        CP      4
        JP      Z,RUNONE
        CP      5
        JP      Z,INFO
        CP      6
        JP      Z,HRESULTS
        CP      7
        JP      Z,HPROFILES
        LD      DE,BADSEL
        CALL    PUTS
        RET

; Return A=1 help, 2 list, 3 all/safe, 4 numeric, 5 info,
; 6 help-results, or 7 help-profiles.
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
        CP      'L'
        JP      Z,PARSEL
        CP      'A'
        JP      Z,PARSEA
        CP      'S'
        JP      Z,PARSEA
        CP      'I'
        JP      Z,PARSEI
        LD      DE,SELBUF
        LD      C,4
PNUM:  LD      A,(HL)
        CP      '0'
        JP      C,PARSEH
        CP      '9'+1
        JP      NC,PARSEH
        LD      (DE),A
        INC     HL
        INC     DE
        DEC     C
        JP      NZ,PNUM
        LD      A,4
        RET
PARSEL:LD      A,2
        RET
PARSEA:LD      A,3
        RET
PARSEI:LD      A,5
        RET
PARSEHX:
        INC     HL
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

HELP:  LD      DE,HLPMSG
        CALL    PUTS
        RET
LIST:  LD      DE,LSTMSG
        CALL    PUTS
        RET
INFO:  LD      DE,INFMSG
        CALL    PUTS
        RET
HRESULTS:
        LD      DE,RESMSG
        CALL    PUTS
        RET
HPROFILES:
        LD      DE,PRFMSG
        CALL    PUTS
        RET

RUNALL:LD      DE,HEADMSG
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
        LD      DE,SUMMSG
        CALL    PUTS
        RET

RUNONE:
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

; Each table row contains pointers to item, status, class, and observation.
PRINTROW:
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTS
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTS
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        INC     HL
        CALL    PUTS
        LD      DE,SP2
        CALL    PUTS
        LD      E,(HL)
        INC     HL
        LD      D,(HL)
        CALL    PUTS
        LD      DE,CRLF
        JP      PUTS

PUTS:  PUSH    HL
        PUSH    BC
        LD      C,9
        CALL    BDOS
        POP     BC
        POP     HL
        RET

HLPMSG:DB 13,10,'BIOSTEST 0.1.0-dev2',13,10,13,10
        DB '  BIOSTEST /NNNN   Run or explain one ledger item',13,10
        DB '  BIOSTEST /ALL    Run all returning checks and observations',13,10
        DB '  BIOSTEST /SAFE   Run rows requiring no destructive media',13,10
        DB '  BIOSTEST /LIST   List implemented ledger items',13,10
        DB '  BIOSTEST /H      Show this help',13,10
        DB '  BIOSTEST /INFO   Show build information',13,10,'$'
INFMSG:DB 13,10,'BetterCP/M BIOSTEST 0.1.0-dev2',13,10
        DB 'Catalog: BIO-001 through BIO-046 (46 rows)',13,10
        DB 'Processor required: Intel 8080',13,10
        DB 'Returning automated checks: 0 in this bring-up revision',13,10,'$'
RESMSG:DB 13,10,'PASS and FAIL are emitted only after the complete oracle runs.',13,10
        DB 'UNTESTED identifies a required procedure not yet automated.',13,10
        DB 'OBSERVED records a permitted variation without claiming PASS.',13,10,'$'
PRFMSG:DB 13,10,'OPT-FN37: optional undocumented Function 37 compatibility.',13,10
        DB 'Device-dependent rows require a declared hardware provider.',13,10,'$'
BADSEL:DB 13,10,'Unknown selector. Use BIOSTEST /H.',13,10,'$'
HEADMSG:DB 13,10,'ITEM  STATUS    CLASS       OBSERVED',13,10
        DB '----  --------  ----------  ----------------------------------------',13,10,'$'
SUMMSG:DB 'Summary: 0 pass, 0 fail, 0 error, 11 observations',13,10
        DB '35 scope/required/profile procedures remain untested.',13,10,'$'
ONESUM:DB 'Summary: selected row reported above.',13,10,'$'
SP2:    DB '  $'
CRLF:   DB 13,10,'$'

; Catalog text is deliberately compact enough for an 80-column terminal.
LSTMSG:DB 13,10
        DB '0423 OUT SCOPE  Function 34 is not Compute File Size',13,10
        DB '0424 REQUIRED   Function 27 allocation-vector pointer',13,10
        DB '0425 REQUIRED   Allocation-vector length and bit mapping',13,10
        DB '0426 REQUIRED   Reserved directory allocation bits',13,10
        DB '0427 REQUIRED   Live allocation state',13,10
        DB '0428 NOT GUAR.  Allocation-pointer address and lifetime',13,10
        DB '0429 NOT GUAR.  Application modification of allocation vector',13,10
        DB '0430 NOT GUAR.  Read-only allocation information',13,10
        DB '0431 REQUIRED   Function 31 DPB pointer and layout',13,10
        DB '0432 REQUIRED   DPB configuration and sharing',13,10
        DB '0433 REQUIRED   Documented DPB modification',13,10
        DB '0434 NOT GUAR.  DPB address and lifetime',13,10
        DB '0435 OPTIONAL   Function 37 compatibility status',13,10
        DB '0437 NOT GUAR.  Reader completion and optional-device behavior',13,10
        DB '0439 REQUIRED   Function 4 Punch convention',13,10
        DB '0441 NOT GUAR.  Character-output result values',13,10
        DB '0443 REQUIRED   Function 8 IOBYTE set',13,10
        DB '0445 REQUIRED   IOBYTE routing boundary',13,10
        DB '0447 NOT GUAR.  IOBYTE set has no initialization contract',13,10
        DB '0448 REQUIRED   Character-device DMA independence',13,10
        DB '0449 REQUIRED   Stateful BIOS disk setup',13,10
        DB '0450 REQUIRED   SELDSK result and deferral',13,10
        DB '0451 REQUIRED   Public DPH layout',13,10
        DB '0452 NOT GUAR.  DPH address and private workspace',13,10
        DB '0453 REQUIRED   Track mapping and OFF',13,10
        DB '0454 REQUIRED   Sector translation chain',13,10
        DB '0455 NOT GUAR.  Translation implementation freedom',13,10
        DB '0456 REQUIRED   BIOS DMA state',13,10
        DB '0457 REQUIRED   BIOS logical-sector transfer',13,10
        DB '0458 REQUIRED   BIOS WRITE type codes',13,10
        DB '0459 OUT SCOPE  Physical storage freedom',13,10
        DB '0460 NOT GUAR.  BIOS disk-call reentrancy',13,10
        DB '0461 REQUIRED   BIOS jump-vector structure',13,10
        DB '0462 NOT GUAR.  BIOS vector address freedom',13,10
        DB '0463 REQUIRED   BIOS-base discovery through WBOOT gateway',13,10
        DB '0464 REQUIRED   BOOT control contract',13,10
        DB '0465 REQUIRED   WBOOT control contract',13,10
        DB '0466 REQUIRED   Warm-start gateway reconstruction',13,10
        DB '0467 OUT SCOPE  Boot implementation freedom',13,10
        DB '0468 REQUIRED   BIOS console status contract',13,10
        DB '0469 REQUIRED   BIOS console input contract',13,10
        DB '0470 REQUIRED   BIOS character output contracts',13,10
        DB '0471 REQUIRED   BIOS reader contract',13,10
        DB '0472 PROFILE    LISTST result policy',13,10
        DB '0473 REQUIRED   Direct BIOS call layering',13,10
        DB '0622 REQUIRED   Self-modifying transient execution',13,10,'$'

STOUT: DB 'UNTESTED$'
STOBS: DB 'OBSERVED$'
CLREQ: DB 'REQUIRED$'
CLNG:  DB 'NOT GUAR.$'
CLOUT: DB 'OUT SCOPE$'
CLOPT: DB 'OPTIONAL$'

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
O0424: DB 'Needs controlled disks; SCRATCH profile pending$'
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
        DS 128
STACKTOP:
        END     START
