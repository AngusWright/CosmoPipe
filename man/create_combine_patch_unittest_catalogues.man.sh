#
# create_combine_patch_unittest_catalogues.sh Documentation & Housekeeping functions
#

#Starting Prompt {{{
function _prompt {
  if [ "$1" != "0" ]
  then
    _message "@BLU@==========================================================@DEF@\n"
    _message "@BLU@== @RED@ Running create_combine_patch_unittest_catalogues.sh Mode @BLU@ ==@DEF@\n"
    _message "@BLU@==========================================================@DEF@\n"
  fi
}
#}}}

#Mode description {{{
function _description {
  echo "#"
  echo "# Create deterministic two-patch FITS catalogues for the combine_patch unit test."
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
  echo PYTHON3BIN RUNROOT SCRIPTPATH STORAGEPATH
}
#}}}

# Input data {{{
function _inp_data {
  echo
}
#}}}

# Output data {{{
function _outputs {
  echo
}
#}}}

# Execution command {{{
function _runcommand {
  echo bash @RUNROOT@/@SCRIPTPATH@/create_combine_patch_unittest_catalogues.sh
}
#}}}

# Unset Function command {{{
function _unset_functions {
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
}
#}}}
