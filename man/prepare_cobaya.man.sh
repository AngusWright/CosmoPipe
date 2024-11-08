#
# prepare_cosmosis.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@========================================@DEF@\n"
    _message "@BLU@== @RED@ Running prepare_cobaya.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@========================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Prepare cobaya configuration'
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
  echo BLU BV:BOLTZMAN BV:PRIOR_ABARY BV:PRIOR_AIA BV:PRIOR_H0 BV:PRIOR_LOGTAGN BV:PRIOR_MNU BV:PRIOR_NS BV:PRIOR_OMBH2 BV:PRIOR_OMCH2 BV:PRIOR_OMEGAK BV:PRIOR_S8INPUT BV:PRIOR_W BV:PRIOR_WA DATABLOCK DEF RED RUNROOT STORAGEPATH SURVEY
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  echo ALLHEAD cosmosis_inputs
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  outlist='cobaya_inputs'
  echo ${outlist}
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/prepare_cobaya.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 
function translate_to_cobaya {
  local param=$1
  local cobaya_param=${param}
  if [ ${param} == "h0" ]
  then
    :
    # cobaya_param="H0"
  elif [ ${param} == "n_s" ]
  then
    cobaya_param="ns"
  elif [ ${param} == "omega_k" ]
  then
    cobaya_param="omegak"
  elif [ ${param} == "log_T_AGN" ]
  then
    cobaya_param="HMCode_logT_AGN"
  elif [ ${param} == "Abary" ]
  then
    cobaya_param="HMCode_A_baryon"
  elif [ ${param} == "AIA" ]
  then
    cobaya_param="A"
  fi
  echo ${cobaya_param}
}

function write_sampling_params {
  local param=$1
  local prefix=$2
  local indent=1
  if [ $3 ]
  then
    indent=$3
  fi
  indent=`seq ${indent} | awk '{printf "  "}'`

  local cobaya_param=$(translate_to_cobaya $1)
  if [ ! -z "${prefix}" ]
  then
    cobaya_param="${prefix}.${cobaya_param}"
  fi

  local extras=$4
  
  #Load the prior variable name {{{
  local pvar=${param^^}
  pvar=PRIOR_${pvar//_/}
  #}}}
  #get the prior value {{{
  pprior=`echo ${!pvar}`
  #}}}
  #Check the prior is correctly specified {{{
  nprior=`echo ${pprior} | awk '{print NF}'` 
  if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
  then 
    _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
    _message "@RED@         it is: @DEF@${pprior}\n"
    exit 1 
  fi 
  #}}}
  if [ ${nprior} == 1 ] 
  then
    if [ ! -z "${extras}" ]
    then
      echo "${indent}${cobaya_param}:"
      echo "${indent}  ref: ${pprior}"
      echo "${indent}  ${extras}"
    else
      echo "${indent}${cobaya_param}: ${pprior}"
    fi
  else 
    #Write the prior {{{
    if [ "${pprior%% *}" == "gaussian" ]
    then 
      #Prior is a gaussian {{{
      parray=(${pprior})
      #}}}
      echo "${indent}${cobaya_param}:"
      echo "${indent}  ref: ${parray[1]}"
      if [ ! -z "${extras}" ]
      then
        echo "${indent}  ${extras}"
      fi
      echo "${indent}  prior:"
      echo "${indent}    dist: norm"
      echo "${indent}    loc: ${parray[1]}"
      echo "${indent}    scale: ${parray[2]}"
      #}}}
    else
      parray=(${pprior})

      echo "${indent}${cobaya_param}:"
      echo "${indent}  ref: ${parray[1]}"
      if [ ! -z "${extras}" ]
      then
        echo "${indent}  ${extras}"
      fi
      echo "${indent}  prior:"
      echo "${indent}    min: ${parray[0]}"
      echo "${indent}    max: ${parray[2]}"
    fi 
    #}}}
  fi
}
