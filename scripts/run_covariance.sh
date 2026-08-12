#=========================================
#
# File Name : run_chain.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Wed 06 Dec 2023 11:29:39 AM CET
#
#=========================================

#Create the covariance output directory
SECONDSTATISTIC="@BV:SECONDSTATISTIC@"
if [ "${SECONDSTATISTIC^^}" == "XIPM" ] || [ "${SECONDSTATISTIC^^}" == "2PCF" ] || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ] || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
then
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@_@BV:SECONDSTATISTIC@ ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@_@BV:SECONDSTATISTIC@/
  fi 
else
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@ ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@/
  fi 
fi
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi

#Run cosmosis for a constructed ini file 
_message " >@BLU@ Running covariance!\n   Start time:@DEF@ `date +'%a %H:%M'`@BLU@)\n@DEF@"
_message " >@BLU@ Status can be monitored in the logfile located here:\n@RED@ `ls -tr @RUNROOT@/@LOGPATH@/step_*_run_covariance.log | tail -n 1` @DEF@\n"
MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 @PYTHON3BIN@ @RUNROOT@/INSTALL/OneCovariance/covariance.py @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@BV:STATISTIC@_@SURVEY@_CosmoPipe_constructed.ini 2>&1 
_message " >@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"

if [ "${SECONDSTATISTIC^^}" == "XIPM" ] || [ "${SECONDSTATISTIC^^}" == "2PCF" ] || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ] || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
then
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@_@BV:SECONDSTATISTIC@/covariance_matrix_${non_linear_model}_reduced.mat ]
  then
    _write_datablock "covariance_@BV:STATISTIC@_@BV:SECONDSTATISTIC@" "covariance_matrix_${non_linear_model}_reduced.mat"
  else
    _write_datablock "covariance_@BV:STATISTIC@_@BV:SECONDSTATISTIC@" "covariance_matrix_${non_linear_model}.mat"
  fi
else
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@/covariance_matrix_${non_linear_model}_reduced.mat ]
  then
    _write_datablock "covariance_@BV:STATISTIC@" "covariance_matrix_${non_linear_model}_reduced.mat"
  else
    _write_datablock "covariance_@BV:STATISTIC@" "covariance_matrix_${non_linear_model}.mat"
  fi
fi

#Clean up the temporary input folder
if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters ]
then 
  rm -r @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
fi 
