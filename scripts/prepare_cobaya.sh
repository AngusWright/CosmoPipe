#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Thu 07 Sep 2023 05:56:22 PM UTC
#
#=========================================

#For each of the files in the nz directory 
inputs="@DB:nz@"
headfiles="@DB:ALLHEAD@"


COBAYA_THEORY_CODE="@BV:COBAYATHEORYCODE@"
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${COBAYA_THEORY_CODE}" == "cobaya" ]
then
  if [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
  then
    HALOFIT_VERSION="--halofit_version=mead"
  elif [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
  then
    HALOFIT_VERSION="--halofit_version=mead2020_feedback"
  else
    _message "@RED@ ERROR - Boltzmann option @DEF@${BOLTZMAN^^}@RED@ not supported by cobaya\n"
    exit 1 
  fi
fi


COBAYA_SAMPLER=@BV:COBAYASAMPLER@
if [ "${COBAYA_SAMPLER}" == "mcmc" ]
then
  COBAYA_SAMPLER_COVMAT="--sampler.mcmc.covmat @BV:COBAYASAMPLERCOVMAT@"
else
  COBAYA_SAMPLER_COVMAT=""
fi

#Generate the .yaml file: 
YAML_FILE_NAME="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cobaya_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@_cobaya_@BV:COBAYASAMPLER@_@BV:COBAYATHEORYCODE@_theory.yaml"

COSMOSIS_PIPELINE_FILE="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini"

OUTPUT_FOLDER="@RUNROOT@/@STORAGEPATH@/MCMC/output_cobaya/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/@BV:COBAYASAMPLER@_@BV:COBAYATHEORYCODE@_theory/"

#TODO? Read cosmosis file path from somewhere
#Run the cobaya preparation script {{{
_message " > @BLU@Constructing the cobaya configuration for @RED@${COSMOSIS_PIPELINE_FILE}@DEF@"
@PYTHON3BIN@ -m cosmosis_cobaya_interface.prepare_config \
  --pipeline-file ${COSMOSIS_PIPELINE_FILE} \
  --boltzmann-code ${COBAYA_THEORY_CODE} \
  ${HALOFIT_VERSION} --sampler ${COBAYA_SAMPLER} ${COBAYA_SAMPLER_COVMAT} \
  --output-yaml-file ${YAML_FILE_NAME} \
  --cobaya-output-path ${OUTPUT_FOLDER} 2>&1 
_message " - @RED@Done!@DEF@\n"
#}}}