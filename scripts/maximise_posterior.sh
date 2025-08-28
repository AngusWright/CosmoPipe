ppython=@PYTHON3BIN@
pythonbin=${ppython%/*}

if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 

_message " >@BLU@ Running posterior maximisation!\n   Start time:@DEF@ `date +'%a %H:%M'`@BLU@)\n@DEF@"
_message " >@BLU@ Status can be monitored in the logfile located here:\n@RED@ `ls -tr @RUNROOT@/@LOGPATH@/step_*_maximise_posterior.log | tail -n 1` @DEF@\n"

# Create output directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/
fi
#Create the nz folder inside the covariance_inputs directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz/
fi 

BOLTZMAN="@BV:BOLTZMAN@"
#Define the data file name {{{ 
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
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

outputdir=@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/
inifile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini

ITERATION=@BV:ITERATION@
NMOCKS=@BV:NMOCKS@
N=@BV:NTHREADS@

CHAINSUFFIX=@BV:CHAINSUFFIX@

if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
then
  previous=`echo "$ITERATION" | awk '{printf "%d", $1-1}'`
  data_file_iterative=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${CHAINSUFFIX}_iteration_$ITERATION.fits
  inputchain=@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/bestfit${CHAINSUFFIX}_chain_iteration_${previous}.txt
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=@BV:NTHREADS@ @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/maximise_posterior.py \
    --inputchain ${inputchain} \
    --inifile ${inifile} \
    --iteration ${ITERATION} \
    --data_file_iterative ${data_file_iterative} \
    --outputdir ${outputdir} \
    --nzfile @DB:cosmosis_nz@ \
    --nzcovariance @DB:nzcov@ \
    --chainsuffix @BV:CHAINSUFFIX@ \
    --nzoutput @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz 2>&1
elif [ -n "$NMOCKS" ] && [ "$NMOCKS" -eq "$NMOCKS" ]
then
  if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/mock ]
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/mock/
  fi
  for ((i=1; i <= @BV:NMOCKS@; i++)); do
  ( 
  data_file_mock=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:STATISTIC@_mocks/mock${i}.fits
  outfile_root=@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/mock/${i}
  
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 ${pythonbin}/cosmosis @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini -p DEFAULT.data_file=${data_file_mock} output.filename=${outfile_root}/output_@BV:SAMPLER@${blinding}.txt multinest.tolerance=0.2 multinest.live_points=90 multinest.efficiency=1.0 multinest.multinest_outfile_root=${outfile_root}/@BV:SAMPLER@${blinding}_ 2>&1
  inputchain=${outfile_root}/output_@BV:SAMPLER@${blinding}.txt
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/maximise_posterior.py \
    --inputchain ${inputchain} \
    --inifile ${inifile} \
    --mock ${i} \
    --data_file_mock ${data_file_mock} \
    --chainsuffix @BV:CHAINSUFFIX@ \
    --outputdir ${outputdir} 2>&1
  ) &
    # allow to execute up to $N jobs in parallel
    if [[ $(jobs -r -p | wc -l) -ge $N ]]; then
        # now there are $N jobs already running, so wait here for any job
        # to be finished so there is a place to start next one.
        wait -n
    fi
  done
else
  inputchain=@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_@BV:SAMPLER@${blinding}${CHAINSUFFIX}.txt
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=@BV:NTHREADS@ @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/maximise_posterior.py \
    --inputchain ${inputchain} \
    --inifile ${inifile} \
    --outputdir ${outputdir} \
    --nzfile @DB:cosmosis_nz@ \
    --nzcovariance @DB:nzcov@ \
    --chainsuffix @BV:CHAINSUFFIX@ \
    --nzoutput @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz 2>&1
fi

_message " >@RED@ Maximisation finished! (`date +'%a %H:%M'`)@DEF@\n"
