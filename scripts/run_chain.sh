#=========================================
#
# File Name : run_chain.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Wed Feb 26 22:51:15 2025
#
#=========================================

#Run cosmosis for a constructed ini file 
ppython=@PYTHON3BIN@
pythonbin=${ppython%/*}

STATISTIC="@BV:STATISTIC@"
if [ "${STATISTIC^^}" == "COSEBIS" ] 
then
  # check whether the pre-computed COSEBIS tables exist 
  SRCLOC=@RUNROOT@/@CONFIGPATH@/cosebis
  normfile=${SRCLOC}/TLogsRootsAndNorms/Normalization_@BV:THETAMINXI@-@BV:THETAMAXXI@.table
  rootfile=${SRCLOC}/TLogsRootsAndNorms/Root_@BV:THETAMINXI@-@BV:THETAMAXXI@.table

  if [ ! -f ${normfile} ] || [ ! -f ${rootfile} ]
  then 
    if [ "@BINNING@" == "log" ] 
    then 
      _message "    -> @BLU@Computing COSEBIs root and norm files@DEF@"
      @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/cosebis_compute_log_weight.py \
        --thetamin @BV:THETAMINXI@ \
        --thetamax @BV:THETAMAXXI@ \
        --nmax @BV:NMAXCOSEBIS@ \
        --outputbase ${SRCLOC}/TLogsRootsAndNorms/ 2>&1
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    else 
      _message "- ERROR!\n"
      _message "COSEBIS pre-computed table ${normfile} or ${rootfile} is missing, and pipeline cannot compute them for linear binning. Download from gitrepo!\n"
      exit 1
    fi 
  fi
  # check whether the precomputed WnLog files exist
  nfiles=@BV:NMAXCOSEBIS@
  basefile="${SRCLOC}/WnLog/WnLogBIN-@BV:THETAMINXI@-@BV:THETAMAXXI@.table"
  for i in $(seq -f "%01g" 1 $nfiles)
  do
    file=`echo ${basefile} | sed "s/BIN/${i}/g"`
    if [ ! -f ${file} ]
    then
      _message "Pre-computed WnLog file ${file} is missing! Calculating on the fly!\n"
    fi
  done
fi

_message " >@BLU@ Running cosmosis chain!\n   Start time:@DEF@ `date +'%a %H:%M'`@BLU@)\n@DEF@"
_message " >@BLU@ Status can be monitored in the logfile located here:\n@RED@ `ls -tr @RUNROOT@/@LOGPATH@/step_*_run_chain.log | tail -n 1` @DEF@\n"
if [ @BV:NTHREADS@ -eq 1 ] || [ "@BV:SAMPLER@" == "test" ] || [ "@BV:SAMPLER@" == "maxlike" ]
then
MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 ${pythonbin}/cosmosis @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini 2>&1
else
objstr=''
# Run mpi chain
{
mpirun -n @BV:NTHREADS@ -x MKL_NUM_THREADS=1 -x NUMEXPR_NUM_THREADS=1 -x OMP_NUM_THREADS=1 ${pythonbin}/cosmosis --mpi @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini 2>&1 && echo "MPI command worked!" || objstr="FAIL"
} >&1
# Run mpi chain with --use-hwthread-cpu option (required for openmpi>4.0.3)
if [ "${objstr}" == "FAIL" ]
then
  _message "MPI chain failed. Trying with --use-hwthread-cpu option (required for openmpi>4.0.3)\n" 
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 mpirun --use-hwthread-cpus -n @BV:NTHREADS@ ${pythonbin}/cosmosis --mpi @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini 2>&1
  #MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 ${pythonbin}/cosmosis --smp @BV:NTHREADS@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini 2>&1
fi
fi
_message " >@RED@ Chain finished! (`date +'%a %H:%M'`)@DEF@\n"
