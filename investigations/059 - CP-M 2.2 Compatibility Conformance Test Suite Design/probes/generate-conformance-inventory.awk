BEGIN { FS=OFS="\t" }
FNR == NR {
  if (FNR == 1) next
  split($7, tests, ",")
  for (i in tests) seen[tests[i],$4]=1
  next
}
FNR == 1 {
  print "test_id","compatibility_requirement","evidence_source","procedure","expected_observation","classification","conformance_treatment","phase","dependencies","validation_mode","evidence_required"
  next
}
{
  id=$1
  classes=""
  treatment=""
  if (seen[id,"REQUIRED"]) { classes="REQUIRED"; treatment="positive criteria" }
  if (seen[id,"POLICY PENDING"]) { classes=classes (classes?",":"") "POLICY PENDING"; treatment=treatment (treatment?"; ":"") "profile-gated diagnostic/positive when selected" }
  if (seen[id,"NOT GUARANTEED"]) { classes=classes (classes?",":"") "NOT GUARANTEED"; treatment=treatment (treatment?"; ":"") "accept permitted variation/non-assertion" }
  if (seen[id,"NOT REQUIRED"]) { classes=classes (classes?",":"") "NOT REQUIRED"; treatment=treatment (treatment?"; ":"") "anti-requirement; do not inspect private mechanism" }
  if (classes == "" && (id ~ /^BDOS-FILE-/ || id ~ /^UTIL-/ || id ~ /^APP-/)) {
    classes="REQUIRED"
    treatment="supplemental positive ecosystem/interface acceptance"
  } else if (classes == "") {
    classes="POLICY PENDING"
    treatment="supplemental named-profile acceptance; not a baseline gate unless selected"
  }

  if (id ~ /^MEM-001$/ || id ~ /^BIOS-001$/ || id ~ /^BDOS-CALL-001$/) { phase="1-foundation"; deps="profile manifest; restored fixture" }
  else if (id ~ /^MEM-/ || id ~ /^BIOS-/ || id ~ /^BDOS-CON-/ || id ~ /^BDOS-STATE-/) { phase="2-interface"; deps="MEM-001; BIOS-001 as applicable" }
  else if (id ~ /^BDOS-FILE-/) { phase="3-storage"; deps="BDOS-CALL-001; BDOS-STATE-003; BIOS-004/006 as applicable" }
  else if (id ~ /^ERROR-/) { phase="4-failure"; deps="healthy corresponding interface/storage test; restored fault fixture" }
  else if (id ~ /^CCP-/) { phase="4-command"; deps="MEM-001; BDOS public/file/console prerequisites used by case" }
  else { phase="5-ecosystem-profile"; deps="all narrow tests for mapped ledger areas; named software/profile fixture" }

  evidence="raw observation; exact fixture/profile; executable/source hash; before/after state where mutable"
  print id,$3,$6,$4,$5,classes,treatment,phase,deps,$7,evidence
}
