#
# construct_som.man.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@=====================================@DEF@\n"
    _message "@BLU@== @RED@ Running construct_som.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@=====================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Construct a SOM with the SOM_DIR.R code from the '
  echo '# spectroscopic data in the spec_adapt data block '
  echo '# entry'
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
  echo BLU BV:ADDITIONALFLAGS BV:CALIBWEIGHTNAME BV:DATATHRESHOLD BV:NITER BV:NTHREADS BV:SOMDIM BV:SOMFEATURES BV:SPARSEFRAC BV:TOPOLOGY BV:TOROIDAL BV:UNWHITEN_FEATURES BV:ZPHOTNAME BV:ZSPECNAME DATABLOCK DEF P_RSCRIPT RED RUNROOT STORAGEPATH
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo DATAHEAD
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  echo DATAHEAD
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/construct_som.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

