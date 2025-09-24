#=========================================
#
# File Name : covariance_constructor.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Fri 08 Dec 2023 10:48:51 AM CET
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
if [ "${STATISTIC^^}" == "XIPM" ]
then
  est_shear=xi_pm
  n_arb=@BV:NXIPM@
  arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
  arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
  arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
  arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
elif [ "${STATISTIC^^}" == "COSEBIS" ]
then
  est_shear=cosebi
  n_arb=@BV:NMAXCOSEBIS@
  arb_fourier_filter_mmE_file_@BV:STATISTIC@="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
  arb_fourier_filter_mmB_file_@BV:STATISTIC@="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
  arb_real_filter_mm_p_file_@BV:STATISTIC@="Tplus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
  arb_real_filter_mm_m_file_@BV:STATISTIC@="Tminus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
elif [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ]
then
  est_shear=cosebi
  n_arb=@BV:NMAXCOSEBIS@
  arb_fourier_filter_mmE_file_@BV:STATISTIC@="dimensionless_Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
  arb_fourier_filter_mmB_file_@BV:STATISTIC@="dimensionless_Wn_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
  arb_real_filter_mm_p_file_@BV:STATISTIC@="dimensionless_Tp_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
  arb_real_filter_mm_m_file_@BV:STATISTIC@="dimensionless_Tm_@BV:THETAMINXI@_to_@BV:THETAMAXXI@_?.table"
elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
  est_shear=bandpowers
  n_arb=@BV:NBANDPOWERS@
  theta_lo=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
  theta_up=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
  t_lo=`printf "%.2f" $theta_lo`
  t_up=`printf "%.2f" $theta_up`
  arb_fourier_filter_mmE_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmE_${t_lo}-${t_up}_?.table"
  arb_fourier_filter_mmB_file_@BV:STATISTIC@="fourier_weight_bandpowers_mmB_${t_lo}-${t_up}_?.table"
  arb_real_filter_mm_p_file_@BV:STATISTIC@="real_weight_bandpowers_mmE_${t_lo}-${t_up}_?.table"
  arb_real_filter_mm_m_file_@BV:STATISTIC@="real_weight_bandpowers_mmB_${t_lo}-${t_up}_?.table"
else 
  #ERROR: Unknown statistic {{{
  _message "Unknown statistic: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
# Check if the arbitrary input files exist and copy to input directory
use_arbitrary=True
for i in $(seq -f "%02g" 1 $n_arb)
do
  file=`echo ${arb_fourier_filter_mmE_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file2=`echo ${arb_fourier_filter_mmB_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file3=`echo ${arb_real_filter_mm_p_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  file4=`echo ${arb_real_filter_mm_m_file_@BV:STATISTIC@} | sed "s/?/${i}/g"`
  arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
  if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ] || [ ! -f $arb_base${file3} ] || [ ! -f $arb_base${file4} ]
  then
    if [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ]
    then
      _message "Error: dimensionless COSEBIs require precalculated filter functions!\n"
      exit 1
    else
      use_arbitrary=False
      _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
      break
    fi
  else
    cp ${arb_base}/{$file,$file2,$file3,$file4} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
  fi
done
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
if [ "${SECONDSTATISTIC^^}" == "XIPM" ] || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ] || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
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
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  non_linear_model=mead2020_feedback
  #non_linear_model=mead2020
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

  if [ "${IAMODEL^^}" == "LINEAR" ] 
	then
    AIA=$intrinsic_alignment_parameters__a
  else
    AIA=`central_value "@BV:PRIOR_AIA@"`
  fi
  H0=${cosmological_parameters__h0}
  omega_b=${cosmological_parameters__ombh2}
  omega_c=${cosmological_parameters__omch2} 
  ns=${cosmological_parameters__n_s}
  S8=${cosmological_parameters__s_8_input}
  if [ "${non_linear_model}" == "mead2020_feedback" ]
  then
    logT_AGN=${halo_model_parameters__log_t_agn}
    nlparam="HMCode_logT_AGN = $logT_AGN"
    nlparam2=""
  elif [ "${non_linear_model}" == "mead2015" ]
  then
    Abary=${halo_model_parameters__a}
    eta=`echo "$Abary 0.98 -0.12" | awk '{printf "%f", $2 + $3 * $1}'`
    nlparam="HMCode_A_baryon = $Abary"
    nlparam2="HMCode_eta_baryon = $eta"
  fi
  filename_extension=${CHAINSUFFIX}_iteration_${ITERATION}
  nzfile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/biased_nz/nz${CHAINSUFFIX}_iteration_${previous}.fits
else
  AIA=`central_value "@BV:PRIOR_AIA@"`
  H0=`central_value "@BV:PRIOR_H0@"`
  omega_b=`central_value "@BV:PRIOR_OMBH2@"`
  omega_c=`central_value "@BV:PRIOR_OMCH2@"` 
  ns=`central_value "@BV:PRIOR_NS@"`
  S8=`central_value "@BV:PRIOR_S8INPUT@"`
  filename_extension=""
  nzfile=@DB:cosmosis_nz@
  nlparam2=""
  if [ "${non_linear_model}" == "mead2020_feedback" ]
  then
    logT_AGN=`central_value "@BV:PRIOR_LOGTAGN@"`
    nlparam="HMCode_logT_AGN = $logT_AGN"
  elif [ "${non_linear_model}" == "mead2015" ]
  then
    Abary=`central_value "@BV:PRIOR_ABARY@"`
    # a_0 and a_1 are hardcoded in the cosmosis constructor as well...
    eta=`echo "$Abary 0.98 -0.12" | awk '{printf "%f", $2 + $3 * $1}'`
    nlparam="HMCode_A_baryon = $Abary"
    nlparam2="HMCode_eta_baryon = $eta"
  fi
fi
w0=`central_value "@BV:PRIOR_W@"`
wa=`central_value "@BV:PRIOR_WA@"` 
mnu=`central_value "@BV:PRIOR_MNU@"`
Omega_m=`echo "$omega_b $omega_c $H0" | awk '{printf "%f", ($1 + $2) /$3 /$3}'`
Omega_b=`echo "$omega_b $H0" | awk '{printf "%f", $1 /$2 /$2}'`
Omega_de=`echo "$Omega_m $H0" | awk '{printf "%f", 1 - $1}'`
sigma8=`echo "$S8 $Omega_m" | awk '{printf "%f", $1 / sqrt($2/0.3)}'`

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
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'` 
# Base settings {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[covariance terms]
gauss = @BV:GAUSS@
split_gauss = @BV:SPLIT_GAUSS@
nongauss = @BV:NONGAUSS@
ssc = @BV:SSC@

[observables]
cosmic_shear = True
est_shear = ${est_shear}
ggl = False
est_ggl = gamma_t
clustering = False
est_clust = w
cstellar_mf = False
cross_terms = True
unbiased_clustering = True

[csmf settings]
csmf_log10Mmin = 9.1
csmf_log10Mmax = 11.3
csmf_N_log10M_bin = 10
csmf_directory = @RUNROOT@/INSTALL/OneCovariance/input/conditional_smf/
;csmf_log10M_bins = 
V_max_file = V_max.asc
f_tomo_file = f_tomo.asc

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

if [ "${STATISTIC^^}" == "XIPM" ] || [ "${SECONDSTATISTIC^^}" == "XIPM" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covTHETAspace settings]
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
theta_bins = @BV:NXIPM@
theta_type = log
theta_list = 1, 2, 3
xi_pp = True
xi_mm = True
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
mix_term_file_path_load_triplets = /net/home/fohlen13/reischke/Git/OneCovariance/input/catalogue_mixed/legacytriplets.fits

EOF
else
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covTHETAspace settings]
theta_accuracy = 1e-5
integration_intervals = 50

EOF
fi

if [ "${STATISTIC^^}" == "COSEBIS" ]  || [ "${SECONDSTATISTIC^^}" == "COSEBIS" ] || [ "${STATISTIC^^}" == "COSEBIS_DIMLESS" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covCOSEBI settings]
En_modes = @BV:NMAXCOSEBIS@
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
En_accuracy = 1e-4
Wn_style = log

EOF
fi

if [ "${STATISTIC^^}" == "BANDPOWERS" ]  || [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[covbandpowers settings]
apodisation_log_width = @BV:APODISATIONWIDTH@
theta_lo = ${theta_lo}
theta_up = ${theta_up}
theta_binning = @BV:NTHETABINXI@
ell_min = @BV:LMINBANDPOWERS@
ell_max = @BV:LMAXBANDPOWERS@
ell_bins = @BV:NBANDPOWERS@
ell_type = log
bandpower_accuracy = 1e-7

EOF
fi

#}}}

# Survey specs {{{
#Get the neffective list 
nefflist=""
for file in @DB:cosmosis_neff@
do 
  nefflist="${nefflist} `cat ${file}`"
done 
nefflist=`echo ${nefflist} | sed 's/ /,/g'`
#get the sigmae list 
sigmaelist=""
for file in @DB:cosmosis_sigmae@
do 
  sigmaelist="${sigmaelist} `cat ${file}`"
done 
sigmaelist=`echo ${sigmaelist} | sed 's/ /,/g'`
surveymask=@BV:SURVEYMASKFILE@
surveymaskfile=${surveymask##*/}
surveymaskdir=${surveymask%/*}
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[survey specs]
survey_area_lensing_in_deg2 = @BV:SURVEYAREADEG@
ellipticity_dispersion = ${sigmaelist}
n_eff_lensing = ${nefflist}
mask_directory = ${surveymaskdir}
mask_file_lensing = ${surveymaskfile}

EOF
#}}}

# Redshift distribution {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
[redshift]
z_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz/
zlens_file = ${nzfile}
zlens_extension = NZ_SOURCE

EOF
#}}}
WnLog_filelist=""
Tplus_filelist=""
Tminus_filelist=""
for i in  `seq @BV:NMAXCOSEBIS@`
do
  WnLog_filelist="${WnLog_filelist} WnLog/WnLog${i}-@BV:THETAMINXI@-@BV:THETAMAXXI@.table,"
  Tplus_filelist="${Tplus_filelist} Tplus/Tp_@BV:THETAMINXI@-@BV:THETAMAXXI@_${i}.table,"
  Tminus_filelist="${Tminus_filelist} Tminus/Tm_@BV:THETAMINXI@-@BV:THETAMAXXI@_${i}.table,"
done
# All kinds of parameters {{{
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
tcmb0 = 2.725

[bias]
model = Tinker10
bias_2h = 1.0
mc_relation_cen = duffy08
mc_relation_sat = duffy08
log10mass_bins = 9.1, 11.3

[IA]
A_IA = $AIA
eta_IA = 0.0
z_pivot_IA = 0.3

[hod]
model_mor_cen = double_powerlaw
model_mor_sat = double_powerlaw
dpow_logm0_cen = 10.51
dpow_logm1_cen = 11.38
dpow_a_cen = 7.096
dpow_b_cen = 0.2
dpow_norm_cen = 1.0
dpow_norm_sat = 0.56
model_scatter_cen = lognormal
model_scatter_sat = modschechter
logn_sigma_c_cen = 0.35
modsch_logmref_sat = 13.0
modsch_alpha_s_sat = -0.858
modsch_b_sat = -0.024, 1.149

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
npair_mm_file = @BV:NPAIRBASE_XI@_nBins_${NTOMO}_Bin?_Bin?.ascii
# These files should not be required anymore.
# cosebi_directory = @RUNROOT@/@CONFIGPATH@/cosebis/
# wn_log_file = ${WnLog_filelist}
# wn_gg_file = W_Psi-@BV:THETAMINXI@-@BV:THETAMAXXI@-lmin-0.5-lmax-1000000.0-lbins-1000000.table
# Tn_plus_file = ${Tplus_filelist}
# Tn_minus_file = ${Tminus_filelist}
# Qn_file = Qn/Q_n_@BV:THETAMINXI@-@BV:THETAMAXXI@_?
# Un_file = Un/U_n_@BV:THETAMINXI@-@BV:THETAMAXXI@_?
Cell_directory = ${output_path}

EOF
#}}}

# Covariance between summary statistics {{{
if [ "${cov_between_stats}" == "True" ]
then
    if [ "${SECONDSTATISTIC^^}" == "XIPM" ]
    then
      n_arb2=@BV:NXIPM@
      arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@="fourier_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
      arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@="fourier_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
      arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@="real_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
      arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@="real_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    elif [ "${SECONDSTATISTIC^^}" == "COSEBIS" ]
    then
      n_arb2=@BV:NMAXCOSEBIS@
      arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
      arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
      arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@="Tplus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
      arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@="Tminus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    elif [ "${SECONDSTATISTIC^^}" == "BANDPOWERS" ]
    then
      n_arb2=@BV:NBANDPOWERS@
      theta_lo=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
      theta_up=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
      t_lo=`printf "%.2f" $theta_lo`
      t_up=`printf "%.2f" $theta_up`
      arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@="fourier_weight_bandpowers_mmE_${t_lo}-${t_up}_?.table"
      arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@="fourier_weight_bandpowers_mmB_${t_lo}-${t_up}_?.table"
      arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@="real_weight_bandpowers_mmE_${t_lo}-${t_up}_?.table"
      arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@="real_weight_bandpowers_mmB_${t_lo}-${t_up}_?.table"
    fi

    # Check if the arbitrary input files for second statistic exist and copy to input directory
    for i in $(seq -f "%02g" 1 $n_arb2)
    do
      file=`echo ${arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
      file2=`echo ${arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
      file3=`echo ${arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
      file4=`echo ${arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@} | sed "s/?/${i}/g"`
      arb_base=@RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
      if [ ! -f $arb_base${file} ] || [ ! -f $arb_base${file2} ] || [ ! -f $arb_base${file3} ] || [ ! -f $arb_base${file4} ]
      then
        use_arbitrary=False
        _message "One or more arbitrary input files do not exist. Calculating filters on the fly!\n"
        break
      else
        cp ${arb_base}/{$file,$file2,$file3,$file4} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
      fi
    done
    #arb_fourier_filter_mmE_file_xipm="fourier_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    #arb_fourier_filter_mmB_file_xipm="fourier_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    #arb_real_filter_mm_p_file_xipm="real_weight_realspace_cf_mm_p_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    #arb_real_filter_mm_m_file_xipm="real_weight_realspace_cf_mm_m_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"

    #arb_fourier_filter_mmE_file_cosebis="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    #arb_fourier_filter_mmB_file_cosebis="WnLog_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    #arb_real_filter_mm_p_file_cosebis="Tplus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"
    #arb_real_filter_mm_m_file_cosebis="Tminus_@BV:THETAMINXI@-@BV:THETAMAXXI@_?.table"

    #t_lo=`printf "%.2f" $theta_lo`
    #t_up=`printf "%.2f" $theta_up`
    #arb_fourier_filter_mmE_file_bandpowers="fourier_weight_bandpowers_mmE_${t_lo}-${t_up}_?.table"
    #arb_fourier_filter_mmB_file_bandpowers="fourier_weight_bandpowers_mmB_${t_lo}-${t_up}_?.table"
    #arb_real_filter_mm_p_file_bandpowers="real_weight_bandpowers_mmE_${t_lo}-${t_up}_?.table"
    #arb_real_filter_mm_m_file_bandpowers="real_weight_bandpowers_mmB_${t_lo}-${t_up}_?.table"

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
#arb_summary_directory = @RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
arb_summary_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
arb_fourier_filter_mmE_file = ${arb_fourier_filter_mmE_file_@BV:STATISTIC@}, ${arb_fourier_filter_mmE_file_@BV:SECONDSTATISTIC@}
arb_fourier_filter_mmB_file = ${arb_fourier_filter_mmB_file_@BV:STATISTIC@}, ${arb_fourier_filter_mmB_file_@BV:SECONDSTATISTIC@}
arb_real_filter_mm_p_file = ${arb_real_filter_mm_p_file_@BV:STATISTIC@}, ${arb_real_filter_mm_p_file_@BV:SECONDSTATISTIC@}
arb_real_filter_mm_m_file = ${arb_real_filter_mm_m_file_@BV:STATISTIC@}, ${arb_real_filter_mm_m_file_@BV:SECONDSTATISTIC@}

[arbitrary_summary]
do_arbitrary_obs = True
oscillations_straddle = 50
arbitrary_accuracy = 1e-5

EOF

fi
if [ "${use_arbitrary}" == "True" ] && [ "${cov_between_stats}" != "True" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
#arb_summary_directory = @RUNROOT@/@CONFIGPATH@/covariance_arb_summary/
arb_summary_directory = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_inputs/arb_summary_filters/
arb_fourier_filter_mmE_file = ${arb_fourier_filter_mmE_file_@BV:STATISTIC@}
arb_fourier_filter_mmB_file = ${arb_fourier_filter_mmB_file_@BV:STATISTIC@}
arb_real_filter_mm_p_file = ${arb_real_filter_mm_p_file_@BV:STATISTIC@}
arb_real_filter_mm_m_file = ${arb_real_filter_mm_m_file_@BV:STATISTIC@}

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

