#
# neff_sigmae.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@===================================@DEF@\n"
    _message "@BLU@== @RED@ Running neff_sigmae.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@===================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Compute neff and sigmae for all catalogues in '
  echo '# DATAHEAD'
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
  list=''
  patchvar="@BV:PATCHLIST@"
  patchvar=`_parse_blockvars ${patchvar}`
  for patch in ${patchvar} @ALLPATCH@ 
  do 
    list="${list} BV:SURVEYAREA_${patch}"
  done
  echo ALLPATCH BLU BV:BLIND BV:E1NAME BV:E2NAME BV:WEIGHTNAME DATABLOCK DEF BV:PATCHLIST PYTHON3BIN RED RUNROOT SCRIPTPATH STORAGEPATH ${list}
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  outlist=''
  for patch in @BV:PATCHLIST@ @ALLPATCH@ 
  do 
    outlist="${outlist} mbias_${patch}_@BV:BLIND@"
  done 
  echo ALLHEAD ${outlist}
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  outlist=''
  for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do 
    outlist="${outlist} cov_inp_${patch}_@BV:BLIND@ neff_${patch}_@BV:BLIND@ sigmae_${patch}_@BV:BLIND@" 
  done 
  echo ${outlist}
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/neff_sigmae.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

