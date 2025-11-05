#
# calc_gt_treecorr.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@==========================================@DEF@\n"
    _message "@BLU@== @RED@ Running calc_gt_w_treecorr.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@==========================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Compute galaxy-galaxy lensing correlation function patch-wise for all '
  echo '# catalogues in the DATAHEAD for sources '
  echo '# and lens catalogues specified in the pipeline/variables.sh '
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
  echo ALLPATCH BINNING BLU BV:BINSLOPNG BV:BINSLOPNN BV:DECNAME BV:E1NAME BV:E2NAME BV:LENSDECNAME BV:LENSRANAME BV:LENSWEIGHTNAME BV:LENS_CATS BV:NLENSBINS BV:NTHETABINGT BV:NTHREADS BV:PATCHLIST BV:PATCH_CENTERFILE BV:RANAME BV:RANDDECNAME BV:RANDRANAME BV:RAND_CATS BV:THETAMAXGT BV:THETAMINGT BV:TOMOLIMS BV:WEIGHTNAME DATABLOCK DEF PYTHON3BIN RED RUNROOT SCRIPTPATH STORAGEPATH
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo ALLHEAD lens_cats rand_cats
}
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  echo gt jackknife_cov_gt
}
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/calc_gt_w_treecorr.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

