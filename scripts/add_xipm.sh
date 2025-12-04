#=========================================
#
# File Name : add_xipm.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Wed 13 Mar 2024 02:34:26 PM CET
#
#=========================================


#If needed, create the output directory 
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/
fi 

file="@BV:TREECORRXIPM@"
file=${file##*/}

#Create the uncertainty file 
outlist=""
if [ -f @BV:TREECORRXIPM@ ]
then 
  cp @BV:TREECORRXIPM@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${file}
  outlist=${file}
elif [ -d @BV:TREECORRXIPM@ ]
then 
  filelist=`ls @BV:TREECORRXIPM@/*.txt*`
  for file in ${filelist} 
  do 
    cp ${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${file##*/}
    outlist="${outlist} ${file##*/}"
  done 
else 
  _message "@RED@- ERROR! Input treecorrxipm variable is neither a file nor a directory"
  exit 1 
fi 

#Update the datablock contents file 
_write_datablock "xipm" "${outlist}"
