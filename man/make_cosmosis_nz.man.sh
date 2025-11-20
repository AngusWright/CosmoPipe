#
# make_cosmosis_nz.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@========================================@DEF@\n"
    _message "@BLU@== @RED@ Running make_cosmosis_nz.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@========================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Construct an Nz file in the format expected by '
  echo '# cosmosis'
  echo "#"
  echo "# Function takes input data:"
  echo "# `_inp_data`"
  echo "#"
}
#}}}

# Abort Message {{{
_abort()
{
  #Message to print when script aborts 
  #$0 is the script that was running when this error occurred
  _message "@BLU@ An error occured while running:\n@DEF@$0.\n" >&2
  _message "@BLU@ Check the logging file for this step in:\n" >&2
  _message "@DEF@@RUNROOT@/@LOGPATH@/\n" >&2
  exit 1
}
trap '_abort' 0
set -e 
#}}}

# Input variables {{{ 
function _inp_var { 
  #Variable inputs (leave blank if none)
  echo ALLPATCH BLU BV:TOMOLIMS BV:TOMOLIMS DATABLOCK DEF BV:PATCHLIST PYTHON3BIN RED RUNROOT SCRIPTPATH STORAGEPATH
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  outlist=''
  #input is dynamic, depending on the value of BV:COSMOSIS_PATCHLIST
  patchvar="@BV:COSMOSIS_PATCHLIST@"
  patchvar=`_parse_blockvars ${patchvar}`
  #Define the patches to loop over {{{
  if [ "${patchvar}" == "ALL" ]
  then 
    patchlist=`echo @PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb` 
  else 
    patchlist="${patchvar}"
  fi 
  #}}}
  for patch in ${patchlist}
  do 
    #>&2 echo ${patch}
    outlist="${outlist} cosmosis_neff_source_${patch/comb/} nz_${patch/comb/} cosmosis_npair_${patch}"
  done 
  echo ${outlist}
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  outlist=''
  for patch in @PATCHLIST@ @ALLPATCH@ 
  do 
    outlist="${outlist} cosmosis_nz_${patch}"
  done 
  echo ${outlist}
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/make_cosmosis_nz.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

