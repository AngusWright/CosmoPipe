#=========================================
#
# File Name : add_gt.sh
# Created By : dvornik
# Creation Date : 19-05-2024
# Last Modified : Fri 19 Apr 2024 08:34:26 AM CEST
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/gt ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/gt/
fi

file="@BV:TREECORRGT@"
file=${file##*/}

#Create the uncertainty file 
outlist=""
if [ -f @BV:TREECORRGT@ ]
then
  cp @BV:TREECORRGT@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/gt/${file}
  outlist=${file}
elif [ -d @BV:TREECORRGT@ ]
then 
  filelist=`ls @BV:TREECORRGT@/*.asc*`
  for file in ${filelist} 
  do 
    cp ${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/gt/${file##*/}
    outlist="${outlist} ${file##*/}"
  done 
else 
  _message "@RED@- ERROR! Input treecorrgt variable is neither a file nor a directory"
  exit 1
fi 

#Update the datablock contents file 
_write_datablock "gt" "${outlist}"
