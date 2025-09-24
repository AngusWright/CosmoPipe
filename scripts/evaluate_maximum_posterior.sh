BOLTZMAN="@BV:BOLTZMAN@"
#Define the data file name {{{ 
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] 
then
  _message "The ${BOLTZMAN^^} Emulator is broken: it produces S_8 constraints that are systematically high.\nUse 'COSMOPOWER_HM2015_S8'\n"
  exit 1
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi
ITERATION=@BV:ITERATION@
CHAINSUFFIX=@BV:CHAINSUFFIX@
previous=`echo "$ITERATION" | awk '{printf "%d", $1-1}'`
inputchain=@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/bestfit${CHAINSUFFIX}_chain_iteration_${previous}.txt
outputdir=@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/
inifile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini
data_file_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${CHAINSUFFIX}_iteration_${ITERATION}.fits

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/evaluate_maximum_posterior.py \
  --inputchain ${inputchain} \
  --inifile ${inifile} \
  --iteration ${ITERATION} \
  --data_file_iterative ${data_file_iterative} \
  --chainsuffix @BV:CHAINSUFFIX@ \
  --outputdir ${outputdir} 2>&1


