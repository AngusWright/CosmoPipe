#=========================================
#
# File Name : make_data_vector_allstats.sh
# Created By : stoelzner
# Creation Date : 01-04-2023
# Last Modified : Thu 29 Feb 2024 10:00:52 PM CET
#
#=========================================

#Statistic
STATISTIC="@BV:STATISTIC@"
MODES="@BV:MODES@"
#Input data vectors
inputs=""
stat_out=""
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
	inputs="${inputs} @DB:cosebis@"
	stat_out="${stat_out} cosebis"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
	inputs="${inputs} @DB:psi_stats_gm@"
	stat_out="${stat_out} psi_stats_gm"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
	inputs="${inputs} @DB:psi_stats_gg@"
	stat_out="${stat_out} psi_stats_gg"
  fi
#}}}
elif [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
	inputs="${inputs} @DB:cosebis_dimless@"
	stat_out="${stat_out} cosebis_dimless"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
	_message "NE mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
	_message "NN mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
	inputs="${inputs} @DB:bandpowers_ee@"
	stat_out="${stat_out} bandpowers_ee"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
	inputs="${inputs} @DB:bandpowers_ne@"
	stat_out="${stat_out} bandpowers_ne"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
	inputs="${inputs} @DB:bandpowers_nn@"
	stat_out="${stat_out} bandpowers_nn"
  fi
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
	inputs="${inputs} @DB:xipm_binned@"
	stat_out="${stat_out} xipm"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
	_message "NE mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
	_message "NN mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
#}}}
elif [ "${STATISTIC^^}" == "XIPSF" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
	inputs="${inputs} @DB:xipsf_binned@"
	stat_out="${stat_out} xipsf"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
	_message "NE mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
	_message "NN mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
#}}}
elif [ "${STATISTIC^^}" == "XIGPSF" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
	inputs="${inputs} @DB:xigpsf_binned@"
	stat_out="${stat_out} xigpsf"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
	_message "NE mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
	_message "NN mode not implemented for ${STATISTIC}, pipeline might break down the line!"
  fi
#}}}
elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
	inputs="${inputs} @DB:xipm_binned@"
	stat_out="${stat_out} xipm"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
	inputs="${inputs} @DB:gt_binned@"
	stat_out="${stat_out} gt"
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
	inputs="${inputs} @DB:wt_binned@"
	stat_out="${stat_out} wt"
  fi
#}}}
fi

#Input mbias files
mfiles="@DB:mbias@"
for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do
  for stat in ${stat_out}
  do
    #Remove the 'comb' if needed
    patchuse=${patch%comb}
    #Get the input files for this patch (there should be NTOMO catalogues)
    filelist=`echo ${inputs} | sed 's/ /\n/g' | grep "_${patch}_" || echo `
    #Get the m-bias file for this patch (there should be one, with NTOMO entries)
    biaslist=`echo ${mfiles} | sed 's/ /\n/g' | grep "_biases" || echo `
    
    #Check if there are any matching files {{{
    if [ "${filelist}" == "" ]
    then
      #If not, loop
      echo
      continue
    fi
    #}}}
  
    #If needed, create the output directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${stat}_vec_${patch} ]
    then
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${stat}_vec_${patch}/
    fi
    #}}}
    
    #Construct the data vector for cosebis and bandpowers{{{
    _message " >@BLU@ Constructing data vector for patch ${patch}@DEF@"
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_data_vector_allstats.py \
      --inputfiles ${filelist}   \
      --statistic ${stat} \
      --mbias   ${biaslist}      \
      --tomobins @BV:TOMOLIMS@  \
      --lensbins @BV:NLENSBINS@ \
      --outputfile  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${stat}_vec_${patch}/combined_vector
    _message "@RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"
    #}}}
  
    #Update the datablock
    _write_datablock "${stat}_vec_${patch}" "combined_vector.txt combined_vector_no_m_bias.txt"
  done
done

