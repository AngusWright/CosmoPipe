#=========================================
#
# File Name : add_nzcov.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 30 Jan 2025 09:23:37 PM CET
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_source ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_source
fi

outputlist=''
filelist="@DB:ALLHEAD@"
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
for inp in `seq ${NTOMO}` 
do 
  file=`echo ${filelist} | awk -v n=$inp '{print $n}'`
  neff=`echo @BV:NEFFLIST@ | awk -v n=$inp '{print $n}'`
  file=${file##*/}
  file=${file%.*}_neff.txt
  echo -n " ${neff} " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_source/${file}
  outputlist="${outputlist} ${file}"
done 

#Update the datablock contents file 
_write_datablock "neff_source" "${outputlist}"
