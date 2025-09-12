#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Sat Feb 24 08:52:14 2024
#
#=========================================

#Number of tomographic bins 
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
#SP(k) parameters fb_a fb_pow fb_pivot epsilon alpha beta gamma m_pivot
#PRIOR_FB_A="@BV:PRIOR_FB_A@"
#PRIOR_FB_POW="@BV:PRIOR_FB_POW@"
#PRIOR_FB_PIVOT="@BV:PRIOR_FB_PIVOT@"
#PRIOR_EPSILON="@BV:PRIOR_EPSILON@"
#PRIOR_ALPHA="@BV:PRIOR_ALPHA@"
#PRIOR_BETA="@BV:PRIOR_BETA@"
#PRIOR_GAMMA="@BV:PRIOR_GAMMA@"
#PRIOR_M_PIVOT="@BV:PRIOR_M_PIVOT@"

#BOLTZMANN code
BOLTZMAN=@BV:BOLTZMAN@
#delta z model
DZMODEL="@BV:DZMODEL@"
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
for param in omch2 ombh2 h0 n_s s_8_input omega_k w wa mnu 
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

if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ]
then
  for param in log_T_AGN
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
elif [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_SPK" ]
then
  for param in logT_AGN
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
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ]
then
  for param in Abary 
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
      echo "${param//bary/} = ${pstring}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
      #Add the gaussian prior to the priors.ini file  {{{
      if [ "${found_gauss}" == "FALSE" ]
      then 
        echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
        found_gauss=TRUE
      fi 
      #Write the gaussian prior to the priors file 
      echo "${param//bary/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
      #}}}
      #}}}
    else 
      #Write the tophat prior to the priors file {{{
      echo "${param//bary/} = ${pprior}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
      #}}}
    fi 
    #}}}
  done 
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
  exit 1
fi
#}}}
#Add intrinsic alignment parameters: {{{
blockname="[intrinsic_alignment_parameters]"
echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
found_gauss=FALSE
if [ "${IAMODEL^^}" == "LINEAR" ] 
then
  for param in AIA 
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
#}}}

#Add the SPk priors if needed {{{ 
if [ "${BOLTZMAN^^}" == "CAMB_SPK" ]
then
  blockname="[spk]"
  echo "${blockname}" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  found_gauss=FALSE
  for param in fb_a fb_pow fb_pivot #fb_a fb_pow fb_pivot epsilon alpha beta gamma m_pivot
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

if [[ $DZMODEL=~ 'STRETCH' ]]
then 
  #Update the values with the uncorrelated Dz priors {{{
  echo "[nz_source_errors]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
  #Add the tomographic bin stretch priors 
  tomoval_all="@BV:NZSTRETCH@"
  tomoerr_all="@BV:NZSTRETCH_UNCERTAINTY@"
  for tomo in `seq ${NTOMO}`
  do 
    tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print $n}'`
    tomoerr=`echo ${tomoerr_all} | awk -v n=${tomo} '{print $n}'`
    tomolo=`echo $tomoval $tomoerr | awk '{print $1-5*$2}'`
    tomohi=`echo $tomoval $tomoerr | awk '{print $1+5*$2}'`
    echo "width_${tomo} = ${tomolo} ${tomoval} ${tomohi} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  done
  #}}}
  #Update the priors with the uncorrelated Dz priors {{{
  echo "[nz_source_errors]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
  #Add the uncorrelated tomographic bin shifts 
  for tomo in `seq ${NTOMO}`
  do 
    tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print $n}'`
    tomoerr=`echo ${tomoerr_all} | awk -v n=${tomo} '{print $n}'`
    echo "width_${tomo} = gaussian ${tomoval} ${tomoerr} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
  done
  #}}}
fi 

_write_datablock "cosmosis_inputs" "@SURVEY@_values.ini @SURVEY@_priors.ini"
#}}}

