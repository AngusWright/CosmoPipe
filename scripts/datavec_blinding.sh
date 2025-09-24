#=========================================
#
# File Name : datavec_blinding.sh
# Created By : dvornik
# Creation Date : 30-07-2024
# Last Modified : Tue 30 Jul 2024 10:06:57 PM CEST
#
#=========================================

#Run blinding for a constructed ini file and input cosmosis fits file

BOLTZMAN="@BV:BOLTZMAN@"
STATISTIC="@BV:STATISTIC@"

if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ]
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

if [ "${STATISTIC^^}" == "COSEBIS" ]
then
  mode="co"
fi
if [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
  mode="bp"
fi
if [ "${STATISTIC^^}" == "2PCF" ]
then
  mode="xi"
fi

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 @PYTHON3BIN@ -m blind_2pt_cosmosis \
    -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini \
    -u @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}.sacc \
    -b -r \
    -m ${mode} \
    --sacc \
    --key_path @BV:KEYPATH@ \
    --file_path @BV:BLINDFILE@ 2>&1

mbias=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/`
if [[ ${mbias} =~ .*"no_m_bias".* ]]
then
  eval "search_string='@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}.sacc'"
  eval "replace_string='@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}_no_m_bias.sacc'"
  sed "s|${search_string}|${replace_string}|g" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini" > "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@_no_m_bias.ini"

  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 @PYTHON3BIN@ -m blind_2pt_cosmosis \
    -i @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@_no_m_bias.ini \
    -u @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}_no_m_bias.sacc \
    -b -r \
    -m ${mode} \
    --sacc \
    --key_path @BV:KEYPATH@ \
    --file_path @BV:BLINDFILE@ 2>&1
fi

# Remove the block entries, but not the datablock data as the _delete_blockitem function does
grep -v "^mcmc_inp_@BV:STATISTIC@=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt | \
  awk '{ print $0 }' \
  > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt

inputlist=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/`
#This just makes sure that the files are added correctly
for file in ${inputlist}
do
  _message "${file}\n"
  if [[ ! "${file}" =~ "MCMC_input_${non_linear_model}.sacc" ]] && [[ ! "${file}" =~ "MCMC_input_${non_linear_model}_no_m_bias.sacc" ]]
  then
    _message "Adding to datablock\n"
    # Add blinds to datablock
    blinded_block=`_read_datablock mcmc_inp_@BV:STATISTIC@`
    _write_datablock "mcmc_inp_@BV:STATISTIC@" "`_blockentry_to_filelist ${blinded_block}` ${file}"
  fi
done

# Remove all the previous statistic files / datavectors / everything after treecorr runs
datablock_names="`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/`"
to_delete="gt wt xipm cosebis bandpowers psi_stats" # Add more if we figure out that is needed
for name in ${datablock_names}
do
  for del in ${to_delete}
  do
    if [[ "${name}" =~ ^"${del}".* ]]
    then
      #_message "Trying to delete ${name}\n"
      name=`_parse_blockvars ${name}`
      _delete_blockitem "${name}"
    fi
  done
  if [[ "smf" =~ "${name}" ]]
  then
    _message "Trying to delete ${name}\n"
    #name=`_parse_blockvars ${name}`
    #_delete_blockitem "${name}"
  fi
done

