#
# test_tomography.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt {
  if [ "$1" != "0" ]
  then
    _message "@BLU@==========================================@DEF@\n"
    _message "@BLU@== @RED@ Running test_tomography.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@==========================================@DEF@\n"
  fi
}
#}}}

#Mode description {{{
function _description {
  echo "#"
  echo "# Validate tomography output catalogues against their expected bin membership."
  echo "#"
  echo "# Function takes input data:"
  echo "# \`_inp_data\`"
  echo "#"
}
#}}}

# Abort Message {{{
_abort()
{
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
  echo BV:TOMOLIMS BV:TOMOVAR PYTHON3BIN RUNROOT SCRIPTPATH
}
#}}}

# Input data {{{
function _inp_data {
  echo ALLHEAD tomography_unittest_input
}
#}}}

# Output data {{{
function _outputs {
  echo
}
#}}}

# Execution command {{{
function _runcommand {
  echo bash @RUNROOT@/@SCRIPTPATH@/test_tomography.sh
}
#}}}

# Unset Function command {{{
function _unset_functions {
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
}
#}}}
