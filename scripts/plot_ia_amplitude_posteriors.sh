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

central_value () {
  n=`echo $1 | awk '{print NF}'`
  if [ $n == 1 ]
  then
    value=`echo $1`
  elif [ $n == 3 ]
  then
    value=`echo $1 | awk '{print $2}'`
  fi
  echo $value
}
# Uncorrelated massdep priors (deprecated)
# PRIOR_LOG10_M_MEAN_1=`central_value "@BV:PRIOR_LOG10_M_MEAN_1@"`
# PRIOR_LOG10_M_MEAN_2=`central_value "@BV:PRIOR_LOG10_M_MEAN_2@"`
# PRIOR_LOG10_M_MEAN_3=`central_value "@BV:PRIOR_LOG10_M_MEAN_3@"`
# PRIOR_LOG10_M_MEAN_4=`central_value "@BV:PRIOR_LOG10_M_MEAN_4@"`
# PRIOR_LOG10_M_MEAN_5=`central_value "@BV:PRIOR_LOG10_M_MEAN_5@"`
# PRIOR_LOG10_M_MEAN_6=`central_value "@BV:PRIOR_LOG10_M_MEAN_6@"`

# f_r=""
# logM=""
# for i in `seq $NTOMO`
# do
#   f_r_centre=`central_value "@BV:PRIOR_F_R_${i}@"`
#   logM_centre=`central_value "@BV:PRIOR_LOG10_M_MEAN_${i}@"`
#   f_r="${f_r} ${f_r_centre}"
#   logM="${logM} ${logM_centre}"
# done

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'` 
f_r="@BV:PRIOR_F_R_1@ @BV:PRIOR_F_R_2@ @BV:PRIOR_F_R_3@ @BV:PRIOR_F_R_4@ @BV:PRIOR_F_R_5@ @BV:PRIOR_F_R_6@"
logM="${PRIOR_LOG10_M_MEAN_1} ${PRIOR_LOG10_M_MEAN_2} ${PRIOR_LOG10_M_MEAN_3} ${PRIOR_LOG10_M_MEAN_4} ${PRIOR_LOG10_M_MEAN_5} ${PRIOR_LOG10_M_MEAN_6}"

# Uncorrelated massdep priors (deprecated)
# @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_ia_amplitude_posteriors.py \
#   --inputbase @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_@BV:SAMPLER@${blinding} \
#   --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/ \
#   --f_r ${f_r} \
#   --logM ${logM} \
#   --logM_pivot @BV:PRIOR_LOG10_M_PIV@ \
#   --a_pivot_zdep @BV:PRIOR_A_PIV@ \
#   --weighted True

#@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/plot_ia_amplitude_posteriors_correlated.py \
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_ia_amplitude_posteriors_correlated.R \
  --inputbase @STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_@BV:SAMPLER@${blinding} \
  --output_dir @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/ \
  --f_r ${f_r} \
  --massdep_cov @BV:MASSDEP_COVARIANCE@ \
  --logM_pivot @BV:PRIOR_LOG10_M_PIV@ \
  --a_pivot_zdep @BV:PRIOR_A_PIV@ \
  --weighted True




