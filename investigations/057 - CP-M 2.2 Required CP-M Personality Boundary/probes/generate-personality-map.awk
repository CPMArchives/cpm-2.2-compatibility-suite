BEGIN { FS=OFS="\t" }
NR == 1 {
  print "entry","compatibility_requirement","evidence_source","personality_responsibility","validation_method","classification","delegation_boundary"
  next
}
{
  boundary=$4
  disposition=$6
  if (disposition == "NOT REQUIRED") {
    responsibility="Excluded from CP/M personality contract"
    delegation="No personality or provider structure constrained"
  } else if (disposition == "NOT GUARANTEED") {
    responsibility="Personality non-guarantee: do not publish one stable result"
    delegation="Owning mechanism may vary; CP/M software receives no broader promise"
  } else if (disposition == "POLICY PENDING") {
    responsibility="Profile-gated CP/M-visible obligation if selected"
    delegation="Profile may select provider/mechanism; applicability must be declared"
  } else if (boundary ~ /BIOS/) {
    responsibility="Expose required CP/M BIOS ABI and configured structures"
    delegation="Physical/host device mechanism may be delegated behind BIOS-visible semantics"
  } else if (boundary ~ /error/) {
    responsibility="Expose required CP/M result/recovery boundary"
    delegation="Detection, retry and unwind may coordinate with delegated device/storage mechanisms"
  } else if (boundary ~ /Transient/) {
    responsibility="Expose required CP/M CPU/memory/entry/lifecycle view"
    delegation="Execution and memory backing may be delegated without changing visible address/state semantics"
  } else if (boundary ~ /CCP/) {
    responsibility="Expose required CP/M command-environment behavior"
    delegation="Parsing/loading mechanisms may vary; delegated file/console operations retain CP/M results"
  } else if (boundary ~ /BDOS/) {
    responsibility="Expose required CP/M BDOS call/state/service semantics"
    delegation="Host/platform mechanisms may be delegated only beneath FCB/DMA/console/state observations"
  } else {
    responsibility="Expose applicable CP/M-visible observation"
    delegation="Mechanism may be delegated while result remains owned by personality claim"
  }
  print $1,$2,$3,responsibility,$5,disposition,delegation
}
