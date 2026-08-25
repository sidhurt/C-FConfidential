#!/bin/bash
# show.sh <Service> <EntityType> [grep-filter]
awk -F'\t' -v svc="$1" -v et="$2" 'NR>1{
  for(i=1;i<=NF;i++) gsub(/"/,"",$i)
  if($1==svc && $3==et)
    printf "%-40s %-14s key=%-2s null=%-6s creat=%-6s updat=%-6s filt=%-6s reqf=%-6s unit=%-8s | %s\n",$4,$5,$10,$6,$11,$12,$14,$15,$16,$17
}' RUNTIME_PROPERTY_INDEX.tsv
