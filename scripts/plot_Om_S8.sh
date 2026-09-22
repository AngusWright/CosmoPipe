#=========================================
#
# File Name : plot_Om_S8.sh
# Created By : awright
# Creation Date : 04-05-2023
# Last Modified : Mon Jul 21 19:47:48 2025
#
#=========================================

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

#Plot the chain 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_Om_S8.R \
  --input @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_@BV:SAMPLER@${blinding}@BV:CHAINSUFFIX@.txt \
  --refr @BV:REFCHAIN@ \
  --prior @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_apriori${blinding}@BV:CHAINSUFFIX@.txt \
  --output @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/Om_S8_@BV:SAMPLER@${blinding}_@BV:STATISTIC@@BV:CHAINSUFFIX@.png \
  --sampler @BV:SAMPLER@ \
  --title "@BV:SAMPLER@, Blind @BV:BLIND@, @BV:BOLTZMAN@" 2>&1 || echo "ignore failed plot generation" 

#Plot the chain 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_Om_S8.R \
  --input @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_@BV:SAMPLER@${blinding}@BV:CHAINSUFFIX@.txt \
  --refr @BV:REFCHAIN@ \
  --prior @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_apriori${blinding}@BV:CHAINSUFFIX@.txt \
  --output @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/S8_IA_@BV:SAMPLER@${blinding}@BV:CHAINSUFFIX@.png \
  --sampler @BV:SAMPLER@ \
  --xlabel IA_a --xtitle "'IA amplitude'" --xlim -3 3 \
  --title "@BV:SAMPLER@, Blind @BV:BLIND@, @BV:BOLTZMAN@" 2>&1 || echo "ignore failed plot generation" 


