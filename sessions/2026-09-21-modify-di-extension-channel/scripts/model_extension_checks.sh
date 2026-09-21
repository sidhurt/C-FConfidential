#!/usr/bin/env bash
# Read-only batch for the three model-extension checks (QS4/700 only; every SAP call goes
# through the QS4/700-guarded scripts). Sequential: one SAP GUI automation at a time.
#  1. CFL registry: which CFD_* tables exist and what they hold for outbound delivery
#  2. How MPC_FLX resolves its custom fields (CL_CFD_ODATA* source)
#  3. Any BAdI call in the delivery API model/update path
set -u
W="C:/Users/sidmy/Downloads/shree-cement-cnf-agent-cowork-20260729T062834Z-1-001/pgi-sweep"
S="$W/sessions/2026-08-18-runtime-certification/scripts"
G="$W/sessions/2026-09-18-pgi-certification/scripts/grab.ps1"
D="$W/sessions/2026-09-21-modify-di-extension-channel"
E="$D/evidence"; SRC="$D/src"
mkdir -p "$E" "$SRC"
q() { local f="$1"; shift; ( cd "$S" && /c/Windows/System32/cscript.exe //nologo qs4_se16_read.vbs "$@" ) > "$E/$f" 2>&1; echo "== $f: $(grep -m1 '^TITLE' "$E/$f") $(grep -m1 '^SBAR' "$E/$f") $(grep -c SELFIELD_ERR "$E/$f") selfield_err"; }
includes() { grep '^ROW' "$E/$1" | cut -f1 | sed 's/^ROW[0-9]*|//' | grep -E 'CM[0-9A-Z]{3}$|CU$|CCIMP$' ; }
grab() { powershell -NoProfile -File "$G" -OutDir "$SRC" "$@" | grep -E 'MISS|EMPTY' ; }

echo "### check 1: CFL registry tables"
q C1_DD02L_CFD.txt DD02L 200 "ctxtI1-LOW=CFD*"
grep '^ROW' "$E/C1_DD02L_CFD.txt" | cut -f1,3 | sed 's/^ROW[0-9]*|//'

echo "### check 2: CFL OData runtime classes"
q C2_REPOSRC_CL_CFD_ODATA.txt REPOSRC 200 "txtI1-LOW=CL_CFD_ODATA*" "txtI2-LOW=A"
grep '^ROW' "$E/C2_REPOSRC_CL_CFD_ODATA.txt" | cut -f1 | sed 's/^ROW[0-9]*|//; s/=*C[A-Z0-9]*$//' | sort -u
grab $(includes C2_REPOSRC_CL_CFD_ODATA.txt)

echo "### check 3: API helper classes on the delivery path"
for c in CL_LE_SHP_ODATA_API_HELPER CL_SHP_API2_HELPER CL_OUTBOUND_DELIVERY_FACTORY; do
  q "C3_REPOSRC_$c.txt" REPOSRC 100 "txtI1-LOW=${c}*" "txtI2-LOW=A"
  grab $(includes "C3_REPOSRC_$c.txt")
done

echo "### search: registry reads in CFL runtime"
grep -n -iE "from +cfd_|select .*cfd_|cl_cfd_[a-z_]*registry|business_context|bus_ctxt|usage" "$SRC"/CL_CFD_ODATA*.txt 2>/dev/null | head -60
echo "### search: BAdI calls on delivery API path"
grep -n -iE "get badi|call badi|cl_exithandler|call method +[a-z_]*badi|if_ex_" "$SRC"/CL_API_OUTBOUND_DELIVE*.txt "$SRC"/CL_SHP_API2*.txt "$SRC"/CL_LE_SHP_ODATA*.txt "$SRC"/CL_OUTBOUND_DELIVERY*.txt 2>/dev/null | head -60
echo "### done"
