
#Initialisation function {{{ 
function _initialise { 
  _callname=${0##*/} 
  if [ ! -f @RUNROOT@/@MANUALPATH@/${_callname//.sh/.man.sh} ] 
  then 
    _message "${RED} - ERROR! Manual file does not exist!"
    exit 1
  fi 
  #Check that we are in the correct conda environment {{{
  if [ "$CONDA_DEFAULT_ENV" != "cosmopipe" ]
  then 
    echo "ERROR! Configuration and Pipeline must be run from within the 'cosmopipe' conda environment!"
  fi 
  #}}}
  #Documentation file 
  source @RUNROOT@/@MANUALPATH@/${_callname//.sh/.man.sh}
  #Startup prompt 
  _prompt ${VERBOSE}
  #Starting time 
  _message "@BLU@Start time: @DEF@`date +'%a %H:%M'`\n"
}
#}}}

#Finalisation function {{{
function _finalise {
  #Concluding time 
  _message "@BLU@End time: @DEF@`date +'%a %H:%M'`\n"
  #Unset functions
  _unset_functions
  #Mark this step as completed
  echo ${0##*/} >> @PIPELINE@_status.sh
  trap : 0 
}
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Message function {{{ 
function _message { 
  if [ "$VERBOSE" != "0" ] 
  then 
    >&2 echo -en "$1"
  fi 
} 
#}}}

# Variable Check {{{ 
function _varcheck { 
  #Loop through the input functions to the script 
  _varlist=`_inp_var`
  _err=0
  _runerr=0
  _missing=''
  _runmissing=''
  _undefined=''
  for var in $_varlist
  do 
    if [ "${var:0:3}" == "BV:" ]
    then 
      #Check that block variables are defined 
      _res=`_check_blockvar ${var:3}`
      if [ "${_res}" == "0" ] 
      then 
        #If not, add to missing
        _runerr=$((_err+1))
        _runmissing="$_runmissing ${var:3}"
      fi 
    elif [ "${!var}" == "" ] 
    then 
      _err=$((_err+1))
      _missing="$_missing $var"
    elif [ "${!var}" == "@${var^^}@" ]
    then 
      _err=$((_err+1))
      _undefined="$_undefined $var"
    fi 
  done  
  if [ "${_err}" == "1" ]
  then 
    if [ "${_undefined}" != "" ]
    then 
      >&2 echo "ERROR: Input variable$_undefined, required by the mode ${1##*/}, is still set to a placeholder value!"
    else
      >&2 echo "ERROR: Input variable$_missing, required by the mode ${1##*/}, is missing entirely (not in the variables file)!"
    fi 
    exit 1 
  elif [ "${_err}" != "0" ]
  then 
    if [ "${_undefined}" != "" ]
    then 
      >&2 echo "ERROR: Input variables$_undefined, required by the mode ${1##*/}, are still set to their placeholder values!"
    fi
    if [ "${_missing}" != "" ]
    then
      >&2 echo "ERROR: Input variables$_missing, required by the mode ${1##*/}, are missing entirely (not in the variables file)!"
    fi
    exit 1 
  fi 
  if [ "${_runerr}" != "0" ]
  then 
    _runmissing=`echo ${_runmissing} | sed 's/ /\n/g' | sort | uniq | sed 's/\n/ /g'` 
    #>&2 echo ${_runmissing}
    echo ${_runmissing}
  fi 
} 
#}}}

#Sanitize variable before vector formatting {{{
function _clean_variable { 
  _VAR=${1}
  _TMP=${_VAR//  / }
  while [ "${_VAR}" != "${_TMP}" ] 
  do
    _VAR=${_TMP} 
    _TMP=${_VAR//  / } 
  done 
  _VAR=${_TMP// /,} 
  echo "${_VAR}"
}
#}}}

#Get option list {{{
function _get_optlist { 
  cat $1 | grep -v "^#" | grep "=" | awk -F= '{print $1}' 
}
#}}}

#Datablock Functions {{{ 

# Add Default Variables {{{ 
function _add_default_vars { 
  #Loop through the input functions to the script 
  _undefined=''
  source @RUNROOT@/@PIPELINE@_defaults.sh
  while read line 
  do 
    if [ "${line}" == "" ] || [ "${line:0:1}" == "#" ]
    then 
      continue
    fi 
    varbase=${line%%=*}
    varval=${line#*=}
    varval=${varval//\"/}
    varval=${varval//\'/}
    if [ "${varval^^}" != "@${varbase^^}@" ]
    then 
      #_write_blockvars ${varbase^^} "${varval}"
      _write_blockvars ${varbase^^} "${!varbase}"
    fi 
    #Write the survey variable 
    _write_blockvars SURVEY "@SURVEY@"
  done < @RUNROOT@/@PIPELINE@_defaults.sh
} 
#}}}

#Initialise the datablock {{{
function _initialise_datablock { 
  #Make the datablock directory, if needed
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD ]
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD
  fi 
  if [ ! -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt ]
  then 
    #Initialise the datablock txt file 
    echo "HEAD: " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    echo "BLOCK: " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
    echo "VARS: " > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
    if [ -f @PIPELINE@_defaults.sh ]
    then 
      _add_default_vars 
    fi 
  fi 
}
#}}}

#Read the datablock {{{
function _read_datablock { 
  #Read the data block entries 
  _req=${1}
  _outblock=''
  if [ "${_req}" == "" ] 
  then 
    _outblock=`grep -v "^BLOCK:" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt `
  else 
    _outblock=`grep "^${_req}=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt || echo `
  fi 
  #_message "#${_outblock}#"
  #_outblock=`echo ${_outblock} | sed 's/ /\n/g' | sort | uniq | xargs echo`
  #_outblock=`echo ${_outblock} | sed 's/ /\n/g' | xargs echo`
  _outblock=`echo ${_outblock} | sed 's/ /\n/g'`
  #_message "#${_outblock}#"
  echo ${_outblock}
}
#}}}

#Read an external datablock {{{
function _read_external_datablock { 
  #Read the data block entries 
  _loc=${1}
  _req=${2}
  _outblock=''
  if [ "${_req}" == "" ] 
  then 
    _outblock=`grep -v "^BLOCK:" ${_loc} `
  else 
    _outblock=`grep "^${_req}=" ${_loc} || echo `
  fi 
  #_message "#${_outblock}#"
  #_outblock=`echo ${_outblock} | sed 's/ /\n/g' | sort | uniq | xargs echo`
  #_outblock=`echo ${_outblock} | sed 's/ /\n/g' | xargs echo`
  _outblock=`echo ${_outblock} | sed 's/ /\n/g'`
  #_message "#${_outblock}#"
  echo ${_outblock}
}
#}}}

#Write the datablock {{{
function _write_datablock { 
  #Update the BLOCK items 
  _filelist="${2// /,}"
  _filelist="{${_filelist/^,/}}"
  if [ ${#_filelist} -gt 100000 ] 
  then 
    grep -v "^${1}=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
    _nchunk=50000
    _ccount=0 
    echo -n "${1}=" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
    while [ ${_ccount} -lt ${#_filelist} ]
    do 
      echo -n "${_filelist:${_ccount}:${_nchunk}}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
      _ccount=$((_ccount+_nchunk))
    done 
  else 
    grep -v "^${1}=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt | \
      awk -v name="${1}" -v list="${_filelist}" '{ print $0 } END { print name "=" list }' \
      > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
  fi 
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
}
#}}}

#Rename a datablock element {{{
function _rename_blockitem { 
  #Get the variables
  _seen=0
  #Parse the oldname 
  oldname=${1%%=*}
  oldname=`_parse_blockvars ${oldname}`
  #Check if the oldname is in the block 
  _val=`_read_datablock ${oldname}`
  #If the item is there 
  if [ "${_val}" == "" ]
  then 
    _message "@RED@ - ERROR! The requested data block to rename (${oldname}) does not exist in the data block!@DEF@\n"
    exit 1 
  fi 
  #Write it the item with a new name 
  _fileend=${_val##*=}
  newname=${2%%=*}
  newname=`_parse_blockvars ${newname}`
  #Add the new name and remove the oldname elements
  if [ ${#_fileend} -gt 100000 ] 
  then 
    grep -v "^${oldname}=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
    _nchunk=50000
    _ccount=0 
    echo -n "${newname}=" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
    while [ ${_ccount} -lt ${#_fileend} ]
    do 
      echo -n "${_fileend:${_ccount}:${_nchunk}}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
      _ccount=$((_ccount+_nchunk))
    done 
  else 
    grep -v "^${oldname}=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt | \
      awk -v name="${newname}" -v list="${_fileend}" '{ print $0 } END { print name "=" list }' \
      > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
  fi
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  if [ "$3" == "" ]
  then 
    #Move the actual block contents 
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname} ]
    then 
      if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${newname} ] 
      then 
        mv -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${newname}
      else 
        #rm -f  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${newname}/*
        find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${newname}/ -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
        mv -f  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname}/* @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${newname}/
        rmdir  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname}
      fi 
    fi 
  fi 
}
#}}}

#Export a datablock element {{{
function _export_blockitem { 
  #Get the block and target names 
  oldname=${1%%=*}
  oldname=`_parse_blockvars ${oldname}`
  newname=${2%%=*}
  newname=`_parse_blockvars ${newname}`
  #Check if the oldname is in the block 
  _val=`_read_datablock ${oldname}`
  if [ "${_val}" == "" ]
  then 
    _message "@RED@ - ERROR! The requested data block to export (${oldname}) does not exist in the data block?!@DEF@\n"
    exit 1 
  fi 
  #If this is not a test 
  if [ "$3" == "" ]
  then 
    #Copy the contents 
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname} ]
    then 
      if [ ! -d @RUNROOT@/@STORAGEPATH@/${newname} ] 
      then 
        rsync -atvL @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname} @RUNROOT@/@STORAGEPATH@/${newname} 2>&1 > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IOlog.txt
      else 
        #Try to add a number to the end of the folder name... 
        copied=FALSE
        for i in `seq 100`
        do 
          if [ ! -d @RUNROOT@/@STORAGEPATH@/${newname}_${i} ] 
          then 
            rsync -atvL @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname} @RUNROOT@/@STORAGEPATH@/${newname}_${i} 2>&1 > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IOlog.txt
            copied=TRUE
            break
          fi 
        done 
        if [ "${copied}" == "FALSE" ]
        then 
          _message "@RED@ - ERROR! The requested data block to export (@DEF@${oldname}@RED@) could not be exported because the requested folder (@DEF@${newname}@RED@) could not be created (even with 100 attempts at unique endings)?!@DEF@\n"
           exit 1 
        fi 
      fi 
    fi 
  fi 
}
#}}}

#Delete a datablock element {{{
function _delete_blockitem { 
  #Get the block element name 
  oldname=${1%%=*}
  oldname=`_parse_blockvars ${oldname}`
  #Check if the oldname is in the block 
  _val=`_read_datablock ${oldname}`
  if [ "${_val}" == "" ]
  then 
    _message "@RED@ - ERROR! The requested data block to delete (${oldname}) does not exist in the data block!@DEF@\n"
    exit 1 
  fi 
  #update the block file 
  grep -v "^${oldname}=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt | \
    awk '{ print $0 }' \
    > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block_$$.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/block.txt
  #If this isn't a test, delete the folder 
  if [ "$2" == "" ]
  then 
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname} ]
    then 
      find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname}/ -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
      rmdir  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${oldname}
    fi 
  fi 
}
#}}}

#Read the datahead {{{
function _read_datahead { 
  #Read the data head entries 
  _outhead=''
  while read item contents 
  do 
    #Check if we have reached the BLOCK yet
    if [ "$item" == "BLOCK:" ] 
    then 
      break
    fi 
    #If we're still in the HEAD, go to the next line 
    if [ "${item}" == "HEAD:" ]
    then 
      continue 
    fi 
    #Add the contents to the output block 
    _outhead="${_outhead} ${item} ${contents}"
  done < @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  #_message "#${_outhead}#"
  #_outhead=`echo ${_outhead} | sed 's/ /\n/g' | sort | uniq | xargs echo`
  #_outhead=`echo ${_outhead} | sed 's/ /\n/g' | xargs echo`
  _outhead=`echo ${_outhead} | sed 's/ /\n/g' `
  #_message "#${_outhead}#"
  echo ${_outhead}
}
#}}}

#Write the datahead {{{
#function _add_datahead { 
function _add_datahead { 
  _name=`_parse_blockvars ${1}`
  #If the request is for nothing
  if [ "${_name}" == "" ] 
  then 
    #Clear the datahead {{{
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    #Remove any datahead files 
    #rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/*
    find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
    #}}}
  else 
    #Copy the requested data to the datahead {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_name}/ ] 
    then 
      _message "@RED@ - ERROR! The requested data block component ${_name} does not have a folder in the data block?!"
      exit 1 
    fi 
    #If the directory is empty {{{
    if [ ! "$(ls -A @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_name})" ]
    then 
      _message "@RED@ - ERROR! The requested data block component ${_name} is empty?!"
      exit 1 
    fi 
    #}}}
    #Get the files in this data{{{
    _files=`_read_datablock ${_name}`
    _files=`_blockentry_to_filelist ${_files}`
    #}}}
    #remove the data in the datahead that we aren't going to use {{{
    if [ -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD ]
    then 
      _headfiles=`_read_datahead`
      #For each file in the DATAHEAD {{{
      for hfile in ${_headfiles}
      do 
        #Check for a matching file in the block object 
        found="FALSE"
        for file in ${_files}
        do 
          #If there is a matching file 
          if [ "${hfile}" == "${file}" ]
          then 
            #If there is a matching file, log and break 
            found="TRUE"
            break 
          fi 
        done 
        #If not found, delete
        if [ "${found}" == "FALSE" ] 
        then 
          #Delete the file 
          rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${hfile}
        fi 
      done 
      #}}}
      ## Old method: delete everything! {{{
      #dir=`pwd`
      #cd @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD
      #rm -fr ./*.*
      #cd $dir
      #}}}
    fi 
    #}}}
    #Copy the requested data to the datahead, if the directory contains anything {{{
    if [ "$(ls -A @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_name})" ] 
    then 
      _message " @BLU@>@DEF@ ${_name} @BLU@-->@DEF@ DATAHEAD:\n"
      #Copy the files one-by-one (to ensure that there isn't accidental use of datablock waste...)
      #For each file in the block element {{{
      count=0
      nfiles=`echo ${_files} | awk '{print NF}'`
      _printstr=''
      for file in ${_files}
      do 
        count=$((count+1))
        #Notify 
        _message "\r${_printstr//?/ }\r"
        _printstr=" @RED@  (`date +'%a %H:%M'`)@BLU@ -->@DEF@ ${file##*/}@BLU@ (${count}/${nfiles})"
        _message "${_printstr}"
        #Copy the file (will skip if file exists and is unchanged)
        rsync -atv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_name}/${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ 2>&1 > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IOlog.txt
      done 
      #}}}
      _message "\n @BLU@>@DEF@ ${_name} @BLU@-->@DEF@ DATAHEAD@BLU@ Done!@DEF@\n"
    fi 
    #Update the datablock txt file 
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    for _file in ${_files} 
    do 
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    done 
    #}}}
    #}}}
  fi 
}
#}}}

#Replace an item in the datahead {{{
function _replace_datahead { 
  #Current head 
  _head=`_read_datahead`
  #Number of head files 
  _nheadfile=`echo ${_head} | awk '{print NF}'` 
  #Number of input files 
  _ninfile=`echo ${1} | awk '{print NF}'` 
  #Number of output files 
  _noutfile=`echo ${2} | awk '{print NF}'` 
  #Make output list 
  _outlist=''
  for _newfile in ${2} 
  do 
    #Strip file paths from outlst 
    _outlist="${_outlist} ${_newfile##*/}" 
  done 
  #For each input file 
  for _infile in ${1} 
  do
    #Check if the file exists in the datahead 
    _nmatchhead=`grep -c ${_infile##*/} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt || echo -n ` 
    if [ ${_nmatchhead} -eq 0 ] 
    then 
      #This file is not in the datahead?! 
      continue 
    fi 
    #Check if the file exists in the output list 
    _nmatchout=`echo ${2} | grep -c ${_infile##*/} || echo -n `
    if [ ${_nmatchout} -ne 0 ]
    then 
      #Don't delete the new file!
      >&2 echo "name unchanged ${_infile##*/}"
    else 
      #Replace this file in the datahead
      if [ ${_noutfile} -eq 1 ] 
      then 
        >&2 echo "replacing ${_infile##*/} -> ${_outlist}"
      elif [ ${_noutfile} -gt 1 ] 
      then 
        >&2 echo "replacing ${_infile##*/} by multiple files" 
      else 
        >&2 echo "deleting ${_infile##*/}" 
      fi 
      #Remove the old file(s)
      rm -f ${_infile} 
    fi 
    #Only update the head if this is a one-to-many replacement 
    if [ ${_ninfile} -eq 1 ] 
    then 
      #This is a one-to-many replacement: add new files to the head.txt 
      _outlist=`echo ${_outlist}`
      @P_SED_INPLACE@ "s#${_infile##*/}#${_outlist// /\\n}#g" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    fi 
  done 
  if [ ${_ninfile} -gt 1 ]
  then 
    if [ ${_ninfile} -ne ${_nheadfile} ] 
    then 
      >&2 echo "_replace_datahead only works with one-to-many replacements OR ALLHEAD-to-ALLHEAD replacement! ${_ninfile} != ${_nheadfile} or 1"
      exit 1 
    fi 
    #This is a many-to-many replacement: write all new files to the head.txt 
    _outlist=`echo ${_outlist}`
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    echo -e "${_outlist// /\\n}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  fi 
}
#}}}

#Write an item (including NULL/clear) to the datahead {{{
function _write_datahead { 
  if [ "${1}" == "" ] 
  then 
    #Clear the datahead 
    echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
    #Remove any datahead files 
    find @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD -mindepth 1 -maxdepth 1 -print0 | xargs -0 rm -f 2> /dev/null || echo "Ignoring attempted directory removal"
  else 
    #Check if the requested item exists in the datablock
    _val=`_read_datablock ${1}`
    if [ "${_val}" == "" ]
    then 
      _message "@RED@ - ERROR! The requested data block component ${1} does not have a folder in the data block?!"
      exit 1 
    fi 
    #Add the new item 
    echo "${2}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  fi 
}
#}}}

#Write a list of items to the datahead {{{
function _writelist_datahead { 
  _head="${1}"
  #Update the datablock txt file 
  echo "HEAD:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  for _file in ${_head} 
  do 
    #Print the existing datahead items 
    echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/head.txt
  done 
}
#}}}

#Add item to datablock {{{
function _add_datablock { 
  #Check if the folder name contains a block variable 
  _targetblock=`_parse_blockvars ${1}`
  #Add the folder to the datablock 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_targetblock}/ ] 
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_targetblock}/
  fi 
  #Get the file designation 
  _filelist=""
  for _file in $2
  do 
    _file=${_file##*/}
    _filelist="$_filelist $_file"
  done 
  #Copy the data to the block 
  if [ "$_filelist" != "" ] 
  then 
    count=0
    nfiles=`echo $2 | awk '{print NF}'`
    _printstr=''
    for _file in $2
    do 
      count=$((count+1))
      if [ -e "$_file" ]
      then 
        #_message " @BLU@>@DEF@ ${_file##*/} @BLU@-->@DEF@ ${_targetblock}"
        _message "\r${_printstr//?/ }\r"
        _printstr=" @RED@  (`date +'%a %H:%M'`)@BLU@ -->@DEF@ ${_file##*/}@BLU@ (${count}/${nfiles})"
        _message "${_printstr}"
        rsync -atv --copy-unsafe-links $_file @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_targetblock}/${_file##*/} 2>&1 > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IOlog.txt
        #_message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      fi 
    done 
    _message "\n @BLU@>@DEF@ DATAHEAD @BLU@-->@DEF@ ${_targetblock}@BLU@ Done!@DEF@\n"
  fi 
  #Add item to datablock list 
  _write_datablock $1 "`echo ${_filelist}`"
}
#}}}

# Write the datahead to a new block entry {{{ 
function _add_head_to_block {
  #Get the requested block name 
  _name=${1}
  #Check if the folder name contains a block variable 
  _name=`_parse_blockvars ${_name}`
  #Get the current datahead 
  _head=`_read_datahead` 
  _itemlist=""
  #Append the full path to head entries 
  for item in ${_head}
  do 
    _itemlist="${_itemlist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item}"
  done 
  #>&2 echo ${_itemlist}
  #Add the datahead entries to the block 
  _add_datablock ${_name} "${_itemlist}"
}
#}}}

#Read the blockvars {{{
function _read_blockvars { 
  #Read the data block variables
  vars=0
  _req=${1}
  #Check if the folder name contains a block variable 
  if [ "${_req}" != "" ] 
  then 
    #>&2 echo "read req: ${_req}"
    _req=`_parse_blockvars ${_req}`
    #>&2 echo "after parse: ${_req}"
  fi 
  _outvars=''
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt ]
  then 
    while read item
    do 
      #Check if we have reached the VARS yet
      if [ "$item" == "VARS:" ] 
      then 
        vars=1
        continue
      fi 
      #If we're still in the HEAD or BLOCK, go to the next line 
      if [ "${vars}" == 0 ]
      then 
        continue 
      fi 
      if [ "${_req}" == "" ] 
      then 
        #Add the contents to the output 
        _outvars="${_outvars} ${item}"
      elif [ "${item%%=*}" == "${_req}" ]
      then 
        #Add the contents to the output 
        _outvars="${_outvars} ${item}"
      fi 
    done < @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
  fi 
  echo ${_outvars}
}
#}}}

#Parse a block variable in a string {{{
function _parse_blockvars {
  _outlist=''
  while [ $# -ge 1 ]
  do 
    string=$1
    #If this string contains a block variable reference 
    count=0
    while [[ ${string} =~ "@BV:".*."@" ]]
    do 
      #>&2 echo ${string}
      #Pull out the block variable
      _var=${string#*@BV:}
      _var=${_var%%@*}
      #The variable assignment is a reference: assign the referred value 
      _filelist=`_read_blockvars ${_var}`
      _baklist=${_filelist}
      #Remove variable name and brackets 
      _filelist=${_filelist#*=}
      _prompt=${_filelist#\{}
      _prompt=${_prompt%\}}
      _prompt=${_prompt//,/ }
      #Incorporate the block variable 
      if [ "${_prompt}" == "" ] 
      then 
        #If not defined, maintain the BV string
        #>&2 echo "!${_var} NOT FOUND IN BLOCK!" 
        #>&2 echo "(${string})" 
        #>&2 echo "[${_baklist}]" 
        #>&2 echo "{${_filelist}}" 
        _filelist="@BV:${_var}@"
        #exit 1 
        break
      else 
        #If defined, maintain the BV string
        _filelist=`echo ${_prompt}`
        ##Prompt about the update
        #>&2 echo "${_var} -> ${_prompt}" 
      fi 
      #Loop over variable values (i.e. allow for block variable to contain multiple entries)
      if [[ ${string} =~ ",@BV:${_var}@" ]] || [[ ${string} =~ "@BV:${_var}@," ]]
      then 
        #Do not vectorise substitution 
        outstring="${string/@BV:${_var}@/${_filelist}}"
      else 
        #Vectorise the substitution 
        outstring=''
        for _value in ${_filelist}
        do 
          outstring="${outstring} ${string/@BV:${_var}@/${_value}}"
        done 
      fi 
      string=`echo ${outstring//\"/}`
      string=`echo ${string//\'/}`
      count=$((count+1))
      if [ ${count} -gt 10 ]
      then 
         _message "@RED@ERROR: VARIABLE PARSE IS RECURSIVE:@BLU@${string} @DEF@"
        #exit 1 
        break
      fi 
    done 
    string="${string//,/ }"
    _outlist="${_outlist} ${string}"
    shift 
  done 
  echo ${_outlist}
}
#}}}

#Write the blockvars {{{
function _write_blockvars { 
  #Get the variables 
  inp=$2
  if [[ "$2" =~ "@BV:".*."@" ]]
  then 
    inp=`_parse_blockvars ${2}` 
    if [ "$2" != "${inp}" ]
    then 
      echo -n " -> #${inp}#"
    fi 
  fi 
  if [ "${inp:0:4}" == "@DB:" ]
  then 
    #The variable assignment is a reference: assign the referred value 
    _target=${inp:4}
    _target=${_target%@}
    _filelist=`_read_datablock ${_target}`
    #Remove variable name and brackets 
    _filelist=${_filelist#*=}
    _prompt=${_filelist#\{}
    _prompt=${_prompt%\}}
    _prompt=${_prompt//,/ }
    if [ "${_prompt}" == "" ] || [ "${_prompt}" == "@BV:${_target}@" ]
    then 
      _filelist="{${inp// /,}}"
    else 
      if [ "${inp:0:4}" == "@DB:" ] 
      then 
        #Make full file paths from block files 
        _filelist=''
        for _file in ${_prompt}
        do 
          _filelist="${_filelist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${_target}/${_file}"
        done 
        _prompt=`echo ${_filelist}`
        _filelist="${_filelist// /,}"
        _filelist="{${_filelist/^,/}}"
      fi 
      #Prompt about the update
      echo -n " -> #${_prompt}#"
    fi 
  else  
    #Add what we want to write
    _filelist="${inp// /,}"
    _filelist="{${_filelist/^,/}}"
  fi 
  #Update the VARS items 
  grep -v "^${1}=" @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt | \
    awk -v name="${1}" -v list="${_filelist}" '{ print $0 } END { print name "=" list }' \
    > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars_$$.txt
  mv @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars_$$.txt @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
}
#}}}

#Write the blockvars {{{
function _write_blockvars_old { 
  #Get the variables 
  _vars=`_read_blockvars`
  if [ "${2:0:4}" == "@BV:" ] 
  then 
    #The variable assignment is a reference: assign the referred value 
    _target=${2:4}
    _target=${_target%@}
    _filelist=`_read_blockvars ${_target}`
    #Remove variable name and brackets 
    _filelist=${_filelist#*=}
    _prompt=${_filelist#\{}
    _prompt=${_prompt%\}}
    _prompt=${_prompt//,/ }
    if [ "${_prompt}" == "" ] || [ "${_prompt}" == "@BV:${target}@" ]
    then 
      _filelist="{${2// /,}}"
    else 
      #Prompt about the update
      echo -n " -> #${_prompt}#"
    fi 
  else  
    #Add what we want to write
    _filelist="{${2// /,}}"
  fi 
  #Update the VARS items 
  echo "VARS:" > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
  echo "${1}=${_filelist}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
  #For each var row:
  for _file in ${_vars} 
  do 
    #If the item isn't what we want to add/write
    if [ "${_file%%=*}" != "${1%%=*}" ]
    then 
      #Write it 
      _file=`echo $_file`
      echo "${_file}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vars.txt
    fi
  done
}
#}}}

# Check whether item 1 is in the blockvars {{{
function _check_blockvar { 
  #Item to check 
  _data=$1
  #Blockvars
  _block=`_read_blockvars`
  #Check whether the requested data object is in the datablock 
  #echo " ${_block} " | grep -c " ${_data}=" | xargs echo || echo 
  present=`echo " ${_block} " | grep -c " ${_data}=" || echo` 
  if [ "${present}" == 1 ] 
  then 
    #>&2 echo -n "Check if ${_data}={@BV:${_data}@}"
    _default=`echo " ${_block} " | grep -c " ${_data}={@BV:${_data}@}" || echo`
    if [ "${_default}" == 1 ]
    then 
      #>&2 echo " - YES!"
      present=0
    #else 
    #  >&2 echo " - No"
    fi 
  fi 
  #>&2 echo "${_data} : ${present} : ${default}"
  echo ${present}
}
#}}}

# Check whether item 1 is in the datablock {{{
function _inblock { 
  #Item to check 
  _data=$1
  if [ "${_data}" == "DATAHEAD" ] || [ "${_data}" == "ALLHEAD" ]
  then 
    #Current datahead
    _head=`_read_datahead`
    if [ "${_head}" == "" ]
    then 
      #Datahead isn't defined: Error 
      echo 0
    else 
      echo 1
    fi 
  else
    #Current datablock 
    _block=`_read_datablock`
    #Check whether the requested data object is in the datablock 
    #echo " ${_block} " | grep -c " ${_data}=" | xargs echo || echo 
    echo " ${_block} " | grep -c " ${_data}="  || echo 
  fi 
}
#}}}

# Check whether the script uses the datahead {{{
function _uses_datahead { 
  #Item to check 
  _inputs=`_inp_data`
  _uses_datahead=""
  for _inp in ${_inputs}
  do 
    if [ "${_inp}" == "DATAHEAD" ]
    then 
      _uses_datahead="USES_DATAHEAD"
    elif [ "${_inp}" == "ALLHEAD" ]
    then 
      _uses_datahead="USES_ALLHEAD"
    fi 
  done
  echo ${_uses_datahead}
}
#}}}

#Convert a block entry into a filelist {{{
function _blockentry_to_filelist { 
  _term=${1##*=}
  _term=${_term//\{/}
  _term=${_term//\}/}
  _term=${_term//,/ }
  echo ${_term}
}
#}}}

# incorporate the current datablock/head into a script {{{ 
function _incorporate_datablock { 
  #Read the current datahead
  _head=`_read_datahead`
  #Read the current datablock 
  _block=`_read_datablock`
  #Read the current blockvars
  _vars=`_read_blockvars`
  ext=${1##*.}
  #If needed, back up the original file 
  if [ ! -f ${1//.${ext}/_noblock.${ext}} ]
  then 
    cp ${1} ${1//.${ext}/_noblock.${ext}}
  fi 

  #Reset the file to the pre-block state 
  #(for cases where someone runs the pipeline twice in a row)
  cp ${1//.${ext}/_noblock.${ext}} ${1//.${ext}/_prehead.${ext}}

  #Update the script to include the datablock {{{
  #nloop=0
  #while [ "`grep -c @DB: ${1//.${ext}/_prehead.${ext}} || echo`" != "0" ]
  #do 
    for item in ${_block}
    do 
      #Extract the name of the item
      base=${item%%=*}
      #Remove leading and trailing braces
      item=${item/\{,/\{}
      item=${item/\{/}
      item=${item%\}}
      #Add spaces
      item=${item//,/ }
      #Loop through entries 
      _itemlist=''
      for _file in ${item}
      do 
        #2>&1 echo -n "${#_itemlist}    \r "
        #Add full file paths 
        _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${base}/${_file#*=}
        _itemlist="${_itemlist} ${_itemfile}"
      done 
      #_itemlist=`echo ${_itemlist}`
      _nchunk=50000
      if [ ${#_itemlist} -gt ${_nchunk} ] 
      then 
        #>&2 echo -n "In chunks:"
        _ccount=0
        while [ ${_ccount} -lt ${#_itemlist} ]
        do 
          #>&2 echo -n '.'
          @P_SED_INPLACE@ "s#\\@DB:${item%%=*}\\@#${_itemlist:${_ccount}:${_nchunk}}\\@DB:${item%%=*}\\@#g" ${1//.${ext}/_prehead.${ext}}
          _ccount=$((_ccount+_nchunk))
        done 
        @P_SED_INPLACE@ "s#\\@DB:${item%%=*}\\@##g" ${1//.${ext}/_prehead.${ext}}
        #>&2 echo ' - Done'
      else 
        #>&2 echo "All at once"
        @P_SED_INPLACE@ "s#\\@DB:${item%%=*}\\@#${_itemlist:1}#g" ${1//.${ext}/_prehead.${ext}}
      fi 
    done 
    #((nloop+=1))
    #if [ ${nloop} -gt 100 ]
    #then 
    #  _message "@RED@ - ERROR! Infinite loop in block incorporation! A @DB:*@ variable is recursive?!@DEF@\n"
    #  exit 1 
    #fi 
  #done 
  #}}}

  #Update the script to include the blockvars {{{
  nloop=0
  while [ "`grep -v "^#" ${1//.${ext}/_prehead.${ext}} | grep -c @BV: || echo`" != "0" ]
  do 
    for item in ${_vars}
    do 
      #Extract the name of the item
      base=${item%%=*}
      #Remove leading and trailing braces
      item=${item/\{,/\{}
      item=${item/\{/}
      item=${item%\}}
      #Add spaces
      item=${item//,/ }
      #Loop through entries 
      _itemlist=''
      for _file in ${item}
      do 
        #Return variable 
        _itemfile="${_file#*=}"
        _itemfile="${_itemfile//&/\\&}"
        _itemlist="${_itemlist} ${_itemfile}"
      done 
      #_itemlist=`echo ${_itemlist}`
      @P_SED_INPLACE@ "s#\\@BV:${item%%=*}\\@#${_itemlist:1}#g" ${1//.${ext}/_prehead.${ext}}
    done 
    ((nloop+=1))
    if [ ${nloop} -gt 100 ]
    then 
      _message "@RED@ ERROR! Infinite loop in block variable incorporation for script @DEF@${1//.${ext}}@RED@!\nA @BV:*@ variable must be missing or recursive?!@DEF@\n"
      exit 1 
    fi 
  done
  #}}}

  #If we do not have a CosmoSIS file {{{
  if [ "${ext}" != "ini" ] 
  then 
    #Insert the startup code {{{
    cat > ${1} <<- EOF
		
		#Source the Script Documentation Functions {{{
		source @RUNROOT@/@MANUALPATH@/CosmoPipe.man.sh
		_initialise
		#}}}
		
		EOF
    #}}}
  fi
  #}}}

  ##Check that we have valid DATAHEAD use {{{
  #if [ "${ext}" != "ini" ] && [ "$2" == "USES_DATAHEAD" ]
  #then 
  #  _message "- @RED@ERROR\n"
  #  _message "Cannot use datahead with cosmosis input files\n"
  #  _message "@DEF -->$1\n"
  #  exit 1
  #fi 
  ##}}}

  #Check if we are stoelzner {{{
  if [ `whoami` == 'qwright' ] || [ `whoami` == 'stoelzner' ]
  then 
    if [ "${ext}" != "ini" ] && [ $(( ( RANDOM % 100 )  + 1 )) -gt 99 ] 
    then 
      echo '# Check if benjamin has had his coffee ----' >> ${1}
      echo '_message "\n\n@RED@~~~~~~~~~~~~~~~~~~~~~~~~~~~@DEF@\n"' >> ${1}
      echo '_message "@RED@~~   @BLU@ HEY! LISTEN!!!! @RED@   ~~\n"' >> ${1}
      echo '_message "@RED@~~~~~~~~~~~~~~~~~~~~~~~~~~~@DEF@\n\n"' >>${1}
      echo 'sleep 5' >> ${1}
      echo '_message "@RED@Have you had your coffee?!!\n\n"' >> ${1}
      echo 'sleep 5' >> ${1}
      echo '_message "@BLU@  If not: @DEF@GO GET IT NOW! \n"' >> ${1}
      echo 'sleep 30' >> ${1}
      echo '_message "@BLU@ Good. Now we can continue...\n@DEF@"' >> ${1}
      echo "# ----" >> ${1}
    elif [ "${ext}" != "ini" ] && [ $(( ( RANDOM % 100 )  + 1 )) -gt 99 ] 
    then 
      echo "# Ensure that Benjamin is taken care of <3 ----" >> ${1}
      echo "_message \"\n\n@RED@#####################################@DEF@\n\"" >> ${1}
      echo "_message \"@RED@#####################################@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##    @DEF@ IT'S  DANGEROUS  TO  GO @RED@    ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##    @DEF@    ALONE!  TAKE  THIS.  @RED@    ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@           {             @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@        {   }{   }       @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@         } {  } {        @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@      .-{\\\`}\\\`}{\\\`\\\`}-.       @RED@    ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     (   } {   {   )     @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |\\\`-.._____..-'|     @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             ;--.  @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |            (__  \\ @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             | )  )@RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             |/  / @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |             /  /  @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     |            (  /   @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@     \\             y'    @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##   @BLU@      \\\`-.._____..-'      @RED@     ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@##                                 ##@DEF@\n\"" >> ${1}
      echo "_message \"@RED@#####################################@DEF@\n\"" >> ${1}
      echo "_message \"@RED@#####################################@DEF@\n\"" >> ${1}
      echo 'sleep 30' >> ${1}
      echo "# ----" >> ${1}
    fi 
  fi 
  #}}}

  #Generate main code block:  
  #Does the code work on DATAHEAD?
  if [ "$2" == "USES_DATAHEAD" ] 
  then 
    #Add code for each file in DATAHEAD {{{
    for item in ${_head} 
    do 
      echo '# ----' >> ${1}
      _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item/=/\/}
      sed "s#\\@DB:DATAHEAD\\@#${_itemfile}#g" ${1//.${ext}/_prehead.${ext}} >> ${1}
      echo '# ----' >> ${1}
    done 
    #}}}
  elif [ "$2" == "USES_ALLHEAD" ] 
  then 
    #Add code for all files in DATAHEAD together {{{
    _itemlist=''
    for item in ${_head} 
    do 
      _itemfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${item/=/\/}
      _itemlist="${_itemlist} ${_itemfile}"
    done 
    #_itemlist=`echo ${_itemlist}`
    #sed "s#\\@DB:ALLHEAD\\@#${_itemlist}#g" ${1//.${ext}/_prehead.${ext}} >> ${1}
    _nchunk=50000
    if [ ${#_itemlist} -gt ${_nchunk} ] 
    then 
      #>&2 echo -n "In chunks:"
      _ccount=0
      cat ${1//.${ext}/_prehead.${ext}} >> ${1} 
      while [ ${_ccount} -lt ${#_itemlist} ]
      do 
        #>&2 echo -n '.'
        @P_SED_INPLACE@ "s#\\@DB:ALLHEAD\\@#${_itemlist:${_ccount}:${_nchunk}}\\@DB:ALLHEAD\\@#g" ${1}
        _ccount=$((_ccount+_nchunk))
      done 
      @P_SED_INPLACE@ "s#\\@DB:ALLHEAD\\@##g" ${1} 
      #>&2 echo ' - Done'
    else 
      #>&2 echo "All at once"
      sed "s#\\@DB:ALLHEAD\\@#${_itemlist:1}#g" ${1//.${ext}/_prehead.${ext}} >> ${1}
    fi 
    #}}}
  else 
    #The code doesn't work on DATAHEAD, so just run it: {{{
    cat ${1//.${ext}/_prehead.${ext}} >> ${1}
    #}}}
  fi 

  #If we do not have a CosmoSIS file {{{
  if [ "${ext}" != "ini" ] 
  then 
    #Insert the finalisation code {{{
    cat >> ${1} <<- EOF
		
		#Finalise {{{
		_finalise
		#}}}
		
		EOF
    #}}}
  fi
  #}}}

}
#}}}

#}}}

