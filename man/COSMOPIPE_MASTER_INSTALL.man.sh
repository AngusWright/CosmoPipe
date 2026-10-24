#
# Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt { 
  VERBOSE=1 _message "${BLU}=====================================================${DEF}\n"
  VERBOSE=1 _message "${BLU}== ${RED} Cosmology Pipeline Installation Master Script ${BLU} ==${DEF}\n"
  VERBOSE=1 _message "${BLU}=====================================================${DEF}\n"
  sleep 1
  VERBOSE=1 _message "\nWelcome to the installation script, ${RED}`whoami`${DEF}!\n\n" 
  if [ "$1" != "0" ] 
  then 
    sleep .2
    _message "I will be running with many ${RED} pre-defined ${DEF} variables! \n"
    _message "(These ${RED}must be defined now ${BLU}(!!!) ${DEF}otherwise the install will fail:\n"
    sleep .2
    _message "    PACKROOT${BLU}=${RED}$PACKROOT ${DEF}\n"
    _message "    RUNROOT${BLU}=${RED}$RUNROOT ${DEF}\n"
    _message "    USER${BLU}=${RED}$USER ${DEF}\n"
    _message "    MACHINE${BLU}=${RED}$MACHINE ${DEF}\n"
    _message "    P_RSCRIPT${BLU}=${RED}$P_RSCRIPT ${DEF}\n"
    _message "    P_SED_INPLACE${BLU}=${RED}$P_SED_INPLACE ${DEF}\n"
    sleep .2
    _message "\n"
    _message "If any of the above are empty or filled with place-holder values, \n"
    _message "then you ${RED} should kill the script now ${DEF} and\n"
    _message "pass relevant values for the parameters on the command line, like this:\n"
    _message "  bash COSMOPIPE_MASTER_INSTALL.sh --packroot \`pwd\` --runroot /path/to/run/root/ --user \`whoami\` --machine MyArch_64 --p_rscript Rscript --p_sed_inplace 'sed -i ' \n" 
    sleep .2
    _message "${BLU}You have 10 sec to decide... ${DEF}"
    
    sleep 10 & _spinner 
    
    echo " OK!"
    sleep 1
    _message "${BLU}Starting Installation now. ${DEF}\n"
    sleep .5
    _message "${BLU}=======================================${DEF}\n"
  else 
    sleep 1 
    VERBOSE=1 _message "You are running without ${RED}VERBOSE${DEF} output.\n"
    VERBOSE=1 _message "${BLU}Starting Installation now, but will not prompt further.${DEF}\n"
    VERBOSE=1 _message "${BLU}=======================================${DEF}\n"
    sleep 1 
  fi 
}
#}}}

# Abort Message {{{
_abort()
{
  VERBOSE=1 _message "${RED} - !FAILED!\n"
  VERBOSE=1 _message "${BLU} An error occurred while running $0.\n"
  VERBOSE=1 _message "${DEF} Check the logging files in ${RUNROOT}/INSTALL/.\n\n"
  trap : 0
  exit 1
}
trap '_abort' 0
set -e 
#}}}

# Input data {{{ 
function _inp_data { 
  #Data inputs: NONE
  echo 
} 
#}}}

# Input variables {{{ 
function _inp_var { 
  #Variable inputs 
  echo RUNROOT PACKROOT USER DATE 
} 
#}}}

# Output data {{{ 
function _outputs { 
  #NONE
  echo 
} 
#}}}

#Additional Functions 

# Installer-only flags take no values: --noconda reuses CONDAPIPENAME;
# --noinstall only writes configuration files; --noconfig runs configure.sh.
# --verbose 0 skips the startup delay. Other options require a value.
# Both platforms use environment.yml; --condapipename overrides its name.
# environment-plotting.yml installs ChainConsumer in RUNROOT/INSTALL/plotting-env.

#Make waiting interesting with a spinner! {{{
function _spinner {
  _pid=$! # Process Id of the previous running command
  _spin='-\|/'
  _i=0
  while kill -0 $_pid 2>/dev/null 1>&2 
  do
    _i=$(( (_i+1) %4 ))
    printf "[${_spin:$_i:1}]\b\b\b"
    sleep .1
  done
}
#}}}

#Error for existing installation {{{
function _existing_install_error { 
  VERBOSE=1 _message "   >${RED} ERROR: There is a previous pipeline installation in ${DEF}\n" 
  VERBOSE=1 _message "   >${BLU} ${RUNROOT}/INSTALL ${DEF}\n" 
  VERBOSE=1 _message "   >${RED} If you want to rerun the installation, then you must delete it!${DEF}\n" 
  VERBOSE=1 _message "${BLU}=======================================${DEF}\n"
  trap : 0 
  exit 1 
} #}}}

#Error for existing installation {{{
function _runroot_error { 
  VERBOSE=1 _message "${RED} ERROR:${DEF} Incorrect calling syntax (--runroot is required)${DEF}\n" 
  VERBOSE=1 _message " > ${BLU} The master installation script should be run with the minimal set of options:${DEF}\n" 
  VERBOSE=1 _message "    bash COSMOPIPE_MASTER_INSTALL.sh --runroot /path/to/desired/install/place/\n" 
  trap : 0 
  exit 1 
} #}}}
