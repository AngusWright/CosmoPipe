function _prompt {
  if [ "$1" != "0" ]; then
    _message "Running plot_dz_priors.sh\n"
  fi
}

function _description {
  echo "# Plot per-bin mean-redshift and width biases with 1-sigma uncertainties,"
  echo "# and their full joint covariance and correlation matrices."
  echo "# Read compute_dz_priors outputs, including adjacent wSig_ companions."
  echo "# Inputs: `_inp_data`"
  echo "#                    "
}

_abort()
{
  _message "An error occurred while running $0.\n" >&2
  _message "Check @RUNROOT@/@LOGPATH@/ for this step's log.\n" >&2
  exit 1
}
trap '_abort' 0
set -e

function _inp_var {
  echo ALLPATCH BV:PATCHLIST BV:TOMOLIMS DATABLOCK P_RSCRIPT RUNROOT SCRIPTPATH STORAGEPATH
}

function _inp_data {
  _vals=''
  for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do
    _vals="$_vals nzbias_${patch} nzcov_${patch}"
  done
  echo $_vals
}

function _outputs {
  _vals=""
  for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
  do
    echo "${_vals} dz_priors_plots_${patch}"
  done
  echo $_vals 
}

function _runcommand {
  echo bash @RUNROOT@/@SCRIPTPATH@/plot_dz_priors.sh
}

function _unset_functions {
  unset -f _prompt _description _inp_data _inp_var _abort _outputs _runcommand _unset_functions
}
