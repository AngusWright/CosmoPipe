#=========================================
#
# File Name : compute_transfer_function.sh
# Created By : awright
# Creation Date : 18-07-2025
# Last Modified : Thu Aug 21 13:53:26 2025
#
#=========================================


#Notify
_message "@BLU@ > Computing transfer function {@DEF@\n"

#Output files 
cells_deep=`echo @BV:SOMCELL_SETS@ | awk '{print $1}'`
cells_wide=`echo @BV:SOMCELL_SETS@ | awk '{print $2}'`
deeplist=`_read_datablock $cells_deep`
deeplist=`_blockentry_to_filelist $deeplist`
widelist=`_read_datablock $cells_wide`
widelist=`_blockentry_to_filelist $widelist`

ndeep=`echo $deeplist | awk '{print NF}'`
nwide=`echo $widelist | awk '{print NF}'`

if [ $ndeep != $nwide ]
then 
  _message "@RED@ > ERROR: deep cell list and wide cell list differ:@DEF@"
  _message "Deep list: $ndeep ; Wide list: ${nwide}\n${deeplist}\n${widelist}\n"
  exit 1 
fi 

#Define the wide dimension 
widedim="@BV:WIDESOM_DIM@"

#Define the deep dimension 
deepdim="@BV:DEEPSOM_DIM@"

outlist=''

for i in `seq $ndeep`
do 
  deep=`echo $deeplist | awk -v i=$i '{print $i}'`
  wide=`echo $widelist | awk -v i=$i '{print $i}'`
  output=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/transfer_func_$i.txt 

  _message "   -> @BLU@Constructing transfer function @DEF@"
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/compute_transfer_function.R \
    -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${cells_deep}/${deep} \
    -w @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${cells_wide}/${wide} \
    --wide_dim $widedim \
    --deep_dim $deepdim \
    --ncluster @BV:NCLUSTER@ \
    -o ${output} \
    2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"

  outlist="${outlist} ${output##*/}"

done 

_writelist_datahead "${outlist}" 

#Notify
_message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"

