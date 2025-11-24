#=========================================
#
# File Name : cosmosis_constructor_3x2pt.sh
# Created By : dvornik
# Creation Date : 09-08-2024
# Last Modified : Fri 16 Aug 2024 02:07:25 PM CEST
#
#=========================================
#Script to generate a cosmosis .ini, values, & priors file 
#Prepare the starting items {{{

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/ ]
then
    mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/
fi

IAMODEL="@BV:IAMODEL@"
CHAINSUFFIX=@BV:CHAINSUFFIX@
blind=@BV:BLIND@

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[DEFAULT]
MY_PATH      = @RUNROOT@/

stats_name    = @BV:STATISTIC@
CSL_PATH      = %(MY_PATH)s/INSTALL/cosmosis-standard-library/
KCAP_PATH     = %(MY_PATH)s/INSTALL/kcap/
HMPATH        = %(MY_PATH)s/INSTALL/onepower/

OUTPUT_FOLDER = %(MY_PATH)s/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/%(stats_name)s/chain/
CONFIG_FOLDER = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/

blind              = @BV:BLIND@
redshift_name      = source
redshift_name_lens = lens
redshift_name_obs  = obs

; default values for halo model part
nz_def = 5 ; 15
nk_def = 300 ; 300
zmin_def =  0.0
zmax_def = 1.2
nmass_def = 100 ; 200
logmassmin_def = 9.0
logmassmax_def = 18.0
beta_nl = True
mead2020_corrections = fit_feedback

SAMPLER_NAME = @BV:SAMPLER@
RUN_NAME = %(SAMPLER_NAME)s_%(blind)s${CHAINSUFFIX}

2PT_STATS_PATH = %(MY_PATH)s/INSTALL/2pt_stats/

EOF
#}}}
STATISTIC="@BV:STATISTIC@"
SAMPLER="@BV:SAMPLER@"
BOLTZMAN="@BV:BOLTZMAN@"
MODES="@BV:MODES@"
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENSBINS="@BV:NLENSBINS@"
NSMFLENSBINS="@BV:NSMFLENSBINS@"
NSMFBINS="@BV:NSMFBINS@"
#Define the data file name {{{
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ]
then
  _message "The ${BOLTZMAN^^} Emulator is broken: it produces S_8 constraints that are systematically high.\nUse 'COSMOPOWER_HM2015_S8'\n"
  exit 1
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi


datafile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}_${blind}${iteration}.sacc

if [ -f ${datafile} ]
then
  datafile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}_${blind}${iteration}.sacc
else
  datafile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${iteration}.sacc
fi

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
2PT_FILE = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${iteration}.sacc

EOF
#}}}

#Set up the scale cuts module {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc.ini <<- EOF
[sacc]
file = %(CSL_PATH)s/likelihood/sacc/sacc_like.py
sacc_like = twopoint
data_file = ${datafile}
kind = linear
include_norm = F
EOF
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc_b.ini <<- EOF
[sacc_b]
file = %(CSL_PATH)s/likelihood/sacc/sacc_like.py
sacc_like = twopoint
data_file = ${datafile}
kind = linear
include_norm = F
EOF
fi
#}}}


#Requested statistic {{{
if [ "${STATISTIC^^}" == "COSEBIS" ] || [ "${STATISTIC^^}" == "COSEBIS_B" ] #{{{
then 
cosebis_configpath=@RUNROOT@/@CONFIGPATH@/cosebis/
  
stats=""
twopt_modules=""
flip=""
lo_ee=""
hi_ee=""
lo_ne=""
hi_ne=""
lo_nn=""
hi_nn=""
if [[ .*\ $MODES\ .* =~ " NN " ]]
then
  stats="${stats} galaxy_density_cosebi"
  twopt_modules="${twopt_modules} psi_gg"
  lo_ee=`echo @BV:NMINCOSEBIS@ | awk '{print $1-0.5}'`
  hi_ee=`echo @BV:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  stats="${stats} galaxy_shearDensity_cosebi_e"
  flip="${flip} galaxy_shearDensity_cosebi_e"
  twopt_modules="${twopt_modules} psi_gm"
  lo_ne=`echo @BV:NMINCOSEBISNE@ | awk '{print $1-0.5}'`
  hi_ne=`echo @BV:NMAXCOSEBISNE@ | awk '{print $1+0.5}'`
fi
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  stats="${stats} galaxy_shear_cosebi_ee"
  twopt_modules="${twopt_modules} cosebis"
  lo_nn=`echo @BV:NMINCOSEBISNN@ | awk '{print $1-0.5}'`
  hi_nn=`echo @BV:NMAXCOSEBISNN@ | awk '{print $1+0.5}'`
fi
if [[ .*\ $MODES\ .* =~ " OBS " ]]
then
  stats="${stats} galaxy_stellarmassfunction"
  twopt_modules="${twopt_modules} project_1d"
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc.ini <<- EOF
data_sets = ${stats}
flip = ${flip}
galaxy_density_cosebi_section = psi_stats_gg
galaxy_shearDensity_cosebi_e_section = psi_stats_gm
galaxy_shear_cosebi_ee_section = cosebis
galaxy_stellarmassfunction_section = smf

angle_range_galaxy_density_cosebi = ${lo_nn} ${hi_nn}
angle_range_galaxy_shearDensity_cosebi_e = ${lo_ne} ${hi_ne}
angle_range_galaxy_shear_cosebi_ee = ${lo_ee} ${hi_ee}

EOF
twopt_modules="${twopt_modules} sacc"

if [ "${STATISTIC^^}" == "COSEBIS_B" ]
then 
cosebis_configpath=@RUNROOT@/@CONFIGPATH@/cosebis/
lo=`echo @BV:NMINCOSEBIS@ | awk '{print $1-0.5}'`
hi=`echo @BV:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
  
twopt_modules="${twopt_modules} cosebis_b "
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc_b.ini <<- EOF
data_sets = alaxy_shear_cosebi_bb
angle_range_galaxy_shear_cosebi_bb = ${lo} ${hi}
galaxy_shear_cosebi_bb_section = cosebis_b

EOF
twopt_modules="${twopt_modules} sacc_b"

fi
#}}}

echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini
#statistic {{{
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis]
file = %(2PT_STATS_PATH)s/cl_to_cosebis/cl_to_cosebis_interface.so
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
n_max =  @BV:NMAXCOSEBIS@
Roots_n_Norms_FolderName = ${cosebis_configpath}/TLogsRootsAndNorms/
Wn_Output_FolderName = ${cosebis_configpath}/WnLog/
Tn_Output_FolderName = %(2PT_STATS_PATH)s/TpnLog/
output_section_name = cosebis
input_section_name = shear_cl
add_2D_cterm = 0 ; (optional) DEFAULT is 0: do not add it
add_c_term = 0

EOF
if [ "${STATISTIC^^}" == "COSEBIS_B" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis_b]
file = %(2PT_STATS_PATH)s/cl_to_cosebis/cl_to_cosebis_interface.so
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
n_max =  @BV:NMAXCOSEBIS@
Roots_n_Norms_FolderName = ${cosebis_configpath}/TLogsRootsAndNorms/
Wn_Output_FolderName = ${cosebis_configpath}/WnLog/
Tn_Output_FolderName = %(2PT_STATS_PATH)s/TpnLog/
output_section_name = cosebis_b
input_section_name = shear_cl_bb
add_2D_cterm = 0 ; (optional) DEFAULT is 0: do not add it
add_c_term = 0

EOF
fi
fi

if [[ .*\ $MODES\ .* =~ " NE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[psi_gm]
file = %(2PT_STATS_PATH)s/cl_to_psi/cl_to_psi_interface.so
type = gm
theta_min = @BV:THETAMINGT@
theta_max = @BV:THETAMAXGT@
n_max =  @BV:NMAXCOSEBISNE@
; l_bins = 1000000
; l_min = 0.5
; l_max = 1e6
W_output_folder_name = %(WnLogPath)s/WFilters/
W_file_name = W_Psi
output_section_name = psi_stats_gm
input_section_name = galaxy_shear_cl


EOF
fi

if [[ .*\ $MODES\ .* =~ " NN " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[psi_gg]
file = %(2PT_STATS_PATH)s/cl_to_psi/cl_to_psi_interface.so
type = gg
theta_min = @BV:THETAMINWT@
theta_max = @BV:THETAMAXWT@
n_max =  @BV:NMAXCOSEBISNN@
; l_bins = 1000000
; l_min = 0.5
; l_max = 1e6
W_output_folder_name = %(WnLogPath)s/WFilters/
W_file_name = W_Psi
output_section_name = psi_stats_gg
input_section_name = galaxy_cl


EOF
fi

#}}}

#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ] #{{{
then
  #scale cut {{{
stats=""
flip=""
twopt_modules=""
if [[ .*\ $MODES\ .* =~ " NN " ]]
then
  stats="${stats} galaxy_density_cl"
  twopt_modules="${twopt_modules} bandpower_clustering"
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  stats="${stats} galaxy_shearDensity_cl_e"
  flip="${flip} galaxy_shearDensity_cl_e"
  twopt_modules="${twopt_modules} bandpower_ggl"
fi
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  stats="${stats} galaxy_shear_cl_ee"
  twopt_modules="${twopt_modules} bandpower_shear_e"
fi
if [[ .*\ $MODES\ .* =~ " OBS " ]]
then
  stats="${stats} galaxy_stellarmassfunction"
  twopt_modules="${twopt_modules} project_1d"
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc.ini <<- EOF
data_sets = ${stats}
flip = ${flip}
galaxy_density_cl_section = bandpower_clustering
galaxy_shearDensity_cl_e_section = bandpower_ggl
galaxy_shear_cl_ee_section = bandpower_shear_e
galaxy_stellarmassfunction_section = smf

angle_range_galaxy_density_cl = @BV:LMINBANDPOWERSNN@ @BV:LMAXBANDPOWERSNN@
angle_range_galaxy_shearDensity_cl_e = @BV:LMINBANDPOWERSNE@ @BV:LMAXBANDPOWERSNE@
angle_range_galaxy_shear_cl_ee = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
twopt_modules="${twopt_modules} sacc"

if [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
stats=""
flip=""
twopt_modules=""
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  stats="${stats} galaxy_shear_cl_bb"
  twopt_modules="${twopt_modules} bandpower_shear_b"
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  stats="${stats} galaxy_shearDensity_cl_b"
  flip="${flip} galaxy_shearDensity_cl_b"
  twopt_modules="${twopt_modules} bandpower_ggl_b"
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc_b.ini <<- EOF
data_sets = ${stats}
flip = ${flip}
galaxy_shearDensity_cl_b_section = bandpower_ggl_b
galaxy_shear_cl_bb_section = bandpower_shear_b

angle_range_galaxy_shearDensity_cl_b = @BV:LMINBANDPOWERSNE@ @BV:LMAXBANDPOWERSNE@
angle_range_galaxy_shear_cl_bb = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
twopt_modules="${twopt_modules} sacc_b"
fi
#}}}

echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
theta_lo_ee=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
theta_up_ee=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
#Statistic {{{
if [ "${STATISTIC^^}" == "BANDPOWERS" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_shear_e]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = cosmic_shear_e
response_function_type = tophat
analytic = 1
output_section_name = bandpower_shear_e
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min = ${theta_lo_ee}
theta_max = ${theta_up_ee}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = shear_cl

EOF
elif [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_shear_e]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = cosmic_shear_e
response_function_type = tophat
analytic = 1
output_section_name = bandpower_shear_e
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min = ${theta_lo_ee}
theta_max = ${theta_up_ee}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = shear_cl

EOF

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_shear_b]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = cosmic_shear_b
response_function_type = tophat
analytic = 1
output_section_name = bandpower_shear_b
l_min = @BV:LMINBANDPOWERS@
l_max = @BV:LMAXBANDPOWERS@
nbands = @BV:NBANDPOWERS@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min =${theta_lo_ee}
theta_max = ${theta_up_ee}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = shear_cl
input_section_name_bmode = shear_cl_bb

EOF
fi
fi
#}}}


if [[ .*\ $MODES\ .* =~ " NE " ]]
then
theta_lo_ne=`echo 'e(l(@BV:THETAMINGT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
theta_up_ne=`echo 'e(l(@BV:THETAMAXGT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
#Statistic {{{
if [ "${STATISTIC^^}" == "BANDPOWERS" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_ggl]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = ggl
response_function_type = tophat
analytic = 1
output_section_name = bandpower_ggl
l_min = @BV:LMINBANDPOWERSNE@
l_max = @BV:LMAXBANDPOWERSNE@
nbands = @BV:NBANDPOWERSNE@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min = ${theta_lo_ne}
theta_max = ${theta_up_ne}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_shear_cl

EOF
elif [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_ggl]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = ggl
response_function_type = tophat
analytic = 1
output_section_name = bandpower_ggl
l_min = @BV:LMINBANDPOWERSNE@
l_max = @BV:LMAXBANDPOWERSNE@
nbands = @BV:NBANDPOWERSNE@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min =${theta_lo_ne}
theta_max = ${theta_up_ne}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_shear_cl

EOF

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_ggl_b]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = ggl
response_function_type = tophat
analytic = 1
output_section_name = bandpower_ggl_b
l_min = @BV:LMINBANDPOWERSNE@
l_max = @BV:LMAXBANDPOWERSNE@
nbands = @BV:NBANDPOWERSNE@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min =${theta_lo_ne}
theta_max = ${theta_up_ne}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_shear_cl
input_section_name_bmode = galaxy_shear_cl_bb

EOF
fi
fi
#}}}

if [[ .*\ $MODES\ .* =~ " NN " ]]
then
theta_lo_nn=`echo 'e(l(@BV:THETAMINWT@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
theta_up_nn=`echo 'e(l(@BV:THETAMAXWT@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
#Statistic {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpower_clustering]
file = %(2PT_STATS_PATH)s/band_powers/band_powers_interface.so
type = clustering
response_function_type = tophat
analytic = 1
output_section_name = bandpower_clustering
l_min = @BV:LMINBANDPOWERSNN@
l_max = @BV:LMAXBANDPOWERSNN@
nbands = @BV:NBANDPOWERSNN@
apodise = 1
delta_x = @BV:APODISATIONWIDTH@
theta_min = ${theta_lo_nn}
theta_max = ${theta_up_nn}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = galaxy_cl

EOF
fi
#}}}


#}}}
elif [ "${STATISTIC^^}" == "2PCF" ] #{{{
then 
  #scale cut {{{
  if [ "${SAMPLER^^}" == "LIST" ]
  then 
    #Keep consistency between plus and minus 
    ximinus_min=@BV:THETAMINXI@
    ximinus_max=@BV:THETAMAXXI@
  else
    #Use the appropriate scale cut  
    ximinus_min=@BV:THETAMINXIM@
    ximinus_max=@BV:THETAMAXXIM@
  fi
  
  stats=""
  flip=""
  twopt_modules=""
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    stats="${stats} galaxy_density_xi"
    twopt_modules="${twopt_modules} wth wth_conv"
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    stats="${stats} galaxy_shearDensity_xi_t"
	flip="${flip} galaxy_shearDensity_xi_t"
    twopt_modules="${twopt_modules} gt gt_conv"
  fi
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    stats="${stats} galaxy_shear_xi_plus galaxy_shear_xi_minus"
    twopt_modules="${twopt_modules} xi xip_conv xim_conv"
  fi
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    stats="${stats} galaxy_stellarmassfunction"
    twopt_modules="${twopt_modules} project_1d"
  fi
  
twopt_modules="${twopt_modules} sacc"

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc.ini <<- EOF
data_sets = ${stats}
flip = ${flip}
galaxy_density_xi_section = galaxy_xi
galaxy_shearDensity_xi_t_section = galaxy_shear_xi
galaxy_shear_xi_plus_section = shear_xi_plus
galaxy_shear_xi_minus_section = shear_xi_minus
galaxy_stellarmassfunction_section = smf

angle_range_galaxy_density_xi = @BV:THETAMINWT@ @BV:THETAMAXWT@
angle_range_galaxy_shearDensity_xi_t = @BV:THETAMINGT@ @BV:THETAMAXGT@
angle_range_galaxy_shear_xi_plus = @BV:THETAMINXI@ @BV:THETAMAXXI@
angle_range_galaxy_shear_xi_minus = ${ximinus_min}  ${ximinus_max}

EOF
#}}}

echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini
#statistic {{{
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[xi]
file = %(CSL_PATH)s/shear/cl_to_xi_fullsky/cl_to_xi_interface.py
n_theta_bins = @BV:NXIPM@
n_theta = @BV:NXIPM@
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
ell_max = 40000
xi_type = '22'
; theta_file = ${datafile} ; Not working with scale_cuts.py that well!
bin_avg = F
input_section_name = shear_cl
output_section_name = shear_xi

[xip_conv]
file = %(HMPATH)s/cosmosis_modules/convert_theta/convert_theta.py
output_units = arcmin
section_name = shear_xi_plus

[xim_conv]
file = %(HMPATH)s/cosmosis_modules/convert_theta/convert_theta.py
output_units = arcmin
section_name = shear_xi_minus

EOF
fi

if [[ .*\ $MODES\ .* =~ " NE " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[gt]
file = %(CSL_PATH)s/shear/cl_to_xi_fullsky/cl_to_xi_interface.py
n_theta_bins = @BV:NGT@
n_theta = @BV:NGT@
theta_min = @BV:THETAMINGT@
theta_max = @BV:THETAMAXGT@
ell_max = 40000
xi_type = '02'
; theta_file = ${datafile} ; Not working with scale_cuts.py that well!
bin_avg = F
input_section_name = galaxy_shear_cl
output_section_name = galaxy_shear_xi

[gt_conv]
file = %(HMPATH)s/cosmosis_modules/convert_theta/convert_theta.py
output_units = arcmin
section_name = galaxy_shear_xi


EOF
fi

if [[ .*\ $MODES\ .* =~ " NN " ]]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[wth]
file = %(CSL_PATH)s/shear/cl_to_xi_fullsky/cl_to_xi_interface.py
n_theta_bins = @BV:NWT@
n_theta = @BV:NWT@
theta_min = @BV:THETAMINWT@
theta_max = @BV:THETAMAXWT@
ell_max = 40000
xi_type = '00'
; theta_file = ${datafile} ; Not working with scale_cuts.py that well!
bin_avg = F
input_section_name = galaxy_cl
output_section_name = galaxy_xi

[wth_conv]
file = %(HMPATH)s/cosmosis_modules/convert_theta/convert_theta.py
output_units = arcmin
section_name = galaxy_xi



EOF
fi
#}}}

#}}}
else 
  #ERROR: unknown statistic {{{
  _message "Statistic Unknown: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
#}}}

bnl_delete=""
fast_slow="F"

#Requested sampler {{{
OUTPUTNAME="%(OUTPUT_FOLDER)s/output_%(RUN_NAME)s.txt"
VALUES=values
PRIORS=priors
listparam=''
if [ "${SAMPLER^^}" == "TEST" ] #{{{
then 
bnl_delete="bnl_delete"
fast_slow="F"
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[test]
save_dir=%(OUTPUT_FOLDER)s/output_%(RUN_NAME)s
fatal_errors=T

EOF

#}}}
elif [ "${SAMPLER^^}" == "MAXLIKE" ] #{{{
then 
fast_slow="F"
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[maxlike]
method = Nelder-Mead
tolerance = 0.01
maxiter = 1000000
max_posterior = T

EOF

#}}}
elif [ "${SAMPLER^^}" == "MULTINEST" ] #{{{
then 
fast_slow="T"
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[multinest]
max_iterations=100000
multinest_outfile_root= %(OUTPUT_FOLDER)s/%(RUN_NAME)s_
resume=F
tolerance = 0.01
constant_efficiency = F
live_points = 1000
efficiency = 0.3

EOF

#}}}
elif [ "${SAMPLER^^}" == "POLYCHORD" ] #{{{
then 
fast_slow="T"
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[polychord]
live_points = 300
;tolerance = 0.001
tolerance = 0.01
num_repeats = 60
boost_posteriors = 10.0 
fast_fraction = 0.1 
feedback = 3 
resume = T
base_dir = %(OUTPUT_FOLDER)s/PC
polychord_outfile_root = pc_run

EOF

#}}}
elif [ "${SAMPLER^^}" == "NAUTILUS" ] #{{{
then
fast_slow="F"
n_batch=`echo "@BV:NTHREADS@" | awk '{printf "%d", 4*$1}'`
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[nautilus]
n_live = 4000
enlarge_per_dim = 1.1
split_threshold = 100
n_networks = 8
n_batch = $n_batch
filepath = %(OUTPUT_FOLDER)s/run_nautilus.hdf5
resume =  False ; True
f_live = 0.01
discard_exploration = True
verbose = True
n_eff = 10000

EOF

#}}}
elif [ "${SAMPLER^^}" == "APRIORI" ] #{{{
then 
fast_slow="F"
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[apriori]
nsample=500000

EOF

#}}}
elif [ "${SAMPLER^^}" == "GRID" ] #{{{
then
  fast_slow="F"
  #Set up the fixed values file {{{
  VALUES=values_fixed
  PRIORS=
  echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values_fixed.ini
  while read line 
  do
    var=`echo ${line} | awk '{print $1}'`
    #if [ "${var}" == "s_8_input" ] || [ "${var}" == "omch2" ] || [ "${var}" == "ombh2" ] || [ "${var:0:1}" == "[" ] || [ "${var}" == "" ] 
    if [ "${var}" == "s_8_input" ] || [ "${var}" == "omch2" ] || [ "${var:0:1}" == "[" ] || [ "${var}" == "" ]
    then
      #we have a variable we want, or a block definition, or an empty line: Reproduce the line
      echo ${line} >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values_fixed.ini
    else 
      #we have a variable we don't want: Print the variable with the expectation value only 
      expect=`echo ${line} | awk -F= '{print $2}' | awk -F\; '{print $1}' | awk '{ if (NF>1) { print $2 } else { print $1 } }'`
      echo ${var} = ${expect} >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values_fixed.ini
    fi 
  done <  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  #}}}
  cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
	[grid]
	nsample_dimension=36
	EOF

#}}}
elif [ "${SAMPLER^^}" == "LIST" ] #{{{
then
  fast_slow="F"
  if [[ .*\ $MODES\ .* =~ " EE " ]]
  then
    ncombinations_ee=`echo "$NTOMO" | awk '{printf "%u", $1*($1+1)/2 }'`
  else
    ncombinations_ee=0
  fi
  if [[ .*\ $MODES\ .* =~ " NE " ]]
  then
    ncombinations_ne=`echo "$NLENSBINS" "$NTOMO" | awk '{printf "%u", $1*$2 }'`
  else
    ncombinations_ne=0
  fi
  if [[ .*\ $MODES\ .* =~ " NN " ]]
  then
    # No cross terms here!
    ncombinations_nn=`echo "$NLENSBINS" | awk '{printf "%u", $1 }'`
  else
    ncombinations_nn=0
  fi
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    ncombinations_obs=`echo "$NSMFLENSBINS" | awk '{printf "%u", $1 }'`
  else
    ncombinations_obs=0
  fi
  
  #if [ "${STATISTIC^^}" == "2PCF" ]
  #then
  #  ncombinations=$(($ncombinations_ee + $ncombinations_ee + $ncombinations_ne + $ncombinations_nn))
  #else
  #  ncombinations=$(($ncombinations_ee + $ncombinations_ne + $ncombinations_nn))
  #fi
    
  if [[ .*\ $MODES\ .* =~ " OBS " ]]
  then
    ndat_obs=`echo "$ncombinations_obs @BV:NSMFBINS@" | awk '{printf "%u", $1*$2 }'`
  else
    ndat_obs=0
  fi
  
  if [ "${STATISTIC^^}" == "COSEBIS" ]
  then
    ndat_=`echo "$ncombinations_ee $ncombinations_ne $ncombinations_nn @BV:NMAXCOSEBIS@ @BV:NMAXCOSEBISNE@ @BV:NMAXCOSEBISNN@" | awk '{printf "%u", ($1*$4)+($2*$5)+($3*$6) }'`
    ndat=$(($ndat_ + $ndat_obs))
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
  then 
	ndat_=`echo "$ncombinations_ee $ncombinations_ne $ncombinations_nn @BV:NBANDPOWERS@ @BV:NBANDPOWERSNE@ @BV:NBANDPOWERSNN@" | awk '{printf "%u", ($1*$4)+($2*$5)+($3*$6) }'`
    ndat=$(($ndat_ + $ndat_obs))
  elif [ "${STATISTIC^^}" == "2PCF" ]
  then 
	ndat_=`echo "$ncombinations_ee $ncombinations_ne $ncombinations_nn @BV:NXIPM@ @BV:NGT@ @BV:NWT@" | awk '{printf "%u", ($1*$4)+($2*$5)+($3*$6) }'`
    ndat=$(($ndat_ + $ndat_obs))
  fi
  listparam="scale_cuts_output/theory#${ndat}"
  list_input="@BV:LIST_INPUT_SAMPLER@"

	cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
	[list]
	filename = %(OUTPUT_FOLDER)s/output_${list_input}_%(blind)s${CHAINSUFFIX}.txt 
	
	EOF
  OUTPUTNAME="%(OUTPUT_FOLDER)s/output_list_${list_input}_%(blind)s${CHAINSUFFIX}.txt"

#}}}
elif [ "${SAMPLER^^}" == "EMCEE" ] #{{{
then 
  _message "Sampler Unimplemented: ${SAMPLER^^}\n"
  exit 1

#}}}
else 
  #ERROR: unknown sampler {{{
  _message "Sampler Unknown: ${SAMPLER^^}\n"
  exit 1
  #}}}
fi
#}}}

#Prepare the pipeline section {{{ 
extraparams="cosmological_parameters/S_8 cosmological_parameters/sigma_8 cosmological_parameters/A_s cosmological_parameters/omega_m cosmological_parameters/omega_nu cosmological_parameters/omega_lambda"

#Add source nz shift values to outputs {{{
shifts_source=""
for i in `seq ${NTOMO}`
do 
   shifts_source="${shifts_source} nofz_shifts/bias_${i}"
done
#}}}

#Add lens nz shift values to outputs {{{
shifts_lens=""
for i in `seq ${NLENSBINS}`
do
   shifts_lens="${shifts_lens} nofz_shifts_lens/bias_${i}"
done
#}}}


#Add the values information #{{{
if [ "@BV:COSMOSIS_PIPELINE@" == "default" ]
then
    # Set up boltzmann code blocks
    if [ "${BOLTZMAN^^}" == "HALO_MODEL" ]
    then
        boltzmann_pipeline="camb"
    elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
    then
        boltzmann_pipeline="cosmopower"
    else
        _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
          exit 1
    fi
    # Set up intrinsic alignment pipeline blocks {{{
    if [ "${IAMODEL^^}" == "LINEAR" ]
    then
        iamodel_pipeline="linear_alignment projection"
    elif [ "${IAMODEL^^}" == "TATT" ]
    then
        iamodel_pipeline="fast_pt tatt projection add_intrinsic"
    elif [ "${IAMODEL^^}" == "LINEAR_Z" ]
    then
        iamodel_pipeline="linear_alignment projection lin_z_dependence_for_ia add_intrinsic"
    elif [ "${IAMODEL^^}" == "MASSDEP" ]
    then
        iamodel_pipeline="correlated_massdep_priors linear_alignment projection mass_dependence_for_ia add_intrinsic"
    elif [ "${IAMODEL^^}" == "HALO_MODEL" ]
    then
        #iamodel_pipeline="projection add_intrinsic"
		iamodel_pipeline="projection"
    else
        _message "Intrinsic alignment model not implemented: ${IAMODEL^^}\n"
          exit 1
    fi

    COSMOSIS_PIPELINE="sample_S8 correlated_dz_priors load_nz_sacc consistency ${boltzmann_pipeline} extrapolate onepower ${iamodel_pipeline} source_photoz_bias ${twopt_modules}"
    
elif [ "@BV:COSMOSIS_PIPELINE@" == "lin_bias" ]
then
    # Set up boltzmann code blocks
    if [ "${BOLTZMAN^^}" == "HALO_MODEL" ]
    then
        boltzmann_pipeline="camb"
    elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
    then
        boltzmann_pipeline="cosmopower"
    else
        _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
          exit 1
    fi
    # Set up intrinsic alignment pipeline blocks {{{
    if [ "${IAMODEL^^}" == "LINEAR" ]
    then
        iamodel_pipeline="linear_alignment projection"
    elif [ "${IAMODEL^^}" == "TATT" ]
    then
        iamodel_pipeline="fast_pt tatt projection add_intrinsic"
    elif [ "${IAMODEL^^}" == "LINEAR_Z" ]
    then
        iamodel_pipeline="linear_alignment projection lin_z_dependence_for_ia add_intrinsic"
    elif [ "${IAMODEL^^}" == "MASSDEP" ]
    then
        iamodel_pipeline="correlated_massdep_priors linear_alignment projection mass_dependence_for_ia add_intrinsic"
    else
        _message "Intrinsic alignment model not implemented: ${IAMODEL^^}\n"
          exit 1
    fi
    
    COSMOSIS_PIPELINE="sample_S8 correlated_dz_priors load_nz_sacc ${boltzmann_pipeline} extrapolate_power source_photoz_bias ${iamodel_pipeline} ${twopt_modules}"
else
	COSMOSIS_PIPELINE="@BV:COSMOSIS_PIPELINE@"
fi
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
[pipeline]
modules = ${COSMOSIS_PIPELINE}
values  = %(CONFIG_FOLDER)s/@SURVEY@_${VALUES}.ini
EOF
#}}}
#If needed, add the priors information #{{{
if [ "${PRIORS}" != "" ] 
then 
  cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
	priors  = %(CONFIG_FOLDER)s/@SURVEY@_priors.ini
	EOF
fi 
#}}}
#Add tpds to outputs {{{
tpdparams=""
if [ "@BV:SAVE_TPDS@" == "True" ]
then
	if [[ .*\ $MODES\ .* =~ " EE " ]]
	then
		for tomo1 in `seq ${NTOMO}`
		do
			for tomo2 in `seq ${tomo1} ${NTOMO}`
			do
				if [ "${STATISTIC^^}" == "BANDPOWERS" ]
				then
					tpdparams="${tpdparams} bandpower_shear_e/bin_${tomo2}_${tomo1}#@BV:NBANDPOWERS@"
				elif [ "${STATISTIC^^}" == "COSEBIS" ]
				then
					tpdparams="${tpdparams} cosebis/bin_${tomo2}_${tomo1}#@BV:NMAXCOSEBIS@"
				elif [ "${STATISTIC^^}" == "2PCF" ]
				then
					tpdparams="${tpdparams} shear_xi_plus/bin_${tomo2}_${tomo1}#@BV:NXIPM@ shear_xi_minus/bin_${tomo2}_${tomo1}#@BV:NXIPM@"
				fi
			done
		done
	fi
	if [[ .*\ $MODES\ .* =~ " NE " ]]
	then
		for tomo1 in `seq ${NLENSBINS}`
		do
			for tomo2 in `seq ${NTOMO}`
			do
				if [ "${STATISTIC^^}" == "BANDPOWERS" ]
				then
					tpdparams="${tpdparams} bandpower_ggl/bin_${tomo1}_${tomo2}#@BV:NBANDPOWERSNE@"
				elif [ "${STATISTIC^^}" == "COSEBIS" ]
				then
					tpdparams="${tpdparams} psi_stats_gm/bin_${tomo1}_${tomo2}#@BV:NMAXCOSEBISNE@"
				elif [ "${STATISTIC^^}" == "2PCF" ]
				then
					tpdparams="${tpdparams} galaxy_shear_xi/bin_${tomo1}_${tomo2}#@BV:NGT@"
				fi
			done
		done
	fi
	if [[ .*\ $MODES\ .* =~ " NN " ]]
	then
		for tomo1 in `seq ${NLENSBINS}`
		do
			# If we also want to use cross-terms here we need to enable them!
			if [ "${STATISTIC^^}" == "BANDPOWERS" ]
			then
				tpdparams="${tpdparams} bandpower_clustering/bin_${tomo1}_${tomo1}#@BV:NBANDPOWERSNN@"
			elif [ "${STATISTIC^^}" == "COSEBIS" ]
			then
				tpdparams="${tpdparams} psi_stats_gg/bin_${tomo1}_${tomo1}#@BV:NMAXCOSEBISNN@"
			elif [ "${STATISTIC^^}" == "2PCF" ]
			then
				tpdparams="${tpdparams} galaxy_xi/bin_${tomo1}_${tomo1}#@BV:NWT@"
			fi
		done
	fi
	if [[ .*\ $MODES\ .* =~ " OBS " ]]
	then
		for tomo1 in `seq ${NSMFLENSBINS}`
		do
			#tpdparams="${tpdparams} smf/bin_${tomo1}#@BV:NSMFBINS@"
			tpdparams="${tpdparams} data_vector/galaxy_stellarmassfunction_mass_theory#@BV:NSMFBINS@"
		done
	fi
fi
#}}}

#Add the other information #{{{
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
; likelihoods  = loglike loglike_b
EOF
else
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
; likelihoods  = loglike
EOF
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
extra_output = ${extraparams} ${shifts} ${listparam} ${tpdparams}
timing = F ; T
debug = F
fast_slow = ${fast_slow}
first_fast_module = hod ; halo_model_ingredients_halomod

[runtime]
sampler = %(SAMPLER_NAME)s
verbosity = quiet ; normal ; quiet
pool_stdout = F ; T

[output]
filename = ${OUTPUTNAME}
format = text

EOF
#}}}
#}}}

#Requested boltzman {{{
if [ "${BOLTZMAN^^}" == "HALO_MODEL" ] #{{{
then
  if [ "@BV:COSMOSIS_PIPELINE@" == "lin_bias" ]
  then
    nl="pk"
  else
    nl="none"
  fi
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = power
nonlinear = ${nl} ; none ; pk
halofit_version = mead2020_feedback
neutrino_hierarchy = normal
kmax = 20.0
kmax_extrapolate = 1000.0
nk = 300
zmin = 0.0
zmax = 3.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ] #{{{
then
  if [ "@BV:COSMOSIS_PIPELINE@" == "lin_bias" ]
  then
    nl="pk"
    emu="nonlin_matter_power_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/log10_reference_non_lin_matter_power_emulator_mead2020_feedback"
    ref="reference_nonlinear_spectra = %(MY_PATH)s/INSTALL/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/center_non_linear_matter_mead2020_feedback.npz"
  else
    nl="none"
    emu=""
    ref=""
  fi
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface_new.py
do_reionization = F
mode = power
nonlinear = ${nl} ; none ; pk
halofit_version = mead2020_feedback ; We need to use this here in order to correctly select the emulator
neutrino_hierarchy = normal
kmax = 20.0
kmax_extrapolate = 1000.0
nk = 300
zmin = 0.0
zmax = 3.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

sample_S8 = True
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmin = 1e-5

lin_matter_power_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/log10_reference_lin_matter_power_emulator_mead2020_feedback
; nonlin_matter_power_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/log10_reference_non_lin_matter_power_emulator_mead2020_feedback
${emu}
reference_linear_spectra = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/center_linear_matter_mead2020_feedback.npz
; reference_nonlinear_spectra = %(MY_PATH)s/INSTALL/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/center_non_linear_matter_mead2020_feedback.npz
${ref}
; As_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/As_emulator

EOF
#}}}
else
  #ERROR: unknown boltzman code
  _message "Boltzman Code Unknown: ${BOLTZMAN^^}\n"
  exit 1
fi
#}}}


#Additional Modules {{{
echo > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini
modulelist=`echo ${COSMOSIS_PIPELINE} | sed 's/ /\n/g' | sort | uniq | awk '{printf $0 " "}'`
for module in ${modulelist}
do 
  case ${module} in
	"sample_S8") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/sample_S8.py
			s8_name = s_8_input
			sigma8_name = sigma_8
			
			EOF
			;;#}}}
	"consistency") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/utility/consistency/consistency_interface.py
			
			EOF
			;; #}}}
	"correlated_dz_priors") #{{{
			shifts_source=""
			unc_shifts=""
			for i in `seq ${NTOMO}`
			do
				shifts_source="${shifts_source} nofz_shifts/bias_${i}"
				unc_shifts="${unc_shifts} nofz_shifts/uncorr_bias_${i}"
			done
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/correlated_priors.py
			uncorrelated_parameters = ${unc_shifts}
			output_parameters = ${shifts_source}
			covariance = @DB:nzcov@
			
			EOF
			;; #}}}
	"extrapolate") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/boltzmann/extrapolate/extrapolate_power.py
			kmax = 1e8
			nmax = 0
			
			EOF
			;; #}}}
	"load_nz_sacc") #{{{
			sets=""
			if [[ .*\ $MODES\ .* =~ " EE " ]] || [[ .*\ $MODES\ .* =~ " NE " ]]
			then
				sets="${sets} %(redshift_name)s"
			fi
			if [[ .*\ $MODES\ .* =~ " NE " ]] || [[ .*\ $MODES\ .* =~ " NN " ]]
			then
				sets="${sets} %(redshift_name_lens)s"
			fi
			if [[ .*\ $MODES\ .* =~ " OBS " ]]
			then
				sets="${sets} %(redshift_name_obs)s"
			fi
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/load_nz_sacc/load_nz_sacc.py
			nz_file = ${datafile}
			data_sets = ${sets}
			
			EOF
			;; #}}}
	"source_photoz_bias") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/photoz_bias/photoz_bias.py
			mode = additive
			sample = nz_%(redshift_name)s
			bias_section  = nofz_shifts
			interpolation = cubic
			output_deltaz = T
			output_section_name = delta_z_out
			
			EOF
			;; #}}}

	"add_intrinsic") #{{{
			if [[ .*\ $MODES\ .* =~ " EE " ]]
			then
				ee="True"
			else
				ee="False"
			fi
			if [[ .*\ $MODES\ .* =~ " NE " ]]
			then
				ne="True"
			else
				ne="False"
			fi
			add_intrinsic=True
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file=%(CSL_PATH)s/shear/add_intrinsic/add_intrinsic.py
			shear-shear=${ee}
			position-shear=${ne}
			perbin=F
			
			EOF
			;; #}}}

	"project_1d") #{{{
			z_mins=""
			z_maxs=""
			suffix=`seq -s ' ' ${NSMFLENSBINS}`
			file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB1.txt"
			slice=`grep '^slice_in' ${file1} | awk '{printf $2}'`
			if [ "${slice}" == "obs" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					#z_mins="${z_mins} ${y_lo}"
					z_mins="${z_mins} 0.0"
					z_maxs="${z_maxs} ${y_hi}"
				done
			elif [ "${slice}" == "z" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					#z_mins="${z_mins} ${x_lo}"
					z_mins="${z_mins} 0.0"
					z_maxs="${z_maxs} ${x_hi}"
				done
			else
				_message "Got wrong or no information about slicing of the lens sample.\n"
				#exit 1
			fi
			h0_in=`echo "@BV:H0_IN@" | awk '{printf "%d", 100*$1}'`
			omega_m="@BV:OMEGAM_IN@"
			omega_v="@BV:OMEGAV_IN@"
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/structure/projection_1d/project_1d.py
			input_section_name = stellar_mass_function:{1-${NSMFLENSBINS}}
			output_section_name = smf
			zmin = ${z_mins}
			zmax = ${z_maxs}
			observable_type = mass
			sample = nz_obs
			astropy_cosmology_class = LambdaCDM
			cosmo_kwargs = "{'H0':${h0_in}, 'Om0':${omega_m}, 'Ode0':${omega_v}}"
			
			EOF
			;; #}}}

	"onepower") #{{{
			if [[ .*\ $MODES\ .* =~ " EE " ]]
			then
				ee="True"
			else
				ee="False"
			fi
			if [[ .*\ $MODES\ .* =~ " NE " ]]
			then
				ne="True"
			else
				ne="False"
			fi
			if [[ .*\ $MODES\ .* =~ " NN " ]]
			then
				nn="True"
			else
				nn="False"
			fi
			
			hod_obs_mins=""
			hod_obs_maxs=""
			hod_z_mins=""
			hod_z_maxs=""
			hod_file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB1.txt"
			hod_slice=`grep '^slice_in' ${hod_file1} | awk '{printf $2}'`
			if [ "${hod_slice}" == "obs" ]
			then
				for i in `seq ${NLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					hod_obs_mins="${hod_obs_mins} ${x_lo}"
					hod_obs_maxs="${hod_obs_maxs} ${x_hi}"
					#hod_z_mins="${hod_z_mins} ${y_lo}"
					#hod_z_maxs="${hod_z_maxs} ${y_hi}"
					hod_z_mins="${hod_z_mins} 0.0"
					hod_z_maxs="${hod_z_maxs} 3.0"
				done
			elif [ "${hod_slice}" == "z" ]
			then
				for i in `seq ${NLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					hod_obs_mins="${hod_obs_mins} ${y_lo}"
					hod_obs_maxs="${hod_obs_maxs} ${y_hi}"
					#hod_z_mins="${hod_z_mins} ${x_lo}"
					#hod_z_maxs="${hod_z_maxs} ${x_hi}"
					hod_z_mins="${hod_z_mins} 0.0"
					hod_z_maxs="${hod_z_maxs} 3.0"
				done
			else
				_message "Got wrong or no information about slicing of the lens sample.\n"
				#exit 1
			fi
			
			smf_obs_mins=""
			smf_obs_maxs=""
			smf_z_mins=""
			smf_z_maxs=""
			smf_file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB1.txt"
			smf_slice=`grep '^slice_in' ${smf_file1} | awk '{printf $2}'`
			if [ "${smf_slice}" == "obs" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					smf_obs_mins="${smf_obs_mins} ${x_lo}"
					smf_obs_maxs="${smf_obs_maxs} ${x_hi}"
					#smf_z_mins="${smf_z_mins} ${y_lo}"
					#smf_z_maxs="${smf_z_maxs} ${y_hi}"
					smf_z_mins="${smf_z_mins} 0.0"
					smf_z_maxs="${smf_z_maxs} 3.0"
				done
			elif [ "${smf_slice}" == "z" ]
			then
				for i in `seq ${NSMFLENSBINS}`
				do
					file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
					x_lo=`grep '^x_lims_lo' ${file} | awk '{printf $2}'`
					x_hi=`grep '^x_lims_hi' ${file} | awk '{printf $2}'`
					y_lo=`grep '^y_lims_lo' ${file} | awk '{printf $2}'`
					y_hi=`grep '^y_lims_hi' ${file} | awk '{printf $2}'`
					smf_obs_mins="${smf_obs_mins} ${y_lo}"
					smf_obs_maxs="${smf_obs_maxs} ${y_hi}"
					#smf_z_mins="${smf_z_mins} ${x_lo}"
					#smf_z_maxs="${smf_z_maxs} ${x_hi}"
					smf_z_mins="${smf_z_mins} 0.0"
					smf_z_maxs="${smf_z_maxs} 3.0"
				done
			else
				_message "Got wrong or no information about slicing of the lens sample.\n"
				#exit 1
			fi
			
			red_obs_file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/red_cen_obs_pdf.txt"
			blue_obs_file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/blue_cen_obs_pdf.txt"
			
			if [ "$add_intrinsic" == "True" ]
			then
				cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
				[$module]
				file= %(HMPATH)s/cosmosis_modules/onepower_interface.py
				p_mm = ${ee}
				p_gg = ${nn}
				p_gm = ${ne}
				p_gI = ${ne}
				p_mI = ${ee}
				p_II = ${ee}
				split_ia = True
				
				EOF
			else
				cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
				[$module]
				file= %(HMPATH)s/cosmosis_modules/onepower_interface.py
				p_mm = ${ee}
				p_gg = ${nn}
				p_gm = ${ne}
				p_gI = False
				p_mI = False
				p_II = False
				split_ia = True
				
				EOF
			fi

			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			bnl =  %(beta_nl)s
			update_bnl = 10
			poisson_type = constant
			point_mass = True
			dewiggle = True
			response = False
			output_suffix = onepower
			use_mead2020_corrections = %(mead2020_corrections)s
			
			log_mass_min = %(logmassmin_def)s
			log_mass_max = %(logmassmax_def)s
			nmass = %(nmass_def)s
			zmin_hmf= %(zmin_def)s
			zmax_hmf= %(zmax_def)s
			nz_hmf= %(nz_def)s
			nk = %(nk_def)s
			
			hmf_model = Tinker10
			bias_model = Tinker10
			mdef_model = SOMean
			overdensity = 200.0
			delta_c = 1.686
			cm_model_cen = Duffy08
			profile_cen = NFW
			cm_model_sat = Duffy08
			profile_sat = NFW
			
			hod_section_name = hod
			observable_section_name = stellar_mass_function
			save_observable = True
			values_name = hod_parameters
			hod_model = Cacciato
			observable_h_unit = 1/h^2
			
			log10_obs_min_hod = ${hod_obs_mins}
			log10_obs_max_hod = ${hod_obs_maxs}
			zmin_hod = ${hod_z_mins}
			zmax_hod = ${hod_z_maxs}
			nz_hod = 50 ; %(nz_def)s
			nobs_hod = 200
			
			log10_obs_min_smf = ${smf_obs_mins}
			log10_obs_max_smf = ${smf_obs_maxs}
			zmin_smf = ${smf_z_mins}
			zmax_smf = ${smf_z_maxs}
			nz_smf = 50 ; %(nz_def)s
			nobs_smf = 200
			
			hod_section_name_ia_1 = hod_ia_red
			observables_file_ia_1 = ${red_obs_file}
			nobs_ia_1 = 200
			nz_ia_1 = 50 ; %(nz_def)s
			central_IA_depends_on = halo_mass
			satellite_IA_depends_on = halo_mass
			output_suffix_ia_1 = ia_red
			
			hod_section_name_ia_2 = hod_ia_blue
			observables_file_ia_2 = ${blue_obs_file}
			nobs_ia_2 = 200 
			nz_ia_2 = 50 ; %(nz_def)s
			central_IA_depends_on = halo_mass
			satellite_IA_depends_on = halo_mass
			output_suffix_ia_2 = ia_blue
			
			EOF
			;; #}}}

	"projection") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/structure/projection/project_2d.py
			ell_min_logspaced = 1.0
			ell_max_logspaced = 1.0e5
			n_ell_logspaced = 50
			verbose = F
			get_kernel_peaks = F
			
			EOF
			if [ "$add_intrinsic" == "True" ]
			then
				if [[ .*\ $MODES\ .* =~ " EE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; Cosmic shear projections
					shear-shear = %(redshift_name)s-%(redshift_name)s
					shear-intrinsic = %(redshift_name)s-%(redshift_name)s
					intrinsic-intrinsic = %(redshift_name)s-%(redshift_name)s
					#intrinsicb-intrinsicb = %(redshift_name)s-%(redshift_name)s
			
					EOF
				fi
				if [[ .*\ $MODES\ .* =~ " NE " ]]
				then
					if [ "@BV:COSMOSIS_PIPELINE@" == "default" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; GGL projections
						GenericClustering-Shear = %(redshift_name_lens)s-%(redshift_name)s:{1-${NLENSBINS}}:
						GenericClustering-Intrinsic = %(redshift_name_lens)s-%(redshift_name)s ; :{1-${NLENSBINS}}:
			
						EOF
					elif [ "@BV:COSMOSIS_PIPELINE@" == "lin_bias" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; GGL projections
						lingal-shear = %(redshift_name_lens)s-%(redshift_name)s
						lingal-intrinsic = %(redshift_name_lens)s-%(redshift_name)s
			
						EOF
					else
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; GGL projections
						position-shear = %(redshift_name_lens)s-%(redshift_name)s
						position-intrinsic = %(redshift_name_lens)s-%(redshift_name)s
			
						EOF
					fi
				fi
				if [[ .*\ $MODES\ .* =~ " NN " ]]
				then
					if [ "@BV:COSMOSIS_PIPELINE@" == "default" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; Clustering projections
						auto_only = genericclustering-genericclustering
						GenericClustering-GenericClustering = %(redshift_name_lens)s-%(redshift_name_lens)s:{1-${NLENSBINS}}:
			
						EOF
					elif [ "@BV:COSMOSIS_PIPELINE@" == "lin_bias" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; Clustering projections
						auto_only = genericclustering-genericclustering
						lingal-lingal = %(redshift_name_lens)s-%(redshift_name_lens)s
			
						EOF
					else
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; Clustering projections
						auto_only = genericclustering-genericclustering
						position-position = %(redshift_name_lens)s-%(redshift_name_lens)s
			
						EOF
					fi
				fi
			else
				if [[ .*\ $MODES\ .* =~ " EE " ]]
				then
					cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
					; Cosmic shear projections
					shear-shear = %(redshift_name)s-%(redshift_name)s
				
					EOF
				fi
				if [[ .*\ $MODES\ .* =~ " NE " ]]
				then
					if [ "@BV:COSMOSIS_PIPELINE@" == "default" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; GGL projections
						GenericClustering-Shear = %(redshift_name_lens)s-%(redshift_name)s:{1-${NLENSBINS}}:
			
						EOF
					elif [ "@BV:COSMOSIS_PIPELINE@" == "lin_bias" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; GGL projections
						lingal-shear = %(redshift_name_lens)s-%(redshift_name)s
			
						EOF
					else
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; GGL projections
						position-shear = %(redshift_name_lens)s-%(redshift_name)s
			
						EOF
					fi
				fi
				if [[ .*\ $MODES\ .* =~ " NN " ]]
				then
					if [ "@BV:COSMOSIS_PIPELINE@" == "default" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; Clustering projections
						auto_only = genericclustering-genericclustering
						GenericClustering-GenericClustering = %(redshift_name_lens)s-%(redshift_name_lens)s:{1-${NLENSBINS}}:
			
						EOF
					elif [ "@BV:COSMOSIS_PIPELINE@" == "lin_bias" ]
					then
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; Clustering projections
						auto_only = genericclustering-genericclustering
						lingal-lingal = %(redshift_name_lens)s-%(redshift_name_lens)s
			
						EOF
					else
						cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
						; Clustering projections
						auto_only = genericclustering-genericclustering
						position-position = %(redshift_name_lens)s-%(redshift_name_lens)s
			
						EOF
					fi
				fi
			fi
			;; #}}}
	"linear_alignment") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/intrinsic_alignments/la_model/linear_alignments_interface.py
			method = bk_corrected
			
			EOF
			;; #}}}
	"tatt") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/intrinsic_alignments/tatt/tatt_interface.py
			sub_lowk=F
			do_galaxy_intrinsic=F
			ia_model=tatt
			
			EOF
			;; #}}}
	"lin_z_dependence_for_ia") #{{{
			if [[ .*\ $MODES\ .* =~ " EE " ]]
			then
				ee="True"
			else
				ee="False"
			fi
			if [[ .*\ $MODES\ .* =~ " NE " ]]
			then
				ne="True"
			else
				ne="False"
			fi
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = @RUNROOT@/INSTALL/ia_models/lin_z_dependent_ia/lin_z_dependent_ia_model.py
			sample = %(redshift_name)s
			do_shear_intrinsic = ${ee}
			do_galaxy_intrinsic = ${ne}
			
			EOF
			;; #}}}
	"mass_dependence_for_ia") #{{{
			if [[ .*\ $MODES\ .* =~ " EE " ]]
			then
				ee="True"
			else
				ee="False"
			fi
			if [[ .*\ $MODES\ .* =~ " NE " ]]
			then
				ne="True"
			else
				ne="False"
			fi
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = @RUNROOT@/INSTALL/ia_models/mass_dependent_ia/mass_dependent_ia_model.py
			do_shear_intrinsic = ${ee}
			do_galaxy_intrinsic = ${ne}
			
			EOF
			;; #}}}
	"fast_pt") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/structure/fast_pt/fast_pt_interface.py
			do_ia = T
			k_res_fac = 0.5
			verbose = F
			
			EOF
			;; #}}}
	"correlated_massdep_priors") #{{{
	  massdep_params="intrinsic_alignment_parameters/a intrinsic_alignment_parameters/beta intrinsic_alignment_parameters/log10_M_mean_1 intrinsic_alignment_parameters/log10_M_mean_2 intrinsic_alignment_parameters/log10_M_mean_3 intrinsic_alignment_parameters/log10_M_mean_4 intrinsic_alignment_parameters/log10_M_mean_5 intrinsic_alignment_parameters/log10_M_mean_6"
	  unc_massdep_params="intrinsic_alignment_parameters/uncorr_a intrinsic_alignment_parameters/uncorr_beta intrinsic_alignment_parameters/uncorr_log10_M_mean_1 intrinsic_alignment_parameters/uncorr_log10_M_mean_2 intrinsic_alignment_parameters/uncorr_log10_M_mean_3 intrinsic_alignment_parameters/uncorr_log10_M_mean_4 intrinsic_alignment_parameters/uncorr_log10_M_mean_5 intrinsic_alignment_parameters/uncorr_log10_M_mean_6"
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/correlated_priors.py
			uncorrelated_parameters = ${unc_massdep_params}
			output_parameters = ${massdep_params}
			covariance = @BV:MASSDEP_COVARIANCE@
			
			EOF
			;; #}}}
  esac
done
#}}}
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc_b.ini >> \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc.ini
fi
#Construct the .ini file {{{
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sacc.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini

#}}}

