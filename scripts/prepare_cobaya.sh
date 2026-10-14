#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Thu 07 Sep 2023 05:56:22 PM UTC
#
#=========================================

#For each of the files in the nz directory 
inputs="@DB:nz@"
headfiles="@DB:ALLHEAD@"

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

#All possible prior values that might need specification
PRIOR_AIA="@BV:PRIOR_AIA@"
PRIOR_ABARY="@BV:PRIOR_ABARY@"
PRIOR_LOGTAGN="@BV:PRIOR_LOGTAGN@"
PRIOR_OMCH2="@BV:PRIOR_OMCH2@"
PRIOR_OMBH2="@BV:PRIOR_OMBH2@"
PRIOR_H0="@BV:PRIOR_H0@"
PRIOR_NS="@BV:PRIOR_NS@"
PRIOR_S8INPUT="@BV:PRIOR_S8INPUT@"
PRIOR_OMEGAK="@BV:PRIOR_OMEGAK@"
PRIOR_W="@BV:PRIOR_W@"
PRIOR_WA="@BV:PRIOR_WA@"
PRIOR_MNU="@BV:PRIOR_MNU@"

#BOLTZMANN code
BOLTZMAN=@BV:BOLTZMAN@

#Cobaya .yaml file {{{
#Create the cobaya_inputs directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cobaya_inputs ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cobaya_inputs/
fi 
#Generate the .yaml file: 
YAML_FILE_NNAME="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cobaya_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@_cobaya.yaml"
if [ -f ${YAML_FILE_NNAME} ]
then 
  _message "  @BLU@Deleting previous yaml file@DEF@"
  rm ${YAML_FILE_NNAME}
  _message "@RED@ - Done!@DEF@\n"
fi 


#Prepare the starting items {{{
cat > ${YAML_FILE_NNAME} <<- EOF
debug: False
stop_at_error: True
timing: True
output: @RUNROOT@/@STORAGEPATH@/MCMC/output_cobaya/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/
sampler:
  evaluate:
  # mcmc:
  #     covmat: proposal_cov.txt

likelihood:
  cosmosis_cobaya_interface.cosmosis_wrapper.CosmoSISWrapperLikelihood:
    ini_file: @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini
    remove_modules: ["sample_S8", "sigma8toAs", "one_parameter_hmcode", "camb", "cosmopower", "distances"]

    kmax: 20.0

    zmid: 2.0
    nz_mid: 100
    zmax: 6.0
    nz: 150

    zmax_background: 6.0
    zmin_background: 0.0
    nz_background: 6000
  
    params:
EOF
#}}}
write_sampling_params AIA intrinsic_alignment_parameters 3 >> ${YAML_FILE_NNAME}

#Update the values with the uncorrelated Dz priors {{{
tomoval_all=`cat @DB:nzbias_uncorr@` 
#Add the uncorrelated tomographic bin shifts 
for tomo in `seq ${NTOMO}`
do
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print $n}'`
  echo "      nofz_shifts.uncorr_bias_${tomo}:" >> ${YAML_FILE_NNAME}
  echo "        ref: ${tomoval}" >> ${YAML_FILE_NNAME}
  echo "        prior:" >> ${YAML_FILE_NNAME}
  echo "          dist: norm" >> ${YAML_FILE_NNAME}
  echo "          loc: ${tomoval}" >> ${YAML_FILE_NNAME}
  echo "          scale: 1.0" >> ${YAML_FILE_NNAME}
done
#}}}

#Prepare the theory setup and cosmology parameters {{{
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  CAMB_BOLTZMANN=mead
elif [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  CAMB_BOLTZMANN=mead2020_feedback
else
  _message "@RED@ ERROR - Boltzmann option @DEF@${BOLTZMAN^^}@RED@ not supported by cobaya\n"
  exit 1 
fi

cat >> ${YAML_FILE_NNAME} <<- EOF
theory:
  camb:
    extra_args:
      halofit_version: ${CAMB_BOLTZMANN}
      neutrino_hierarchy: normal

params:
EOF
#}}}

#Add cosmological parameters: {{{
for param in omch2 ombh2 h0 n_s omega_k w wa mnu 
do 
  write_sampling_params ${param} >> ${YAML_FILE_NNAME}
done
write_sampling_params s_8_input "" 1 "drop: True" >> ${YAML_FILE_NNAME}

echo "  H0: \"lambda h0: h0*100\"" >> ${YAML_FILE_NNAME}
echo "  sigma8: \"lambda s_8_input, ombh2, omch2, H0: s_8_input/np.sqrt((ombh2 + omch2)/(H0/100)**2/0.3)\"" >> ${YAML_FILE_NNAME}
echo "  omegam:" >> ${YAML_FILE_NNAME}
echo "  As:" >> ${YAML_FILE_NNAME}
echo "  s8:" >> ${YAML_FILE_NNAME}
echo "    derived: \"lambda sigma8, omegam: sigma8*np.sqrt(omegam/0.3)\"" >> ${YAML_FILE_NNAME}

if [ "${BOLTZMAN^^}" == "CAMB_HM2020" ]
then
  write_sampling_params log_T_AGN >> ${YAML_FILE_NNAME}
elif [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  write_sampling_params Abary >> ${YAML_FILE_NNAME}
  echo "  HMCode_eta_baryon: \"lambda HMCode_A_baryon: 0.98 - 0.12*HMCode_A_baryon\"" >> ${YAML_FILE_NNAME}
fi
#}}}


