#!/usr/bin/env python3
import collections
import hashlib
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(errors="strict")
entries = []
matches = list(re.finditer(r"(?m)^(\d{4})\.\s+(.+)$", text))
for i, match in enumerate(matches):
    block = text[match.start() : matches[i + 1].start() if i + 1 < len(matches) else len(text)]
    cls = re.search(r"(?m)^\s*Disposition:\s*(REQUIRED|NOT GUARANTEED|NOT REQUIRED|POLICY PENDING)\s*$", block)
    proposition = re.search(r"(?ms)^\d{4}\.\s+[^\n]+\n\s*(.*?)(?=^\s*Disposition:)", block)
    normalized = " ".join(proposition.group(1).split()).lower() if proposition else ""
    entries.append((int(match.group(1)), match.group(2).strip(), cls.group(1) if cls else "MISSING", normalized))

ids = [e[0] for e in entries]
counts = collections.Counter(e[2] for e in entries)
dupe_ids = sorted(x for x, n in collections.Counter(ids).items() if n > 1)
gaps = sorted(set(range(min(ids), max(ids) + 1)) - set(ids))
same = collections.defaultdict(list)
for ident, title, cls, proposition in entries:
    if proposition:
        same[proposition].append((ident, cls, title))
exact = [group for group in same.values() if len(group) > 1]

print(f"ledger={path}")
print(f"sha256={hashlib.sha256(path.read_bytes()).hexdigest()}")
print(f"entries={len(entries)} range={min(ids):04d}-{max(ids):04d}")
print("classifications=" + ", ".join(f"{key}:{counts[key]}" for key in sorted(counts)))
print(f"duplicate_ids={dupe_ids or 'none'}")
print(f"gaps={gaps or 'none'}")
print(f"missing_classification={sum(1 for e in entries if e[2] == 'MISSING')}")
print(f"exact_duplicate_propositions={len(exact)}")
for group in exact:
    print("EXACT " + " | ".join(f"{ident:04d} {cls} {title}" for ident, cls, title in group))
print("policy_pending_entries:")
for ident, title, cls, proposition in entries:
    if cls == "POLICY PENDING":
        print(f"{ident:04d}\t{title}")
