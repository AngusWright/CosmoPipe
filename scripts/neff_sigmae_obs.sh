#=========================================
#
# File Name : neff_sigmae_obs.sh
# Created By : dvornik
# Creation Date : 22-08-2024
# Last Modified : Thu 22 Aug 2024 01:51:35 PM CEST
#
#=========================================

headlist="@DB:ALLHEAD@"

#Check that the patches match in all files {{{
found_patches=""
for catname in ${headlist} 
do 
  catname=${catname##*/}
  found="FALSE"
  for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do
    #Find files with matching patch strings
    if [[ "${catname}" =~ .*"_${patch}_".* ]]
    then
      found='TRUE'
      found_patches="${found_patches} ${patch}"
      break 
    fi
  done 
  #If the file doesn't match any patch, error {{{
  if [ "${found}" == "FALSE" ] 
  then 
    _message "@RED@ - ERROR! DATAHEAD file ${catname} doesn't match any patch?!@DEF@\n"
    exit 1 
  fi 
done 
#}}}
#}}}

found_patches=`echo ${found_patches} | sed 's/ /\n/g' | sort | uniq `

for patch in ${found_patches} 
do 
  
  #Get the survey area and extract just the value 
  SurveyArea=`_read_blockvars SURVEYAREA_${patch}`
  SurveyArea=${SurveyArea##*=}
  SurveyArea=${SurveyArea/\}/}
  SurveyArea=${SurveyArea/\{/}
  #Get the mbiases for this patch 
  usepatch=${patch//comb/}
  
  _message " ->@BLU@ Patch @RED@${patch}@BLU@\n"
  _message " -> @BLU@Use effective area for patch: @RED@${SurveyArea} square arcmin@DEF@\n"
  
  #If doesn't exist, make the output folder
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}_@BV:BLIND@ ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}_@BV:BLIND@
  fi 
  #If doesn't exist, make the neff folder
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_obs_${patch}_@BV:BLIND@ ]
  then
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_obs_${patch}_@BV:BLIND@
  fi

  patchlist=''
  for catname in ${headlist} 
  do 
    catbase=${catname##*/}
    if [[ "${catbase}" =~ .*"_${patch}_".* ]]
    then
      patchlist="${patchlist} ${catname}"
    fi
  done 

  nfile=`echo ${patchlist} | awk '{print NF}'`

  _message "> @BLU@Computing sigma_e and n_effective@DEF@" 
  _message "> @BLU@There are @RED@${nfile} files@BLU@ to analyse in this patch:\n@DEF@" 
  
  count=0
  patchoutlist_neff=''
  for catfull in ${patchlist}
  do 
    catname=${catfull##*/}
    catbase=${catname%.*}
    count=$((count+1))
    _message " -> @DEF@ ${catname}"
    #Prepare the neff & ellipticity dispersion file
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/neff_sigmae_lens.py \
      -i ${catfull} \
      --wname @BV:LENSWEIGHTNAME@ \
      --area ${SurveyArea} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}_@BV:BLIND@/${catbase}_neff_obs.txt
    #Construct the separated files
    tail -n +2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}_@BV:BLIND@/${catbase}_neff_obs.txt \
      | awk '{ printf $2" " }' >  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_obs_${patch}_@BV:BLIND@/${catbase}_neff.txt
    #Save the output names
    patchoutlist_neff="${patchoutlist_neff} ${catbase}_neff.txt"
    #Notify
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  done 
  
  #Add the new file to the datablock 
  _write_datablock neff_obs_${patch}_@BV:BLIND@ "${patchoutlist_neff}"

done 

