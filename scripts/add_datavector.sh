#=========================================
#
# File Name : add_datavector.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 30 Jan 2025 09:27:54 PM CET
#
#=========================================

DATAVEC_TYPE="@BV:DATAVEC_TYPE@"
#If needed, create the output directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${DATAVEC_TYPE,,}_vec ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${DATAVEC_TYPE,,}_vec/
fi


file_in=@BV:INPUT_DATAVEC@

file="${file_in}"
file=${file##*/}

#Create the uncertainty file
cp ${file_in} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${DATAVEC_TYPE,,}_vec/${file}

#Update the datablock contents file
_write_datablock "${DATAVEC_TYPE,,}_vec" "${file}"
