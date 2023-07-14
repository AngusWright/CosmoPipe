#=========================================
#
# File Name : add_sigmae.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri 07 Jul 2023 08:04:20 PM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae
fi 

outputlist=''
filelist="@DB:ALLHEAD@"
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
for inp in `seq ${NTOMO}` 
do 
  file=`echo ${filelist} | awk -v n=$inp '{print $n}'`
  sigmae=`echo @SIGMAELIST@ | awk -v n=$inp '{print $n}'`
  file=${file##*/}
  file=${file%.*}_sigmae.txt
  echo -n " ${sigmae} " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae/${file}
  outputlist="${outputlist} ${file}"
done 

#Update the datablock contents file 
_write_datablock "sigmae" "${outputlist}"
