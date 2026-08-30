#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-or-later
"""Generate the two loadable FILETEST executables from their common source."""
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'suite/src'
src = SOURCES / 'FILECORE.ASM'
text = src.read_text()

def own(n, part):
    return (n < 300) if part == 1 else (n >= 300)

def build(part):
    lines = text.splitlines()
    out=[]
    i=0
    while i < len(lines):
        line=lines[i]
        # Selector triplet: LD HL,ARGBUF / LD DE,Snnnn or SCnnn / CALL STREQ / JP Z,RUNnnnn
        if i+3 < len(lines) and re.match(r'\s*LD\s+HL,ARGBUF', line):
            m=re.match(r'\s*LD\s+DE,S(?:C|CASE)?0?(\d{3,4})\s*$', lines[i+1])
            j=re.match(r'\s*JP\s+Z,RUN0?(\d{3,4})\s*$', lines[i+3])
            if m and j and not own(int(j.group(1)), part):
                i += 4; continue
        # Tool-specific command groups belong only to the relevant half.
        if i+3 < len(lines) and re.match(r'\s*LD\s+HL,ARGBUF', line):
            m=re.match(r'\s*LD\s+DE,(SGROUPOPEN|SGROUPSEQ|SGROUPCLOSE|SGFCB|SGREAD|SGWRITE|SGRANDOM|SGLIFE|SFN15|SFN16|SFN20|SGFN15|SGFN16|SGFN20)\s*$', lines[i+1])
            if m:
                first=m.group(1) in {'SGROUPOPEN','SGROUPSEQ','SGROUPCLOSE','SGFCB','SGREAD','SGWRITE','SFN15','SFN16','SFN20','SGFN15','SGFN16','SGFN20'}
                if first != (part == 1): i += 4; continue
        # Group-call line for a numbered runner.
        m=re.match(r'(\s*)CALL\s+RUN0?(\d{3,4})\s*$', line)
        if m and not own(int(m.group(2)), part):
            i += 1; continue
        # Group observation triplet: LD HL,Snnnn / CALL RUNDIAGONE
        if i+1 < len(lines):
            m=re.match(r'\s*LD\s+HL,S0?(\d{3,4})\s*$', line)
            if m and re.match(r'\s*CALL\s+RUNDIAGONE\s*$', lines[i+1]) and not own(int(m.group(1)), part):
                i += 2; continue
        # Observation deck entries are numbered 0-15 in part 1 and 16-22
        # in the unsplit source.  Drop the other part and rebase part 2.
        if i+1 < len(lines):
            m=re.match(r'(\s*)LD\s+A,(\d+)\s*$', line)
            if m and re.match(r'\s*CALL\s+RUNDIAGONE\s*$', lines[i+1]):
                index=int(m.group(2))
                if (index < 16) != (part == 1):
                    i += 2; continue
                if part == 2:
                    out.append(f'{m.group(1)}LD      A,{index-16}')
                    out.append(lines[i+1]); i += 2; continue
        # Split the seven-byte observation table itself.
        if re.match(r'\s*DW\s+S0?(\d{3,4}),', line):
            m=re.match(r'\s*DW\s+S0?(\d{3,4}),', line)
            if m and not own(int(m.group(1)), part):
                i += 2; continue
        # Catalog: keep group headings but only owned item rows.
        if re.match(r'\s*DB\s+.*[\'\"]  0?(\d{3,4}) [RNS] ', line):
            m=re.search(r'[\'\"]  0?(\d{3,4}) [RNS] ', line)
            if m and not own(int(m.group(1)), part):
                i += 1; continue
        # Detailed case card: unowned cards collapse to one terminator.
        m=re.match(r'(C0?(\d{3,4})MSG):\s*(.*)$', line)
        if m and not own(int(m.group(2)), part):
            out.append(f"{m.group(1)}: DB '$'")
            i += 1
            while i < len(lines) and not re.match(r'^[A-Za-z][A-Za-z0-9_]*:', lines[i]):
                i += 1
            continue
        out.append(line)
        i += 1
    result='\n'.join(out)+'\n'
    name='FILETEST' if part == 1 else 'RANDTEST'
    result=result.replace('DIAG_COUNT EQU  23', f'DIAG_COUNT EQU  {16 if part == 1 else 7}')
    result=result.replace('FILETEST 0.1.0-dev35', f'{name} 0.1.0-dev35')
    result=result.replace('EXECUTABLE FILETEST.COM', f'EXECUTABLE {name}.COM')
    if part == 2:
        result=result.replace("DB 'FILETEST: unknown command.", "DB 'RANDTEST: unknown command.")
        result=result.replace('FILETEST /', 'RANDTEST /')
        result=result.replace("        DB '  RANDTEST /FN:n            Select BDOS function 15, 16, or 20',13,10\n", '')
    total = 93 if part == 1 else 49
    req, diag, scope = ((68,16,9) if part == 1 else (41,7,1))
    result=result.replace("DB 13,10,'TOTAL: 142 ITEMS',13,10,'$'", f"DB 13,10,'TOTAL: {total} ITEMS',13,10,'$'")
    result=result.replace("DB 'Coverage: 142 implemented FILETEST catalog items',13,10", f"DB 'Coverage: {total} implemented {name} catalog items',13,10")
    result=result.replace("DB 'Required: 109  Diagnostics: 23  Outside scope: 10',13,10", f"DB 'Required: {req}  Diagnostics: {diag}  Outside scope: {scope}',13,10")
    # Only advertise functional and orthogonal groups owned by this half.
    if part == 1:
        for phrase in (
            "        DB '  RANDOM        Random I/O and file size (37)',13,10\n",
            "        DB '  LIFECYCLE     Protection and lifecycle behavior (12)',13,10,13,10\n",
        ): result=result.replace(phrase,'')
        result=result.replace("        DB 13,10,'RANDOM I/O (37)',13,10\n",'')
        result=result.replace("        DB 13,10,'LIFECYCLE AND PROTECTION (12)',13,10\n",'')
        result=result.replace("        LD      DE,SKIPMAN\n        LD      A,2\n        CALL    PUTSKIPS", "        LD      DE,SKIPMAN\n        XOR     A\n        CALL    PUTSKIPS", 1)
        result=result.replace("        LD      DE,SKIPALL\n        LD      A,12\n        CALL    PUTSKIPS", "        LD      DE,SKIPALL\n        LD      A,9\n        CALL    PUTSKIPS")
        result=result.replace("DB 13,10,'MANUAL ITEMS (2)',13,10", "DB 13,10,'MANUAL ITEMS (0)',13,10")
        result=result.replace("        DB '  0368 - R File read-only sequential protection',13,10\n",'')
        result=result.replace("        DB '  0369 - R File read-only random protection',13,10\n",'')
    else:
        for phrase in (
            "        DB '  FCBOPEN       FCB representation, Open, and Close (31)',13,10\n",
            "        DB '  READ          Sequential Read and Make prerequisites (38)',13,10\n",
            "        DB '  WRITE         Sequential Write and persistence (24)',13,10\n",
            "        DB 'ADDITIONAL GROUPS',13,10\n",
            "        DB '  OPEN          Core Open workflow',13,10\n",
            "        DB '  SEQREAD       Core sequential-read workflow',13,10\n",
            "        DB '  CLOSE         Core Close workflow',13,10,13,10\n",
            "        DB 'ORTHOGONAL GROUPS',13,10\n",
            "        DB '  FN:15         Function 15/Open-dependent items (/FN:15)',13,10\n",
            "        DB '  FN:16         Function 16/Close-dependent items (/FN:16)',13,10\n",
            "        DB '  FN:20         Function 20/Read-dependent items (/FN:20)',13,10,'$'\n",
        ): result=result.replace(phrase,'')
        result=result.replace("        DB 13,10,'FCB AND OPEN (31)',13,10\n",'')
        result=result.replace("        DB 13,10,'SEQUENTIAL READ (38)',13,10\n",'')
        result=result.replace("        DB 13,10,'WRITE (24)',13,10\n",'')
        result=result.replace("        DB '  LIFECYCLE     Protection and lifecycle behavior (12)',13,10,13,10\n", "        DB '  LIFECYCLE     Protection and lifecycle behavior (12)',13,10,'$'\n")
        # /SAFE on the second half uses its returning REQUIRED deck.
        result=result.replace("        LD      DE,SSAFE\n        CALL    STREQ\n        JP      Z,RUNALL", "        LD      DE,SSAFE\n        CALL    STREQ\n        JP      Z,RUNREQUIRED")
        result=result.replace("        LD      DE,SKIPALL\n        LD      A,12\n        CALL    PUTSKIPS", "        LD      DE,SKIPALL\n        LD      A,3\n        CALL    PUTSKIPS")
    return result

for part,name in ((1,'FILETEST.ASM'),(2,'RANDTEST.ASM')):
    (SOURCES / name).write_text(build(part), encoding='ascii')
    print(f'generated {name}')
