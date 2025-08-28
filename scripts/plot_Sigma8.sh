if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 

#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 

@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_Sigma8.py \
  --input @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_@BV:SAMPLER@${blinding}@BV:CHAINSUFFIX@.txt \
  --output @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/Sigma8_@BV:SAMPLER@${blinding}_@BV:STATISTIC@@BV:CHAINSUFFIX@.pdf \
  --statistic @BV:STATISTIC@ 2>&1 

