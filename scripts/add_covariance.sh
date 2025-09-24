#=========================================
#
# File Name : add_covariance.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 07 Nov 2023 08:08:34 PM CET
#
#=========================================

STATISTIC="@BV:STATISTIC@"
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_${STATISTIC,,} ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_${STATISTIC,,}
fi


file_in=@BV:INPUT_COVFILE@

file="${file_in}"
file=${file##*/}

#Create the uncertainty file 
cp ${file_in} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_${STATISTIC,,}/${file}

#Update the datablock contents file 
_write_datablock "covariance_${STATISTIC,,}" "${file}"


