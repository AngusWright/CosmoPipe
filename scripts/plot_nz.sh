#=========================================
#
# File Name : plot_nz.sh
# Created By : awright
# Creation Date : 23-03-2023
# Last Modified : Sat Sep 13 12:40:03 2025
#
#=========================================

#Construct the tomographic bin catalogue strings {{{
binstrings=''
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
for i in `seq ${NTOMO}`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
  ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the string to append to the file names {{{
  ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
  ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
  appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
  #}}}
  binstrings="${binstrings} ${appendstr}"
done
#}}}

truth=`_read_datablock nz_truth`
truth=`_blockentry_to_filelist ${truth}`
if [ "$truth" == "" ] 
then 
  truth=''
else 
  truth_out=''
  for tmp in $truth
  do 
    truth_out="$truth_out @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_truth/$tmp"
  done
  truth=$truth_out
fi 

#Run the R plotting code 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_nz.R -i @DB:nz@ --truth ${truth} --binstrings ${binstrings} 2>&1

