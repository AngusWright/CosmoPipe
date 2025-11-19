#=========================================
#
# File Name : covariance_constructor_3x2pt.sh
# Created By : dvornik
# Creation Date : 21-08-2024
# Last Modified : Wed 21 Aug 2024 10:48:51 AM CEST
#
#=========================================

#Script to generate a covariance .ini

#Create the covariance_inputs directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/
fi
#Create a (temporary) directory for arbitrary filter files
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
fi 
#Create the mixterm directory
if [ "@BV:MIXTERM@" == "True" ]
then 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/mixterm ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/mixterm/
  fi 
fi

# Infer statistic {{{
STATISTIC="@BV:STATISTIC@"
SECONDSTATISTIC="@BV:SECONDSTATISTIC@"
MODES="@BV:MODES@"
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENS="@BV:NLENSBINS@"
NOBS="@BV:NSMFLENSBINS@"


if [ "${STATISTIC^^}" == "2PCF" ]
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    est_shear=xi_pm
    cosmic_shear=True
    n_arb_ee=@BV:NXIPM@
    arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_p_?.table"
    arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_m_?.table"
    arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_p_?.table"
    arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_m_?.table"
  else
    est_shear=xi_pm
    cosmic_shear=False
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    est_ggl=gamma_t
    ggl=True
    n_arb_ne=@BV:NGT@
    arb_fourier_filter_gm_file_@BV:STATISTIC@="fourier_weight_realspace_cf_gm_?.table"
    arb_real_filter_gm_file_@BV:STATISTIC@="real_weight_realspace_cf_gm_?.table"
  else
    est_ggl=gamma_t
    ggl=False
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    est_clust=w
    clustering=True
    n_arb_nn=@BV:NWT@
    arb_fourier_filter_gg_file_@BV:STATISTIC@="fourier_weight_realspace_cf_gg_?.table"
    arb_real_filter_gg_file_@BV:STATISTIC@="real_weight_realspace_cf_gg_?.table"
  else
    est_clust=w
    clustering=False
  fi
elif [ "${STATISTIC^^}" == "COSEBIS" ]
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    est_shear=cosebi
    cosmic_shear=True
    n_arb_ee=@BV:NMAXCOSEBIS@
    arb_fourier_filter_mmE_file_@BV:STATISTIC@="Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
    arb_fourier_filter_mmB_file_@BV:STATISTIC@="Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_p_file_@BV:STATISTIC@="Tp_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
    arb_real_filter_mm_m_file_@BV:STATISTIC@="Tm_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
  else
    est_shear=cosebi
    cosmic_shear=False
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    est_ggl=cosebi
    ggl=True
    n_arb_ne=@BV:NMAXCOSEBISNE@
    arb_fourier_filter_gm_file_@BV:STATISTIC@="Qgm_@BV:THETAMINGT@_to_@BV:THETAMAXGT@_?.table"
    arb_real_filter_gm_file_@BV:STATISTIC@="Wn_psigm_@BV:THETAMINGT@_to_@BV:THETAMAXGT@_?.table"
  else
    est_ggl=cosebi
    ggl=False
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    est_clust=cosebi
    clustering=True
    n_arb_nn=@BV:NMAXCOSEBISNN@
    arb_fourier_filter_gg_file_@BV:STATISTIC@="Ugg_@BV:THETAMINWT@_to_@BV:THETAMAXWT@_?.table"
    arb_real_filter_gg_file_@BV:STATISTIC@="Wn_psigg_@BV:THETAMINWT@_to_@BV:THETAMAXWT@_?.table"
  else
    est_clust=cosebi
    clustering=False
  fi
elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    est_shear=bandpowers
    cosmic_shear=True
    n_arb_ee=@BV:NBANDPOWERS@
    theta_lo=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    theta_up=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    t_lo=`printf "%.2f" $theta_lo`
    t_up=`printf "%.2f" $theta_up`
    arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmE_?.table"
    arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmB_?.table"
    arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_bandpowers_mmE_?.table"
    arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_bandpowers_mmB_?.table"
  else
    est_shear=bandpowers
    cosmic_shear=False
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    est_ggl=bandpowers
    ggl=True
    n_arb_ne=@BV:NBANDPOWERSNE@
    theta_lo_lensing=`echo 'e(l(@BV:THETAMINGT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    theta_up_lensing=`echo 'e(l(@BV:THETAMAXGT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    t_lo=`printf "%.2f" $theta_lo_lensing`
    t_up=`printf "%.2f" $theta_up_lensing`
    arb_fourier_filter_gm_file_@BV:STATISTIC@="fourier_weight_bandpowers_gm_?.table"
    arb_real_filter_gm_file_@BV:STATISTIC@="real_weight_bandpowers_gm_?.table"
  else
    est_ggl=bandpowers
    ggl=False
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    est_clust=bandpowers
    clustering=True
    n_arb_nn=@BV:NBANDPOWERSNN@
    theta_lo_clustering=`echo 'e(l(@BV:THETAMINWT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    theta_up_clustering=`echo 'e(l(@BV:THETAMAXWT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
    t_lo=`printf "%.2f" $theta_lo_clustering`
    t_up=`printf "%.2f" $theta_up_clustering`
    arb_fourier_filter_gg_file_@BV:STATISTIC@="fourier_weight_bandpowers_gg_?.table"
    arb_real_filter_gg_file_@BV:STATISTIC@="real_weight_bandpowers_gg_?.table"
  else
    est_clust=bandpowers
    clustering=False
  fi
else
  #ERROR: Unknown statistic {{{
  _message "Unknown statistic: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi

if [[ .*\ $MODES\ .* =~ " OBS " ]]
then
  obs_mins=""
  obs_maxs=""
  z_mins=""
  z_maxs=""
  file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB1.txt"
  if [ -f ${file1} ]
  then
    slice=`grep '^slice_in' ${file1} | awk '{printf $2}'`
    if [ "${slice}" == "obs" ]
    then
      for i in `seq ${NOBS}`
      do
        file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
        x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
        x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
        y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
        y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
        obs_mins="${obs_mins} $(echo "$x_lo + l(@BV:H0_IN@)/l(10)" | bc -l)"
        obs_maxs="${obs_maxs} $(echo "$x_hi + l(@BV:H0_IN@)/l(10)" | bc -l)"
        z_mins="${z_mins} ${y_lo}"
        z_maxs="${z_maxs} ${y_hi}"
      done
    elif [ "${slice}" == "z" ]
    then
      for i in `seq ${NOBS}`
      do
        file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
        x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
        x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
        y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
        y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
        obs_mins="${obs_mins} $(echo "$y_lo + l(@BV:H0_IN@)/l(10)" | bc -l)"
        obs_maxs="${obs_maxs} $(echo "$y_hi + l(@BV:H0_IN@)/l(10)" | bc -l)"
        z_mins="${z_mins} ${x_lo}"
        z_maxs="${z_maxs} ${x_hi}"
      done
    else
      _message "Got wrong or no information about slicing of the lens sample.\n"
      #exit 1
    fi
    cstellar_mf=True
    csmf_Mmin=`echo ${obs_mins} | sed 's/ /,/g'`
    csmf_Mmax=`echo ${obs_maxs} | sed 's/ /,/g'`
    csmf_N_log10M_bin=@BV:NSMFBINS@
    csmf_directory="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/"
    V_max_file="@DB:vmax@" # This assumes one file, currently we have NSMFLENSBINS
    f_tomo_file="@DB:f_tomo@" # This assumes one file, currently we have NSMFLENSBINS
  else
    _message "No SMF lens catalog metadata found, setting default CSMF parameters from saved variables.\n"
    if [ "${NOBS}" = "1" ]
    then
      csmf_Mmin=$(echo @BV:SMFLENSLIMSX@ | awk '{print $1}')
      csmf_Mmax=$(echo @BV:SMFLENSLIMSX@ | awk '{print $2}')
    else
      csmf_Mmin=$(echo @BV:SMFLENSLIMSX@ | awk '{for(i=1; i<NF; i++) printf "%s,", $i; print ""}' | sed 's/,$//')
      csmf_Mmax=$(echo @BV:SMFLENSLIMSX@ | awk '{for(i=2; i<=NF; i++) printf "%s,", $i; print ""}' | sed 's/,$//')
    fi
    cstellar_mf=True
    csmf_N_log10M_bin=10
    csmf_directory="@RUNROOT@/INSTALL/OneCovariance/input/conditional_smf/"
    V_max_file="V_max.asc"
    f_tomo_file="f_tomo.asc"
  fi
else
  cstellar_mf=False
  csmf_Mmin=9.1
  csmf_Mmax=11.3
  csmf_N_log10M_bin=10
  csmf_directory="@RUNROOT@/INSTALL/OneCovariance/input/conditional_smf/"
  V_max_file="V_max.asc"
  f_tomo_file="f_tomo.asc"
fi


if [[ .*\ $MODES\ .* =~ " NE " ]] || [[ .*\ $MODES\ .* =~ " NN " ]]
then
  obs_mins=""
  obs_maxs=""
  z_mins=""
  z_maxs="" 
  file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB1.txt"
  if [ -f ${file1} ]
  then
    slice=`grep '^slice_in' ${file1} | awk '{printf $2}'`
    if [ "${slice}" == "obs" ]
    then
      for i in `seq ${NLENS}`
      do
        file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB${i}.txt"
        x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
        x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
        y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
        y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
        obs_mins="${obs_mins} $(echo "$x_lo + l(@BV:H0_IN@)/l(10)" | bc -l)"
        obs_maxs="${obs_maxs} $(echo "$x_hi + l(@BV:H0_IN@)/l(10)" | bc -l)"
        z_mins="${z_mins} ${y_lo}"
        z_maxs="${z_maxs} ${y_hi}"
      done
    elif [ "${slice}" == "z" ]
    then
      for i in `seq ${NLENS}`
      do
        file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB${i}.txt"
        x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
        x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
        y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
        y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
        obs_mins="${obs_mins} $(echo "$y_lo + l(@BV:H0_IN@)/l(10)" | bc -l)"
        obs_maxs="${obs_maxs} $(echo "$y_hi + l(@BV:H0_IN@)/l(10)" | bc -l)"
        z_mins="${z_mins} ${x_lo}"
        z_maxs="${z_maxs} ${x_hi}"
      done
    else
      _message "Got wrong or no information about slicing of the lens sample.\n"
      #exit 1
    fi
    bias_Mmin=`echo ${obs_mins} | sed 's/ /,/g'`
    bias_Mmax=`echo ${obs_maxs} | sed 's/ /,/g'`
    # Merge, split into lines, sort uniquely, and turn back into comma-separated
    #bias_mass=$(echo "$obs_mins $obs_maxs" | tr ' ' '\n' | sort -n | uniq | tr '\n' ',' | sed 's/,$//')
  else  
    _message "No lens catalog metadata found, setting default bias mass parameters from saved variables.\n"
    if [ "${NLENS}" = "1" ]
    then
      bias_Mmin=$(echo @BV:LENSLIMSX@ | awk '{print $1}')
      bias_Mmax=$(echo @BV:LENSLIMSX@ | awk '{print $2}')
    else
      bias_Mmin=$(echo @BV:LENSLIMSX@ | awk '{for(i=1; i<NF; i++) printf "%s,", $i; print ""}' | sed 's/,$//')
      bias_Mmax=$(echo @BV:LENSLIMSX@ | awk '{for(i=2; i<=NF; i++) printf "%s,", $i; print ""}' | sed 's/,$//')
    fi
  fi
else
  bias_Mmin=9.0
  bias_Mmax=13.0
  #bias_mass=9.0,13.0
fi

# Check if the arbitrary input files exist and copy to input directory
use_arbitrary=True #False
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  for i in $(seq -f "%02g" 1 $n_arb_ee)
  do
    file=`echo ${arb_fourier_filter_mmE_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
    file2=`echo ${arb_fourier_filter_mmB_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
    file3=`echo ${arb_real_filter_mm_p_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
    file4=`echo ${arb_real_filter_mm_m_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
    arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
    if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ] || [ ! -f $arb_base${file3} ] || [ ! -f $arb_base${file4} ]
    then
      #use_arbitrary=False
      _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
      break
    else
      cp ${arb_base}/{$file,$file2,$file3,$file4} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
    fi
  done
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  for i in $(seq -f "%02g" 1 $n_arb_ne)
  do
    file=`echo ${arb_fourier_filter_gm_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
    file2=`echo ${arb_real_filter_gm_file_@BV:STATISTIC@}   | sed "s/?/${i}/g"`
    arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
    if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ]
    then
      #use_arbitrary=False
      _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
      break
    else
      cp ${arb_base}/{$file,$file2} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
    fi
  done
fi
if [[ .*\ $MODES\ .* =~ " NN " ]]
then
  for i in $(seq -f "%02g" 1 $n_arb_nn)
  do
    file=`echo ${arb_fourier_filter_gg_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
    file2=`echo ${arb_real_filter_gg_file_@BV:STATISTIC@}   | sed "s/?/${i}/g"`
    arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
    if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ]
    then
      #use_arbitrary=False
      _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
      break
    else
      cp ${arb_base}/{$file,$file2} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
    fi
  done
fi

if [ "${use_arbitrary}" == "True" ]
then
  _message "Using arbitrary input files!\n"
fi

mix_term=@BV:MIXTERM@
if [ "${mix_term^^}" == "TRUE" ]
then 
  mixterm="xipxip,xipxim,ximxim"
  mixterm_basefile=`_read_datablock @BV:MIXTERM_BASEFILE@`
  mixterm_basefile=`_blockentry_to_filelist ${mixterm_basefile}`
  mixterm_basefile="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:MIXTERM_BASEFILE@/${mixterm_basefile}"
else
  mixterm=""
fi

if [ "${SECONDSTATISTIC^^}" == "2PCF" ] || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ] || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
then
  if [ "${STATISTIC^^}" == "${SECONDSTATISTIC^^}" ]
  then
    _message "You requested the OneCovariance to compute the correlation between two statistics, but both were set to ${STATISTIC^^}! Computing the covariance for this statistic only!\n"
    cov_between_stats=False
  else
    _message "You requested the OneCovariance to compute the correlation between ${STATISTIC^^} and ${SECONDSTATISTIC^^}!\n"
    cov_between_stats=True
  fi
fi

#}}}
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020_NOFEEDBACK" ]
then
  non_linear_model=mead2020
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
    exit 1
fi
IAMODEL="@BV:IAMODEL@"
# Infer central values of the prior for cosmological and nuisance parameters
central_value () {
  n=`echo $1 | awk '{print NF}'`
  if [ $n == 1 ]
  then
    value=`echo $1`
  elif [ $n == 3 ]
  then
    value=`echo $1 | awk '{print $2}'`
  fi
  echo $value
}

get_param_value() {
  local param="$1"
  local file="$2"

  awk -v p="$param" -F'=' '
    /^[[:space:]]*;/ { next }          # skip comments
    /^\[/ { next }                     # skip section headers
    NF == 2 {
      key=$1
      gsub(/[[:space:]]/, "", key)     # strip spaces/tabs from key
      if (key == p) {
        vals=$2
        sub(/;.*/, "", vals)           # strip inline comments
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", vals) # trim ends
        n=split(vals, a, /[[:space:]]+/) # split by space OR tab
        if (n==1) {
          print a[1]
        } else if (n==3) {
          print a[2]
        }
      }
    }
  ' "$file"
}

assign_if_empty() {
  local varname="$1"
  local param="$2"

  eval current=\$$varname
  if [ -z "$current" ]; then
    value=$(get_param_value "${param}" "${values}")
    eval $varname="'$value'"
  fi
}

values="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini"
ITERATION=@BV:ITERATION@
if [ -n "$ITERATION" ] && [ "$ITERATION" -eq "$ITERATION" ]
then
  CHAINSUFFIX=@BV:CHAINSUFFIX@
  previous=`echo "$ITERATION" | awk '{printf "%d", $1-1}'`
  bestfit_file=@RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/bestfit/bestfit${CHAINSUFFIX}_values_iteration_${previous}.txt
  while read name value
  do
    name=`echo $name| tr '-' '_'`
    printf -v "$name" '%s' $value
  done < ${bestfit_file}

  AIA=${intrinsic_alignment_parameters__a}
  H0=${cosmological_parameters__h0}
  ombh2=${cosmological_parameters__ombh2}
  omch2=${cosmological_parameters__omch2} 
  ns=${cosmological_parameters__n_s}
  S8=${cosmological_parameters__s_8_input}
  tcmb0=${cosmological_parameters__TCMB}
  
  logT_AGN=${halo_model_parameters__log_t_agn}

  w0=${halo_model_parameters__w0}
  wa=${halo_model_parameters__wa} 
  mnu=${halo_model_parameters__mnu}

  log10_obs_norm_c=${halo_model_parameters__log10_obs_norm_c}
  log10_m_ch=${halo_model_parameters__log10_m_ch}
  g1=${halo_model_parameters__g1}
  g2=${halo_model_parameters__g2}
  norm_s=${halo_model_parameters__norm_s}
  sigma_log10_O_c=${halo_model_parameters__sigma_log10_O_c}
  pivot=${halo_model_parameters__pivot}
  alpha_s=${halo_model_parameters__alpha_s}
  b0=${halo_model_parameters__b0}
  b1=${halo_model_parameters__b1}
  b2=${halo_model_parameters__b2}

  if [ -z "${AIA}" ]; then
    AIA=1.0
  fi
  assign_if_empty H0 "h0"
  assign_if_empty ombh2 "ombh2"
  assign_if_empty omch2 "omch2"
  assign_if_empty ns "n_s"
  assign_if_empty S8 "s_8_input"
  assign_if_empty tcmb0 "TCMB"

  assign_if_empty logT_AGN "logT_AGN"

  assign_if_empty w0 "w"
  assign_if_empty wa "wa"
  assign_if_empty mnu "mnu"

  assign_if_empty log10_obs_norm_c "log10_obs_norm_c"
  assign_if_empty log10_m_ch "log10_m_ch"
  assign_if_empty g1 "g1"
  assign_if_empty g2 "g2"
  assign_if_empty norm_s "norm_s"
  assign_if_empty sigma_log10_O_c "sigma_log10_O_c"
  assign_if_empty pivot "pivot"
  assign_if_empty alpha_s "alpha_s"
  assign_if_empty b0 "b0"
  assign_if_empty b1 "b1"
  assign_if_empty b2 "b2"

  Omega_m=`echo "$ombh2 $omch2 $H0" | awk '{printf "%f", ($1 + $2) /$3 /$3}'`
  Omega_b=`echo "$ombh2 $H0" | awk '{printf "%f", $1 /$2 /$2}'`
  Omega_de=`echo "$Omega_m $H0" | awk '{printf "%f", 1 - $1}'`
  sigma8=`echo "$S8 $Omega_m" | awk '{printf "%f", $1 / sqrt($2/0.3)}'` 

  nlparam="HMCode_logT_AGN = $logT_AGN"
  nlparam2=""
  
  filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
  nzfile_source=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz/nz${CHAINSUFFIX}_iteration_${previous}.fits
  nzfile_lens=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz/nz${CHAINSUFFIX}_iteration_${previous}.fits
  nzfile_obs=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz/nz${CHAINSUFFIX}_iteration_${previous}.fits
else
  H0=$(get_param_value h0 ${values})
  omch2=$(get_param_value omch2 ${values})
  ombh2=$(get_param_value ombh2 ${values})
  ns=$(get_param_value n_s ${values})
  S8=$(get_param_value s_8_input ${values})
  tcmb0=$(get_param_value TCMB ${values})
  AIA=1.0
  logT_AGN=$(get_param_value logT_AGN ${values})
  w0=$(get_param_value w ${values})
  wa=$(get_param_value wa ${values}) 
  mnu=$(get_param_value mnu ${values})
  Omega_m=`echo "$ombh2 $omch2 $H0" | awk '{printf "%f", ($1 + $2) /$3 /$3}'`
  Omega_b=`echo "$ombh2 $H0" | awk '{printf "%f", $1 /$2 /$2}'`
  Omega_de=`echo "$Omega_m $H0" | awk '{printf "%f", 1 - $1}'`
  sigma8=`echo "$S8 $Omega_m" | awk '{printf "%f", $1 / sqrt($2/0.3)}'` 

  log10_obs_norm_c=$(get_param_value log10_obs_norm_c ${values})
  log10_m_ch=$(get_param_value log10_m_ch ${values})
  g1=$(get_param_value g1 ${values})
  g2=$(get_param_value g2 ${values})
  norm_s=$(get_param_value norm_s ${values})
  sigma_log10_O_c=$(get_param_value sigma_log10_O_c ${values})
  pivot=$(get_param_value pivot ${values})
  alpha_s=$(get_param_value alpha_s ${values})
  b0=$(get_param_value b0 ${values})
  b1=$(get_param_value b1 ${values})
  b2=$(get_param_value b2 ${values})

  nlparam="HMCode_logT_AGN = $logT_AGN"
  nlparam2=""

  filename_extension=""
  nzfile_source=@DB:cosmosis_nz_source@
  nzfile_lens=@DB:cosmosis_nz_lens@
  nzfile_obs=@DB:cosmosis_nz_obs@
fi

# log10_obs_norm_c=10.51
# log10_m_ch=11.38
# g1=7.096
# g2=0.2
# norm_s=0.56
# sigma_log10_O_c=0.35
# pivot=13.0
# alpha_s=-0.858
# b0=-0.024
# b1=1.149
# b2=0.0


# Covariance input path (just pointing to a inputs folder in the datablock) 
input_path="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs"
# Output path
if [ "${cov_between_stats}" == "True" ]
then
  output_path=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@_@BV:SECONDSTATISTIC@
else
  output_path=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_@BV:STATISTIC@
fi
# COSEBIs basis function path
COSEBISLOC=@RUNROOT@/@CONFIGPATH@/cosebis/
msigmalist=""
for file in @DB:cosmosis_msigma@
do 
  msigmalist="${msigmalist} `cat ${file}`"
done

msigmalist=`echo ${msigmalist} | sed 's/ /,/g'`

# Base settings {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[covariance terms]
gauss = @BV:GAUSS@
split_gauss = @BV:SPLIT_GAUSS@
nongauss = @BV:NONGAUSS@
ssc = @BV:SSC@

[observables]
cosmic_shear = ${cosmic_shear}
est_shear = ${est_shear}
ggl = ${ggl}
est_ggl = ${est_ggl}
clustering = ${clustering}
est_clust = ${est_clust}
cstellar_mf = ${cstellar_mf}
cross_terms = True
unbiased_clustering = True
# combinations_clustering = $(seq 0 $((NLENS-1)) | sed 's/.*/&-&/' | paste -sd, -)

[csmf settings]
csmf_log10Mmin = ${csmf_Mmin}
csmf_log10Mmax = ${csmf_Mmax}
csmf_N_log10M_bin = ${csmf_N_log10M_bin}
csmf_directory = ${csmf_directory}
;csmf_log10M_bins =
V_max_file = ${V_max_file}
f_tomo_file = ${f_tomo_file}
csmf_diagonal = False
csmf_auto_only = True
csmf_diagonal_lenses = True

[output settings]
directory = ${output_path}
file = covariance_list_${non_linear_model}${filename_extension}.dat, covariance_matrix_${non_linear_model}${filename_extension}.mat
style = list, matrix
list_style_spatial_first = True
corrmatrix_plot = correlation_coefficient${filename_extension}.pdf
save_configs = save_configs.ini
save_Cells = True
save_trispectra = False
save_alms = False
use_tex = False

[covELLspace settings]
ell_min = @BV:LMINCOV@
ell_max = @BV:LMAXCOV@
ell_bins = @BV:LBINSCOV@
ell_type = log
delta_z = 0.08
tri_delta_z = 0.5
integration_steps = 500
nz_interpolation_polynom_order = 1
mult_shear_bias = ${msigmalist}
limber = True
pixelised_cell = False
pixel_Nside = 2048

[covRspace settings]
projected_radius_min = 0.01
projected_radius_max = 10
projected_radius_bins = 24
projected_radius_type = log
mean_redshift = 0.51, 0.6
projection_length_clustering = 100

EOF
#}}}

# Statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF

EOF

if [ "${STATISTIC^^}" == "2PCF" ] || [ "${SECONDSTATISTIC^^}" == "2PCF" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covTHETAspace settings]
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
theta_bins = @BV:NXIPM@
theta_min_lensing = @BV:THETAMINGT@
theta_max_lensing = @BV:THETAMAXGT@
theta_bins_lensing = @BV:NGT@
theta_min_clustering = @BV:THETAMINWT@
theta_max_clustering = @BV:THETAMAXWT@
theta_bins_clustering = @BV:NWT@
theta_type = log
theta_type_lensing = log
theta_type_clustering = log
theta_list = 1, 2, 3
xi_pp = ${cosmic_shear}
xi_mm = ${cosmic_shear}
ggl   = ${ggl}
clustering = ${clustering}
theta_accuracy = 1e-5
integration_intervals = 50

mix_term_do_mix_for = ${mixterm}
mix_term_file_path_catalog = ${mixterm_basefile}
mix_term_col_name_weight = @BV:WEIGHTNAME@
mix_term_col_name_pos1 = @BV:RANAME@
mix_term_col_name_pos2 = @BV:DECNAME@
mix_term_col_name_zbin = TOMOBIN
mix_term_isspherical = True
mix_term_target_patchsize = 10
mix_term_do_overlap = True
mix_term_nbins_phi = 100
mix_term_nmax = 10
mix_term_do_ec = False
mix_term_subsample = 1 
mix_term_nsubr = 7 
mix_term_file_path_save_triplets = @RUNROOT@/INSTALL/OneCovariance/input/catalogue_mixed/tripletcounts_legacy.fits
mix_term_file_path_load_triplets = @RUNROOT@/INSTALL/OneCovariance/input/catalogue_mixed/legacytriplets.fits

EOF
else
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covTHETAspace settings]
theta_accuracy = 1e-5
integration_intervals = 50

EOF
fi

if [ "${STATISTIC^^}" == "COSEBIS" ]  || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covCOSEBI settings]
En_modes = @BV:NMAXCOSEBIS@
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
En_modes_lensing = @BV:NMAXCOSEBISNE@
theta_min_lensing = @BV:THETAMINGT@
theta_max_lensing = @BV:THETAMAXGT@
En_modes_clustering = @BV:NMAXCOSEBISNN@
theta_min_clustering = @BV:THETAMINWT@
theta_max_clustering = @BV:THETAMAXWT@
En_accuracy = 1e-4
Wn_style = log

EOF
fi

if [ "${STATISTIC^^}" == "BANDPOWERS" ]  || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covbandpowers settings]
apodisation_log_width_lensing = @BV:APODISATIONWIDTH@
apodisation_log_width_clustering = @BV:APODISATIONWIDTH@
theta_lo = ${theta_lo}
theta_up = ${theta_up}
theta_lo_lensing = ${theta_lo_lensing}
theta_up_lensing = ${theta_up_lensing}
theta_lo_clustering = ${theta_lo_clustering}
theta_up_clustering = ${theta_up_clustering}
theta_binning = @BV:NTHETABINXI@
ell_min = @BV:LMINBANDPOWERS@
ell_max = @BV:LMAXBANDPOWERS@
ell_bins = @BV:NBANDPOWERS@
ell_type = log
ell_min_lensing = @BV:LMINBANDPOWERSNE@
ell_max_lensing = @BV:LMAXBANDPOWERSNE@
ell_bins_lensing = @BV:NBANDPOWERSNE@
ell_type_lensing = log
ell_min_clustering = @BV:LMINBANDPOWERSNN@
ell_max_clustering = @BV:LMAXBANDPOWERSNN@
ell_bins_clustering = @BV:NBANDPOWERSNN@
ell_type_clustering = log
bandpower_accuracy = 1e-7

EOF
fi

#}}}

# Survey specs {{{
#Get the neffective list
nefflist=""
sigmaelist=""
if [[ .*\ $MODES\ .* =~ " EE " ]] || [[ .*\ $MODES\ .* =~ " NE " ]]
then
  for file in @DB:cosmosis_neff_source@
  do
    nefflist="${nefflist} `cat ${file}`"
  done
  nefflist=`echo ${nefflist} | sed 's/ /,/g'`
  
  #get the sigmae list
  for file in @DB:cosmosis_sigmae@
  do
    sigmaelist="${sigmaelist} `cat ${file}`"
  done
  sigmaelist=`echo ${sigmaelist} | sed 's/ /,/g'`
fi

nefflist_lens=""
if [[ .*\ $MODES\ .* =~ " NE " ]] || [[ .*\ $MODES\ .* =~ " NN " ]]
then
  for file in @DB:cosmosis_neff_lens@
  do
    nefflist_lens="${nefflist_lens} `cat ${file}`"
  done
  nefflist_lens=`echo ${nefflist_lens} | sed 's/ /,/g'`
fi

surveymask=@BV:SURVEYMASKFILE@
surveymaskfile=${surveymask##*/}
surveymaskdir=${surveymask%/*}
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[survey specs]
survey_area_lensing_in_deg2 = @BV:SURVEYAREADEG@
survey_area_clust_in_deg2 = @BV:SURVEYAREADEG@
survey_area_ggl_in_deg2 = @BV:SURVEYAREADEG@
ellipticity_dispersion = ${sigmaelist}
n_eff_lensing = ${nefflist}
n_eff_clust = ${nefflist_lens}
n_eff_ggl   = ${nefflist_lens}
mask_directory = ${surveymaskdir}
mask_file_lensing = ${surveymaskfile}
mask_file_clust   = ${surveymaskfile}
mask_file_ggl     = ${surveymaskfile}

EOF
#}}}

# Redshift distribution {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[redshift]
zlens_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_source/
zlens_file = ${nzfile_source}
zlens_extension = NZ_SOURCE

zclust_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_lens/
zclust_file = ${nzfile_lens}
zclust_extension = NZ_LENS

zcsmf_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_obs/
zcsmf_file = ${nzfile_obs}
zcsmf_extension = NZ_OBS

EOF
#}}}

# All kinds of parameters {{{
npair_mm_file="@BV:NPAIRBASE_XI@_nBins_${NTOMO}_Bin?_Bin?.ascii"
npair_gm_file="@BV:NPAIRBASE_GT@_nBins_${NLENS}_Bin?_Bin?.ascii"
npair_gg_file="@BV:NPAIRBASE_WT@_nBins_${NLENS}_Bin?_Bin?.ascii"

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[cosmo]
sigma8 = $sigma8
h = $H0
omega_m = $Omega_m
omega_b = $Omega_b
omega_de = $Omega_de
w0 = $w0
wa = $wa
ns = $ns
neff = 3.046
m_nu = $mnu
tcmb0 = $tcmb0

[bias]
model = Tinker10
bias_2h = 1.0
mc_relation_cen = duffy08
mc_relation_sat = duffy08
log10mass_bins_lower = ${bias_Mmin}
log10mass_bins_upper = ${bias_Mmax}

[IA]
A_IA = $AIA
eta_IA = 0.0
z_pivot_IA = 0.3

[hod]
model_mor_cen = double_powerlaw
model_mor_sat = double_powerlaw
dpow_logm0_cen = ${log10_obs_norm_c}
dpow_logm1_cen = ${log10_m_ch}
dpow_a_cen = ${g1}
dpow_b_cen = ${g2}
dpow_norm_cen = 1.0
dpow_norm_sat = ${norm_s}
model_scatter_cen = lognormal
model_scatter_sat = modschechter
logn_sigma_c_cen = ${sigma_log10_O_c}
modsch_logmref_sat = ${pivot}
modsch_alpha_s_sat = ${alpha_s}
modsch_b_sat = ${b0}, ${b1}, ${b2}

[halomodel evaluation]
m_bins = 900
log10m_min = 6
log10m_max = 18
hmf_model = Tinker10
mdef_model = SOMean
mdef_params = overdensity, 200
disable_mass_conversion = True
delta_c = 1.686
transfer_model = CAMB
small_k_damping_for1h = damped

[powspec evaluation]
non_linear_model = ${non_linear_model}
log10k_bins = 400
log10k_min = -3.49
log10k_max = 2.15
${nlparam}
${nlparam2}

[trispec evaluation]
log10k_bins = 70
log10k_min = -3.49
log10k_max = 2
matter_klim = 0.001
matter_mulim = 0.001
small_k_damping_for1h = damped
lower_calc_limit = 1e-200

[misc]
num_cores = @BV:COVNCORES@

[tabulated inputs files]
npair_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair/
npair_mm_file = ${npair_mm_file}
npair_gm_file = ${npair_gm_file}
npair_gg_file = ${npair_gg_file}
Cell_directory = ${output_path}

EOF
#}}}

# Covariance between summary statistics {{{
if [ "${cov_between_stats}" == "True" ]
then
    if [ "${SECONDSTATISTIC^^}" == "2PCF" ]
    then
      if [[ .*\ $MODES\ .* =~ " EE " ]]
      then
        n_arb_ee2=@BV:NXIPM@
        arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_p_?.table"
        arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_m_?.table"
        arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_p_?.table"
        arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_m_?.table"
      fi
      if [[ .*\ $MODES\ .* =~ " NE " ]]
      then
        n_arb_ne2=@BV:NGT@
        arb_fourier_filter_gm_file_@BV:STATISTIC@="fourier_weight_realspace_cf_gm_?.table"
        arb_real_filter_gm_file_@BV:STATISTIC@="real_weight_realspace_cf_gm_?.table"
      fi
      if [[ .*\ $MODES\ .* =~ " NN " ]]
      then
        n_arb_nn2=@BV:NWT@
        arb_fourier_filter_gg_file_@BV:STATISTIC@="fourier_weight_realspace_cf_gg_?.table"
        arb_real_filter_gg_file_@BV:STATISTIC@="real_weight_realspace_cf_gg_?.table"
      fi
    elif [ "${SECONDSTATISTIC^^}" == "COSEBIS" ]
    then
      if [[ .*\ $MODES\ .* =~ " EE " ]]
      then
        n_arb_ee2=@BV:NMAXCOSEBIS@
        arb_fourier_filter_mmE_file_@BV:STATISTIC@="Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
        arb_fourier_filter_mmB_file_@BV:STATISTIC@="Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
        arb_real_filter_mm_p_file_@BV:STATISTIC@="Tp_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
        arb_real_filter_mm_m_file_@BV:STATISTIC@="Tm_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
      fi
      if [[ .*\ $MODES\ .* =~ " NE " ]]
      then
        n_arb_ne2=@BV:NMAXCOSEBISNE@
        arb_fourier_filter_gm_file_@BV:STATISTIC@="Qgm_@BV:THETAMINGT@_to_@BV:THETAMAXGT@_?.table"
        arb_real_filter_gm_file_@BV:STATISTIC@="Wn_psigm_@BV:THETAMINGT@_to_@BV:THETAMAXGT@_?.table"
      fi
      if [[ .*\ $MODES\ .* =~ " NN " ]]
      then
        n_arb2_nn=@BV:NMAXCOSEBISNN@
        arb_fourier_filter_gg_file_@BV:STATISTIC@="Ugg_@BV:THETAMINWT@_to_@BV:THETAMAXWT@_?.table"
        arb_real_filter_gg_file_@BV:STATISTIC@="Wn_psigg_@BV:THETAMINWT@_to_@BV:THETAMAXWT@_?.table"
      fi
    elif [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
    then
      if [[ .*\ $MODES\ .* =~ " EE " ]]
      then
        n_arb_ee2=@BV:NBANDPOWERS@
        theta_lo_lensing=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
        theta_up_lensing=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
        t_lo=`printf "%.2f" $theta_lo`
        t_up=`printf "%.2f" $theta_up`
        arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmE_?.table"
        arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmB_?.table"
        arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_bandpowers_mmE_?.table"
        arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_bandpowers_mmB_?.table"
      fi
      if [[ .*\ $MODES\ .* =~ " NE " ]]
      then
        n_arb_ne2=@BV:NBANDPOWERSNE@
        theta_lo_clustering=`echo 'e(l(@BV:THETAMINGT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
        theta_up_clustering=`echo 'e(l(@BV:THETAMAXGT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
        t_lo=`printf "%.2f" $theta_lo`
        t_up=`printf "%.2f" $theta_up`
        arb_fourier_filter_gm_file_@BV:STATISTIC@="fourier_weight_bandpowers_gm_?.table"
        arb_real_filter_gm_file_@BV:STATISTIC@="real_weight_bandpowers_gm_?.table"
      fi
      if [[ .*\ $MODES\ .* =~ " NN " ]]
      then
        n_arb_nn2=@BV:NBANDPOWERSNN@
        theta_lo_clustering=`echo 'e(l(@BV:THETAMINWT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
        theta_up_clustering=`echo 'e(l(@BV:THETAMAXWT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
        t_lo=`printf "%.2f" $theta_lo`
        t_up=`printf "%.2f" $theta_up`
        arb_fourier_filter_gg_file_@BV:STATISTIC@="fourier_weight_bandpowers_gg_?.table"
        arb_real_filter_gg_file_@BV:STATISTIC@="real_weight_bandpowers_gg_?.table"
      fi
    fi

    # Check if the arbitrary input files for second statistic exist and copy to input directory
    if [[ .*\ $MODES\ .* =~ " EE " ]]
    then
      for i in $(seq -f "%02g" 1 $n_arb_ee2)
      do
        file=`echo ${arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
        file2=`echo ${arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
        file3=`echo ${arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
        file4=`echo ${arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
        arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
        if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ] || [ ! -f $arb_base${file3} ] || [ ! -f $arb_base${file4} ]
        then
          #use_arbitrary=False
          _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
          break
        else
          cp ${arb_base}/{$file,$file2,$file3,$file4} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
        fi
      done
    fi
    if [[ .*\ $MODES\ .* =~ " NE " ]]
    then
      for i in $(seq -f "%02g" 1 $n_arb_ne2)
      do
        file=`echo ${arb_fourier_filter_gm_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
        file2=`echo ${arb_real_filter_gm_file_@BV:SECONDSTATISTIC@}   | sed "s/?/${i}/g"`
        arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
        if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ]
        then
          #use_arbitrary=False
          _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
          break
        else
          cp ${arb_base}/{$file,$file2} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
        fi
      done
    fi
    if [[ .*\ $MODES\ .* =~ " NN " ]]
    then
      for i in $(seq -f "%02g" 1 $n_arb_nn2)
      do
        file=`echo ${arb_fourier_filter_gg_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
        file2=`echo ${arb_real_filter_gg_file_@BV:SECONDSTATISTIC@}   | sed "s/?/${i}/g"`
        arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
        if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ]
        then
          #use_arbitrary=False
          _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
          break
        else
          cp ${arb_base}/{$file,$file2} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
        fi
      done
    fi

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
;arb_summary_directory = @RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
arb_summary_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
arb_fourier_filter_mmE_file = ${arb_fourier_filter_mmE_file_@BV:STATISTIC@}, ${arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@}
arb_fourier_filter_mmB_file = ${arb_fourier_filter_mmB_file_@BV:STATISTIC@}, ${arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@}
arb_real_filter_mm_p_file = ${arb_real_filter_mm_p_file_@BV:STATISTIC@}, ${arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@}
arb_real_filter_mm_m_file = ${arb_real_filter_mm_m_file_@BV:STATISTIC@}, ${arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@}
arb_fourier_filter_gm_file = ${arb_fourier_filter_gm_file_@BV:STATISTIC@}, ${arb_fourier_filter_gm_file_@BV:SECONDSTATISTIC@}
arb_real_filter_gm_file = ${arb_real_filter_gm_file_@BV:STATISTIC@}, ${arb_real_filter_gm_file_@BV:SECONDSTATISTIC@}
arb_fourier_filter_gg_file = ${arb_fourier_filter_gg_file_@BV:STATISTIC@}, ${arb_fourier_filter_gg_file_@BV:SECONDSTATISTIC@}
arb_real_filter_gg_file = ${arb_real_filter_gg_file_@BV:STATISTIC@}, ${arb_real_filter_gg_file_@BV:SECONDSTATISTIC@}

[arbitrary_summary]
do_arbitrary_obs = True
oscillations_straddle = 50
arbitrary_accuracy = 1e-5

EOF

fi
if [ "${use_arbitrary}" == "True" ] && [ "${cov_between_stats}" != "True" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
;arb_summary_directory = @RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
arb_summary_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
arb_fourier_filter_mmE_file = ${arb_fourier_filter_mmE_file_@BV:STATISTIC@}
arb_fourier_filter_mmB_file = ${arb_fourier_filter_mmB_file_@BV:STATISTIC@}
arb_real_filter_mm_p_file = ${arb_real_filter_mm_p_file_@BV:STATISTIC@}
arb_real_filter_mm_m_file = ${arb_real_filter_mm_m_file_@BV:STATISTIC@}
arb_fourier_filter_gm_file = ${arb_fourier_filter_gm_file_@BV:STATISTIC@}
arb_real_filter_gm_file = ${arb_real_filter_gm_file_@BV:STATISTIC@}
arb_fourier_filter_gg_file = ${arb_fourier_filter_gg_file_@BV:STATISTIC@}
arb_real_filter_gg_file = ${arb_real_filter_gg_file_@BV:STATISTIC@}

[arbitrary_summary]
do_arbitrary_obs = True
oscillations_straddle = 50
arbitrary_accuracy = 1e-5

EOF
fi
#}}}


#Construct the .ini file {{{
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@BV:STATISTIC@_@SURVEY@_CosmoPipe_constructed.ini

#}}}

