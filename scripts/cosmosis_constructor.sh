#=========================================
#
# File Name : cosmosis_constructor.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Wed Feb 26 21:21:49 2025
#
#=========================================
#Script to generate a cosmosis .ini, values, & priors file 
#Prepare the starting items {{{
DZMODEL="@BV:DZMODEL@"
IAMODEL="@BV:IAMODEL@"
CHAINSUFFIX=@BV:CHAINSUFFIX@
STATISTIC="@BV:STATISTIC@"
SAMPLER="@BV:SAMPLER@"
BOLTZMAN="@BV:BOLTZMAN@"

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/ ] 
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs 
fi 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[DEFAULT]
MY_PATH      = @RUNROOT@/

stats_name    = @BV:STATISTIC@
CSL_PATH      = %(MY_PATH)s/INSTALL/cosmosis-standard-library/
KCAP_PATH     = %(MY_PATH)s/INSTALL/kcap/

OUTPUT_FOLDER = %(MY_PATH)s/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/%(stats_name)s/chain/
CONFIG_FOLDER = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/

blind         = @BV:BLIND@
redshift_name = source

SAMPLER_NAME = @BV:SAMPLER@
RUN_NAME = %(SAMPLER_NAME)s_%(blind)s${CHAINSUFFIX}

2PT_STATS_PATH = %(MY_PATH)s/INSTALL/2pt_stats/

EOF
#}}}

#Define the data file name {{{ 
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_SPK" ] 
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

datafile=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcmc_inp_@BV:STATISTIC@/MCMC_input_${non_linear_model}${iteration}.fits

cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
data_file = ${datafile}

EOF
#}}}

#Set up the scale cuts module {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
[scale_cuts]
file = %(KCAP_PATH)s/modules/scale_cuts/scale_cuts.py
output_section_name = scale_cuts_output
data_and_covariance_fits_filename = %(data_file)s
simulate = F
simulate_with_noise = T
mock_filename =
EOF
if [ "@BV:REMOVETOMOBIN@" != "" ]
then 
  NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'` 
  rempairs=''
  for i in `seq $NTOMO`
  do 
    if [ @BV:REMOVETOMOBIN@ -lt ${i} ] 
    then 
      rempairs="${rempairs} @BV:REMOVETOMOBIN@+${i}"
    else 
      rempairs="${rempairs} ${i}+@BV:REMOVETOMOBIN@"
    fi 
  done
  if [ "${STATISTIC^^}" == "COSEBIS" ] 
  then 
    echo "cut_pair_En = $rempairs " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini 
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ] 
  then 
    echo "cut_pair_PeeE = $rempairs " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini 
    echo "cut_pair_PeeB = $rempairs " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini 
  elif [ "${STATISTIC^^}" == "XIPM" ] 
  then 
    echo "cut_pair_xiP = $rempairs " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini 
    echo "cut_pair_xiM = $rempairs " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini 
  fi 
fi 
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
[scale_cuts_b]
file = %(KCAP_PATH)s/modules/scale_cuts/scale_cuts.py
output_section_name = scale_cuts_output_b
data_and_covariance_fits_filename = %(data_file)s
simulate = F
simulate_with_noise = T
mock_filename =
EOF
fi
#}}}

#Define the tomographic strings {{{
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'` 
NHALF=`echo "$NTOMO" | awk '{printf "%d", $1/2}'`
SPLITMODE=@BV:SPLITMODE@
if [ "${SPLITMODE^^}" == "REDBLUE" ] || [ "${SPLITMODE^^}" == "NORTHSOUTH" ] 
then
  tomostring=""
  nottomostring=""
  for tomo1 in `seq ${NTOMO}` 
  do
    for tomo2 in `seq ${tomo1} ${NTOMO}` 
    do 
      if ([ $tomo1 -le ${NHALF} ] && [ $tomo2 -le ${NHALF} ]) || ([ $tomo1 -gt ${NHALF} ] && [ $tomo2 -gt ${NHALF} ])
	  then 
	    tomostring="${tomostring} ${tomo1}+${tomo2}"
	  else
	    nottomostring="${nottomostring} ${tomo1}+${tomo2}"
	  fi
    done
  done
fi
#}}}

#Requested statistic {{{
if [ "${STATISTIC^^}" == "COSEBIS" ] || [ "${STATISTIC^^}" == "COSEBIS_B" ] #{{{
then 
  cosebis_configpath=@RUNROOT@/@CONFIGPATH@/cosebis/
  #Scalecuts {{{
  lo=`echo @BV:NMINCOSEBIS@ | awk '{print $1-0.5}'`
  hi=`echo @BV:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = En
keep_ang_En   = ${lo} ${hi} 
cosebis_extension_name = En
cosebis_section_name = cosebis

EOF
if [ "${SPLITMODE^^}" == "REDBLUE" ] || [ "${SPLITMODE^^}" == "NORTHSOUTH" ] 
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
cut_pair_En = $nottomostring

EOF
fi
#}}}
if [ "${STATISTIC^^}" == "COSEBIS_B" ]
then 
  #COSEBIs_B {{{
cosebis_configpath=@RUNROOT@/@CONFIGPATH@/cosebis/
  #Scalecuts {{{
  lo=`echo @BV:NMINCOSEBIS@ | awk '{print $1-0.5}'`
  hi=`echo @BV:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
use_stats = Bn
keep_ang_En   = ${lo} ${hi} 
cosebis_extension_name = Bn
cosebis_section_name = cosebis_b

EOF
if [ "${SPLITMODE^^}" == "REDBLUE" ] || [ "${SPLITMODE^^}" == "NORTHSOUTH" ] 
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
cut_pair_En = $nottomostring

EOF
fi
#}}}
fi

#Base variables {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
;COSEBIs settings
tmin_cosebis = @BV:THETAMINXI@
tmax_cosebis = @BV:THETAMAXXI@
nmax_cosebis = @BV:NMAXCOSEBIS@
WnLogPath = ${cosebis_configpath}/WnLog/

EOF
#}}}

#statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis]
file = %(2PT_STATS_PATH)s/cl_to_cosebis/cl_to_cosebis_interface.so
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
Roots_n_Norms_FolderName = ${cosebis_configpath}/TLogsRootsAndNorms/
Wn_Output_FolderName = %(WnLogPath)s
Tn_Output_FolderName = %(2PT_STATS_PATH)s/TpnLog/
output_section_name =  cosebis
add_2D_cterm = 0 ; (optional) DEFAULT is 0: don't add it
add_c_term = 0
input_section_name = shear_cl

EOF
if [ "${STATISTIC^^}" == "COSEBIS_B" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis_b]
file = %(2PT_STATS_PATH)s/cl_to_cosebis/cl_to_cosebis_interface.so
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
Roots_n_Norms_FolderName = ${cosebis_configpath}/TLogsRootsAndNorms/
Wn_Output_FolderName = %(WnLogPath)s
Tn_Output_FolderName = %(2PT_STATS_PATH)s/TpnLog/
output_section_name =  cosebis_b
add_2D_cterm = 0 ; (optional) DEFAULT is 0: don't add it
add_c_term = 0
input_section_name = shear_cl_bb

EOF
fi
#}}}

#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ] #{{{
then 
  #scale cut {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = PeeE
bandpower_e_cosmic_shear_extension_name = PeeE
bandpower_e_cosmic_shear_section_name = bandpower_shear_e
keep_ang_PeeE = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
if [ "${SPLITMODE^^}" == "REDBLUE" ] || [ "${SPLITMODE^^}" == "NORTHSOUTH" ] 
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
cut_pair_PeeE = $nottomostring

EOF
fi
if [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
use_stats = PeeB
bandpower_b_cosmic_shear_extension_name = PeeB
bandpower_b_cosmic_shear_section_name = bandpower_shear_b
keep_ang_PeeE = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
if [ "${SPLITMODE^^}" == "REDBLUE" ] || [ "${SPLITMODE^^}" == "NORTHSOUTH" ] 
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini <<- EOF
cut_pair_PeeB = $nottomostring

EOF
fi
fi
#}}}
theta_lo=`echo 'e(l(@BV:THETAMINXI@)+@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
theta_up=`echo 'e(l(@BV:THETAMAXXI@)-@BV:APODISATIONWIDTH@/2)' | bc -l | awk '{printf "%.9f", $0}'`
#Statistic {{{
if [ "${STATISTIC^^}" == "BANDPOWERS" ]
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpowers]
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
theta_min = ${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/

EOF
elif [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpowers]
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
theta_min =${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/

EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[bandpowers_b]
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
theta_min =${theta_lo}
theta_max = ${theta_up}
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/
input_section_name = shear_cl
input_section_name_bmode = shear_cl_bb

EOF
fi
#}}}

#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
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
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
use_stats = xiP xiM
xi_plus_extension_name = xiP
xi_minus_extension_name = xiM
xi_plus_section_name = shear_xi_plus_binned
xi_minus_section_name = shear_xi_minus_binned
keep_ang_xiP  = @BV:THETAMINXI@ @BV:THETAMAXXI@ 
keep_ang_xiM  = ${ximinus_min}  ${ximinus_max}

EOF
if [ "${SPLITMODE^^}" == "REDBLUE" ] || [ "${SPLITMODE^^}" == "NORTHSOUTH" ] 
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini <<- EOF
cut_pair_xiP = $nottomostring
cut_pair_xiM = $nottomostring


EOF
fi
#}}}

#statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[xip_binned]
file = %(2PT_STATS_PATH)s/bin_xi/bin_xi_interface.so
output_section_name= shear_xi_plus_binned 
input_section_name= shear_xi_plus 
type=plus 

theta_min=@BV:THETAMINXI@
theta_max=@BV:THETAMAXXI@
nTheta=@BV:NXIPM@

weighted_binning = 1 

InputNpair = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm/@BV:NPAIRBASE@
InputNpair_suffix = .ascii
Column_theta_Name = meanr 
#Column_Npair_Name = npairs_weighted
Column_Npair_Name = weight
nBins_in = ${NTOMO}

add_2D_cterm = 0 
add_c_term = 0  

[xim_binned]
file = %(2PT_STATS_PATH)s/bin_xi/bin_xi_interface.so
output_section_name = shear_xi_minus_binned 
type = minus 
input_section_name = shear_xi_minus

theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
nTheta = @BV:NXIPM@

weighted_binning = 1 
InputNpair = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm/@BV:NPAIRBASE@
InputNpair_suffix = .ascii
Column_theta_Name = meanr 
#Column_Npair_Name = npairs_weighted
Column_Npair_Name = weight
nBins_in = ${NTOMO} 

add_2D_cterm = 0
add_c_term = 0 

EOF
#}}}

#}}}
else 
  #ERROR: unknown statistic {{{
  _message "Statistic Unknown: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
#}}}

#Requested sampler {{{
OUTPUTNAME="%(OUTPUT_FOLDER)s/output_%(RUN_NAME)s.txt"
VALUES=values
PRIORS=priors
listparam=''
if [ "${SAMPLER^^}" == "TEST" ] #{{{
then 
  
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[test]
save_dir=%(OUTPUT_FOLDER)s/output_%(RUN_NAME)s
fatal_errors=T

EOF

#}}}
elif [ "${SAMPLER^^}" == "MAXLIKE" ] #{{{
then 

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

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[multinest]
max_iterations=100000
multinest_outfile_root= %(OUTPUT_FOLDER)s/%(RUN_NAME)s_
resume=T
tolerance = 0.01
constant_efficiency = F
live_points = 1000
efficiency = 0.3

EOF

#}}}
elif [ "${SAMPLER^^}" == "POLYCHORD" ] #{{{
then 

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
n_batch=`echo "@BV:NTHREADS@" | awk '{printf "%d", 4*$1}'`
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[nautilus]
live_points = 4000
enlarge_per_dim = 1.1
split_threshold = 100
n_networks = 8
n_batch = $n_batch
filepath = %(OUTPUT_FOLDER)s/run_nautilus.hdf5
resume = @BV:NAUTILUS_RESUME@
f_live = 0.01
discard_exploration = True
verbose = True
n_eff = @BV:NAUTILUS_NSAMP@

EOF

#}}}
elif [ "${SAMPLER^^}" == "APRIORI" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[apriori]
nsample=500000

EOF

#}}}
elif [ "${SAMPLER^^}" == "GRID" ] #{{{
then 
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
  ncombinations=`echo "$NTOMO" | awk '{printf "%u", $1*($1+1)/2 }'`
  if [ "${STATISTIC^^}" == "COSEBIS" ]
  then
    ndat=`echo "$ncombinations @BV:NMAXCOSEBIS@" | awk '{printf "%u", $1*$2 }'`
  elif [ "${STATISTIC^^}" == "BANDPOWERS" ] 
  then 
	ndat=`echo "$ncombinations @BV:NBANDPOWERS@" | awk '{printf "%u", $1*$2 }'`
  elif [ "${STATISTIC^^}" == "XIPM" ]
  then 
	ndat=`echo "$ncombinations @BV:NXIPM@" | awk '{printf "%u", $1*$2*2 }'`
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

#Prepare the pipeline ini files {{{ 
#Extra parameters {{{
extraparams="cosmological_parameters/S_8 cosmological_parameters/sigma_8 cosmological_parameters/A_s cosmological_parameters/omega_m cosmological_parameters/omega_nu cosmological_parameters/omega_lambda cosmological_parameters/cosmomc_theta"
if [ "${IAMODEL^^}" == "MASSDEP" ] 
then
  extraparams="${extraparams} intrinsic_alignment_parameters/a intrinsic_alignment_parameters/beta intrinsic_alignment_parameters/log10_m_mean_1 intrinsic_alignment_parameters/log10_m_mean_2 intrinsic_alignment_parameters/log10_m_mean_3 intrinsic_alignment_parameters/log10_m_mean_4 intrinsic_alignment_parameters/log10_m_mean_5 intrinsic_alignment_parameters/log10_m_mean_6"
fi
#}}}
#Add nz shift values to outputs {{{
shifts=""
for i in `seq ${NTOMO}`
do 
   shifts="${shifts} nofz_shifts/bias_${i}"
done
#}}}
#Add the values information #{{{
if [  "@BV:COSMOSIS_PIPELINE@" == "default" ]
then
	# Set up boltzmann code blocks {{{
	if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] 
	then
		#boltzmann_pipeline="cosmopower distances"
		boltzmann_pipeline="cosmopower camb"
	elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ]
	then
		boltzmann_pipeline="one_parameter_hmcode cosmopower camb"
	elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ]
	then
		boltzmann_pipeline="sigma8toAs one_parameter_hmcode cosmopower camb"
	elif [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] 
	then
		boltzmann_pipeline="camb"
	elif [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
	then
		boltzmann_pipeline="one_parameter_hmcode camb"
	elif [ "${BOLTZMAN^^}" == "CAMB_SPK" ] 
	then
		boltzmann_pipeline="camb spk"
	else
		_message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  		exit 1
	fi
  #}}}
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
  #}}}
  #Do we want to use stretch as well as shift in the delta z? {{{
  #Check for the nz stretch priors 
  if [ "${DZMODEL^^}" == "SHIFT+STRETCH" ] 
  then 
    source_nz_model='source_photoz_bias source_photoz_width'
  elif [ "${DZMODEL^^}" == "SHIFT" ] 
  then 
    source_nz_model='source_photoz_bias'
    source_stretch=''
  elif [ "${DZMODEL^^}" == "STRETCH" ] 
  then 
    source_nz_model='source_photoz_width'
    source_stretch=''
  elif [ "${DZMODEL^^}" == "STRETCH+SHIFT" ] 
  then 
    source_nz_model='source_photoz_width source_photoz_bias'
    source_stretch=''
  else 
    _message "@RED@ ILLEGAL OPTION IN DZMODEL: must be some combination of SHIFT and STRETCH, separated by a +\n@DEF@"
    exit 1
  fi 
  #}}}

	if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
	then
		COSMOSIS_PIPELINE="sample_S8 correlated_dz_priors load_nz_fits ${boltzmann_pipeline} extrapolate_power ${source_nz_model} ${iamodel_pipeline} cosebis scale_cuts likelihood"
	#}}}
	elif [ "${STATISTIC^^}" == "COSEBIS_B" ] #{{{
	then
		COSMOSIS_PIPELINE="sample_S8 correlated_dz_priors load_nz_fits ${boltzmann_pipeline} extrapolate_power ${source_nz_model} ${iamodel_pipeline} cosebis scale_cuts cosebis_b scale_cuts_b likelihood likelihood_b"
	#}}}
	elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
	then 
		COSMOSIS_PIPELINE="sample_S8 correlated_dz_priors load_nz_fits ${boltzmann_pipeline} extrapolate_power ${source_nz_model} ${iamodel_pipeline} bandpowers scale_cuts likelihood"
	#}}}
	elif [ "${STATISTIC^^}" == "BANDPOWERS_B" ] #{{{
	then 
		COSMOSIS_PIPELINE="sample_S8 correlated_dz_priors load_nz_fits ${boltzmann_pipeline} extrapolate_power ${source_nz_model} ${iamodel_pipeline} bandpowers scale_cuts bandpowers_b scale_cuts_b likelihood likelihood_b"
  #}}}
	elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
	then 
		COSMOSIS_PIPELINE="sample_S8 correlated_dz_priors load_nz_fits ${boltzmann_pipeline} extrapolate_power ${source_nz_model} ${iamodel_pipeline} cl2xi xip_binned xim_binned scale_cuts likelihood"
	fi
  #}}}
else
  #Generic {{{
	COSMOSIS_PIPELINE="@BV:COSMOSIS_PIPELINE@"
  #}}}
fi
#Setup the pipeline block {{{
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
        elif [ "${STATISTIC^^}" == "XIPM" ] 
        then
            tpdparams="${tpdparams} shear_xi_plus_binned/bin_${tomo2}_${tomo1}#@BV:NXIPM@ shear_xi_minus_binned/bin_${tomo2}_${tomo1}#@BV:NXIPM@"
        fi
    done
done
fi
#}}}

#Add the other information #{{{
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
likelihoods  = loglike loglike_b
EOF
else
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
likelihoods  = loglike
EOF
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
extra_output = ${extraparams} ${shifts} ${listparam} ${tpdparams}
quiet = T
timing = F
debug = F

[runtime]
sampler = %(SAMPLER_NAME)s

[output]
filename = ${OUTPUTNAME}
format = text

EOF
#}}}
#}}}

#Requested boltzman {{{
if [ "${BOLTZMAN^^}" == "CAMB_HM2015" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = power
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = power
nonlinear = pk
halofit_version = mead2020_feedback
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000
use_ppf_w = True

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] #{{{
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface.py
path_2_trained_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmax = 10.0
kmin = 1e-5
nk = 200

[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = background
nonlinear = pk
halofit_version = original
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] #{{{
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface_S8.py
path_2_trained_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/train_emulator_camb_S8/outputs/
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmax = 10.0
kmin = 1e-5
nk = 200

[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = background
nonlinear = pk
halofit_version = original
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] #{{{
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface_S8_HM2015.py
path_2_trained_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/trained_models/HM2015_S8/
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmax = 10.0
kmin = 1e-5
nk = 200

[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = background
nonlinear = pk
halofit_version = original
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "CAMB_SPK" ] #{{{
then 

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[camb]
file = %(CSL_PATH)s/boltzmann/camb/camb_interface.py
do_reionization = F
mode = power
nonlinear = pk
halofit_version = mead2020_feedback
neutrino_hierarchy = normal
kmax = 10.0
zmid = 2.0
nz_mid = 100
zmax = 3.0
nz = 150
zmax_background = 6.0
zmin_background = 0.0
nz_background = 6000
use_ppf_w = True

[spk]
file = %(CSL_PATH)s/structure/spk/spk_interface.py
astropy_model = flatlambdacdm
fb_table = %(CSL_PATH)s/structure/spk/BAHAMAS_fb_M200.csv

EOF
#}}}
else 
  #ERROR: unknown boltzman code {{{
  _message "Boltzman Code Unknown: ${BOLTZMAN^^}\n"
  exit 1
  #}}}
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
    "sigma8toAs") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/sigma8toAs.py
			
			EOF
			;; #}}}
    "correlated_dz_priors") #{{{
      shifts=""
      unc_shifts=""
      for i in `seq ${NTOMO}`
      do 
         shifts="${shifts} nofz_shifts/bias_${i}"
         unc_shifts="${unc_shifts} nofz_shifts/uncorr_bias_${i}"
      done
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/correlated_priors.py
			uncorrelated_parameters = ${unc_shifts}
			output_parameters = ${shifts}
			covariance = @DB:nzcov@
			
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
    "one_parameter_hmcode") #{{{
      cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/one_parameter_hmcode.py
			a_0 = 0.98
			a_1 = -0.12
			
			EOF
			;; #}}}
    "extrapolate_power") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/boltzmann/extrapolate/extrapolate_power.py
			kmax = 500.0
			
			EOF
			;; #}}}
    "load_nz_fits") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/load_nz_fits/load_nz_fits.py
			nz_file = %(data_file)s
			data_sets = %(redshift_name)s
			
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
    "source_photoz_width") #{{{
      cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/photoz_width/photoz_width.py
			mode = stretch
			sample = nz_%(redshift_name)s
			bias_section = nofz_widths
			interpolation = cubic
			
			EOF
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
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = @RUNROOT@/INSTALL/ia_models/lin_z_dependent_ia/lin_z_dependent_ia_model.py
			sample = %(redshift_name)s
			
			EOF
			;; #}}}
	"mass_dependence_for_ia") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = @RUNROOT@/INSTALL/ia_models/mass_dependent_ia/mass_dependent_ia_model.py
			
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
	"add_intrinsic") #{{{
			add_intrinsic=True
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file=%(CSL_PATH)s/shear/add_intrinsic/add_intrinsic.py
			shear-shear=T
			position-shear=F
			perbin=F
			
			EOF
			;; #}}}
    "projection") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/structure/projection/project_2d.py
			ell_min_logspaced = 1.0
			ell_max_logspaced = 1.0e5
			n_ell_logspaced = 50
			position-shear = F
			verbose = F
			get_kernel_peaks = F
			EOF
			if [ "$add_intrinsic" == "True" ]
			then
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			shear-shear = %(redshift_name)s-%(redshift_name)s
			shear-intrinsic = %(redshift_name)s-%(redshift_name)s
			intrinsic-intrinsic = %(redshift_name)s-%(redshift_name)s
			#intrinsicb-intrinsicb = %(redshift_name)s-%(redshift_name)s

			EOF
			else
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			fast-shear-shear-ia = %(redshift_name)s-%(redshift_name)s

			EOF
			fi
			;; #}}}
    "likelihood") #{{{
			MASKDATAPOINT=@BV:MASKDATAPOINT@
			if [ -n "$MASKDATAPOINT" ] && [ "$MASKDATAPOINT" -eq "$MASKDATAPOINT" ]
			then
				if [ "${STATISTIC^^}" == "COSEBIS" ]
				then
					NDATA=@BV:NMAXCOSEBIS@
				elif [ "${STATISTIC^^}" == "BANDPOWERS" ]
				then 
					NDATA=@BV:NBANDPOWERS@
				fi
			  	cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
				[$module]
				file = %(KCAP_PATH)s/utils/mini_like_dodgymask.py
				input_section_name = scale_cuts_output
				like_name = loglike
				mask_datapoint=$MASKDATAPOINT
				n_data=${NDATA}
				n_tomo=${NTOMO}

			EOF
			else
				cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
				[$module]
				file = %(KCAP_PATH)s/utils/mini_like.py
				input_section_name = scale_cuts_output
				like_name = loglike

				EOF
			fi
    	;; #}}}
	"likelihood_b") #{{{
		cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
		[$module]
		file = %(KCAP_PATH)s/utils/mini_like.py
		input_section_name = scale_cuts_output_b
		like_name = loglike_b

		EOF
	;; #}}}
	"cl2xi") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/shear/cl_to_xi_nicaea/nicaea_interface.so
			corr_type = 0

			EOF
    	;; #}}}
  esac
done
#}}}
#}}}

#Construct the .ini file {{{
if [ "${STATISTIC^^}" == "COSEBIS_B" ] || [ "${STATISTIC^^}" == "BANDPOWERS_B" ]
then
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_b.ini >> \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini
fi
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini

#}}}

