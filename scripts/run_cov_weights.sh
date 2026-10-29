#!/bin/bash
#
# Script to construct weights needed for arbitrary covariance stats
#

STATISTIC="@BV:STATISTIC@"

# Output folder:
outfold=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
mkdir -p "${outfold}"

# Set variables depending on the statistic
case "${STATISTIC^^}" in
  "2PCF")
    n_arb_ee=@BV:NXIPM@
    n_arb_ne=@BV:NGT@
    n_arb_nn=@BV:NWT@

    arb_fourier_filter_mmE_file="fourier_weight_realspace_cf_mm_p_?.table"
    arb_fourier_filter_mmB_file="fourier_weight_realspace_cf_mm_m_?.table"
    arb_real_filter_mm_p_file="real_weight_realspace_cf_mm_p_?.table"
    arb_real_filter_mm_m_file="real_weight_realspace_cf_mm_m_?.table"

    arb_fourier_filter_gm_file="fourier_weight_realspace_cf_gm_?.table"
    arb_real_filter_gm_file="real_weight_realspace_cf_gm_?.table"

    arb_fourier_filter_gg_file="fourier_weight_realspace_cf_gg_?.table"
    arb_real_filter_gg_file="real_weight_realspace_cf_gg_?.table"

    arb_base=@RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/rcf/
    ;;
  "COSEBIS")
    n_arb_ee=@BV:NMAXCOSEBIS@
    n_arb_ne=@BV:NMAXCOSEBISNE@
    n_arb_nn=@BV:NMAXCOSEBISNN@

    arb_fourier_filter_mmE_file="Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
    arb_fourier_filter_mmB_file="Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_p_file="Tp_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_m_file="Tm_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"

    arb_fourier_filter_gm_file="Qgm_@BV:THETAMINGT@_to_@BV:THETAMAXGT@_?.table"
    arb_real_filter_gm_file="Wn_psigm_@BV:THETAMINGT@_to_@BV:THETAMAXGT@_?.table"

    arb_fourier_filter_gg_file="Ugg_@BV:THETAMINWT@_to_@BV:THETAMAXWT@_?.table"
    arb_real_filter_gg_file="Wn_psigg_@BV:THETAMINWT@_to_@BV:THETAMAXWT@_?.table"

    arb_base=@RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/cosebis/
    ;;
  "BANDPOWERS")
    n_arb_ee=@BV:NBANDPOWERS@
    n_arb_ne=@BV:NBANDPOWERSNE@
    n_arb_nn=@BV:NBANDPOWERSNN@

    theta_lo_lensing=$(echo "e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)" | bc -l)
    theta_up_lensing=$(echo "e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)" | bc -l)
    t_lo_mm=$(printf "%.2f" "$theta_lo_lensing")
    t_up_mm=$(printf "%.2f" "$theta_up_lensing")

    theta_lo_ggl=$(echo "e(l(@BV:THETAMINGT@)+@BV:APODISATIONWIDTH@/2)" | bc -l)
    theta_up_ggl=$(echo "e(l(@BV:THETAMAXGT@)-@BV:APODISATIONWIDTH@/2)" | bc -l)
    t_lo_gm=$(printf "%.2f" "$theta_lo_ggl")
    t_up_gm=$(printf "%.2f" "$theta_up_ggl")

    theta_lo_clustering=$(echo "e(l(@BV:THETAMINWT@)+@BV:APODISATIONWIDTH@/2)" | bc -l)
    theta_up_clustering=$(echo "e(l(@BV:THETAMAXWT@)-@BV:APODISATIONWIDTH@/2)" | bc -l)
    t_lo_gg=$(printf "%.2f" "$theta_lo_clustering")
    t_up_gg=$(printf "%.2f" "$theta_up_clustering")

    arb_fourier_filter_mmE_file="fourier_weight_bandpowers_mmE_?.table"
    arb_fourier_filter_mmB_file="fourier_weight_bandpowers_mmB_?.table"
    arb_real_filter_mm_p_file="real_weight_bandpowers_mmE_?.table"
    arb_real_filter_mm_m_file="real_weight_bandpowers_mmB_?.table"

    arb_fourier_filter_gm_file="fourier_weight_bandpowers_gm_?.table"
    arb_real_filter_gm_file="real_weight_bandpowers_gm_?.table"

    arb_fourier_filter_gg_file="fourier_weight_bandpowers_gg_?.table"
    arb_real_filter_gg_file="real_weight_bandpowers_gg_?.table"

    arb_base=@RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/bandpowers/
    ;;
  *)
    _message "Unknown statistic: ${STATISTIC^^}\n"
    exit 1
    ;;
esac

run_arbitrary=False

# Function to check and copy files
check_and_copy_files() {
    local n=$1
    shift
    local files=("$@")

    for i in $(seq -f "%02g" 1 "$n"); do
        missing=False
        expanded_files=()
        for f in "${files[@]}"; do
            file="${f//\?/$i}"
            expanded_files+=("$file")
            if [ ! -f "$arb_base$file" ]; then
                missing=True
            fi
        done

        if [ "$missing" == "True" ]; then
            run_arbitrary=True
            _message "One or more arbitrary input files do not exist. Calculating filters now!\n"
            break
        else
            for f in "${expanded_files[@]}"; do
                cp "$arb_base$f" "$outfold"
            done
        fi
    done
}

# Check files
check_and_copy_files "$n_arb_ee" "$arb_fourier_filter_mmE_file" "$arb_fourier_filter_mmB_file" "$arb_real_filter_mm_p_file" "$arb_real_filter_mm_m_file"
check_and_copy_files "$n_arb_ne" "$arb_fourier_filter_gm_file" "$arb_real_filter_gm_file"
check_and_copy_files "$n_arb_nn" "$arb_fourier_filter_gg_file" "$arb_real_filter_gg_file"

# Run scripts if needed
if [ "$run_arbitrary" == "True" ]; then
    cd @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/script_weights/

    case "${STATISTIC^^}" in
      "2PCF")
        _message "    -> @BLU@Generating arbitrary statistic weights for 2pcfs @DEF@"
        @PYTHON3BIN@ get_weights_realspace.py \
          -n @BV:NTHREADS@ \
          -nf 100000 \
          -nt 100000 \
          --theta_lo_mm @BV:THETAMINXI@ \
          --theta_up_mm @BV:THETAMAXXI@ \
          --t_bins_mm @BV:NXIPM@ \
          --t_type_mm "log" \
          --theta_lo_gm @BV:THETAMINGT@ \
          --theta_up_gm @BV:THETAMAXGT@ \
          --t_bins_gm @BV:NGT@ \
          --t_type_gm "log" \
          --theta_lo_gg @BV:THETAMINWT@ \
          --theta_up_gg @BV:THETAMAXWT@ \
          --t_bins_gg @BV:NWT@ \
          --t_type_gg "log" 2>&1

        cp -a @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/rcf/. "$outfold"
        ;;
      "COSEBIS")
        _message "    -> @BLU@Generating arbitrary statistic weights for cosebis / psi stats @DEF@"
        @PYTHON3BIN@ get_weights_cosebis.py \
          -n @BV:NTHREADS@ \
          -nf 100000 \
          -nt 10000 \
          --Nmax_mm @BV:NMAXCOSEBIS@ \
          --tmin_mm @BV:THETAMINXI@ \
          --tmax_mm @BV:THETAMAXXI@ \
          --Nmax_gm @BV:NMAXCOSEBISNE@ \
          --tmin_gm @BV:THETAMINGT@ \
          --tmax_gm @BV:THETAMAXGT@ \
          --Nmax_gg @BV:NMAXCOSEBISNN@ \
          --tmin_gg @BV:THETAMINWT@ \
          --tmax_gg @BV:THETAMAXWT@ 2>&1

        cp -a @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/cosebis/. "$outfold"
        ;;
      "BANDPOWERS")
        _message "    -> @BLU@Generating arbitrary statistic weights for bandpowers @DEF@"
        @PYTHON3BIN@ get_weights_bandpowers.py \
          -n @BV:NTHREADS@ \
          -nf 10000 \
          -nt 10000 \
          --delta_ln_theta_mm @BV:APODISATIONWIDTH@ \
          --theta_lo_mm ${t_lo_mm} \
          --theta_up_mm ${t_up_mm} \
          --L_min_mm @BV:LMINBANDPOWERS@ \
          --L_max_mm @BV:LMAXBANDPOWERS@ \
          --L_bins_mm @BV:NBANDPOWERS@ \
          --L_type_mm "log" \
          --delta_ln_theta_gm @BV:APODISATIONWIDTH@ \
          --theta_lo_gm ${t_lo_gm} \
          --theta_up_gm ${t_up_gm} \
          --L_min_gm @BV:LMINBANDPOWERSNE@ \
          --L_max_gm @BV:LMAXBANDPOWERSNE@ \
          --L_bins_gm @BV:NBANDPOWERSNE@ \
          --L_type_gm "log" \
          --delta_ln_theta_gg @BV:APODISATIONWIDTH@ \
          --theta_lo_gg ${t_lo_gg} \
          --theta_up_gg ${t_up_gg} \
          --L_min_gg @BV:LMINBANDPOWERSNN@ \
          --L_max_gg @BV:LMAXBANDPOWERSNN@ \
          --L_bins_gg @BV:NBANDPOWERSNN@ \
          --L_type_gg "log" 2>&1

        cp -a @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/bandpowers/. "$outfold"
        ;;
    esac
    cd @RUNROOT@
fi

_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
