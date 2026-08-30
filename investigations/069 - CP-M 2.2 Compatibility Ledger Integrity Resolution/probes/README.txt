Investigation 069 ledger integrity resolution
==============================================

Authoritative input:
  reference/02 Compatibility Ledger - Investigation 068.txt

Canonical output:
  02 Compatibility Ledger - Investigation 069.txt

The output is produced deterministically by canonicalize069.awk.  The script:

  - removes only the second verbatim Investigation-011 / 0248-0277 block;
  - makes entry 0523 an explicit profile-scope cross-reference to 0435;
  - adds I063 processor propositions as contiguous IDs 0623-0627;
  - extends the investigation source catalogue through I069;
  - appends the Investigation 069 cumulative-history note.

Validation:

  ./probes/validate069.sh

Artifacts include complete before/after diff, identifier reports, disposition
audit, processor decision table, cross-reference audit, protected-tree audit,
and SHA-256 manifests.  The original Investigation 068 ledger is unchanged.
