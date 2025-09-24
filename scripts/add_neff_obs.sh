#=========================================
#
# File Name : add_neff_lens.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Fri 07 Jul 2023 08:03:50 PM CEST
#
#=========================================


if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_obs ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_obs
fi

outputlist=''
filelist="@DB:ALLHEAD@"
NLENS="@BV:NSMFLENSBINS@"
for inp in `seq ${NLENS}`
do
  file=`echo ${filelist} | awk -v n=$inp '{print $n}'`
  neff=`echo @BV:NEFFLIST_OBS@ | awk -v n=$inp '{print $n}'`
  file=${file##*/}
  file=${file%.*}_neff.txt
  echo -n " ${neff} " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_obs/${file}
  outputlist="${outputlist} ${file}"
done 

#Update the datablock contents file 
_write_datablock "neff_obs" "${outputlist}"
