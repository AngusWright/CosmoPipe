#=========================================
#
# File Name : ldac_crossmask.sh
# Created By : awright
# Creation Date : 09-09-2025
# Last Modified : Thu Sep 25 05:42:08 2025
#
#=========================================

#Get the catalogue to mask 
maskbase=@DB:mask_base@

#Output file name 
output=${maskbase##*/}
ext=${output##*.}
output=${output%.*}_cmask.${ext}
output=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${output}

#Apply the mask to the mask base: 
#Get the list of all columns 
cols=`@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${maskbase} -t OBJECTS 2>&1 | grep "Key name" | sed 's@Key name:\(\.\)\{1,\}@@' || echo `

if [ "${cols}" == "" ] 
then 
  _message "@RED@ - ERROR! Column read using ldacdesc failed! Is this an LDAC catalogue?@DEF@\n"
  _message "${maskbase}\n"
  exit 1 
fi 

#Check if crossmask is one of the columns 
colcheck=`echo ${cols} | sed 's/ /\n/g' | grep -ci "crossmask" || echo `

if [ ${colcheck} -ne 0 ]
then 
  #_message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  _message "@RED@ Warning! Column name to add already exists!@DEF@\n"
  _message "@BLU@ Removing existing column @DEF@crossmask@DEF@"
  #Calculate the new column 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
    -i ${maskbase} \
    -o ${maskbase}_tmp \
    -t OBJECTS \
    -k crossmask 2>&1
  
  mv ${maskbase}_tmp $maskbase
  _message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  _message "@BLU@ Resuming@DEF@"
fi 
  
_message "@BLU@ Creating the crossmask @DEF@"
#Crossmask the catalogues: 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/crossmask.R \
  -i @DB:ALLHEAD@ \
  -b ${maskbase} \
  -c "@BV:MASKCOND@" \
  --mask_only -o ${output} 2>&1 
_message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

_message "@BLU@ Merging mask with the base catalogue @DEF@"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${maskbase} \
    -p ${output} \
    -o ${output}_tmp \
    -t OBJECTS \
    -k crossmask \
    2>&1
_message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

_message "@BLU@ Filtering base catalogue with crossmask @DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
  -i ${output}_tmp \
  -t OBJECTS \
  -c "crossmask<=0;" \
  -o ${output} 2>&1 
_message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

rm ${output}_tmp 

#Update the datahead
_replace_datahead "@DB:ALLHEAD@" "${output}"

#Finalise 
