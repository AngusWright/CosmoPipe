set -e

root="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@"
patches=()
for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do
  if [[ " ${patches[*]} " == *" ${patch} "* ]]; then
    continue
  fi
  patches+=("${patch}")
done

plotted=()
for patch in "${patches[@]}"
do
  bias_entry=$(_read_datablock "nzbias_${patch}")
  cov_entry=$(_read_datablock "nzcov_${patch}")
  bias_files=$(_blockentry_to_filelist "${bias_entry}")
  cov_files=$(_blockentry_to_filelist "${cov_entry}")
  if [ -z "${bias_files}" ] && [ -z "${cov_files}" ]; then
    _message " > No dz priors for ${patch}; skipping.\n"
    continue
  fi
  read -r -a bias_list < <(printf '%s\n' "${bias_files}")
  read -r -a cov_list < <(printf '%s\n' "${cov_files}")
  if [ "${#bias_list[@]}" -ne 1 ] || [ "${#cov_list[@]}" -ne 1 ]; then
    _message "ERROR: expected one nzbias and one nzcov file for ${patch}.\n" >&2
    exit 1
  fi
  bias="${root}/nzbias_${patch}/${bias_list[0]}"
  covariance="${root}/nzcov_${patch}/${cov_list[0]}"
  # compute_dz_priors writes joint mean/width companions beside the registered files.
  joint_bias="${bias%/*}/wSig_${bias##*/}"
  joint_cov="${covariance%/*}/wSig_${covariance##*/}"
  for file in "${bias}" "${covariance}" "${joint_bias}" "${joint_cov}"
  do
    if [ ! -f "${file}" ]; then
      _message "ERROR: missing dz prior input ${file}.\n" >&2
      exit 1
    fi
  done
  output="${root}/dz_priors_plots_${patch}"
  _message " > Plotting dz priors for ${patch}.\n"
  @P_RSCRIPT@ "@RUNROOT@/@SCRIPTPATH@/plot_dz_priors.R" \
    --bias "${joint_bias}" \
    --covariance "${joint_cov}" \
    --tomolims @BV:TOMOLIMS@ \
    --patch "${patch}" \
    --output "${output}" 2>&1
  plotted+=("${patch}")
done
if [ "${#plotted[@]}" -eq 0 ]; then
  _message "ERROR: no compute_dz_priors outputs were found for the configured patches.\n" >&2
  exit 1
fi
for patch in "${plotted[@]}"
do
  _write_datablock "dz_priors_plots_${patch}" "nzbias.pdf width_bias.pdf covariance.pdf correlation.pdf"
done
