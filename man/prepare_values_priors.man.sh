#
# prepare_values_priors.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@=============================================@DEF@\n"
    _message "@BLU@== @RED@ Running prepare_values_priors.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@=============================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Construct cosmosis values and prior files'
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
  echo BLU BV:BOLTZMAN BV:IAMODEL BV:PRIOR_A1 BV:PRIOR_A2 BV:PRIOR_ABARY BV:PRIOR_AIA BV:PRIOR_ALPHA1 BV:PRIOR_ALPHA2 BV:PRIOR_A_IA BV:PRIOR_A_PIV BV:PRIOR_BIAS_TA BV:PRIOR_B_IA BV:PRIOR_F_R_1 BV:PRIOR_F_R_2 BV:PRIOR_F_R_3 BV:PRIOR_F_R_4 BV:PRIOR_F_R_5 BV:PRIOR_F_R_6 BV:PRIOR_H0 BV:PRIOR_LOG10_M_PIV BV:PRIOR_LOGTAGN BV:PRIOR_MNU BV:PRIOR_NS BV:PRIOR_OMBH2 BV:PRIOR_OMCH2 BV:PRIOR_OMEGAK BV:PRIOR_S8INPUT BV:PRIOR_W BV:PRIOR_WA BV:PRIOR_Z_PIV BV:TOMOLIMS DATABLOCK DEF RED RUNROOT STORAGEPATH SURVEY
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  iamodel="@BV:IAMODEL@"
  iamodel=`_parse_blockvars ${iamodel}`
  if [ ${iamodel} == 'massdep' ]
  then 
    echo massdep_params_uncorr nzbias_uncorr
  else 
    echo nzbias_uncorr
  fi 
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  echo nzbias_uncorr cosmosis_inputs
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/prepare_values_priors.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

