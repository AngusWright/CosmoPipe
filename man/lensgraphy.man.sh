#
# lensgraphy.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@==================================@DEF@\n"
    _message "@BLU@== @RED@ Running lensgraphy.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@==================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Perform lens binning of the catalogue '
  echo '# currently at the top of the data block. The script'
  echo '#  takes the catalogue and applies the selection '
  echo '# given by LENSLIMSX and LENSLIMSY, creating N new catalogues on '
  echo '# the top of the data block.'
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
  echo BLU BV:STELLARMASS BV:REDSHIFT BV:LENSLIMSX BV:LENSLIMSY BV:SLICEIN BV:VOLUMELIMITED BV:STACKED_NZ BV:ZDEPERR BV:ZSIGMA BV:NZSTEP DEF PYTHON3BIN RED RUNROOT SCRIPTPATH STORAGEPATH DATABLOCK
}
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo fluxscale_corrected
}
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  echo lens_cats lens_cats_metadata rand_cats smf_lens_cats smf_lens_cats_metadata smf_rand_cats nz_lens nz_obs
}
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/lensgraphy.sh
}
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

