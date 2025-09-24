#
# covariance_constructor.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  #Check if we do want verbose output
  if [ "$1" != "0" ] 
  then
    _message "@BLU@==============================================@DEF@\n"
    _message "@BLU@== @RED@ Running covariance_constructor.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@==============================================@DEF@\n"
  fi 
}
#}}}

#Mode description {{{
function _description { 
  echo "#"
  echo '# Constructs a covariance .ini file'
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
  echo BLINDING BV:APODISATIONWIDTH BV:BOLTZMAN BV:CHAINSUFFIX BV:COVNCORES BV:DECNAME BV:GAUSS BV:IAMODEL BV:ITERATION BV:LBINSCOV BV:LMAXBANDPOWERS BV:LMAXCOV BV:LMINBANDPOWERS BV:LMINCOV BV:MIXTERM BV:MIXTERM_BASEFILE BV:NBANDPOWERS BV:NMAXCOSEBIS BV:NONGAUSS BV:NPAIRBASE_XI BV:NTHETABINXI BV:NXIPM BV:PRIOR_ABARY BV:PRIOR_AIA BV:PRIOR_H0 BV:PRIOR_LOGTAGN BV:PRIOR_MNU BV:PRIOR_NS BV:PRIOR_OMBH2 BV:PRIOR_OMCH2 BV:PRIOR_S8INPUT BV:PRIOR_W BV:PRIOR_WA BV:RANAME BV:SECONDSTATISTIC BV:SPLIT_GAUSS BV:SSC BV:STATISTIC BV:SURVEYAREADEG BV:SURVEYMASKFILE BV:THETAMAXXI BV:THETAMINXI BV:TOMOLIMS BV:WEIGHTNAME CONFIGPATH DATABLOCK RUNROOT STORAGEPATH SURVEY
} 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs (leave blank if none)
  if [ "@BV:MIXTERM@" == "True" ]
  then 
    mixtermbase=`_parse_blockvars @BV:MIXTERM_BASEFILE@`
    echo cosmosis_msigma cosmosis_neff cosmosis_nz cosmosis_sigmae ${mixtermbase}
  else
    echo cosmosis_msigma cosmosis_neff cosmosis_nz cosmosis_sigmae
  fi
} 
#}}}

# Output data {{{ 
function _outputs { 
  #Data outputs (leave blank if none)
  echo cov
} 
#}}}

# Execution command {{{ 
function _runcommand { 
  #Command for running the script 
  echo bash @RUNROOT@/@SCRIPTPATH@/covariance_constructor.sh
} 
#}}}

# Unset Function command {{{ 
function _unset_functions { 
  #Remove these functions from the environment
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
} 
#}}}

#Additional Functions 

