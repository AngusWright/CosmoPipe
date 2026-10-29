#=========================================
#
# File Name : add_wt.sh
# Created By : dvornik
# Creation Date : 19-05-2024
# Last Modified : Fri 19 Apr 2024 08:34:26 AM CEST
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt/
fi

file="@BV:TREECORRWT@"
file=${file##*/}

#Create the uncertainty file 
outlist=""
if [ -f @BV:TREECORRWT@ ]
then
  cp @BV:TREECORRWT@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt/${file}
  outlist=${file}
elif [ -d @BV:TREECORRWT@ ]
then 
  filelist=`ls @BV:TREECORRWT@/*.txt*`
  for file in ${filelist} 
  do 
    cp ${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt/${file##*/}
    outlist="${outlist} ${file##*/}"
  done 
else 
  _message "@RED@- ERROR! Input treecorrwt variable is neither a file nor a directory"
  exit 1
fi 

#Update the datablock contents file 
_write_datablock "wt" "${outlist}"
