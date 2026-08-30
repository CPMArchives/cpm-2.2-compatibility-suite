BEGIN { FS=OFS="\t" }
NR == 1 {
  print "entry","compatibility_requirement","evidence_source","extension_constraint","validation_method","classification","safe_boundary_rule"
  next
}
{
  d=$6
  if (d == "REQUIRED") {
    constraint="Extensions must preserve this CP/M-visible observation"
    rule="May change or delegate mechanism only with observational equivalence in the declared CP/M personality"
  } else if (d == "POLICY PENDING") {
    constraint="Extension must not silently choose or expose this unresolved behavior"
    rule="Require named opt-in/profile and activate its tests before claiming compatibility"
  } else if (d == "NOT GUARANTEED") {
    constraint="Extension may vary this result within the ledger boundary"
    rule="Do not turn one extension/provider result into a CP/M baseline promise"
  } else {
    constraint="No CP/M requirement to reproduce this private/incidental mechanism"
    rule="Extension/internal implementation may differ; keep private details outside CP/M acceptance criteria"
  }
  print $1,$2,$3,constraint,$5,d,rule
}
