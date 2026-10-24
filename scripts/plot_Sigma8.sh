plotting_python="@RUNROOT@/INSTALL/plotting-env/bin/python"
if [ ! -x "${plotting_python}" ]
then
  echo "ERROR: Missing plotting environment at @RUNROOT@/INSTALL/plotting-env. See the README installation instructions." >&2
  exit 1
fi

if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 

plot_dir="@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots"
mkdir -p "${plot_dir}"

"${plotting_python}" "@RUNROOT@/@SCRIPTPATH@/plot_Sigma8.py" \
  --inputfile "@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_@BV:SAMPLER@${blinding}@BV:CHAINSUFFIX@.txt" \
  --outputfile "${plot_dir}/Sigma8_@BV:SAMPLER@${blinding}_@BV:STATISTIC@@BV:CHAINSUFFIX@.pdf" \
  --statistic "@BV:STATISTIC@" 2>&1
