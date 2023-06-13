#=========================================
#
# File Name : make_data_vector.sh
# Created By : awright
# Creation Date : 01-04-2023
# Last Modified : Thu 01 Jun 2023 06:02:15 PM CEST
#
#=========================================

#Input data vectors 
inputs="@DB:cosebis@"
#Input mbias files 
mfiles="@DB:mbias@"

for patch in @PATCHLIST@ @ALLPATCH@
do 
  #Get the input files for this patch (there should be NTOMO catalogues)
  filelist=`echo ${inputs} | sed 's/ /\n/g' | grep "_${patch}_" || echo `
  #Get the m-bias file for this patch (there should be one, with NTOMO entries)
  biaslist=`echo ${mfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep "_biases" || echo `

  #Check if there are any matching files {{{
  if [ "${filelist}" == "" ] 
  then 
    #If not, loop
    continue
  fi 
  #}}}

  #If needed, create the output directory {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec_${patch} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec_${patch}/
  fi 
  #}}}

  #Construct the data vector for cosebis {{{
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_data_vector.py \
    --inputfiles ${filelist}   \
    --mbias   ${biaslist}      \
    --tomobins @BV:TOMOLIMS@  \
    --outputfile  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_vec_${patch}/combined_vector.txt 
  #}}}

  #Update the datablock 
  _write_datablock "cosebis_vec_${patch}" "combined_vector.txt"
done

