#=========================================
#
# File Name : prepare_values_priors_3x2pt.sh
# Created By : dvornik
# Creation Date : 06-11-2025
# Last Modified : Wed Nov 06 08:52:14 2024
#
#=========================================

#Number of tomographic bins 
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENS="@BV:NLENSBINS@"
NOBS="@BV:NSMFLENSBINS@"

#All possible prior values that might need specification
PRIOR_OMCH2="@BV:PRIOR_OMCH2@"
PRIOR_OMBH2="@BV:PRIOR_OMBH2@"
PRIOR_H0="@BV:PRIOR_H0@"
PRIOR_NS="@BV:PRIOR_NS@"
PRIOR_S8INPUT="@BV:PRIOR_S8INPUT@"
PRIOR_OMEGAK="@BV:PRIOR_OMEGAK@"
PRIOR_W="@BV:PRIOR_W@"
PRIOR_WA="@BV:PRIOR_WA@"
PRIOR_MNU="@BV:PRIOR_MNU@"
PRIOR_TCMB="@BV:PRIOR_TCMB@"

#Halo model parameters
PRIOR_LOGTAGN="@BV:PRIOR_LOGTAGN@"
PRIOR_MB="@BV:PRIOR_M_B@"

#HOD parameters
PRIOR_LOG10_OBS_NORM_C="@BV:PRIOR_LOG10_OBS_NORM_C@"
PRIOR_LOG10_M_CH="@BV:PRIOR_LOG10_M_CH@"
PRIOR_G1="@BV:PRIOR_G1@"
PRIOR_G2="@BV:PRIOR_G2@"
PRIOR_SIGMA_LOG10_O_C="@BV:PRIOR_SIGMA_LOG10_O_C@"
PRIOR_NORM_S="@BV:PRIOR_NORM_S@"
PRIOR_PIVOT="@BV:PRIOR_PIVOT@"
PRIOR_ALPHA_S="@BV:PRIOR_ALPHA_S@"
PRIOR_BETA_S="@BV:PRIOR_BETA_S@"
PRIOR_B0="@BV:PRIOR_B0@"
PRIOR_B1="@BV:PRIOR_B1@"
PRIOR_B2="@BV:PRIOR_B2@"
PRIOR_A_CEN="@BV:PRIOR_A_CEN@"
PRIOR_A_SAT="@BV:PRIOR_A_SAT@"

#PROFILE parameters
PRIOR_NORMCEN="@BV:PRIOR_NORMCEN@"
PRIOR_NORMSAT="@BV:PRIOR_NORMSAT@"
PRIOR_ETACEN="@BV:PRIOR_ETACEN@"
PRIOR_ETASAT="@BV:PRIOR_ETASAT@"

#PK parameters
PRIOR_POISSON="@BV:PRIOR_POISSON@"
PRIOR_SLOPE="@BV:PRIOR_SLOPE@"
PRIOR_M_0="@BV:PRIOR_M_0@"

# IA model red
PRIOR_MPIVOT_CEN_RED="@BV:PRIOR_MPIVOT_CEN_RED@"
PRIOR_MPIVOT_SAT_RED="@BV:PRIOR_MPIVOT_SAT_RED@"
PRIOR_GAMMA_2H_AMPLITUDE_RED="@BV:PRIOR_GAMMA_2H_AMPLITUDE_RED@"
PRIOR_BETA_CEN_RED="@BV:PRIOR_BETA_CEN_RED@"
PRIOR_GAMMA_1H_SLOPE_RED="@BV:PRIOR_GAMMA_1H_SLOPE_RED@"
PRIOR_GAMMA_1H_AMPLITUDE_RED="@BV:PRIOR_GAMMA_1H_AMPLITUDE_RED@"
PRIOR_BETA_SAT_RED="@BV:PRIOR_BETA_SAT_RED@"
PRIOR_BETA_TWO_RED="@BV:PRIOR_BETA_TWO_RED@"

# IA model_blue
PRIOR_MPIVOT_CEN_BLUE="@BV:PRIOR_MPIVOT_CEN_BLUE@"
PRIOR_MPIVOT_SAT_BLUE="@BV:PRIOR_MPIVOT_SAT_BLUE@"
PRIOR_GAMMA_2H_AMPLITUDE_BLUE="@BV:PRIOR_GAMMA_2H_AMPLITUDE_BLUE@"
PRIOR_BETA_CEN_BLUE="@BV:PRIOR_BETA_CEN_BLUE@"
PRIOR_GAMMA_1H_SLOPE_BLUE="@BV:PRIOR_GAMMA_1H_SLOPE_BLUE@"
PRIOR_GAMMA_1H_AMPLITUDE_BLUE="@BV:PRIOR_GAMMA_1H_AMPLITUDE_BLUE@"
PRIOR_BETA_SAT_BLUE="@BV:PRIOR_BETA_SAT_BLUE@"
PRIOR_BETA_TWO_BLUE="@BV:PRIOR_BETA_TWO_BLUE@"

#NLA model
PRIOR_AIA="@BV:PRIOR_AIA@"
#TATT parameters
PRIOR_ZPIV="@BV:PRIOR_Z_PIV@"
PRIOR_A1="@BV:PRIOR_A1@"
PRIOR_A2="@BV:PRIOR_A2@"
PRIOR_ALPHA1="@BV:PRIOR_ALPHA1@"
PRIOR_ALPHA2="@BV:PRIOR_ALPHA2@"
PRIOR_BIASTA="@BV:PRIOR_BIAS_TA@"
#Linear z IA model
PRIOR_A_IA="@BV:PRIOR_A_IA@"
PRIOR_B_IA="@BV:PRIOR_B_IA@"
PRIOR_A_PIV="@BV:PRIOR_A_PIV@"
#Mass dependent IA model
PRIOR_LOG10_M_PIV="@BV:PRIOR_LOG10_M_PIV@"
PRIOR_F_R_1="@BV:PRIOR_F_R_1@"
PRIOR_F_R_2="@BV:PRIOR_F_R_2@"
PRIOR_F_R_3="@BV:PRIOR_F_R_3@"
PRIOR_F_R_4="@BV:PRIOR_F_R_4@"
PRIOR_F_R_5="@BV:PRIOR_F_R_5@"
PRIOR_F_R_6="@BV:PRIOR_F_R_6@"
#Bias priors
PRIOR_BIAS_1="@BV:PRIOR_BIAS_1@"
PRIOR_BIAS_2="@BV:PRIOR_BIAS_2@"
PRIOR_BIAS_3="@BV:PRIOR_BIAS_3@"
PRIOR_BIAS_4="@BV:PRIOR_BIAS_4@"
PRIOR_BIAS_5="@BV:PRIOR_BIAS_5@"
PRIOR_BIAS_6="@BV:PRIOR_BIAS_6@"
# dz bias prior for single obs bin
PRIOR_OBS_BIAS_1="@BV:PRIOR_OBS_BIAS_1@"

#BOLTZMANN code
BOLTZMAN=@BV:BOLTZMAN@
#IA model
IAMODEL="@BV:IAMODEL@"
#Split IA model
SPLIT_IA="@BV:SPLIT_IA@"
#Bias model
GALAXY_BIAS="@BV:GALAXY_BIAS@"
#Modes
MODES="@BV:MODES@"

#Values and prior files {{{
#Create the cosmosis_inputs directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/
fi 
#Generate the _values.ini file: 
#cp @RUNROOT@/@CONFIGPATH@/values.ini @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini ]
then 
  _message "  @BLU@Deleting previous _values file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  _message "@RED@ - Done!@DEF@\n"
fi 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini ]
then 
  _message "  @BLU@Deleting previous _priors file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
  _message "@RED@ - Done!@DEF@\n"
fi

#Add cosmological parameters: {{{
blockname="[cosmological_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
for param in omch2 ombh2 h0 n_s s_8_input omega_k w wa mnu TCMB
do
  #Load the prior variable name {{{
  pvar=${param^^}
  pvar=PRIOR_${pvar//_/}
  #}}}
  #get the prior value {{{
  pprior=`echo ${!pvar}`
  #}}}
  #Check the prior is correctly specified {{{
  nprior=`echo ${pprior} | awk '{print NF}'` 
  if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
  then 
    _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
    _message "@RED@         it is: @DEF@${pprior}\n"
    exit 1 
  fi 
  #}}}
  #Write the prior {{{
  if [ "${pprior%% *}" == "gaussian" ]
  then 
    #Prior is a gaussian {{{
    #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
    pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
    echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
    #Add the gaussian prior to the priors.ini file  {{{
    if [ "${found_gauss}" == "FALSE" ]
    then 
      echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      found_gauss=TRUE
    fi 
    #Write the gaussian prior to the priors file 
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
    #}}}
    #}}}
  else 
    #Write the tophat prior to the priors file {{{
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
  fi 
  #}}}
done 
#}}}


#Add halo model parameters: {{{
if [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ] 
then
  blockname="[halo_model_parameters]"
  echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  found_gauss=FALSE
  for param in logT_AGN m_b
  do
    #Load the prior variable name {{{
    pvar=${param^^}
    pvar=PRIOR_${pvar//_/}
    #}}}
    #get the prior value {{{
    pprior=`echo ${!pvar}`
    #}}}
    #Check the prior is correctly specified {{{
    nprior=`echo ${pprior} | awk '{print NF}'` 
    if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
    then 
      _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
      _message "@RED@         it is: @DEF@${pprior}\n"
      exit 1 
    fi 
    #}}}
    #Write the prior {{{
    if [ "${pprior%% *}" == "gaussian" ]
    then 
      #Prior is a gaussian {{{
      #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
      pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
      echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
      #Add the gaussian prior to the priors.ini file  {{{
      if [ "${found_gauss}" == "FALSE" ]
      then 
        echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi 
      #Write the gaussian prior to the priors file 
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      #}}}
      #}}}
    else 
      #Write the tophat prior to the priors file {{{
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
    fi 
    #}}}
  done
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi
#}}}

#Add profile parameters: {{{
blockname="[profile_parameters]"
echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
for param in norm_cen norm_sat eta_cen eta_sat
do
  #Load the prior variable name {{{
  pvar=${param^^}
  pvar=PRIOR_${pvar//_/}
  #}}}
  #get the prior value {{{
  pprior=`echo ${!pvar}`
  #}}}
  #Check the prior is correctly specified {{{
  nprior=`echo ${pprior} | awk '{print NF}'`
  if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
  then
    _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
    _message "@RED@         it is: @DEF@${pprior}\n"
    exit 1
  fi
  #}}}
  #Write the prior {{{
  if [ "${pprior%% *}" == "gaussian" ]
  then
    #Prior is a gaussian {{{
    #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
    pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
    echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
    #Add the gaussian prior to the priors.ini file  {{{
    if [ "${found_gauss}" == "FALSE" ]
    then
      echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      found_gauss=TRUE
    fi
    #Write the gaussian prior to the priors file
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
    #}}}
    #}}}
  else
    #Write the tophat prior to the priors file {{{
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
  fi
  #}}}
done
#}}}

#Add hod parameters: {{{
blockname="[hod_parameters]"
echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
for param in log10_obs_norm_c log10_m_ch g1 g2 sigma_log10_O_c norm_s pivot alpha_s beta_s b0 b1 b2 A_cen A_sat
do
  #Load the prior variable name {{{
  pvar=${param^^}
  pvar=PRIOR_${pvar}
  #}}}
  #get the prior value {{{
  pprior=`echo ${!pvar}`
  #}}}
  #Check the prior is correctly specified {{{
  nprior=`echo ${pprior} | awk '{print NF}'`
  if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
  then
    _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
    _message "@RED@         it is: @DEF@${pprior}\n"
    exit 1
  fi
  #}}}
  #Write the prior {{{
  if [ "${pprior%% *}" == "gaussian" ]
  then
    #Prior is a gaussian {{{
    #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
    pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
    echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
    #Add the gaussian prior to the priors.ini file  {{{
    if [ "${found_gauss}" == "FALSE" ]
    then
      echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      found_gauss=TRUE
    fi
    #Write the gaussian prior to the priors file
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
    #}}}
    #}}}
  else
    #Write the tophat prior to the priors file {{{
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
  fi
  #}}}
done
#}}}

#Add poisson parameters: {{{
blockname="[pk_parameters]"
echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
for param in poisson m_0 slope
do
  #Load the prior variable name {{{
  pvar=${param^^}
  pvar=PRIOR_${pvar}
  #}}}
  #get the prior value {{{
  pprior=`echo ${!pvar}`
  #}}}
  #Check the prior is correctly specified {{{
  nprior=`echo ${pprior} | awk '{print NF}'`
  if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
  then
    _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
    _message "@RED@         it is: @DEF@${pprior}\n"
    exit 1
  fi
  #}}}
  #Write the prior {{{
  if [ "${pprior%% *}" == "gaussian" ]
  then
    #Prior is a gaussian {{{
    #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
    pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
    echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
    #Add the gaussian prior to the priors.ini file  {{{
    if [ "${found_gauss}" == "FALSE" ]
    then
      echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      found_gauss=TRUE
    fi
    #Write the gaussian prior to the priors file
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
    #}}}
    #}}}
  else
    #Write the tophat prior to the priors file {{{
    echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    #}}}
  fi
  #}}}
done
#}}}


#Add intrinsic alignment parameters: {{{
# Halo model requires two IA blocks (red and blue). Check this first.
if [ "${IAMODEL^^}" == "HALO_MODEL" ]
then 
  colours=(blue)
  if [ "${SPLIT_IA^^}" == "TRUE" ]
  then
    colours+=(red)
  fi

  for colour in "${colours[@]}"
  do
    blockname="[intrinsic_alignment_parameters_ia_${colour}]"
    echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    found_gauss=FALSE
    for param in mpivot_cen mpivot_sat gamma_2h_amplitude beta_cen gamma_1h_slope gamma_1h_amplitude beta_sat beta_two
    do 
      #Load the prior variable name {{{
      pvar=${param^^}
      pvar=PRIOR_${pvar}_${colour^^}
      #}}}
      #get the prior value {{{
      pprior=`echo ${!pvar}`
      #}}}
      #Check the prior is correctly specified {{{
      nprior=`echo ${pprior} | awk '{print NF}'` 
      if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
      then 
        _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
        _message "@RED@         it is: @DEF@${pprior}\n"
        exit 1 
      fi 
      #}}}
      #Write the prior {{{   
      if [ "${pprior%% *}" == "gaussian" ]
      then 
        #Prior is a gaussian {{{
        #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
        pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
        echo "${param//IA/} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
        #Add the gaussian prior to the priors.ini file  {{{
        if [ "${found_gauss}" == "FALSE" ]
        then 
          echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
          found_gauss=TRUE
        fi 
        #Write the gaussian prior to the priors file 
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        #}}}
        #}}}
      else 
        #Write the tophat prior to the priors file {{{
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
      fi 
      #}}}
    done
  done
elif [ "${IAMODEL^^}" == "NONE" ]
then
    # Do nothing if IA model is set to none
    :
else
  # All other IA models only require one IA block
  blockname="[intrinsic_alignment_parameters]"
  echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  found_gauss=FALSE
  if [ "${IAMODEL^^}" == "LINEAR" ] 
  then
    for param in AIA 
    do 
      #Load the prior variable name {{{
      pvar=${param^^}
      pvar=PRIOR_${pvar}
      #}}}
      #get the prior value {{{
      pprior=`echo ${!pvar}`
      #}}}
      #Check the prior is correctly specified {{{
      nprior=`echo ${pprior} | awk '{print NF}'` 
      if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
      then 
        _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
        _message "@RED@         it is: @DEF@${pprior}\n"
        exit 1 
      fi 
      #}}}
      #Write the prior {{{   
      if [ "${pprior%% *}" == "gaussian" ]
      then 
        #Prior is a gaussian {{{
        #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
        pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
        echo "${param//IA/} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
        #Add the gaussian prior to the priors.ini file  {{{
        if [ "${found_gauss}" == "FALSE" ]
        then 
          echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
          found_gauss=TRUE
        fi 
        #Write the gaussian prior to the priors file 
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        #}}}
        #}}}
      else 
        #Write the tophat prior to the priors file {{{
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
      fi 
      #}}}
    done 
  elif [ "${IAMODEL^^}" == "TATT" ] 
  then
    for param in z_piv A1 A2 alpha1 alpha2 bias_ta
    do 
      #Load the prior variable name {{{
      pvar=${param^^}
      pvar=PRIOR_${pvar//_/}
      #}}}
      #get the prior value {{{
      pprior=`echo ${!pvar}`
      #}}}
      #Check the prior is correctly specified {{{
      nprior=`echo ${pprior} | awk '{print NF}'` 
      if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
      then 
        _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
        _message "@RED@         it is: @DEF@${pprior}\n"
        exit 1 
      fi 
      #}}}
      #Write the prior {{{   
      if [ "${pprior%% *}" == "gaussian" ]
      then 
        #Prior is a gaussian {{{
        #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
        pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
        echo "${param//IA/} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
        #Add the gaussian prior to the priors.ini file  {{{
        if [ "${found_gauss}" == "FALSE" ]
        then 
          echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
          found_gauss=TRUE
        fi 
        #Write the gaussian prior to the priors file 
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        #}}}
        #}}}
      else 
        #Write the tophat prior to the priors file {{{
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
      fi 
      #}}}
    done 
  elif [ "${IAMODEL^^}" == "LINEAR_Z" ]
  then
    for param in a_ia b_ia a_piv
    do 
      #Load the prior variable name {{{
      pvar=${param^^}
      pvar=PRIOR_${pvar}
      #}}}
      #get the prior value {{{
      pprior=`echo ${!pvar}`
      #}}}
      #Check the prior is correctly specified {{{
      nprior=`echo ${pprior} | awk '{print NF}'` 
      if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
      then 
        _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
        _message "@RED@         it is: @DEF@${pprior}\n"
        exit 1 
      fi 
      #}}}
      #Write the prior {{{   
      if [ "${pprior%% *}" == "gaussian" ]
      then 
        #Prior is a gaussian {{{
        #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
        pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
        echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
        #Add the gaussian prior to the priors.ini file  {{{
        if [ "${found_gauss}" == "FALSE" ]
        then 
          echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
          found_gauss=TRUE
        fi 
        #Write the gaussian prior to the priors file 
        echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        #}}}
        #}}}
      else 
        #Write the tophat prior to the priors file {{{
        echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
      fi 
      #}}}
    done 
    # This model requires the NLA IA parameter to be set to 1
    echo "A = 1.0" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  elif [ "${IAMODEL^^}" == "MASSDEP" ] 
  then
    for param in log10_M_piv f_r_1 f_r_2 f_r_3 f_r_4 f_r_5 f_r_6
    do 
      #Load the prior variable name {{{
      pvar=${param^^}
      pvar=PRIOR_${pvar}
      #}}}
      #get the prior value {{{
      pprior=`echo ${!pvar}`
      #}}}
      #Check the prior is correctly specified {{{
      nprior=`echo ${pprior} | awk '{print NF}'` 
      if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ] 
      then 
        _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
        _message "@RED@         it is: @DEF@${pprior}\n"
        exit 1 
      fi 
      #}}}
      #Write the prior {{{   
      if [ "${pprior%% *}" == "gaussian" ]
      then 
        #Prior is a gaussian {{{
        #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
        pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
        echo "${param//IA/} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
        #Add the gaussian prior to the priors.ini file  {{{
        if [ "${found_gauss}" == "FALSE" ]
        then 
          echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
          found_gauss=TRUE
        fi 
        #Write the gaussian prior to the priors file 
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        #}}}
        #}}}
      else 
        #Write the tophat prior to the priors file {{{
        echo "${param//IA/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
        #}}}
      fi 
      #}}}
    done
    #Add the uncorrelated AIA and beta 
    params_all=`cat @DB:massdep_params_uncorr@`
    n=1
    for param in uncorr_a uncorr_beta uncorr_log10_M_mean_1 uncorr_log10_M_mean_2 uncorr_log10_M_mean_3 uncorr_log10_M_mean_4 uncorr_log10_M_mean_5 uncorr_log10_M_mean_6
    do 
      val=`echo ${params_all} | awk -v d=${n} '{print $d}'`
      lo=`echo $val | awk '{print $1-5.00}'`
      hi=`echo $val | awk '{print $1+5.00}'`
      echo "${param} = ${lo} ${val} ${hi} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      if [ "${found_gauss}" == "FALSE" ]
      then 
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi 
      echo "${param} = gaussian ${val} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      n=$((n+1))
    done
  else
    _message "Intrinsic alignment model not implemented: ${IAMODEL^^}\n"
    exit 1
  fi
fi
#}}}



#Update the values with the uncorrelated Dz priors {{{

# sources
if [[ .*\ $MODES\ .* =~ " EE " ]] || [[ .*\ $MODES\ .* =~ " NE " ]]
then
echo $'\n'"[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
#Add the uncorrelated tomographic bin shifts 
#Note: we multiply the bin shift by -1 because cosmosis defines the shifts with a relative minus sign!
tomoval_all=`cat @DB:nzbias_uncorr@`
for tomo in `seq ${NTOMO}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
  tomolo=`echo $tomoval | awk '{print $1-5.00}'`
  tomohi=`echo $tomoval | awk '{print $1+5.00}'`
  echo "uncorr_bias_${tomo} = ${tomolo} ${tomoval} ${tomohi} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
done
#}}}
#Update the priors with the uncorrelated Dz priors {{{
echo $'\n'"[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
#Add the uncorrelated tomographic bin shifts 
for tomo in `seq ${NTOMO}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
  echo "uncorr_bias_${tomo} = gaussian ${tomoval} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
done
fi

# lenses
if [[ .*\ $MODES\ .* =~ " NE " ]] || [[ .*\ $MODES\ .* =~ " NN " ]]
then
echo $'\n'"[nofz_shifts_lens]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
#Add the uncorrelated tomographic bin shifts 
#Note: we multiply the bin shift by -1 because cosmosis defines the shifts with a relative minus sign!
tomoval_all=`cat @DB:nzbias_uncorr_lens@`
for tomo in `seq ${NLENS}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
  tomolo=`echo $tomoval | awk '{print $1-5.00}'`
  tomohi=`echo $tomoval | awk '{print $1+5.00}'`
  echo "uncorr_bias_${tomo} = ${tomolo} ${tomoval} ${tomohi} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
done
#}}}
#Update the priors with the uncorrelated Dz priors {{{
echo $'\n'"[nofz_shifts_lens]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
#Add the uncorrelated tomographic bin shifts 
for tomo in `seq ${NLENS}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
  echo "uncorr_bias_${tomo} = gaussian ${tomoval} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
done
fi

# SMF
if [[ .*\ $MODES\ .* =~ " OBS " ]]
then
  if [ "${NOBS}" -gt 1 ]
  then
    echo $'\n'"[nofz_shifts_obs]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
    #Add the uncorrelated tomographic bin shifts 
    #Note: we multiply the bin shift by -1 because cosmosis defines the shifts with a relative minus sign!
    tomoval_all=`cat @DB:nzbias_uncorr_obs@`
    for tomo in `seq ${NOBS}`
    do 
      tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
      tomolo=`echo $tomoval | awk '{print $1-5.00}'`
      tomohi=`echo $tomoval | awk '{print $1+5.00}'`
      echo "uncorr_bias_${tomo} = ${tomolo} ${tomoval} ${tomohi} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    done
    #}}}
    #Update the priors with the uncorrelated Dz priors {{{
    echo $'\n'"[nofz_shifts_obs]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
    #Add the uncorrelated tomographic bin shifts 
    for tomo in `seq ${NOBS}`
    do 
      tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
      echo "uncorr_bias_${tomo} = gaussian ${tomoval} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
    done
  else
    # Read prior for single obs bin
    blockname="[nofz_shifts_obs]"
    echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
    found_gauss=FALSE
    param=bias_1
    pvar=${param^^}
    pvar=PRIOR_OBS_${pvar}
    #}}}
    #get the prior value {{{
    pprior=`echo ${!pvar}`
    #}}}
    #Check the prior is correctly specified {{{
    nprior=`echo ${pprior} | awk '{print NF}'`
    if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
    then
      _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
      _message "@RED@         it is: @DEF@${pprior}\n"
      exit 1
    fi
    #}}}
    #Write the prior {{{
    if [ "${pprior%% *}" == "gaussian" ]
    then
      #Prior is a gaussian {{{
      #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
      pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
      echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
      #Add the gaussian prior to the priors.ini file  {{{
      if [ "${found_gauss}" == "FALSE" ]
      then
        echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi
      #Write the gaussian prior to the priors file
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      #}}}
      #}}}
    else
      #Write the tophat prior to the priors file {{{
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
    fi
  fi
fi


#}}}

if [ "${GALAXY_BIAS^^}" == "LINEAR" ]
then
  #Note: redshift_name_lens is hardcoded in cosmosis_constructor. Using the same name here.
  redshift_name_lens="lens"

  blockname="[bias_${redshift_name_lens}]"
  echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  found_gauss=FALSE
  for i in $(seq 1 $NLENS)
  do
    param=b${i}               
    #Load the prior variable name {{{
    pvar=PRIOR_BIAS_${i}     
    #get the prior value {{{
    pprior=${!pvar}
    #}}}
    #Check the prior is correctly specified {{{
    nprior=`echo ${pprior} | awk '{print NF}'`
    if [ ${nprior} -ne 3 ] && [ ${nprior} -ne 1 ]
    then
      _message "@RED@ ERROR - prior @DEF@${pvar}@RED@ does not have 3 values! Must be tophat ('lo start hi') or gaussian ('gaussian mean sd')@DEF@\n"
      _message "@RED@         it is: @DEF@${pprior}\n"
      exit 1
    fi
    #}}}
    #Write the prior {{{
    if [ "${pprior%% *}" == "gaussian" ]
    then
      #Prior is a gaussian {{{
      #Construct the tophat prior: [-10 sigma, +10 sigma ] {{{
      pstring=`echo ${pprior} | awk '{print $2-10*$3,$2,$2+10*$3}'`
      echo "${param} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
      #Add the gaussian prior to the priors.ini file  {{{
      if [ "${found_gauss}" == "FALSE" ]
      then
        echo $'\n'"${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi
      #Write the gaussian prior to the priors file
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      #}}}
      #}}}
    else
      #Write the tophat prior to the priors file {{{
      echo "${param} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
    fi
    #}}}
  done
fi

_write_datablock "cosmosis_inputs" "@SURVEY@_values.ini @SURVEY@_priors.ini"
#}}}

