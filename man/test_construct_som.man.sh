#
# test_construct_som.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt {
  if [ "$1" != "0" ]
  then
    _message "@BLU@============================================@DEF@\n"
    _message "@BLU@== @RED@ Running test_construct_som.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@============================================@DEF@\n"
  fi
}
#}}}

#Mode description {{{
function _description {
  echo "#"
  echo "# Validate the grid and feature codes in a constructed SOM."
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
  echo BV:SOMFEATURES BV:SOM_TEST_XDIM BV:SOM_TEST_YDIM P_RSCRIPT RUNROOT SCRIPTPATH
}
#}}}

# Input data {{{
function _inp_data {
  echo DATAHEAD
}
#}}}

# Output data {{{
function _outputs {
  echo
}
#}}}

# Execution command {{{
function _runcommand {
  echo bash @RUNROOT@/@SCRIPTPATH@/test_construct_som.sh
}
#}}}

# Unset Function command {{{
function _unset_functions {
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
}
#}}}
