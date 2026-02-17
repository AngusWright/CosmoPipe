#
# Script to construct a pipeline from input pipeline descriptor 
#

set -e 
#set -x 

#Read command line options  {{{
resume="FALSE"
while [ $# -gt 0 ] 
do 
  case $1 in 
    "--resume") 
      resume="TRUE" 
      echo "Resuming pipeline from requested location!"
      shift
      resumenum=$1
      echo "Resume number is ${resumenum}"
      shift 
      ;; 
    *)
      if [ -f $1 ] 
      then 
        pipeline_file=$1
        shift 
      else 
        echo "Unknown command line option: $1"
        exit 1
      fi 
      ;; 
  esac
done 
#}}}

#Source the Script Documentation Functions {{{
source @RUNROOT@/@MANUALPATH@/CosmoPipe.man.sh
_initialise
#}}}

#Paths and variables for configuration {{{
source @RUNROOT@/variables.sh
#}}}

#Do the variable check {{{
blockneeds=`_varcheck $0`
#}}}

#Read the pipeline description file {{{
pipeline_steps=`VERBOSE=1 _read_pipe @PIPELINE@`
echo ${pipeline_steps}
count=0
echo "Expanding pipeline items"
echo "Starting:\n${pipeline_steps}"
#If there are any substeps 
while [[ " ${pipeline_steps} " =~ " ." ]]
do 
  count=$((count+1))
  #Loop through the steps
  for step in ${pipeline_steps}
  do 
    #Check if we are running a 'resume' {{{
    if [ "${resume}" == "TRUE" ] 
    then 
      #If so, did we find 'RESUME' 
      if [ "${step}" == "RESUME" ] 
      then 
        echo "skipping over RESUME item"
        #If so, continue 
        continue
      fi 
    fi
    #}}}
    #Strip out the step number {{{
    stepnum=${step##*=}
    step=${step%=*}
    #}}}
    #If the step is a substep
    if [ "${step:0:1}" == "." ]
    then 
      echo "Parsing variables for step: ${step}"
      step=`_parse_blockvars ${step}`
      echo "Getting substeps for step: ${step}"
      #Read the substep modes 
      sublist=`VERBOSE=1 _read_pipe $step ${stepnum}` 
      #Sanitise the sublist 
      sublist=${sublist//&/\\&}
      #Replace the substep (whole matches only)
      pipeline_steps=`echo " $pipeline_steps " | sed "s/ $step=${stepnum} / ${sublist//\//\\\/} /" | xargs echo `
      echo "  -> ${sublist}"
    fi 
  done 
  #If count > 100: there is something wrong 
  if [ $count -gt 100 ] 
  then 
    VERBOSE=1 _message " -ERROR! Something has gone wrong with the pipeline step determination...\n"
    VERBOSE=1 _message " Current pipeline step list is:\n"
    VERBOSE=1 _message " ${pipeline_steps}"
    exit 1
  fi 
done
echo "Ending:\n${pipeline_steps}"
echo "Done!"
#}}}
#If running resume, and RESUME not found, create it explicitly {{{

#}}}

#Check that all functions exits {{{
_err=0
for step in ${pipeline_steps}
do 
  echo "Checking scripts for step ${step}"
  #Check if we are running a 'resume' {{{
  if [ "${resume}" == "TRUE" ] 
  then 
    #If so, did we find 'RESUME' 
    if [ "${step}" == "RESUME" ] 
    then 
      echo "  -> Skipping RESUME item"
      #If so, continue 
      continue
    fi 
  fi
  #}}}
  #Strip out the version number 
  step=${step%=*}
  #If the step is not a HEAD or VARS change
  if [ "${step:0:1}" != "@" ] && [ "${step:0:1}" != "!" ] && [ "${step:0:1}" != "~" ] \
    && [ "${step:0:1}" != "%" ] && [ "${step:0:1}" != "+" ] && [ "${step:0:1}" != "-" ]
  then 
    ##Parse block variables 
    #step=`_parse_blockvars ${step}`
    #If the step has no script 
    if [ ! -f @RUNROOT@/@SCRIPTPATH@/${step}.sh ] && [ ! -f @RUNROOT@/@CONFIGPATH@/${step}.ini ]
    then 
      #Notify the user that it is missing 
      if [ ${_err} == "0" ]
      then 
        missing="${step}.sh"
      else 
        missing="${missing}\n${step}.sh"
      fi 
      _err=$((_err+1))
      echo "  -> Script ${step}.sh not found!"
    fi 
  else 
    echo "  -> this is not a script step! Continuing..."
  fi
done 
#If there was an error, prompt and stop 
if [ "${_err}" != "0" ]
then 
  if [ "${_err}" == "1" ]
  then 
    #If there was only one missing file 
    VERBOSE=1 _message "${RED} - ERROR${DEF}\n\n"
    VERBOSE=1 _message "   ${RED}ERROR: script ${missing} does not exist in the script path!${DEF}\n"
    VERBOSE=1 _message "   ${BLU}       it is either misspelled in the pipeline.ini file, or does not exist yet!${DEF}\n"
    exit 1
  else 
    #If there was many missing files 
    VERBOSE=1 _message "${RED} - ERROR${DEF}\n\n"
    VERBOSE=1 _message "${RED}ERROR: the following ${_err} scripts do not exist in the script path!${DEF}\n"
    VERBOSE=1 _message "${missing}\n"
    VERBOSE=1 _message "${BLU}They are either misspelled in the pipeline.ini file, or does not exist yet!${DEF}\n"
    exit 1
  fi 
fi 
#}}}

#Initialise datablock {{{ 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt ] 
then 
  #echo -en "\nBLOCK EXISTS:"
  #Check if block is a testing block 
  ntest=`grep -c "_validitytest_" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt || echo `
  #Save the current block status
  if [ ! -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt ] && [ "${ntest}" == "0" ]
  then 
    #echo -en " COPY BLOCK TO RUNBLOCK\n"
    #run_block will already exist if a recent pipeline construction attempt failed... don't overwrite it!
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_head.txt
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_vars.txt
  elif [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt ] 
  then 
    #echo -en " COPY RUNBLOCK TO BLOCK\n"
    #reset the block 
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_head.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_vars.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
  elif [ "${ntest}" != "0"  ]
  then 
    #echo -en " REMOVE BLOCK & START NEW (${ntest})\n"
    rm  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    rm  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    rm  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
    VERBOSE=1 _initialise_datablock
  fi 
  @P_SED_INPLACE@ "s/={.*/={_validitytest_}/" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  @P_SED_INPLACE@ "s/={.*/={_validitytest_}/" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  @P_SED_INPLACE@ "s/={.*/={_validitytest_}/" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
else 
  #echo -en " NO BLOCK : START NEW\n"
  VERBOSE=1 _initialise_datablock
fi
#}}}

#Check the validity of the pipeline {{{
#Add default variables (if they exist) {{{
if [ -f @PIPELINE@_defaults.sh ]
then 
  VERBOSE=1 _add_default_vars
fi 
#}}}
#Initialise variables {{{
allneeds=''
allneeds_def=''
absent_block=''
echo  > @RUNROOT@/@PIPELINE@_links.R
currstep=0
currsubstep=0
found_resume="FALSE"
#}}}
#For each step in the pipeline: 
for step in ${pipeline_steps}
do 
  echo ${step}
  #Check if we are running a 'resume' {{{
  if [ "${resume}" == "TRUE" ] 
  then 
    #If so, did we find 'RESUME' 
    stepnum=${step##*=}
    if [ "${step}" == "RESUME" ] || [ "${stepnum}" == "${resumenum}" ]
    then 
      #Did we _already_ find resume (multiple in the pipeline?!)
      if [ "${found_resume}" == "TRUE" ]
      then 
        VERBOSE=1 _message " - ERROR!\n\n"
        VERBOSE=1 _message "   ${RED}ERROR: ${BLU}Multiple ${RED}RESUME${BLU} items are present in the pipeline!${DEF}\n" 
        exit 1 
      fi 
      #Document that we found the resume step
      found_resume='TRUE'
      if [ "${step}" == "RESUME" ]
      then 
        #If so, continue 
        continue
      fi 
    fi 
  fi
  #}}}
  #Strip out the version number {{{
  stepnum=${step##*=}            #Strip out numbers 
  stepnum=${stepnum%%.*}         #Get the first number 
  substepnum=${step##*=}         #Strip out the numbers 
  substepnum=${substepnum#*.}    #Remove the first number 
  if [[ "${substepnum}" =~ .*".".* ]]
  then 
    substepnum=${substepnum%%.*}
  else 
    substepnum=0
  fi 
  #}}}
  #If we have a numbered step {{{
  if [ "${stepnum}" != "_" ] 
  then 
    #Is this part of a new step? {{{
    if [ ${stepnum} -gt ${currstep} ]
    then 
      #If not the first substep: 
      if [ ${currsubstep} -gt 0 ] 
      then 
        #Close the last substep 
        echo "end" >> @RUNROOT@/@PIPELINE@_links.R
      fi 
      currsubstep=0
      #If not the first step: 
      if [ ${currstep} -gt 0 ] 
      then 
        #Close the last step 
        echo "end" >> @RUNROOT@/@PIPELINE@_links.R
      fi 
      #Open the new step: 
      echo "subgraph Step ${stepnum}" >> @RUNROOT@/@PIPELINE@_links.R
      currstep=${stepnum}
    fi 
    #}}}
    #Is this part of a new substep? {{{
    if [ ${substepnum} -gt ${currsubstep} ]
    then 
      #If not the first substep: 
      if [ ${currsubstep} -gt 0 ] 
      then 
        #Close the last step 
        echo "end" >> @RUNROOT@/@PIPELINE@_links.R
      fi 
      #Open the new step: 
      echo "subgraph Sub-Step ${stepnum}.${substepnum}" >> @RUNROOT@/@PIPELINE@_links.R
      currsubstep=${substepnum}
    fi 
    #}}}
  fi 
  echo links: subgraph specified
  #}}}

  step=${step%=*}
  #If the step is a HEAD update 
  if [ "${step:0:1}" == "@" ]
  then 
    echo HEAD assignment: writing ${step:1} to datahead 
    #Modify the HEAD to the request value {{{
    _target=${step:1}
    _target=`VERBOSE=0 _parse_blockvars ${_target}`
    echo parsed: ${_target}
    if [ "$(_inblock $_target)" == "0" ]
    then 
      absent_block="${absent_block} ${_target}"
      _write_datablock $_target "_validitytest_"
    fi 
    VERBOSE=1 _write_datahead "${_target}" "_validitytest_" 
    #Set the "laststep" to be this block element
    laststep=${_target}
    #If resuming and haven't found the "RESUME" entry, save this assignment
    if [ "${resume}" == "TRUE" ] && [ "${found_resume}" == "FALSE" ]
    then 
      lastassign=${_target}
      resume_nstep=0
    fi 
    #}}}
  elif [ "${step:0:1}" == "!" ]
  then 
    echo BLOCK assignment: writing datahead to ${step:1} 
    #Modify the datablock with the current HEAD {{{
    _target=${step:1}
    _target=`VERBOSE=0 _parse_blockvars ${_target}`
    echo parsed: ${_target}
		VERBOSE=1 _write_datablock ${_target} "`_read_datahead`"
    #Write the link between the previous processing function and this block element
    echo "${laststep} -.-> ${_target}(${_target})" >> @RUNROOT@/@PIPELINE@_links.R
    #If resuming and haven't found the "RESUME" entry, save this assignment
    if [ "${resume}" == "TRUE" ] && [ "${found_resume}" == "FALSE" ]
    then 
      lastassign=${_target}
      resume_nstep=0
    fi 
    #}}}
  elif [ "${step:0:1}" == "-" ]
  then 
    #Delete an item from the datablock  {{{
    name=${step:1}
    name=`VERBOSE=0 _parse_blockvars ${name}`
    echo BLOCK deletion: removing ${name} 
		VERBOSE=1 _delete_blockitem "${name}" TEST
    #}}}
  elif [ "${step:0:1}" == "%" ]
  then 
    #Rename an item in the datablock  {{{
    names=${step:1}
    oldname=${names%%-*}
    oldname=`VERBOSE=0 _parse_blockvars ${oldname}`
    newname=${names##*-}
    newname=`VERBOSE=0 _parse_blockvars ${newname}`
    echo BLOCK rename: moving ${oldname} to ${newname}
		VERBOSE=1 _rename_blockitem "${oldname}" "${newname}" TEST
    if [ "${lastassign}" == "${oldname}" ] 
    then 
      lastassign=${newname}
      resume_nstep=0
    fi 
    #Rewrite all instances of oldname(oldname) in the links file to newname(newname)
    cat @RUNROOT@/@PIPELINE@_links.R | sed "s/${oldname}(${oldname})/${newname}(${newname})/g" > @RUNROOT@/@PIPELINE@_links.R.tmp
    mv @RUNROOT@/@PIPELINE@_links.R.tmp @RUNROOT@/@PIPELINE@_links.R
    #}}}
  elif [ "${step:0:1}" == "~" ]
  then 
    #Export an item from the datablock  {{{
    names=${step:1}
    blockname=${names%%-*}
    blockname=`VERBOSE=0 _parse_blockvars ${blockname}`
    outname=${names##*-}
    outname=`VERBOSE=0 _parse_blockvars ${outname}`
    echo BLOCK export: copying ${blockname} to external folder ${outname}
		VERBOSE=1 _export_blockitem "${blockname}" "${outname}" TEST
    #}}}
  elif [ "${step:0:1}" == "+" ]
  then 
    #Add the new variable to the datablock {{{
    echo Variable assignment: ${step:1}
    _var=${step:1}
    if [[ "${_var}" =~ .*"+=".* ]]
    then 
      _oldval=`_read_blockvars ${_var}` 
      _addval=${_var#*=}
      _varval=$((${_oldval}+${_addval}))
      _var=${_var%%=*}
    else 
      _varval=${_var#*=}
      _var=${_var%%=*}
    fi 
    _varval=`VERBOSE=0 _parse_blockvars ${_varval}`
    echo _write_blockvars ${_var} "${_varval}"
    _write_blockvars ${_var} "${_varval}"
    #}}}
  else 
    #Check for the manual file  {{{
    echo Script: ${step}
    #If we havent found the resume, increment the resume step counter
    if [ "${found_resume}" == "FALSE" ]
    then 
      resume_nstep=$((nstep+1))
    fi 
    if [ ! -f @RUNROOT@/@MANUALPATH@/${step}.man.sh ]
    then 
      #If not found, error 
      VERBOSE=1 _message "${RED} - ERROR${DEF}\n\n"
      VERBOSE=1 _message "${RED}ERROR: the manual files for the following script are not available!\n   ${step}.sh!${DEF}\n"
      exit 1
    fi
    #}}}
    #Source the step documentation {{{
    echo Source documentation: ${step}.man.sh
    source @RUNROOT@/@MANUALPATH@/${step}.man.sh 
    #}}}
    #Perform the variable check {{{
    blockneeds=`_varcheck $step.sh`
    if [ ! -f  @PIPELINE@_defaults.sh ] 
    then 
      touch  @PIPELINE@_defaults.sh
    fi 
    if [ "${blockneeds}" != "" ]
    then 
      allneeds="${allneeds} ${blockneeds}"
      for var in ${blockneeds}
      do 
        #Check whether the variable is already in the pipeline defaults 
        exists=`grep -c "^${var}=" @PIPELINE@_defaults.sh || echo`
        if [ "${exists}" == "0" ]
        then 
          #If not, check whether the global defaults file exists 
          if [ -e defaults.sh ]
          then 
            #If so, check whether this variable is in the global defaults 
            exists=`grep -c "^${var}=" defaults.sh || echo`
            if [ "${exists}" != "0" ]
            then 
              #If so, use the global default 
              grep -v "^#${var}" defaults.sh | grep -m 1 -B 1 "^${var}=" >> @PIPELINE@_defaults.sh 
              varstring="`grep -m 1 "^${var}=" defaults.sh | awk -F# '{print $1}'`"
            else 
              allneeds_def="${allneeds_def} ${var}"
              #Otherwise, insert a blank entry 
              echo "#INSERT DEFAULT VALUE HERE:" >> @PIPELINE@_defaults.sh 
              echo ${var}=@BV:${var}@ >> @PIPELINE@_defaults.sh 
              varstring="${var}=@BV:${var}@"
            fi
          else 
            allneeds_def="${allneeds_def} ${var}"
            #If there is no global defaults, insert a blank entry 
            echo "#INSERT DEFAULT VALUE HERE:" >> @PIPELINE@_defaults.sh 
            echo ${var}=@BV:${var}@ >> @PIPELINE@_defaults.sh 
            varstring="${var}=@BV:${var}@"
          fi 
        else 
          #Check if the existing default is a blank entry 
          exists_isdef=`grep -c "^${var}=@BV:${var}@" @PIPELINE@_defaults.sh || echo`
          if [ "${exists_isdef}" != "0" ]
          then 
            allneeds_def="${allneeds_def} ${var}"
            varstring="${var}=@BV:${var}@"
          else 
            varstring="`grep -c "^${var}=@BV:${var}@" @PIPELINE@_defaults.sh | awk -F# '{print $1}'`"
          fi 
        fi 
        #Add the variables to the datablock 
        #>&2 echo _write_blockvars ${varstring%%=*} ${varstring#*=}
        _write_blockvars ${varstring%%=*} ${varstring#*=}
      done 
      #sort @PIPELINE@_defaults.sh | uniq > @PIPELINE@_defaults_uniq.sh
      #mv @PIPELINE@_defaults_uniq.sh @PIPELINE@_defaults.sh
    fi 
    echo Completed Block-needs runtime variable check.
    #}}}
    echo Checking inputs 
    #Check inputs and outputs {{{
    inputs=`_inp_data`
    echo "Raw inputs: ${inputs}"
    inputs=`VERBOSE=0 _parse_blockvars ${inputs}` 
    echo "After variable parse: ${inputs}"
    #}}}
    #Check the data block for these inputs & add graph entries {{{
    nstep=`grep -c ${step} @RUNROOT@/@PIPELINE@_links.R || echo`
    for inp in $inputs
    do 
      echo -n "  ${inp} "
      #Add to the graph {{{
      if [ "${inp}" != "DATAHEAD" ] && [ "${inp}" != "ALLHEAD" ]
      then 
        #Add link to the requested blockentry {{{
        echo "${inp}(${inp}) --> ${step}_${nstep}[${step}]" >> @RUNROOT@/@PIPELINE@_links.R
        #}}}
      else 
        #Add link to current datahead blockentry or the last processing function {{{
        echo "${laststep} --> ${step}_${nstep}[${step}]" >> @RUNROOT@/@PIPELINE@_links.R
        #}}}
      fi 
      #}}}
      #If not in the data block {{{
      echo "$(_inblock $inp)" || echo "FAILED BLOCKCHECK" 
      if [ "$(_inblock $inp)" == "0" ] 
      then 
        if [ "${inp}" == "ALLHEAD" ]
        then 
          echo "warning message"
          #Warn {{{
          VERBOSE=1 _message "${RED}(WARNING)${DEF} "
          if [ "${warnings}" == "" ] 
          then 
            warnings="${RED}    WARNINGS:${DEF}\n     - ${RED}ALLHEAD${BLU} was requested at a step where no ${RED}DATAHEAD${BLU} was currently assigned. This could be a quirk of the pipeline check.${DEF}\n"
          else 
            warnings="${warnings}     - ${RED}ALLHEAD${BLU} was requested at a step where no ${RED}DATAHEAD${BLU} was currently assigned. This could be a quirk of the pipeline check.${DEF}\n"
          fi 
          #}}}
        elif [[ "${inp}" =~ .*"__validitytest_".* ]]
        then
          #Ignore: probably ok 
          echo "warning message 2"
          #Warn {{{
          VERBOSE=1 _message "${RED}(WARNING)${DEF} "
          if [ "${warnings}" == "" ] 
          then 
            warnings="${RED}    WARNINGS:${DEF}\n     - ${RED}${inp}${BLU} was requested, but includes a dynamically defined variable (set to '__validitytest__' during pipeline constructions. This should be ok, but maybe not...${DEF}\n"
          else 
            warnings="${warnings}     - ${RED}${inp}${BLU} was requested, but includes a dynamically defined variable (set to '__validitytest__' during pipeline constructions. This should be ok, but maybe not...${DEF}\n"
          fi 
          #}}}
        else 
          #echo "Error message"
          ##Error {{{
          #VERBOSE=1 _message " - ERROR!\n\n"
          #VERBOSE=1 _message "   ${RED}ERROR: ${BLU}Input ${DEF}${inp}${BLU} does not exist in the data-block when needed for step ${DEF}${step}${BLU}!${DEF}\n" 
          #VERBOSE=1 _message "   ${RED}       ${BLU}Check the ${DEF}@PIPELINE@_pipeline.log${BLU} file for details of the construction.\n" 
          #echo "`_read_datablock`"
          #VERBOSE=1 _message "   ${RED}       Pipeline is invalid!${DEF}\n" 
          #exit 1 
          ##}}}
          #
          #Add the missing item to the absent_block list 
          echo "${inp} is missing!"
          absent_block="${absent_block} \n($step) ${inp}"
        fi 
      fi 
      #}}}
    done 
    #}}}
    echo Checking outputs 
    #Expand any outputs that are variables {{{
    outlist=''
    outputs=`_outputs`
    echo "Raw outputs: ${outputs}"
    outputs=`VERBOSE=0 _parse_blockvars ${outputs}` 
    echo "After variable parse: ${outputs}"
    ##}}}
    #Save these outputs to the data block  {{{
    for out in $outputs
    do 
      #Check for a DATAHEAD modification
      if [ "${out}" == "DATAHEAD" ] || [ "${out}" == "ALLHEAD" ] 
      then 
        #Don't update the block (not needed), but track the last step for the flowchart 
        if [ "$(_inblock $out)" == "0" ] 
        then 
          _writelist_datahead "__validitytest__"
        fi 
        laststep="${step}_${nstep}[${step}]"
      elif [ "${out:0:3}" == "BV:" ] 
      then 
        #Add it to the datablock 
        if [[ "${out:3}" =~ .*"PATCH".* ]]
        then 
          str="@BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb"
          str=${str//\"/}
          _write_blockvars ${out:3} "${str//\'/}"
        else 
          _write_blockvars ${out:3} "__validitytest__"
        fi 
      else 
        #Update the datablock 
        _write_datablock $out "_validitytest_"
        #Add link to diagram 
        echo "${step}_${nstep}[${step}] --> ${out}(${out})" >> @RUNROOT@/@PIPELINE@_links.R
      fi 
    done 
    datablock=`_read_datablock`
    #}}}
  fi 
done
#Check for absent block elements {{{
absent_block=`echo ${absent_block} | sort | uniq`
if [ "${absent_block}" != "" ] 
then 
  echo "Error: missing block elements"
  #absent_block=`echo ${absent_block} | sed 's/ /\n/g' | sort | uniq | awk '{printf $0" "}'`
  #Error {{{
  VERBOSE=1 _message " - @RED@ERROR!@DEF@\n"
  VERBOSE=1 _message "   ${RED}ERROR: ${BLU}There are requested or input block elements that do not exist in the data-head when needed. These are: ${DEF}\n" 
  VERBOSE=1 _message "   ${BLU}->${DEF}${absent_block}${BLU}<-${DEF}\n" 
  VERBOSE=1 _message "   ${RED}       ${BLU}These should either be inherited from other pipelines, or the processing functions that make them must be added.\n" 
  VERBOSE=1 _message "   ${RED}       Pipeline is invalid!${DEF}\n" 
  exit 1 
  #}}}
fi 
#}}}
#Check for resume errors {{{
if [ "${resume}" == "TRUE" ] && [ "${found_resume}" == "FALSE" ]
then 
  echo "Error: resume requested but no RESUME item found"
  #Error 
  VERBOSE=1 _message " - ERROR!\n\n"
  VERBOSE=1 _message "   ${RED}ERROR: ${BLU}--resume was requested, but there is no ${RED}RESUME${BLU} item in the pipeline!${DEF}\n" 
  exit 1 
fi 
#}}}
echo Done: Pipeline check complete 
#Final Graph edits {{{
#Close the last subgraph {{{
echo "end" >> @RUNROOT@/@PIPELINE@_links.R
#}}}
#Remove unused patch-wise assignments from graph (assuming they are dummies) {{{
skip=''
for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do 
  #Get all entries matching this patch {{{
  patch_links=`awk -F\> '{print $NF}' @RUNROOT@/@PIPELINE@_links.R | grep "_${patch})$" || echo`
  #}}}
  #Loop through the patchlinks {{{
  for link in ${patch_links}
  do 
    #Item name {{{
    name=${link%%(*}
    #}}}
    #Check if there is a starting use of this product {{{
    nstart=`awk -F\> '{print $1}' @RUNROOT@/@PIPELINE@_links.R | grep -c "^${name}[ (]" || echo `
    #}}}
    #If not, add it to the removal list {{{
    if [ ${nstart} -eq 0 ] 
    then 
      if [ "${skip}" == "" ] 
      then 
        skip="${name}(${name})$"
      else 
        skip="${skip}\|${name}(${name})"
      fi 
    fi 
    #}}}
  done 
  #}}}
done 
#Remove skipped entries {{{
if [ "${skip}" != "" ]
then 
  grep -v "${skip}" @RUNROOT@/@PIPELINE@_links.R > @RUNROOT@/@PIPELINE@_links.R.tmp
  mv @RUNROOT@/@PIPELINE@_links.R.tmp @RUNROOT@/@PIPELINE@_links.R
fi 
#}}}
#}}}
#Add graph colouring {{{ 
assignments=`awk -F\> '{print $NF}' @RUNROOT@/@PIPELINE@_links.R | grep ")$" | awk -F\( '{printf $1 " "}' || echo`
assignments=`echo ${assignments}`
echo  "classDef green fill:#9f6,stroke:#333,stroke-width:2px;" >> @RUNROOT@/@PIPELINE@_links.R
echo "class ${assignments// /,} green" >> @RUNROOT@/@PIPELINE@_links.R
#}}}
#Finalise the graph file {{{
cat @RUNROOT@/@SCRIPTPATH@/graph_base.R @RUNROOT@/@PIPELINE@_links.R > @RUNROOT@/@PIPELINE@_graph.R
echo '")' >> @RUNROOT@/@PIPELINE@_graph.R 
#}}}
#}}}

#Reset the documentation functions {{{
VERBOSE=0 _initialise
#}}}
#Remove the test block {{{
rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
#}}}
#Remove empty datablock directories {{{
for item in `ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/`
do 
  #If the item is a directory 
  if [ -d ${item} ]
  then 
    #If the directory is empty {{{
    if [ ! "$(ls -A ${item})" ]
    then 
      #Remove the directory {{{
      rmdir ${item}
      #}}}
    fi 
    #}}}
  fi 
done 
#}}}
#Replace the initial block, if present {{{
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt ]
then 
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_block.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_head.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/run_vars.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
fi 
#}}}
#Prompt the user about missing default variables, if needed {{{
if [ "${allneeds}" != "" ]
then 
  allneeds=`echo ${allneeds} | sed 's/ /\n/g' | sort | uniq | awk '{printf $0 " "}'`
  allneeds_def=`echo ${allneeds_def} | sed 's/ /\n/g' | sort | uniq | awk '{printf $0 " "}' || echo `
  allneeds_def=`echo ${allneeds_def}` 
  if [ "${warnings}" == "" ] 
  then 
    warnings="${RED}     WARNINGS:${DEF}\n     ${BLU}The pipeline used the following undeclared runtime variables:${DEF}\n     ${allneeds}\n"
  else 
    warnings="${warnings}     ${BLU}The pipeline used the following undeclared runtime variables:${DEF}\n     ${allneeds}\n"
  fi 
  if [ "${allneeds_def}" != "" ]
  then 
    warnings="${warnings}     ${BLU}Of these variables, the following ${RED}have no default value assigned${BLU}:\n     ${DEF}${allneeds_def}\n     ${BLU}You need to update those variables in the ${DEF}@PIPELINE@_defaults.sh${BLU} file!\n"
  else 
    warnings="${warnings} ${RED}    !BUT!${DEF} - ${BLU}all of them were assigned defaults in the ${DEF}@PIPELINE@_defaults.sh${BLU} file!\n     So there is ${RED}no action is required${BLU}!${DEF}\n"
  fi 
fi 
#}}}
#}}}

#Pipeline is valid: construct pipeline commands {{{
#Preamble 
cat @RUNROOT@/@SCRIPTPATH@/pipeline_base.sh > @RUNROOT@/@PIPELINE@_pipeline.sh

#Add the opening prompt {{{
cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
`_openingprompt`

#Add the default variables to the datablock 
_add_default_vars 
EOF
#}}}

#Check if we are running a 'resume' {{{
if [ "${resume}" == "TRUE" ] & [ "${resume_nstep}" == 0 ]
then 
  #Start by performing the last assignment before the resume {{{
  cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
	
	#Modify the HEAD to the request value
	#Intermediate Step: write block item ${lastassign} to current DATAHEAD {{{
	#Notify
	_message "@BLU@Copying requested elements of \`_parse_blockvars ${lastassign}\` to DATAHEAD @DEF@ {\n"
	#Modify the current HEAD to requested block element
	_add_datahead "${lastassign}"
	#Notify
	_message "} - @RED@Done!@DEF@\n"
	#}}}


	EOF
  #}}}
elif [ "${resume}" == "TRUE" ] 
then 
  #Do not re-initialise the DATAHEAD before the resume {{{
  if [ "${warnings}" == "" ] 
  then 
    warnings="${RED}     WARNINGS:${DEF}\n     ${RED}RESUME${BLU} was requested and was found ${RED}${resume_nstep}${BLU} processing-function step(s) from\n"
    warnings="${warnings}     ${BLU}the last DATAHEAD assignment (${RED}${lastassign}${BLU})${DEF}\n"
    warnings="${warnings}     ${BLU}This can result in ${RED}pathologically bad behaviour${BLU} if the pipeline crash\n"
    warnings="${warnings}     ${BLU}happened mid-way through the running of the previous processing function${DEF}\n"
    warnings="${warnings}     ${BLU}This pipeline configuration will continue, but it is ${RED}strongly advised${BLU}\n"
    warnings="${warnings}     ${BLU}that you monitor the outputs, and consider moving the ${RED}RESUME${BLU} statement\n"
    warnings="${warnings}     ${BLU}to directly below the previous assignment in the pipeline (i.e. ${DEF}@${lastassign}${BLU}).${DEF}\n"
  else 
    warnings="${warnings}     ${RED}RESUME${BLU} was requested and was found ${resume_nstep} processing-function steps from\n"
    warnings="${warnings}     ${BLU}the last DATAHEAD assignment (${RED}${lastassign}${BLU})${DEF}\n"
    warnings="${warnings}     ${BLU}This can result in ${RED}pathologically bad behaviour${BLU} if the pipeline crash\n"
    warnings="${warnings}     ${BLU}happened mid-way through the running of the previous processing function${DEF}\n"
    warnings="${warnings}     ${BLU}This pipeline configuration will continue, but it is ${RED}strongly advised${BLU}\n"
    warnings="${warnings}     ${BLU}that you monitor the outputs, and consider moving the ${RED}RESUME${BLU} statement\n"
    warnings="${warnings}     ${BLU}to directly below the previous assignment in the pipeline (i.e. ${DEF}@${lastassign}${BLU}).${DEF}\n"
  fi 
  cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
	
	#Modify the HEAD to the request value
	#Skip the head update {{{
	#Notify
	_message "@RED@SKIPPING@BLU@ the assignment of @DEF@${lastassign}@BLU@ to the DATAHEAD:\n"
	_message "     -> @RED@RESUME@BLU@ was requested in the middle of a chained-sequence of processing functions@DEF@.\n"
	#}}}


	EOF
  #}}}
fi
#}}}

#For each step in the pipeline {{{
found_resume="FALSE"
for step in ${pipeline_steps}
do 
  #Check if we are running a 'resume' {{{
  if [ "${resume}" == "TRUE" ] 
  then 
    #If so, did we find 'RESUME' 
    stepnum=${step##*=}
    if [ "${step}" == "RESUME" ]  || [ "${stepnum}" == "${resumenum}" ]
    then 
      #If so, document and continue 
      found_resume='TRUE'
      if [ "${step}" == "RESUME" ]
      then 
        #If so, continue 
        continue
      fi 
    elif [ "${found_resume}" == "FALSE" ] && [ "${step:0:1}" != "+" ]
    then 
      echo "RESUME means that we skip step: ${step}" 
      continue 
    fi 
  fi
  #}}}
  #Strip out the version number {{{
  stepnum=${step##*=}
  step=${step%=*}
  #}}}
  #Write each step of the pipeline 
  if [ "${step:0:1}" == "@" ]
  then 
    _name=${step:1}
    #_name=`_parse_blockvars ${_name}`
    if [ "${_name}" == "" ] 
    then 
    	#If this is a datahead clearing: {{{
    	cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
			
			#Clear the datahead 
			#Intermediate Step: clear the DATAHEAD {{{
			#Notify
			_message "@BLU@Clearing the current DATAHEAD @DEF@ {\n"
			#Erase the datahead by doing a NULL assignment 
			_write_datahead "${_name}"
			#Notify
			_message "} - @RED@Done!@DEF@\n"
			#}}}

			EOF
    	#}}}
    else 
    	#If this is a datahead assignment: {{{
    	cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
			
			#Modify the HEAD to the request value
			#Intermediate Step: write block item ${_name} to current DATAHEAD {{{
			#Notify
			_message "@BLU@Copying requested elements of \`_parse_blockvars ${_name}\` to DATAHEAD @DEF@ {\n"
			#Modify the current HEAD to requested block element
			_add_datahead "${_name}"
			#Notify
			_message "} - @RED@Done!@DEF@\n"
			#}}}


			EOF
    	#}}}
    fi
  elif [ "${step:0:1}" == "!" ]
  then 
    _name=${step:1}
    #_name=`_parse_blockvars ${_name}` 
    #If this is a datablock assignment: {{{
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Intermediate Step: write current DATAHEAD to block item: ${_name} {{{
		#Notify
    _message "@BLU@Copying current DATAHEAD items to \`_parse_blockvars ${_name}\`@DEF@ {\n"
		#Modify the datablock with the current HEAD
		_add_head_to_block ${_name} 
		#Notify
		_message "} - @RED@Done!@DEF@\n"
		#}}}

		EOF
    #}}}
  elif [ "${step:0:1}" == "-" ]
  then 
    _name=${step:1}
    #_name=`_parse_blockvars ${_name}` 
    #If this is a datablock deletion: {{{
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Intermediate Step: delete the block item ${_name} {{{
		#Notify
    _message "@BLU@Deleting block item \`_parse_blockvars ${_name}\` from the datablock@DEF@ {\n"
		#Delete the requested block item ${_name} 
    _delete_blockitem ${_name} 
		#Notify
		_message "} - @RED@Done!@DEF@\n"
		#}}}

		EOF
    #}}}
  elif [ "${step:0:1}" == "%" ]
  then 
    #If this is a datablock rename: {{{
    names=${step:1}
    oldname=${names%%-*}
    #oldname=`_parse_blockvars ${oldname}` 
    newname=${names##*-}
    #newname=`_parse_blockvars ${newname}` 
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Intermediate Step: rename block item ${oldname} to ${newname} {{{
		#Notify
		_message "@BLU@Renaming block item \`_parse_blockvars ${oldname}\` to \`_parse_blockvars ${newname}\`@DEF@"
		#Rename block item
		_rename_blockitem "${oldname}" "${newname}"
		#Notify
		_message " - @RED@Done!@DEF@\n"
		#}}}

		EOF
    #}}}
  elif [ "${step:0:1}" == "+" ]
  then 
    #If this is a blockvariable assignment: {{{
    echo "ASSIGNMENT TIME: ${step}"
    _var=${step:1}
    if [[ "${_var}" =~ .*"+=".* ]]
    then 
      _oldval=`_read_blockvars ${_var}` 
      _addval=${_var#*=}
      _varval=$((${_oldval}+${_addval}))
      _var=${_var%%=*}
    else 
      _varval=${_var#*=}
      _var=${_var%%=*}
    fi 
    #_varval=${_var#*=}
    #_var=${_var%%=*}
    #_var=`_parse_blockvars ${_var}`
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Modify the block variable to the request value
		#Intermediate Step: write block variable ${_var} to requested value {{{
		#Notify
		_message "@BLU@Assigning variable @RED@${_var^^}@BLU@ to @DEF@${_varval}"
		#Modify the VARS to include requested block element
		_write_blockvars ${_var^^} "${_varval}"
		#Notify
		_message " @BLU@- @RED@Done!@DEF@\n"
		#}}}

		EOF
    #}}}
  elif [ "${step:0:1}" == "~" ]
  then 
    #If this is a datablock item export: {{{
    names=${step:1}
    blockname=${names%%-*}
    outname=${names##*-}
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Intermediate Step: export the block item ${blockname} to external storage {{{
		#Notify
		_message "@BLU@Exporting block element \`_parse_blockvars ${blockname}\` into external storage \`_parse_blockvars ${outname}\` @DEF@ {\n"
		#Export the requested block item ${blockname} to external storage ${outname}
		_export_blockitem ${blockname} ${outname}
		#Notify
		_message "} - @RED@Done!@DEF@\n"
		#}}}

		EOF
    #}}}
  else 
    #If this is a bone-fide script method {{{
    #Source the documentation information 
    source @RUNROOT@/@MANUALPATH@/${step}.man.sh 
    if [ -f @RUNROOT@/@SCRIPTPATH@/${step}.sh ] 
    then 
      basefile=@RUNROOT@/@SCRIPTPATH@/${step}.sh
    else 
      basefile=@RUNROOT@/@CONFIGPATH@/${step}.ini
    fi
    #Write the step to the pipeline file {{{
    cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
		
		#Step $stepnum: $step {{{
		#DESCRIPTION: #{{{
		`_description`
		#}}}
		#Update script for datablock 
		_incorporate_datablock ${basefile} `_uses_datahead`
		#Run the mode 
		`_runcommand` > @RUNROOT@/@LOGPATH@/step_${stepnum}_${step##*/}.log
		#}}}
		 
		EOF
    #}}}
    #}}}
  fi
done 
#}}}

#Add the closing prompt {{{
cat >> @RUNROOT@/@PIPELINE@_pipeline.sh <<- EOF 
`_closingprompt`
EOF
#}}}

#Add the pipeline end
cat @RUNROOT@/@SCRIPTPATH@/pipeline_close.sh >> @RUNROOT@/@PIPELINE@_pipeline.sh

#}}}

#If there are warnings, print them: 
if [ "${warnings}" != "" ] 
then 
  VERBOSE=1 _message "${DEF} {\n${warnings}${DEF}   }${DEF}"
fi 

#End
trap : 0 
