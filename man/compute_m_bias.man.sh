#
# compute_m_bias.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@======================================@DEF@\n"
    _message "@BLU@== @RED@ Running compute_m_bias.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@======================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Compute the m bias for each DATAHEAD catalogue and'
  echo '#  its corresponding m surface'
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
  echo ALLPATCH BLU BV:BLIND BV:M1NAME BV:M2NAME BV:MBIASCORR BV:NTHREADS BV:PATCHLIST BV:RNAME BV:SNRNAME BV:TOMOLIMS BV:WEIGHTNAME DATABLOCK DEF PYTHON3BIN P_RSCRIPT RED RUNROOT RUNTIME SCRIPTPATH STORAGEPATH
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo ALLHEAD m_surface
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  if [ "@BLINDING@" != "UNBLIND" ] 
  then 
    blinding=_@BV:BLIND@
  else 
    blinding=
  fi 
  outlist=''
  for patch in @BV:PATCHLIST@ @ALLPATCH@ 
  do 
    outlist="${outlist} mbias_${patch}${blinding} mcov_${patch}${blinding}"
  done 
  echo DATAHEAD ${outlist}
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/compute_m_bias.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

