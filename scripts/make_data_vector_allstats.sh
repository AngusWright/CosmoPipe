#=========================================
#
# File Name : make_data_vector_allstats.sh
# Created By : stoelzner
# Creation Date : 01-04-2023
# Last Modified : Tue Jul 22 13:19:33 2025
#
#=========================================

#Statistic
STATISTIC="@BV:STATISTIC@"
#Input data vectors
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  inputs="@DB:cosebis@"
#}}}
elif [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ] #{{{
then
  inputs="@DB:cosebis_dimless@"
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  inputs="@DB:bandpowers@"
#}}}
elif [ "${STATISTIC^^}" == "XIPSF" ] #{{{
then 
  inputs="@DB:xipsf_binned@"
#}}}
elif [ "${STATISTIC^^}" == "XIGPSF" ] #{{{
then 
  inputs="@DB:xigpsf_binned@"
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then 
  inputs="@DB:xipm_binned@"
#}}}
fi
#Input mbias files 
mfiles="@DB:mbias@"
for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do 
  #Remove the 'comb' if needed 
  patchuse=${patch%comb}
  #Get the input files for this patch (there should be NTOMO catalogues)
  filelist=`echo ${inputs} | sed 's/ /\n/g' | grep "[\^_/]${patch}_" || echo `
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
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:STATISTIC@_vec_${patch} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:STATISTIC@_vec_${patch}/
  fi
  #}}}

  #Construct the data vector for cosebis and bandpowers{{{
  _message " >@BLU@ Constructing data vector for patch ${patch}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_data_vector_allstats.py \
    --inputfiles ${filelist}   \
    --statistic @BV:STATISTIC@ \
    --mbias   ${biaslist}      \
    --tomobins @BV:TOMOLIMS@  \
    --outputfile  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:STATISTIC@_vec_${patch}/combined_vector 
  _message "@RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}

  #Update the datablock 
  _write_datablock "@BV:STATISTIC@_vec_${patch}" "combined_vector.txt combined_vector_no_m_bias.txt"
done

