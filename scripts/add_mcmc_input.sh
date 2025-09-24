#=========================================
#
# File Name : add_mcmc_input.sh
# Created By : stoelzner
# Creation Date : 30-03-2023
# Last Modified : Tue 07 Jan 2025 12:24:13 PM CET
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/
fi 

#Statistic
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ]  || [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi

file="@BV:MCMCINPUTFILE@"
filename="MCMC_input_${non_linear_model}.fits"

#Create the uncertainty file 
cp $file @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/${filename}

#Update the datablock contents file 
_write_datablock "mcmc_inp_@BV:STATISTIC@" "${filename}"

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov
fi 

#Create the uncertainty file 
cp @BV:NZCOVFILE@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov/nz_covariance.txt 

#Update the datablock contents file 
_write_datablock nzcov "nz_covariance.txt"
