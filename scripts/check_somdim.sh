#=========================================
#
# File Name : check_somdim.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Fri Aug  1 18:46:29 2025
#
#=========================================

#Define the output filename 
inputlist="@DB:ALLHEAD@"

somdim=`echo @BV:SOMDIM@ | awk '{print $1,$2}'`

for input in ${inputlist} 
do 
  #Get the file name
  output=${input}
  outext=${output##*.}
  outbase=${output//.${outext}/}
  outlist="${outbase}_somdim.txt"
  #Split catalogues in the DATAHEAD into NSPLIT regions 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/check_somdim.R \
    -i ${input} \
    -d ${somdim} \
    -o ${outlist} 2>&1
  
  newdim=`tail -1 ${outlist} | awk '{print $1,$2}'`
  if [ "${newdim}" == '' ]
  then 
    _message "@RED@ERROR@BLU@ - No SOM dimensions produced?!@DEF@\n"
    exit 1 
  fi 
  
  if [ "${newdim}" != "${somdim}" ]
  then
    _message "@RED@MODIFICATION!@BLU@ - Updating SOM dimensions from @RED@${somdim}@BLU@ to @RED@${newdim}!@DEF@\n"
    #Save the tomolims variable to the datablock 
    somdim=${newdim}
  fi 
done
_write_blockvars "SOMDIM" "${somdim}"

