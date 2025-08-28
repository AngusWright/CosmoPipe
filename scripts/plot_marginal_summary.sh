#=========================================
#
# File Name : plot_Om_S8.sh
# Created By : awright
# Creation Date : 04-05-2023
# Last Modified : Mon Jul 21 19:48:18 2025
#
#=========================================
if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 


#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/summary/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/summary/plots/
fi 

labels=''
for stat in @BV:SUMMARY_STATISTICS@ 
do 
  if [ -f @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/${stat}/chain/output_@BV:SAMPLER@${blinding}@BV:CHAINSUFFIX@.txt ]
  then 
    filelist="${filelist} @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/${stat}/chain/output_@BV:SAMPLER@${blinding}@BV:CHAINSUFFIX@.txt"
    case $stat in 
      'cosebis') labels="$labels 'COSEBIs '*(italic(E)[italic(n)]);" ;;
      'bandpowers') labels="$labels 'Bandpowers '*(italic(C)[E]);" ;;
      'xipm') labels="$labels xi[''%+-%''];" ;;
    esac 

  else 
    filelist="${filelist} NONE"
  fi 
done 

ialim="-3 3"
ialabel='"IA amplitude"'
if [ "@BV:IAMODEL@" == "massdep" ]
then 
  ialim="4.5 7"
  ialabel='"Red Galaxy IA amplitude"'
fi 

#Plot the chain 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_Om_S8.R \
  --input ${filelist} \
  --refr @BV:PLANCKCHAIN@ \
  --prior @BV:PRIORCHAIN@  \
  --prior_white \
  --output @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/summary/plots/Om_S8_@BV:SAMPLER@${blinding}_summary@BV:CHAINSUFFIX@.pdf \
  --sampler @BV:SAMPLER@ \
  --labels "${labels}" \
  --ylim 0.65 0.9 \
  --xlim 0.15 0.55 \
  --title " " 2>&1 || echo "ignore failed plot generation" 

#Plot the chain 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_Om_S8.R \
  --input ${filelist} \
  --refr @BV:PLANCKCHAIN@ \
  --prior @BV:PRIORCHAIN@ \
  --prior_white \
  --output @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/summary/plots/sigma8_Om_@BV:SAMPLER@${blinding}_summary@BV:CHAINSUFFIX@.pdf \
  --sampler @BV:SAMPLER@ \
  --ylabel "SIGMA_8" \
  --ytitle "sigma[8]" \
  --ylim 0.45 1.2 \
  --xlim 0.14 0.62 \
  --hval 0.0085 0.0085 \
  --minbuff 0.15 \
  --priorh 0.01 0.01 \
  --title " " 2>&1 || echo "ignore failed plot generation" 

#Plot the chain 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_Om_S8.R \
  --input ${filelist} \
  --refr NONE \
  --prior @BV:PRIORCHAIN@ \
  --prior_white \
  --output @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/summary/plots/Sigma8_IA_@BV:SAMPLER@${blinding}_summary@BV:CHAINSUFFIX@.pdf \
  --sampler @BV:SAMPLER@ \
  --ylabel "SIGMA_8*(OMEGA_M/0.3)^0.58" \
  --ytitle "Sigma[8]*'='*sigma[8]*(Omega[m]/0.3)^0.58" \
  --ylim 0.65 0.9 \
  --xlabel ia_A --xtitle "${ialabel}" --xlim ${ialim} \
  --title " " 2>&1 || echo "ignore failed plot generation" 


