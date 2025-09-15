#
#
# Script to construct weights needed for arbitrary covariance stats
#
#

STATISTIC="@BV:STATISTIC@"

#Output folder:
outfold=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 


if [ "${STATISTIC^^}" == "2PCF" ]
then
    n_arb_ee=@BV:NXIPM@
    arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    n_arb_ne=@BV:NGT@
    arb_fourier_filter_gm_file_@BV:STATISTIC@="fourier_weight_realspace_cf_gm_@BV:THETAMINGT@-@BV:THETAMAXGT@_?.table"
    arb_real_filter_gm_file_@BV:STATISTIC@="real_weight_realspace_cf_gm_@BV:THETAMINGT@-@BV:THETAMAXGT@_?.table"
    n_arb_nn=@BV:NWT@
    arb_fourier_filter_gg_file_@BV:STATISTIC@="fourier_weight_realspace_cf_gg_@BV:THETAMINWT@-@BV:THETAMAXWT@_?.table"
    arb_real_filter_gg_file_@BV:STATISTIC@="real_weight_realspace_cf_gg_@BV:THETAMINWT@-@BV:THETAMAXWT@_?.table"
    arb_base=@RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/rcf/
    
elif [ "${STATISTIC^^}" == "COSEBIS" ]
then
    n_arb_ee=@BV:NMAXCOSEBIS@
    arb_fourier_filter_mmE_file_@BV:STATISTIC@="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    arb_fourier_filter_mmB_file_@BV:STATISTIC@="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_p_file_@BV:STATISTIC@="Tplus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_m_file_@BV:STATISTIC@="Tminus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    n_arb_ne=@BV:NMAXCOSEBISNE@
    arb_fourier_filter_gm_file_@BV:STATISTIC@="Qgm_@BV:THETAMINGT@-@BV:THETAMAXGT@_?.table"
    arb_real_filter_gm_file_@BV:STATISTIC@="Wn_psigm_@BV:THETAMINGT@-@BV:THETAMAXGT@_?.table"
    n_arb_nn=@BV:NMAXCOSEBISNN@
    arb_fourier_filter_gg_file_@BV:STATISTIC@="Ugg_@BV:THETAMINWT@-@BV:THETAMAXWT@_?.table"
    arb_real_filter_gg_file_@BV:STATISTIC@="Wn_psigg_@BV:THETAMINWT@-@BV:THETAMAXWT@_?.table"
    arb_base=@RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/cosebis/

elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
    n_arb_ee=@BV:NBANDPOWERS@
    theta_lo_lensing=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    theta_up_lensing=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    t_lo_mm=`printf "%.2f" $theta_lo_lensing`
    t_up_mm=`printf "%.2f" $theta_up_lensing`
    arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmE_${t_lo_mm}-${t_up_mm}_?.table"
    arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmB_${t_lo_mm}-${t_up_mm}_?.table"
    arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_bandpowers_mmE_${t_lo_mm}-${t_up_mm}_?.table"
    arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_bandpowers_mmB_${t_lo_mm}-${t_up_mm}_?.table"
    n_arb_ne=@BV:NBANDPOWERSNE@
    theta_lo_ggl=`echo 'e(l(@BV:THETAMINGT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    theta_up_ggl=`echo 'e(l(@BV:THETAMAXGT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    t_lo_gm=`printf "%.2f" $theta_lo_ggl`
    t_up_gm=`printf "%.2f" $theta_up_ggl`
    arb_fourier_filter_gm_file_@BV:STATISTIC@="fourier_weight_bandpowers_gm_${t_lo_gm}-${t_up_gm}_?.table"
    arb_real_filter_gm_file_@BV:STATISTIC@="real_weight_bandpowers_gm_${t_lo_gm}-${t_up_gm}_?.table"
    n_arb_nn=@BV:NBANDPOWERSNN@
    theta_lo_clustering=`echo 'e(l(@BV:THETAMINWT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    theta_up_clustering=`echo 'e(l(@BV:THETAMAXWT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    t_lo_gg=`printf "%.2f" $theta_lo_clustering`
    t_up_gg=`printf "%.2f" $theta_up_clustering`
    arb_fourier_filter_gg_file_@BV:STATISTIC@="fourier_weight_bandpowers_gg_${t_lo_gg}-${t_up_gg}_?.table"
    arb_real_filter_gg_file_@BV:STATISTIC@="real_weight_bandpowers_gg_${t_lo_gg}-${t_up_gg}_?.table"
    arb_base=@RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/bandpowers/
else
  #ERROR: Unknown statistic {{{
  _message "Unknown statistic: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi


run_arbitrary=False
for i in $(seq -f "%02g" 1 $n_arb_ee)
do
  file=`echo ${arb_fourier_filter_mmE_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file2=`echo ${arb_fourier_filter_mmB_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file3=`echo ${arb_real_filter_mm_p_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file4=`echo ${arb_real_filter_mm_m_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ] || [ ! -f $arb_base${file3} ] || [ ! -f $arb_base${file4} ]
  then
    run_arbitrary=True
    _message "One or more arbitrary input files do not exist. Calculating filters now!\n"
    break
  else
    cp ${arb_base}/{$file,$file2,$file3,$file4} ${outfold}
  fi
done
for i in $(seq -f "%02g" 1 $n_arb_ne)
do
  file=`echo ${arb_fourier_filter_gm_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file2=`echo ${arb_real_filter_gm_file_@BV:STATISTIC@}   | sed "s/?/${i}/g"`
  if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ]
  then
    run_arbitrary=True
    _message "One or more arbitrary input files do not exist. Calculating filters now!\n"
    break
  else
    cp ${arb_base}/{$file,$file2} ${outfold}
  fi
done
for i in $(seq -f "%02g" 1 $n_arb_nn)
do
  file=`echo ${arb_fourier_filter_gg_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file2=`echo ${arb_real_filter_gg_file_@BV:STATISTIC@}   | sed "s/?/${i}/g"`
  if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ]
  then
    run_arbitrary=True
    _message "One or more arbitrary input files do not exist. Calculating filters now!\n"
    break
  else
    cp ${arb_base}/{$file,$file2} ${outfold}
  fi
done


if [ "${run_arbitrary}" == "True" ]
then
  if [ "${STATISTIC^^}" == "2PCF" ]
  then
    _message "    -> @BLU@Generating arbitrary statistic weights for 2pcfs @DEF@"
    cd @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/script_weights/
    @PYTHON3BIN@ @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/script_weights/get_weights_realspace.py \
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
      --theta_lo_gg @BV:THETAMINWT@\
      --theta_up_gg @BV:THETAMAXWT@\
      --t_bins_gg @BV:NWT@ \
      --t_type_gg "log" 2>&1
  
    cd @RUNROOT@
    cp -a @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/rcf/. ${outfold}
  
  elif [ "${STATISTIC^^}" == "COSEBIS" ]
  then
    _message "    -> @BLU@Generating arbitrary statistic weights for cosebis / psi stats @DEF@"
    cd @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/script_weights/
    @PYTHON3BIN@ @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/script_weights/get_weights_cosebis.py \
      -n @BV:NTHREADS@ \
      -nf 100000 \
      -nt 100000 \
      --Nmax_mm @BV:NMAXCOSEBIS@ \
      --tmin_mm @BV:THETAMINXI@ \
      --tmax_mm @BV:THETAMAXXI@ \
      --Nmax_gm @BV:NMAXCOSEBISNE@ \
      --tmin_gm @BV:THETAMINGT@ \
      --tmax_gm @BV:THETAMAXGT@ \
      --Nmax_gg @BV:NMAXCOSEBISNN@ \
      --tmin_gg @BV:THETAMINWT@ \
      --tmax_gg @BV:THETAMAXWT@  2>&1
  
    cd @RUNROOT@
    cp -a @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/cosebis/. ${outfold}
  
  
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
  then
    _message "    -> @BLU@Generating arbitrary statistic weights for bandpowers @DEF@"
    cd @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/script_weights/
    @PYTHON3BIN@ @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/script_weights/get_weights_bandpowers.py \
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
  
    cd @RUNROOT@
    cp -a @RUNROOT@/INSTALL/OneCovariance/input/arbitrary_summary/bandpowers/. ${outfold}
  fi
fi

_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"





