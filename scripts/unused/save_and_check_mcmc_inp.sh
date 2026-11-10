#=========================================
#
# File Name : save_and_check_mcmc_inp.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Tue 07 Nov 2023 08:06:55 PM CET
#
#=========================================

#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/
fi 
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 

BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi

#Covar name
cov="@DB:covariance_cosebis@"
cov=${cov##*/}
cov=${cov//.ascii/.fits}

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp.py \
  --datavector @DB:cosebis_vec@ \
  --nz @DB:nz@ \
  --nmaxcosebis @BV:NMAXCOSEBIS@ \
  --ntomo ${NTOMO} \
  --neff @DB:cosmosis_neff@ \
  --sigmae @DB:cosmosis_sigmae@ \
  --covariance @DB:covariance_cosebis@ \
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}.fits \
  --plotfolder @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

_write_datablock "mcmc_inp_@BV:STATISTIC@" "MCMC_input_${non_linear_model}.fits"

