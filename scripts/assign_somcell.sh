#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 21-03-2023
# Last Modified : Fri Jul 18 19:00:17 2025
#
#=========================================

#Notify
_message "@BLU@ > Assign SOM cell IDs to catalogue {@DEF@\n"

#Output files 
input="@DB:DATAHEAD@"
ext=${input##*.}
output=${input%.*}_cell.${ext}
som=`_read_datablock @BV:SOMBLOCK@`
som=`_blockentry_to_filelist $som`
som=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:SOMBLOCK@/$som

_message "  @RED@SOM:@DEF@ ${som##*/}@DEF@\n"
_message "  @RED@Cat:@DEF@ ${input##*/}@DEF@\n"
_message "   -> @BLU@Assigning cell IDs @DEF@"
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/assign_somcell.R \
  -i ${input} \
  -s ${som} \
  --data.threshold @BV:DATATHRESHOLD@ \
  --n.cluster.bins @BV:NCLUSTER@ \
  --som.cores @BV:NTHREADS@ \
  -o ${output} \
  --features @BV:SOMFEATURES@ 2>&1 
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"

_message "   -> @BLU@Merge IDs with original catalogue @DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${input} \
  -p ${output} \
  -o ${output}_tmp \
  -k cellID groupID -t OBJECTS 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"

mv ${output}_tmp ${output}

_replace_datahead "${input}" "${output}" 

#Notify
_message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"


