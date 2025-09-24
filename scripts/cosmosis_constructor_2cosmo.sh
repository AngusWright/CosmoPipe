#=========================================
#
# File Name : cosmosis_constructor.sh
# Created By : awright
# Creation Date : 14-04-2023
# Last Modified : Fri 05 May 2023 10:49:58 AM CEST
#
#=========================================

#Script to generate a cosmosis .ini, values, & priors file 
# Infer splitmode {{{
SPLITMODE=@BV:SPLITMODE@
if [ "${SPLITMODE^^}" == "CATALOGUE" ] 
then
mode=catalogue
elif [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ANGULAR" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then
mode=datavector
elif [ "${SPLITMODE^^}" == "STATISTIC" ] 
then
  _message "Split not yet implemented: ${STATISTIC^^}\n"
  exit 1
else
#ERROR: unknown split mode {{{
  _message "Split mode Unknown: ${SPLITMODE^^}\n"
  exit 1
  #}}}
fi
#}}}

if [ "${SPLITMODE^^}" == "ZBIN" ]
then
OUTPUTNAME="${SPLITMODE}@BV:ZBIN@"
else
OUTPUTNAME="${SPLITMODE}"
fi
#Prepare the starting items {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
[DEFAULT]
MY_PATH      = @RUNROOT@/

stats_name    = @BV:STATISTIC@
CSL_PATH      = %(MY_PATH)s/INSTALL/cosmosis-standard-library/
KCAP_PATH     = %(MY_PATH)s/INSTALL/kcap/
ADDITIONAL_MODULES_PATH = %(MY_PATH)s/INSTALL/2cosmo_modules/

OUTPUT_FOLDER =  %(MY_PATH)s/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/%(stats_name)s/chain/2cosmo/
CONFIG_FOLDER = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/

blind         = @BV:BLIND@
redshift_name = source

SAMPLER_NAME = @BV:SAMPLER@
RUN_NAME = ${OUTPUTNAME}_split_%(SAMPLER_NAME)s_%(blind)s

2PT_STATS_PATH = %(MY_PATH)s/INSTALL/2pt_stats/

EOF
#}}}
STATISTIC="@BV:STATISTIC@"
#Define the data file name {{{ 
if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then
  datafile=@DB:mcmc_inp_cosebis@
#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  datafile=@DB:mcmc_inp_bandpowers@
#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then 
  datafile=@DB:mcmc_inp_xipm@
fi

#Data files  {{{
if [ "${SPLITMODE^^}" == "CATALOGUE" ] 
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
data_file_1 = @DB:mcmc_inp_1@
data_file_2 = @DB:mcmc_inp_2@
data_file = @DB:mcmc_inp_1@

EOF
else
# some modules (load_nz_fits) take different data files as input by default. For non-catalogue-like splits we don't need this
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
data_file_1 = ${datafile}
data_file_2 = ${datafile}
data_file = ${datafile}

EOF
fi

#}}}
#Set up the scale cuts modules {{{
# Split by summary statistic doesn't require two separate scale cuts modules
if [ "${SPLITMODE^^}" == "STATISTIC" ] 
then
  _message "Split not yet implemented: ${SPLITMODE^^}\n"
  exit 1
else
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
[scale_cuts_1]
file = %(KCAP_PATH)s/modules/scale_cuts/scale_cuts.py
output_section_name = scale_cuts_output_1
data_and_covariance_fits_filename = %(data_file_1)s
simulate = F
EOF
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
[scale_cuts_2]
file = %(KCAP_PATH)s/modules/scale_cuts/scale_cuts.py
output_section_name = scale_cuts_output_2
data_and_covariance_fits_filename = %(data_file_2)s
simulate = F
EOF
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ANGULAR" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_uncut.ini <<- EOF
[scale_cuts_uncut]
file = %(KCAP_PATH)s/modules/scale_cuts/scale_cuts.py
output_section_name = scale_cuts_output_uncut
data_and_covariance_fits_filename = %(data_file_1)s
simulate = F
EOF
fi
fi


#}}}

#Requested statistic {{{
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

if [ "${SPLITMODE^^}" == "ZBIN" ]
then
	ZBIN=@BV:ZBIN@
	tomostring=''
	nottomostring=''
	for tomo1 in `seq ${NTOMO}` 
	do
		for tomo2 in `seq ${tomo1} ${NTOMO}` 
		do 
			if [ $tomo1 -ne ${ZBIN} ] && [ $tomo2 -ne ${ZBIN} ]
			then 
				tomostring="${tomostring} ${tomo1}+${tomo2}"
			else 
				nottomostring="${nottomostring} ${tomo1}+${tomo2}"
			fi 
		done
	done
elif [ "${SPLITMODE^^}" == "ACCC" ]
then
	tomostring=''
	nottomostring=''
	for tomo1 in `seq ${NTOMO}` 
	do
		for tomo2 in `seq ${tomo1} ${NTOMO}` 
		do 
			if [ $tomo1 -ne $tomo2 ] 
			then 
				tomostring="${tomostring} ${tomo1}+${tomo2}"
			else 
				nottomostring="${nottomostring} ${tomo1}+${tomo2}"
			fi 
		done
	done
fi

if [ "${STATISTIC^^}" == "COSEBIS" ] #{{{
then 
  #Scalecuts {{{
  lo=`echo @BV:NMINCOSEBIS@ | awk '{print $1-0.5}'`
  hi=`echo @BV:NMAXCOSEBIS@ | awk '{print $1+0.5}'`
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
use_stats = En
keep_ang_En   = ${lo} ${hi} 
cosebis_extension_name = En
cosebis_section_name = cosebis
EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
use_stats = En
keep_ang_En   = ${lo} ${hi} 
cosebis_extension_name = En
cosebis_section_name = cosebis
EOF
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_uncut.ini <<- EOF
use_stats = En
keep_ang_En   = ${lo} ${hi} 
cosebis_extension_name = En
cosebis_section_name = cosebis

EOF
fi
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
cut_pair_En = ${tomostring}

EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
cut_pair_En = ${nottomostring}

EOF
elif [ "${SPLITMODE^^}" == "ANGULAR" ]
then
#ERROR: Angular split only with BPs {{{
  _message "Split mode ${SPLITMODE^^} only possible with BandPowers or COSEBIs!\n"
  exit 1
  #}}}
fi

#}}}

#Base variables {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini <<- EOF
;COSEBIs settings
tmin_cosebis = @BV:THETAMINXI@
tmax_cosebis = @BV:THETAMAXXI@
nmax_cosebis = @BV:NMAXCOSEBIS@
WnLogPath = @RUNROOT@/@CONFIGPATH@/cosebis/WnLog/

EOF
#}}}

#statistic {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini <<- EOF
[cosebis]
file = %(2PT_STATS_PATH)s/cl_to_cosebis/cl_to_cosebis_interface.so
theta_min = %(tmin_cosebis)s
theta_max = %(tmax_cosebis)s
n_max = %(nmax_cosebis)s
Roots_n_Norms_FolderName = %(2PT_STATS_PATH)s/TLogsRootsAndNorms/
Wn_Output_FolderName = %(WnLogPath)s
Tn_Output_FolderName = %(2PT_STATS_PATH)s/TpnLog/
output_section_name =  cosebis
add_2D_cterm = 0 ; (optional) DEFAULT is 0: don't add it
add_c_term = 0

EOF
#}}}

#}}}
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] #{{{
then 
  #scale cut {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
use_stats = PeeE
bandpower_e_cosmic_shear_extension_name = PeeE
bandpower_e_cosmic_shear_section_name = bandpower_shear_e
EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
use_stats = PeeE
bandpower_e_cosmic_shear_extension_name = PeeE
bandpower_e_cosmic_shear_section_name = bandpower_shear_e
EOF
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ANGULAR" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_uncut.ini <<- EOF
use_stats = PeeE
bandpower_e_cosmic_shear_extension_name = PeeE
bandpower_e_cosmic_shear_section_name = bandpower_shear_e
keep_ang_peee = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
fi
if [ "${SPLITMODE^^}" == "ZBIN" ]|| [ "${SPLITMODE^^}" == "ACCC" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
cut_pair_PeeE = ${tomostring}
keep_ang_peee = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
cut_pair_PeeE = ${nottomostring}
keep_ang_peee = @BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
elif [ "${SPLITMODE^^}" == "ANGULAR" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
keep_ang_peee = @BV:LMINBANDPOWERS@ @BV:LSPLITBANDPOWERS@

EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
keep_ang_peee = @BV:LSPLITBANDPOWERS@ @BV:LMAXBANDPOWERS@

EOF
fi
#}}}

#Statistic {{{
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
theta_min = @BV:THETAMINXI@
theta_max = @BV:THETAMAXXI@
output_foldername = %(2PT_STATS_PATH)s/bandpowers_window/

EOF
#}}}

#}}}
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then 
  #scale cut {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
use_stats = xiP xiM
xi_plus_extension_name = xiP
xi_minus_extension_name = xiM
xi_plus_section_name = shear_xi_plus_binned
xi_minus_section_name = shear_xi_minus_binned
keep_ang_xiP  = @BV:THETAMINXI@ @BV:THETAMAXXI@
keep_ang_xiM  = @BV:THETAMINXIM@ @BV:THETAMAXXIM@
EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
use_stats = xiP xiM
xi_plus_extension_name = xiP
xi_minus_extension_name = xiM
xi_plus_section_name = shear_xi_plus_binned
xi_minus_section_name = shear_xi_minus_binned
keep_ang_xiP  = @BV:THETAMINXI@ @BV:THETAMAXXI@
keep_ang_xiM  = @BV:THETAMINXIM@ @BV:THETAMAXXIM@
EOF
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_uncut.ini <<- EOF
use_stats = xiP xiM
xi_plus_extension_name = xiP
xi_minus_extension_name = xiM
xi_plus_section_name = shear_xi_plus_binned
xi_minus_section_name = shear_xi_minus_binned
keep_ang_xiP  = @BV:THETAMINXI@ @BV:THETAMAXXI@
keep_ang_xiM  = @BV:THETAMINXIM@ @BV:THETAMAXXIM@

EOF
fi
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
cut_pair_xiP = ${tomostring}
cut_pair_xiM = ${tomostring}

EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
cut_pair_xiP = ${nottomostring}
cut_pair_xiM = ${nottomostring}

EOF
elif [ "${SPLITMODE^^}" == "ANGULAR" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini <<- EOF
keep_ang_xiP  = @BV:THETAMINXI@ @BV:XISPLIT@
keep_ang_xiP  = @BV:THETAMINXI@ @BV:XISPLIT@

EOF
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini <<- EOF
keep_ang_xiP  = @BV:XISPLIT@ @BV:THETAMAXXI@
keep_ang_xiP  = @BV:XISPLIT@ @BV:THETAMAXXI@

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

InputNpair = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair/@BV:NPAIRBASE_XI@
InputNpair_suffix = .ascii
Column_theta_Name = meanr 
Column_Npair_Name = npairs_weighted
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
InputNpair = @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair/@BV:NPAIRBASE_XI@
InputNpair_suffix = .ascii
Column_theta_Name = meanr 
Column_Npair_Name = npairs_weighted
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

#Parameter selection {{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini <<- EOF
[select_parameter_set_1]
file = %(ADDITIONAL_MODULES_PATH)s/select_parameter_set.py
input_set = 1

[select_parameter_set_2]
file = %(ADDITIONAL_MODULES_PATH)s/select_parameter_set.py
input_set = 2

EOF
#}}}

#Combine theory vectors {{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini <<- EOF
[combine_theoryvectors]
file = %(ADDITIONAL_MODULES_PATH)s/combine_theoryvectors.py
mode = ${mode}
input_section_name_1 = scale_cuts_output_1
input_section_name_2 = scale_cuts_output_2
output_section_name = scale_cuts_output

EOF
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ANGULAR" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini <<- EOF
input_section_name_uncut = scale_cuts_output_uncut

EOF
fi

if [ "${STATISTIC^^}" == "COSEBIS" ] 
then 
	source_section=cosebis
	dest1=cosebis_set1
	dest2=cosebis_set2
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] 
then
	source_section=bandpower_shear_e
	dest1=bandpowers_set1
	dest2=bandpowers_set2
elif [ "${STATISTIC^^}" == "XIPM" ] #{{{
then
  source_section="shear_xi_plus_binned shear_xi_minus_binned"
  dest1="xip_set1 xim_set1"
  dest2="xip_set2 xim_set2"
  #}}}
else 
  #ERROR: unknown statistic {{{
  _message "Statistic Unknown: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini <<- EOF
[copy_1]
file = %(CSL_PATH)s/utility/copy/copy_section.py
source = ${source_section}
dest = ${dest1}

[copy_2]
file = %(CSL_PATH)s/utility/copy/copy_section.py
source = ${source_section}
dest = ${dest2}

EOF

#Delete first set of theory calculations {{{
if [ "${STATISTIC^^}" == "COSEBIS" ] 
then 
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini <<- EOF
[delete]
file = %(CSL_PATH)s/utility/delete/delete_section.py
sections = distances intrinsic_power matter_intrinsic_power matter_power_lin matter_power_nl intrinsic_alignment_parameters cosebis cosmological_parameters halo_model_parameters recfast
			
EOF
elif [ "${STATISTIC^^}" == "BANDPOWERS" ] 
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini <<- EOF
[delete]
file = %(CSL_PATH)s/utility/delete/delete_section.py
sections = distances intrinsic_power matter_intrinsic_power matter_power_lin matter_power_nl intrinsic_alignment_parameters bandpower_shear_e cosmological_parameters halo_model_parameters recfast
			
EOF
elif [ "${STATISTIC^^}" == "XIPM" ]
then
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini <<- EOF
[delete]
file = %(CSL_PATH)s/utility/delete/delete_section.py
sections = distances intrinsic_power matter_intrinsic_power matter_power_lin matter_power_nl intrinsic_alignment_parameters shear_xi_plus shear_xi_minus shear_xi_plus_binned shear_xi_minus_binned cosmological_parameters halo_model_parameters recfast
			
EOF
else 
  #ERROR: unknown statistic {{{
  _message "Statistic Unknown: ${STATISTIC^^}\n"
  exit 1
  #}}}
fi
#}}}

#Requested sampler {{{
SAMPLER="@BV:SAMPLER@"
VALUES=values_2cosmo
PRIORS=priors_2cosmo
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
resume=F
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

cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
[nautilus]
live_points = 2000
enlarge_per_dim = 1.1
split_threshold = 100
n_networks = 8
n_batch = 128
filepath = %(OUTPUT_FOLDER)s/Nautilus/run_nautilus.hdf5
resume = False
f_live = 0.01
discard_exploration = True
verbose = True

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
	nsample_dimension=35
	EOF

#}}}
elif [ "${SAMPLER^^}" == "LIST" ] #{{{
then 
  ndof="@BV:DVLENGTH@"
  listparam="scale_cuts_output/theory#${ndof}"
  list_input="@BV:LIST_INPUT_SAMPLER@"

	cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini <<- EOF
	[list]
	filename = %(OUTPUT_FOLDER)s/output_${list_input}_%(blind)s.txt 
	
	EOF
  @P_SED_INPLACE@ "s@filename = %(OUTPUT_FOLDER)s/output_%(RUN_NAME)s.txt@filename = %(OUTPUT_FOLDER)s/output_list_%(RUN_NAME)s.txt@g" \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini

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
extraparams="cosmological_parameters/S_8 cosmological_parameters/sigma_8 cosmological_parameters/A_s cosmological_parameters/omega_m cosmological_parameters/omega_nu cosmological_parameters/omega_lambda cosmological_parameters/cosmomc_theta"
#Add nz shift values to outputs {{{
shifts=""
for i in `seq ${NTOMO}`
do 
   shifts="${shifts} nofz_shifts/bias_${i}"
done
#}}}
#Add tpds to outputs {{{
tpdparams=""
for tomo1 in `seq ${NTOMO}` 
do
  for tomo2 in `seq ${tomo1} ${NTOMO}` 
  do 
	if [ "${STATISTIC^^}" == "BANDPOWERS" ] 
	then
      tpdparams="${tpdparams} bandpowers_set1/bin_${tomo2}_${tomo1}#@BV:NBANDPOWERS@ bandpowers_set2/bin_${tomo2}_${tomo1}#@BV:NBANDPOWERS@"
	elif [ "${STATISTIC^^}" == "COSEBIS" ]
	then
	  tpdparams="${tpdparams} cosebis_set1/bin_${tomo2}_${tomo1}#@BV:NMAXCOSEBIS@ cosebis_set2/bin_${tomo2}_${tomo1}#@BV:NMAXCOSEBIS@"
	elif [ "${STATISTIC^^}" == "XIPM" ]
	then
	  tpdparams="${tpdparams} xip_set1/bin_${tomo2}_${tomo1}#@BV:NXIPM@ xim_set1/bin_${tomo2}_${tomo1}#@BV:NXIPM@ xip_set2/bin_${tomo2}_${tomo1}#@BV:NXIPM@ xim_set2/bin_${tomo2}_${tomo1}#@BV:NXIPM@"
	fi
  done
done
#}}}
#Add the values information #{{{
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
[pipeline]
modules = @BV:COSMOSIS_PIPELINE@
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
#Add the other information #{{{
cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini <<- EOF
likelihoods  = loglike
extra_output = ${extraparams} ${shifts} ${listparam} ${tpdparams}
quiet = T
timing = F
debug = F

[runtime]
sampler = %(SAMPLER_NAME)s

[output]
filename = %(OUTPUT_FOLDER)s/output_%(RUN_NAME)s.txt
format = text

EOF
#}}}
#}}}

#Requested boltzman {{{
BOLTZMAN="@BV:BOLTZMAN@"
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

[distances]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/camb_distances.py
do_reionization = F
mode = transfer
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
background_zmax = 6.0
background_zmin = 0.0
background_nz = 6000

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

[distances]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/camb_distances.py
do_reionization = F
mode = transfer
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
background_zmax = 6.0
background_zmin = 0.0
background_nz = 6000

EOF
#}}}
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] #{{{
then 
cat > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini <<- EOF
[cosmopower]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/cosmopower_interface_S8.py
path_2_trained_emulator = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/S8_input/
use_specific_k_modes = F
; otherwise it uses the k-modes the emulator is trained on
kmax = 10.0
kmin = 1e-5
nk = 200

[distances]
file = %(MY_PATH)s/INSTALL/CosmoPowerCosmosis/cosmosis_modules/camb_distances.py
do_reionization = F
mode = transfer
nonlinear = pk
halofit_version = mead
neutrino_hierarchy = normal
kmax = 20.0
zmid = 2.0
nz_mid = 100
zmax = 6.0
nz = 150
background_zmax = 6.0
background_zmin = 0.0
background_nz = 6000

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
modulelist=`echo @BV:COSMOSIS_PIPELINE@ | sed 's/ /\n/g' | sort | uniq | awk '{printf $0 " "}'`
for module in ${modulelist}
do 
  case ${module} in 
    "sample_S8") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/sample_S8.py
			s8_name = s_8_input
			
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
	"correlated_dz_priors_1") #{{{
		shifts=""
		unc_shifts=""
		for i in `seq ${NTOMO}`
		do 
			shifts="${shifts} nofz_shifts_1/bias_${i}"
			unc_shifts="${unc_shifts} nofz_shifts_1/uncorr_bias_${i}"
		done
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/correlated_priors.py
			uncorrelated_parameters = ${unc_shifts}
			output_parameters = ${shifts}
			covariance = @DB:nzcov@
			
			EOF
			;; #}}}
	"correlated_dz_priors_2") #{{{
		shifts=""
		unc_shifts=""
		for i in `seq ${NTOMO}`
		do 
			shifts="${shifts} nofz_shifts_2/bias_${i}"
			unc_shifts="${unc_shifts} nofz_shifts_2/uncorr_bias_${i}"
		done
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/correlated_priors.py
			uncorrelated_parameters = ${unc_shifts}
			output_parameters = ${shifts}
			covariance = @DB:nzcov@
			
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
	"load_nz_fits_1") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/load_nz_fits/load_nz_fits.py
			nz_file = %(data_file_1)s
			data_sets = %(redshift_name)s
			
			EOF
			;; #}}}
	"load_nz_fits_2") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/load_nz_fits/load_nz_fits.py
			nz_file = %(data_file_2)s
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
	"source_photoz_bias_1") #{{{
      cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/photoz_bias/photoz_bias.py
			mode = additive
			sample = nz_%(redshift_name)s
			bias_section  = nofz_shifts_1
			interpolation = cubic
			output_deltaz = T
			output_section_name = delta_z_out_1
			
			EOF
			;; #}}}
	"source_photoz_bias_2") #{{{
      cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/number_density/photoz_bias/photoz_bias.py
			mode = additive
			sample = nz_%(redshift_name)s
			bias_section  = nofz_shifts_2
			interpolation = cubic
			output_deltaz = T
			output_section_name = delta_z_out_2
			
			EOF
			;; #}}}
    "linear_alignment") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/intrinsic_alignments/la_model/linear_alignments_interface.py
			method = bk_corrected
			
			EOF
			;; #}}}
    "projection") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(CSL_PATH)s/structure/projection/project_2d.py
			ell_min_logspaced = 1.0
			ell_max_logspaced = 1.0e4
			n_ell_logspaced = 50
			position-shear = F
			fast-shear-shear-ia = %(redshift_name)s-%(redshift_name)s
			verbose = F
			get_kernel_peaks = F
			
			EOF
			;; #}}}
    "likelihood") #{{{
			cat >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini <<- EOF
			[$module]
			file = %(KCAP_PATH)s/utils/mini_like.py
			input_section_name = scale_cuts_output
			like_name = loglike
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

# Combine scale cuts ini files

cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_1.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_2.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini
if [ "${SPLITMODE^^}" == "ZBIN" ] || [ "${SPLITMODE^^}" == "ANGULAR" ] || [ "${SPLITMODE^^}" == "ACCC" ]
then
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut_uncut.ini >> \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini
fi

#Construct the .ini file {{{
cat \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_pipe.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_2cosmo_base.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_statistic.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_scalecut.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_boltzman.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_sampler.ini \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_other.ini > \
  @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@_2cosmo_${OUTPUTNAME}.ini

#}}}

