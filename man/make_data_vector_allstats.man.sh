#
# make_data_vector_allstats.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@============================================@DEF@\n"
    _message "@BLU@== @RED@ Running make_data_vector_allstats.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@============================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Constructs a cosebis and bandpower data vector '
  echo '# file for cosmosis'
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
  echo ALLPATCH BLU BV:MODES BV:NLENSBINS BV:PATCHLIST BV:STATISTIC BV:TOMOLIMS DATABLOCK DEF PYTHON3BIN RED RUNROOT SCRIPTPATH STORAGEPATH
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  #Input data vectors
  STATISTIC=`_parse_blockvars @BV:STATISTIC@`
  MODES=`_parse_blockvars @BV:MODES@`
  inputs=""
  if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      inputs="${inputs} cosebis"
    fi
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      inputs="${inputs} psi_stats_gm"
    fi
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      inputs="${inputs} psi_stats_gg"
    fi
  #}}}
  elif [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ] #{{{
  then
    inputs="${inputs} cosebis_dimless"
  #}}}
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      inputs="${inputs} bandpowers_ee"
    fi
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      inputs="${inputs} bandpowers_ne"
    fi
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      inputs="${inputs} bandpowers_nn"
    fi
  #}}}
  elif [ "${STATISTIC^^}" == "XIPSF" ] #{{{
  then
    inputs="${inputs} xipsf_binned"
  #}}}
  elif [ "${STATISTIC^^}" == "XIGPSF" ] #{{{
  then
    inputs="${inputs} xigpsf_binned"
  #}}}
  elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
  then
    inputs="${inputs} xipm_binned"
  #}}}
  elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      inputs="${inputs} xipm_binned"
    fi
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      inputs="${inputs} gt_binned"
    fi
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      inputs="${inputs} wt_binned"
    fi
  #}}}
  fi
  #}}}
  echo "$inputs mbias"
}
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  STATISTIC=`_parse_blockvars @BV:STATISTIC@`
  MODES=`_parse_blockvars @BV:MODES@`
  outputs=""
  if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      outputs="${outputs} cosebis"
    fi
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      outputs="${outputs} psi_stats_gm"
    fi
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      outputs="${outputs} psi_stats_gg"
    fi
  #}}}
  elif [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ] #{{{
  then
    outputs="${outputs} cosebis_dimless"
  #}}}
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      outputs="${outputs} bandpowers_ee"
    fi
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      outputs="${outputs} bandpowers_ne"
    fi
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      outputs="${outputs} bandpowers_nn"
    fi
  #}}}
  elif [ "${STATISTIC^^}" == "XIPSF" ] #{{{
  then
    outputs="${outputs} xipsf_binned"
  #}}}
  elif [ "${STATISTIC^^}" == "XIGPSF" ] #{{{
  then
    outputs="${outputs} xigpsf_binned"
  #}}}
  elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
  then
    outputs="${outputs} xipm"
  #}}}
  elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
  then
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      outputs="${outputs} xipm"
    fi
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      outputs="${outputs} gt"
    fi
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      outputs="${outputs} wt"
    fi
  #}}}
  fi
  outlist=""
  for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do
    for out in ${outputs}
    do
      outlist="${outlist} ${out}_vec_${patch}"
    done
  done
  echo "${outlist}"
}
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/make_data_vector_allstats.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

