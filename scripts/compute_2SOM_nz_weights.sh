#=========================================
#
# File Name : compute_2SOM_nz_weights.sh
# Created By : awright
# Creation Date : 18-07-2025
# Last Modified : Tue Sep  2 18:07:02 2025
#
#=========================================

#Notify
_message "@BLU@ > Assign SOM weights to spec sources {@DEF@\n"

wide_catalogues="@DB:som_weight_wide@"
spec_catalogues="@DB:som_weight_spec@"
transfer="@DB:som_weight_transfer@"

#Check if the number of output files is not equal to the number of training files 
nwid=`echo ${wide_catalogues} | awk '{print NF}'`
nspe=`echo ${spec_catalogues} | awk '{print NF}'`
ntra=`echo ${transfer} | awk '{print NF}'`
outlist=''

for i in `seq $nwid`
do 
  #input files 
  wide=`echo ${wide_catalogues} | awk -v i=$i '{print $i}'`
  spec=`echo ${spec_catalogues} | awk -v i=$i '{print $i}'`
  tran=`echo ${transfer} | awk -v i=$i '{print $i}'`
  #Output files 
  ext=${spec##*.}
  output=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${spec##*/}
  output=${output%.*}_somweight.${ext}
  
  _message "  @RED@Spec:@DEF@ ${spec##*/}@DEF@\n"
  _message "  @RED@Wide:@DEF@ ${wide##*/}@DEF@\n"
  _message "  @RED@Transfer:@DEF@ ${transfer##*/}@DEF@\n"
  _message "   -> @BLU@Computing SOM weights@DEF@"
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/compute_2SOM_nz_weights.R \
    -w ${wide} \
    -s ${spec} \
    -t ${tran} \
    -o ${output} 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  _message "   -> @BLU@Merge IDs with original catalogue @DEF@"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${spec} \
    -p ${output} \
    -o ${output}_tmp \
    -k SOMweight -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  mv ${output}_tmp ${output}
  outlist="${outlist} ${output##*/}"
  

done
_writelist_datahead "${outlist}" 

#Notify
_message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"


