#
# Bmodes_pvalue.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@=====================================@DEF@\n"
    _message "@BLU@== @RED@ Running Bmodes_pvalue.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@=====================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Calculates p values for bmodes'
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
  echo BLINDING BV:BOLTZMAN BV:CHAINSUFFIX BV:MULT BV:STATISTIC BV:THETAMAXXI BV:THETAMINXI BV:TOMOLIMS PYTHON3BIN P_RSCRIPT RUNROOT SCRIPTPATH STORAGEPATH SURVEY
} 
#}}}
stat="BV:STATISTIC@"
# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo mcmc_inp_bandpowers mcmc_inp_cosebis mcmc_inp_xiB mcmc_inp_xiE
} 
    echo mcmc_inp_cosebis
  elif [ "${stat^^}" == "BANDPOWERS" ]
  then
    echo mcmc_inp_bandpowers
  fi
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  echo ''
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/Bmodes_pvalue.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

