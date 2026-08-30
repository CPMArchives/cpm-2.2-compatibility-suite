BEGIN { FS=OFS="\t" }
NR == 1 { next }
{
  count[$1]++
  title[$1]=$2
  disposition[$1 SUBSEP $4]=1
  if ($4 == "POLICY PENDING") policy[++pc]=$0
}
END {
  print "entry","occurrences","title","dispositions" > dupfile
  for (id in count) if (count[id] > 1) {
    d=""
    for (k in disposition) {
      split(k,a,SUBSEP)
      if (a[1] == id) d=d (d?",":"") a[2]
    }
    print id,count[id],title[id],d > dupfile
  }
  print "entry","title","source_section","disposition","conformance","validation_class","primary_tests" > policyfile
  for (i=1;i<=pc;i++) print policy[i] > policyfile
}
