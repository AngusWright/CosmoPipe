#=========================================
#
# File Name : neff_sigmae.sh
# Created By : awright
# Creation Date : 28-03-2023
# Last Modified : Mon Jul 21 22:00:32 2025
#
#=========================================

if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 

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
    if [[ "${catname}" =~ .*"_${patch}_".* ]] || [[ "$catname" =~ ^"${patch}_".* ]]
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
  mfiles="`_read_datablock mbias_${usepatch}${blinding}`"
  mfiles="`_blockentry_to_filelist ${mfiles}`"
  mbiasfile=`echo ${mfiles} | sed 's/ /\n/g' | grep "_biases" || echo `
  mbiasfile="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${usepatch}${blinding}/${mbiasfile}"
  
  _message " ->@BLU@ Patch @RED@${patch}@BLU@, Blind @RED@@BV:BLIND@@DEF@\n"
  _message " -> @BLU@Use effective area for patch: @RED@${SurveyArea} square arcmin@DEF@\n"
  
  #If doesn't exist, make the output folder
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}${blinding} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}${blinding}
  fi 
  #If doesn't exist, make the neff folder
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_${patch}${blinding} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_${patch}${blinding}
  fi 
  #If doesn't exist, make the output folder
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae_${patch}${blinding} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae_${patch}${blinding}
  fi 

  patchlist=''
  for catname in ${headlist} 
  do 
    catbase=${catname##*/}
    if [[ "${catbase}" =~ .*"_${patch}_".* ]] || [[ "$catbase" =~ ^"${patch}_".* ]]
    then
      patchlist="${patchlist} ${catname}"
    fi
  done 

  nfile=`echo ${patchlist} | awk '{print NF}'`

  _message "> @BLU@Computing sigma_e and n_effective@DEF@" 
  _message "> @BLU@There are @RED@${nfile} files@BLU@ to analyse in this patch:\n@DEF@" 
  
  count=0
  patchoutlist_neff=''
  patchoutlist_sigmae=''
  for catfull in ${patchlist}
  do 
    catname=${catfull##*/}
    catbase=${catname%.*}
    count=$((count+1))
    _message " -> @DEF@ ${catname}" 
    mbias=`cat $mbiasfile | awk '{printf $0 " "}' | awk -v count=${count} '{print $count}'`
    _message "@BLU@ (m=@DEF@$mbias@BLU@)@DEF@" 
    #Prepare the neff & ellipticity dispersion file
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/neff_sigmae.py \
      -i ${catfull} \
      --e1name @BV:E1NAME@ \
      --e2name @BV:E2NAME@ \
      --wname @BV:WEIGHTNAME@ \
      --mbias ${mbias} \
      --area ${SurveyArea} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}${blinding}/${catbase}_neff_sigmae.txt 
    #Construct the separated files 
    tail -n +2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}${blinding}/${catbase}_neff_sigmae.txt \
      | awk '{ printf $2" " }' >  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/neff_${patch}${blinding}/${catbase}_neff.txt 
    tail -n +2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cov_input_${patch}${blinding}/${catbase}_neff_sigmae.txt \
      | awk '{ printf $7" " }' > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/sigmae_${patch}${blinding}/${catbase}_sigmae.txt 
    #Save the output names 
    patchoutlist_neff="${patchoutlist_neff} ${catbase}_neff.txt"
    patchoutlist_sigmae="${patchoutlist_sigmae} ${catbase}_sigmae.txt"
    #Notify 
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  done 
  
  #Add the new file to the datablock 
  _write_datablock neff_${patch}${blinding} "${patchoutlist_neff}"
  _write_datablock sigmae_${patch}${blinding} "${patchoutlist_sigmae}"

done 

