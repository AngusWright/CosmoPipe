#=========================================
#
# File Name : save_and_check_mcmc_inp.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Tue 28 Jan 2025 12:32:14 AM CET
#
#=========================================

#Statistic
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020_NOFEEDBACK" ]
then
  non_linear_model=mead2020
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi
CHAINSUFFIX=@BV:CHAINSUFFIX@
#Input data vector
STATISTIC="@BV:STATISTIC@"
ITERATION=@BV:ITERATION@
input_covariance_iterative=
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  input_datavector="@DB:cosebis_vec@"
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi 
#}}}
elif [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ] #{{{
then
  input_datavector="@DB:cosebis_dimless_vec@"
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis_dimless/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_cosebis_dimless/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi 
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  input_datavector="@DB:bandpowers_vec@"
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_bandpowers/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_bandpowers/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi 
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then
  input_datavector="@DB:xipm_vec@"
  input_covariance="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xipm/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xipm/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi
elif [ "${STATISTIC^^}" == "XIEB" ] #{{{
then 
  input_datavector_E="@DB:xiE_vec@"
  input_covariance_E="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiE/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative_E=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiE/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi
  input_datavector_B="@DB:xiB_vec@"
  input_covariance_B="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiB/covariance_matrix_${non_linear_model}.mat"
  if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
  then
    filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
    input_covariance_iterative_B=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiB/covariance_matrix_${non_linear_model}${filename_extension}.mat
  fi
fi
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020_NOFEEDBACK" ]
then
  non_linear_model=mead2020_feedback
fi
#If needed, create the output directory {{{
if [ "${STATISTIC^^}" == "XIEB" ] #{{{
then 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiE ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiE/
fi
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiB ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiB/
fi
else
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@ ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/
fi
fi
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 
#}}}

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

if [ "${STATISTIC^^}" != "XIEB" ] 
then 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats.py \
  --datavector ${input_datavector} \
  --statistic @BV:STATISTIC@ \
  --nz @DB:nz@ \
  --nmaxcosebis @BV:NMAXCOSEBIS@ \
  --nbandpowers @BV:NBANDPOWERS@ \
  --nxipm @BV:NXIPM@ \
  --ellmin @BV:LMINBANDPOWERS@ \
  --ellmax @BV:LMAXBANDPOWERS@ \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --ntomo ${NTOMO} \
  --neff @DB:cosmosis_neff@ \
  --sigmae @DB:cosmosis_sigmae@ \
  --covariance ${input_covariance} \
  --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model} \
  --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

if [ ! -z "$input_covariance_iterative" ]
then
  if [ -f "$input_covariance_iterative" ] 
  then 
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats.py \
    --datavector ${input_datavector} \
    --statistic @BV:STATISTIC@ \
    --nz @DB:nz@ \
    --nmaxcosebis @BV:NMAXCOSEBIS@ \
    --nbandpowers @BV:NBANDPOWERS@ \
    --nxipm @BV:NXIPM@ \
    --ellmin @BV:LMINBANDPOWERS@ \
    --ellmax @BV:LMAXBANDPOWERS@ \
    --thetamin @BV:THETAMINXI@ \
    --thetamax @BV:THETAMAXXI@ \
    --ntomo ${NTOMO} \
    --neff @DB:cosmosis_neff@ \
    --sigmae @DB:cosmosis_sigmae@ \
    --covariance ${input_covariance_iterative} \
    --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${filename_extension} \
    --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
  else 
    cp -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model} \
    @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${filename_extension}.fits 
  fi 
fi
_write_datablock "mcmc_inp_@BV:STATISTIC@" "MCMC_input_${non_linear_model}.fits"

else
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats.py \
      --datavector ${input_datavector_E} \
      --statistic @BV:STATISTIC@ \
      --nz @DB:nz@ \
      --nmaxcosebis @BV:NMAXCOSEBIS@ \
      --nbandpowers @BV:NBANDPOWERS@ \
      --nxipm @BV:NXIPM@ \
      --ellmin @BV:LMINBANDPOWERS@ \
      --ellmax @BV:LMAXBANDPOWERS@ \
      --thetamin @BV:THETAMINXI@ \
      --thetamax @BV:THETAMAXXI@ \
      --ntomo ${NTOMO} \
      --neff @DB:cosmosis_neff@ \
      --sigmae @DB:cosmosis_sigmae@ \
      --covariance ${input_covariance_E} \
      --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiE/MCMC_input_${non_linear_model} \
      --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/save_and_check_mcmc_inp_allstats.py \
    --datavector ${input_datavector_B} \
    --statistic @BV:STATISTIC@ \
    --nz @DB:nz@ \
    --nmaxcosebis @BV:NMAXCOSEBIS@ \
    --nbandpowers @BV:NBANDPOWERS@ \
    --nxipm @BV:NXIPM@ \
    --ellmin @BV:LMINBANDPOWERS@ \
    --ellmax @BV:LMAXBANDPOWERS@ \
    --thetamin @BV:THETAMINXI@ \
    --thetamax @BV:THETAMAXXI@ \
    --ntomo ${NTOMO} \
    --neff @DB:cosmosis_neff@ \
    --sigmae @DB:cosmosis_sigmae@ \
    --covariance ${input_covariance_B} \
    --outputfile @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_xiB/MCMC_input_${non_linear_model} \
    --plotdir @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/

  _write_datablock "mcmc_inp_xiE" "MCMC_input_${non_linear_model}.fits"
  _write_datablock "mcmc_inp_xiB" "MCMC_input_${non_linear_model}.fits"
fi

