#=========================================
#
# File Name : add_mbias.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Thu 11 Jan 2024 12:16:45 AM CET
#
#=========================================

#Loop over patches & allpatch 
for patch in @BV:PATCHLIST@ @ALLPATCH@ 
do 

  #Construct the output directory 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@ ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@ 
  fi 

  #Create the values file 
  echo "@BV:MBIASVALUES@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@/m_${patch}_biases.txt 
  #Create the uncertainty file 
  echo "@BV:MBIASERRORS@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@/m_${patch}_uncertainty.txt 
  #Create the correlation file 
  echo "@BV:MBIASCORR@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}_@BV:BLIND@/m_${patch}_correlation.txt 

  #update the output list 
  outputlist="m_${patch}_biases.txt m_${patch}_uncertainty.txt m_${patch}_correlation.txt"

  #Update the datablock contents file 
  _write_datablock mbias_${patch}_@BV:BLIND@ "${outputlist}"

done 

