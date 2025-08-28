#=========================================
#
# File Name : compute_m_bias.sh
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Mon Jul 21 19:47:17 2025
#
#=========================================

if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 
#For each file in the datahead, make a shape recal surface
allhead="@DB:ALLHEAD@"
allsurf="@DB:m_surface@"

#Ensure that the HEAD & surface catalogues are the appropriate lengths {{{
nhead=`echo ${allhead} | awk '{print NF}'`
nsurf=`echo ${allsurf} | awk '{print NF}'`

if [ ${nhead} -gt ${nsurf} ] && [ ${nsurf} -ne 1 ]
then 
  _message "@RED@ERROR!\n@DEF@The provided lists of\n"
  _message "m calibration surfaces (${nsurf}), is smaller than \n"
  _message "the length of the DATAHEAD (${nhead}) but not length 1.\n"
  exit 1
elif [ ${nsurf} -eq 1 ]
then 
  outlist=''
  for i in `seq ${nhead}` 
  do 
    outlist="${outlist} ${allsurf}"
  done
  allsurf="${outlist}"
fi 
#}}}

outputlist=''
outputlistbase=''
#Initialise the joblist 
echo > @RUNROOT@/@RUNTIME@/mbias_joblist_$$.sh 
for i in `seq ${nsurf}` 
do 
  #Select the relevant files {{{
  surf_current=`echo ${allsurf} | awk -v n=$i '{print $n}'`
  surf_current_new=${surf_current##.*}_datwgt.asc
  if [ ${nsurf} -gt ${nhead} ] 
  then 
    #Data side requires recycling 
    if [ $((${i}%${nhead})) -eq 0 ]
    then 
      #Last entry 
      data_current=`echo ${allhead} | awk '{print $NF}'`
    else 
      #The (n mod m)^th entry 
      data_current=`echo ${allhead} | awk -v n=$i -v m=${nhead} '{print $(n%m)}'`
    fi 
    count=$((i-1))
    appendstr="_mbias_$((${count}/${nhead}))"
    if [ $((${i}%${nhead})) -eq 1 ]
    then 
      #First loop of a new realisation, notify
      _message "\r@BLU@Preparing realisation @RED@$((${count}/${nhead}))@DEF@"
    fi 
  else 
    #The n^th entry 
    data_current=`echo ${allhead} | awk -v n=$i '{print $n}'`
    appendstr="_mbias"
  fi 
  #}}}

  #Prepare the filenames {{{
  #Define the output file name 
  ext=${data_current##*.}
  outputname=${data_current//.${ext}/${appendstr}.asc}
  #Check if the outputname file exists 
  if [ -f ${outputname} ] 
  then 
    #If it exists, remove it 
    _message " > @BLU@Removing previous m bias file for @RED@${current##*/}@DEF@"
    rm -f ${outputname}
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}

  #Correct for the variable shear dm {{{
  #Add job to the joblist 
  cat >> @RUNROOT@/@RUNTIME@/mbias_joblist_$$.sh << EOF 
  echo " > @BLU@Computing the m-biases for catalogue @RED@${data_current##*/}@DEF@" ; \
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/compute_m_bias.py \
    --input_surface ${surf_current} \
    --output_surface ${surf_current_new} \
    --input_cat ${data_current} \
    --output ${outputname} \
    --m12name @BV:M1NAME@ @BV:M2NAME@ \
    --weightname @BV:WEIGHTNAME@ \
    --SNRname @BV:SNRNAME@ \
    --Rname @BV:RNAME@ 2>&1 ; \
  echo " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
EOF
  #}}}

  #Update the output list {{{
  outputlist="${outputlist} ${outputname}"
  outputlistbase="${outputlistbase} ${outputname##*/}"
  #}}}
done

#Run the jobs in parallel {{{
NTHREAD=@BV:NTHREADS@
_message "\n@BLU@Preparing Parallel Jobs with $NTHREAD threads @DEF@\n"
#Constructs NTHREAD chunks of the original commandlist {{{
split --numeric-suffixes=01 -e -n l/${NTHREAD} --additional-suffix=_of_${NTHREAD}.sh @RUNROOT@/@RUNTIME@/mbias_joblist_$$.sh mbias_$$_job
#}}}
#Distribute the executables and wait for their completion {{{
for i in `seq -w $NTHREAD`
do
  _message "\r@BLU@Launching job @RED@${i}@DEF@"
  if [ -f mbias_$$_job${i}_of_${NTHREAD}.sh ]
  then 
    screen -L -Logfile mbias_$$_job${i}_of_${NTHREAD}.log -S mbias_$$_job${i}_of_${NTHREAD}.sh -d -m bash mbias_$$_job${i}_of_${NTHREAD}.sh
  fi 
done
#}}}
sleep 1
#Check if we can continue to the next MODE {{{
while [ `ps au | grep -v "bash -c " | grep -v grep | grep -c mbias_$$_job` -ge 1 ]
do
  #If this is the first loop of the wait, then print what is running  /*fold*/ {{{
  if [ "${prompt}" != "mbias" ]
  then
    _message "@BLU@Pipeline paused while waiting for @RED@mbias@BLU@ to be completed (@DEF@`date`@BLU@)@DEF@"
    prompt=mbias
  fi
  sleep 10
  #/*fend*/}}}
done
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
#}}}
#}}}

#Update the datahead {{{
for _head in ${allhead} 
do 
  _replace_datahead ${_head} ""
done 
_writelist_datahead "${outputlistbase}" 
#}}}

#Loop over patches 
for patch in @BV:PATCHLIST@ @ALLPATCH@
do 
  #Get the m-bias files for this patch (there should be NTOMO*NREALISATION files)
  filelist=`echo ${outputlist} | sed 's/ /\n/g' | grep "_${patch}_" || echo `

  #Check if there are any matching files {{{
  if [ "${filelist}" == "" ] 
  then 
    #If not, loop
    continue
  fi 
  #}}}

  #If needed, create the output directory {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding} 
  fi 
  #}}}

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

  #Output the m-prior files {{{
  nfile=`echo ${filelist} | awk '{print NF}'`
  if [ ${nfile} -gt ${NTOMO} ]
  then 
    #If there are multiple realisations {{{
    #If needed, create the output cov directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding} 
    fi 
    #}}}
    #Run the m prior construction for each bin {{{
    @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/compute_m_priors.R -i ${filelist} \
      --binstrings ${binstrings} \
      --corr @BV:MBIASCORR@ \
      --biasout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/m_${patch}${blinding}_biases.txt \
      --uncout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/m_${patch}${blinding}_uncertainty.txt \
      --covout @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding}/m_${patch}${blinding}_covariance.txt 2>&1
    #}}}
    #Create the correlation file {{{
    echo "@BV:MBIASCORR@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/m_${patch}${blinding}_correlation.txt 
    #}}}
    #Add covariance file to the data block {{{
    _write_datablock mcov_${patch}${blinding} "m_${patch}${blinding}_covariance.txt"
    #}}}
    #}}}
  elif [ ${nfile} -eq ${NTOMO} ]
  then 
    #Output the m-bias values for this patch into the mbias block {{{
    tail -qn 1 ${filelist} | awk -F, '{printf $1" "}' > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/m_${patch}${blinding}_biases.txt
    tail -qn 1 ${filelist} | awk -F, '{printf $2" "}' > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/m_${patch}${blinding}_uncertainty.txt
    echo "@BV:MBIASCORR@" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/m_${patch}${blinding}_correlation.txt 
    #}}}
  else 
    #There are fewer m files than tomographic bins?! {{{
    _message " - @RED@ERROR!\n@DEF@There are fewer then NTOMO m calibration files?!\n"
    exit 1 
    #}}}
  fi 
  #}}}

  #Add files to output list
  mfiles="m_${patch}${blinding}_biases.txt m_${patch}${blinding}_uncertainty.txt m_${patch}${blinding}_correlation.txt"

  #Update the datablock contents file 
  _write_datablock mbias_${patch}${blinding} "${mfiles}"

done

