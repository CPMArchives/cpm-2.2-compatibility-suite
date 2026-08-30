BEGIN { FS=OFS="\t" }
NR == 1 {
  print "entry","compatibility_requirement","evidence_source","responsible_boundary","validation_method","classification","responsibility_rule"
  next
}
{
  tests=$7
  split(tests, parts, ",")
  primary=parts[1]
  if (primary ~ /CCP-/) boundary="CCP / command-environment boundary"
  else if (primary ~ /BDOS-CALL-/) boundary="BDOS public-call boundary"
  else if (primary ~ /BDOS-CON-/) boundary="BDOS console-service boundary"
  else if (primary ~ /BDOS-STATE-/) boundary="BDOS system/disk-state boundary"
  else if (primary ~ /BDOS-FILE-/) boundary="BDOS file/directory/storage boundary"
  else if (primary ~ /ERROR-/) boundary="Cross-layer error/recovery boundary"
  else if (primary ~ /BIOS-/) boundary="BIOS configured-platform boundary"
  else if (primary ~ /MEM-/) boundary="Transient runtime / memory boundary"
  else if (primary ~ /COMM-/) boundary="Declared communications/device profile"
  else if (primary ~ /HW-/) boundary="Declared hardware profile"
  else if (primary ~ /UTIL-/ || primary ~ /APP-/) boundary="Cross-layer ecosystem validation boundary"
  else boundary="Unresolved cross-layer ownership"

  if ($4 == "REQUIRED") rule="Preserve external observation; internal realization remains free"
  else if ($4 == "POLICY PENDING") rule="Profile/policy ownership provisional; test diagnostic until selected"
  else if ($4 == "NOT GUARANTEED") rule="Boundary must tolerate permitted variation; do not expose as promise"
  else rule="No architecture constraint from private/incidental mechanism"

  evidence=$3 "; I052 " tests
  print $1,$2,evidence,boundary,tests,$4,rule
}
