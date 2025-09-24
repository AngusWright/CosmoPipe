#
# add_datavector.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@======================================@DEF@\n"
    _message "@BLU@== @RED@ Running add_datavector.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@======================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Add a pre-existing data vector to the data block'
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
  echo BV:INPUT_DATAVEC BV:STATISTIC DATABLOCK RUNROOT STORAGEPATH
} 
}
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo 
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  STATISTIC=@BV:STATISTIC@
  STATISTIC=`_parse_blockvars ${STATISTIC}`
  MODES=@BV:MODES@
  MODES=`_parse_blockvars ${MODES}`
  if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      output="cosebis_vec"
  #}}}
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      output="psi_stats_gm_vec"
  #}}}
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      output="psi_stats_gg_vec"
  #}}}
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      output="bandpowers_ee_vec"
  #}}}
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      output="bandpowers_ne_vec"
  #}}}
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      output="bandpowers_nn_vec"
  #}}}
  elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
  then
    output="xipm_vec"
  #}}}
  elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      output="xipm_vec"
  #}}}
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      output="gt_vec"
  #}}}
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      output="wt_vec"
  #}}}
  elif [ "${STATISTIC^^}" == "OBS" ] #{{{
  then
    output="obs_vec"
  fi
  #}}}
  echo ${output}
}
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/add_datavector.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

