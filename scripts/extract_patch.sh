#=========================================
#
# File Name : extract_patch.sh
# Created By : awright
# Creation Date : 28-03-2023
# Last Modified : Tue Feb 17 19:40:28 2026
#
#=========================================


#Input Filename & Extension {{{
inputfile=@DB:DATAHEAD@
extn=${inputfile##*.}
#}}}

#Notify
_message "@BLU@Constructing Patch-wise catalogue from:@DEF@ ${inputfile##*/}\n"

#Construct the tomographic bin catalogues {{{
outputlist=''
for patch in @BV:PATCHLIST@ 
do
  #Define the output file name {{{
  inputroot=${inputfile%/*}
  inputbase=${inputfile##*/}
  outputname=${inputroot}/${inputbase//_@ALLPATCH@_/_${patch}_}
  #}}}
  #Check for rename errors {{{
  if [ "${outputname}" == "${inputfile}" ]
  then 
    tmp_ext=${inputbase##*.}
    tmp_base=${inputbase%.*}
    outputname=${inputroot}/${tmp_base}_${patch}_pws.${tmp_ext}
  fi 
  #}}}
  #Add the output name to the output list {{{ 
  outputlist="${outputlist} ${outputname##*/}"
  #}}}
  #Check if the outputname file exists {{{
  if [ -f ${outputname} ] 
  then 
    #If it exists, remove it 
    _message "  > @BLU@Removing previous catalogue for patch ${patch}@DEF@ "
    rm -f ${outputname}
    _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${inputfile} ${outname}
  do 
    if [ ${#file} -gt 255 ] 
    then 
      links="TRUE"
    fi 
  done 
  
  if [ "${links}" == "TRUE" ] 
  then
    #Remove existing infile links 
    if [ -e infile_$$.lnk ] || [ -h infile_$$.lnk ]
    then 
      rm infile_$$.lnk
    fi 
    #Remove existing outfile links 
    if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
    then 
      rm outfile_$$.lnk
    fi
    #Create input link
    originp=${inputfile}
    ln -s ${inputfile} infile_$$.lnk 
    inputfile="infile_$$.lnk"
    #Create output links 
    ln -s ${outputname} outfile_$$.lnk
    origout=${outputname}
    outputname=outfile_$$.lnk
  fi 
  #}}}
  
  #Try to filter with ldactools {{{
  #Filter condition for ldactools 
  filtercond="(PATCH=='${patch}_patch');" 
  count=0
  while [[ "${filtercond}" =~ "&" ]]
  do 
    count=$((count+1))
    filtercond="(${filtercond}"
    filtercond=${filtercond/&/AND}
    start=${filtercond%%&*}
    ending="${filtercond#*&}"
    if [ "${ending}" == "${filtercond}" ]
    then 
      filtercond="${start})"
    else 
      filtercond="${start})&${ending}"
    fi 
    if [ ${count} -gt 100 ] 
    then 
      _message "ERROR IN ldac filter command construction!"
      exit 1
    fi 
  done 
  filtercond=${filtercond//==/=}
  ldacpass=TRUE
  #Select sources using required filter condition 
  _message "@BLU@Creating Patch ${patch} catalogue@DEF@"
  { 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
    -i ${inputfile} \
    -t OBJECTS \
    -c "${filtercond};" \
    -o ${outputname} 2>&1 || ldacpass=FALSE 
  } >&1

  #}}}

  #If using links, replace them {{{
  if [ "${links}" == "TRUE" ] 
  then 
    rm ${inputfile} ${outputname}
    inputfile=${originp}
    outputname=${origout}
  fi 
  #}}}
  
  #If ldactools failed, use ldacfilter.py {{{
  if [ "${ldacpass}" == "TRUE" ]
  then 
    _message " @BLU@- @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  else 
    #Construct the output patch {{{
    _message " @RED@(py)"
  
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
             -i ${inputfile} \
    	       -o ${outputname} \
    	       -t OBJECTS \
    	       -c "(PATCH=='${patch}_patch');" 2>&1
    _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
    #}}}
  fi 
  #}}}
done
#}}}

#Update the datahead 
_replace_datahead ${inputfile} "${outputlist}"

