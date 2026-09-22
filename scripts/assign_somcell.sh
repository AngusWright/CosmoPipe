#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Tue Jun 30 19:57:20 2026
#
#=========================================

#Get the input catalogues from the DATAHEAD 
input="@DB:ALLHEAD@"
ninp=`echo ${input} | awk '{print NF}'`
#Get the SOMs from BV:SOMBLOCK 
soms=`_read_datablock @BV:SOMBLOCK@`
soms=`_blockentry_to_filelist $som`
nsom=`echo ${soms} | awk '{print NF}'`
#Check for more mismatch in soms and target catalogues  {{{
if [ ${nsom} -ne 1 ] && [ ${nsom} -ne ${ninp} ] && [ ${ninp} -ne 1 ]
then 
  _message "@RED@ ERROR!@DEF@\n"
  _message "@RED@ The provided SOM list is length @BLU@${nsom}@RED@, and@DEF@\n"
  _message "@RED@ the provided target catalogue list is length @BLU@${ninp}@RED@. These @DEF@\n"
  _message "@RED@ should be of the same length, or one should be a single catalogue.@DEF@\n"
  exit 1
elif [ ${nsom} -ne ${ninp} ]
then 
  if [ ${ninp} -ne 1 ] 
  then 
    outlist=''
    for i in `seq ${ninp}` 
    do 
      outlist="${outlist} ${soms}"
    done
    soms="${outlist}"
  elif [ ${nsom} -ne 1 ]
  then 
    outlist=''
    for i in `seq ${nsom}` 
    do 
      outlist="${outlist} ${input}"
    done
    input="${outlist}"
  fi 
fi 
#}}}
#Update the nsom value 
nsom=`echo ${soms} | awk '{print NF}'`

#Loop through the catalogues, constructing the matches 
for i in `seq ${nsom}`
do 
  #Get the current SOM 
  current_som=`echo ${soms} | awk -v col=${i} '{print $col}'`
  #Get the current target catalogue 
  current_input=`echo ${input} | awk -v col=${i} '{print $col}'`
  #Notify
  _message "@BLU@ > Assign SOM cell IDs to catalogue {@DEF@\n"

  #Output files 
  ext=${current_input##*.}
  output=${current_input%.*}_cell.${ext}
  current_som=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:SOMBLOCK@/$current_som

  _message "  @RED@SOM:@DEF@ ${current_som##*/}@DEF@\n"
  _message "  @RED@Cat:@DEF@ ${current_input##*/}@DEF@\n"
  _message "   -> @BLU@Assigning cell IDs @DEF@"
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/assign_somcell.R \
    -i ${current_input} \
    -s ${current_som} \
    --data.threshold @BV:DATATHRESHOLD@ \
    --n.cluster.bins @BV:NCLUSTER@ \
    --som.cores @BV:NTHREADS@ \
    -o ${output} \
    --features @BV:SOMFEATURES@ 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"

  _message "   -> @BLU@Merge IDs with original catalogue @DEF@"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${current_input} \
    -p ${output} \
    -o ${output}_tmp \
    -k cellID groupID -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  mv ${output}_tmp ${output}

  _replace_datahead "${current_input}" "${output}" 

  #Notify
  _message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"
done 


