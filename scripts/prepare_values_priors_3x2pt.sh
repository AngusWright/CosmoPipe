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
PRIOR_SIGMA8="@BV:PRIOR_SIGMA8@"
PRIOR_OMEGAK="@BV:PRIOR_OMEGAK@"
PRIOR_W="@BV:PRIOR_W@"
PRIOR_WA="@BV:PRIOR_WA@"
PRIOR_MNU="@BV:PRIOR_MNU@"
PRIOR_TCMB="@BV:PRIOR_TCMB@"

#Halo model parameters
PRIOR_LOGTAGN="@BV:PRIOR_LOGTAGN@"
PRIOR_MB="@BV:PRIOR_MB@"

#HOD parameters
PRIOR_LOG10_OBS_NORM_C="@BV:PRIOR_LOG10_OBS_NORM_C@"
PRIOR_LOG_M_CH="@BV:PRIOR_LOG_M_CH@"
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
PRIOR_POISSON_A="@BV:PRIOR_POISSON_A@"
PRIOR_POISSON_SLOPE="@BV:PRIOR_POISSON_SLOPE@"
PRIOR_POISSON_M0="@BV:PRIOR_POISSON_M0@"

#Mass dependent IA model
PRIOR_A_IA_RED="@BV:PRIOR_A_IA_RED@"
PRIOR_LOG10_M_PIV_RED="@BV:PRIOR_LOG10_M_PIV_RED@"
PRIOR_BETA_IA_ONE_RED="@BV:PRIOR_BETA_IA_ONE_RED@"
PRIOR_BETA_IA_TWO_RED="@BV:PRIOR_BETA_IA_TWO_RED@"
PRIOR_A_IA_1H_RED="@BV:PRIOR_A_IA_1H_RED@"
PRIOR_SLOPE_1H_RED="@BV:PRIOR_SLOPE_1H_RED@"
PRIOR_BETA_IA_SAT_RED="@BV:PRIOR_BETA_IA_SAT_RED@"

PRIOR_A_IA_BLUE="@BV:PRIOR_A_IA_BLUE@"
PRIOR_LOG10_M_PIV_BLUE="@BV:PRIOR_LOG10_M_PIV_BLUE@"
PRIOR_BETA_IA_ONE_BLUE="@BV:PRIOR_BETA_IA_ONE_BLUE@"
PRIOR_BETA_IA_TWO_BLUE="@BV:PRIOR_BETA_IA_TWO_BLUE@"
PRIOR_A_IA_1H_BLUE="@BV:PRIOR_A_IA_1H_BLUE@"
PRIOR_SLOPE_1H_BLUE="@BV:PRIOR_SLOPE_1H_BLUE@"
PRIOR_BETA_IA_SAT_BLUE="@BV:PRIOR_BETA_IA_SAT_BLUE@"


#BOLTZMANN code
BOLTZMAN=@BV:BOLTZMAN@
#IA model
IAMODEL="@BV:IAMODEL@"

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
for param in omch2 ombh2 h0 n_s sigma_8 omega_k w wa mnu TCMB
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
blockname="[halo_model_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE

if [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ]
then
  for param in log_T_AGN m_b
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
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi
#}}}

#Add profile parameters: {{{
blockname="[profile_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
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

#Add hod parameters: {{{
blockname="[hod_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
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

#Add poisson parameters: {{{
blockname="[pk_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
for param in poisson_a poisson_m0 poisson_slope
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


#Add intrinsic alignment parameters red: {{{
blockname="[intrinsic_alignment_parameters_ia_red]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
if [ "${IAMODEL^^}" == "LINEAR" ] 
then
  for param in AIA 
  do 
    #Load the prior variable name {{{
    pvar=${param^^}
    pvar=PRIOR_${pvar//_RED/}
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
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
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
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
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
elif [ "${IAMODEL^^}" == "LUMDEP" ]
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
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
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
else
	_message "Intrinsic alignment model not implemented: ${IAMODEL^^}\n"
  exit 1
fi
#}}}



#Update the values with the uncorrelated Dz priors {{{
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
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
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
#Add the uncorrelated tomographic bin shifts 
for tomo in `seq ${NTOMO}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
  echo "uncorr_bias_${tomo} = gaussian ${tomoval} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
done
#}}}

_write_datablock "cosmosis_inputs" "@SURVEY@_values.ini @SURVEY@_priors.ini"
#}}}

