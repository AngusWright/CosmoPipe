#=========================================
#
# File Name : get_features.sh
# Created By : awright
# Creation Date : 06-08-2023
# Last Modified : Fri Jul 18 06:39:12 2025
#
#=========================================

#Get the list of magnitudes 
fluxlist="@BV:FLUXLIST@" 

#Get the feature specification 
feature_types="@BV:FEATURETYPES@"

#Check for colours, mags, or both 
magnitudes=""
colours=""
if [[ "${feature_types^^}" =~ "FLUX" ]]
then 
  if [[ "${feature_types^^}" =~ "ALLFLUX" ]] 
  then 
    magnitudes="ALL"
  else 
    magnitudes="REF"
  fi
fi 
if [[ "${feature_types^^}" =~ "RATIO" ]] 
then 
  if [[ "${feature_types^^}" =~ "ALLRATIO" ]] 
  then 
    colours="ALL"
  elif [[ "${feature_types^^}" =~ "REFRATIO" ]] 
  then 
    colours="REL"
  else 
    colours="SIMPLE"
  fi
fi 

features=""
if [ "${colours}" == "ALL" ]
then 
  #Get the number of magnitudes 
  nmag=`echo ${fluxlist} | awk '{print NF}'`
  #Loop through the magnitudes  
  for i in `seq 1 $((nmag-1))`
  do 
    #Loop through the remaining magnitudes  
    for j in `seq $((i+1)) ${nmag}`
    do 
      #Construct the ratio label 
      col=`echo ${fluxlist} | awk -v i=${i} -v j=${j} '{print $i "/" $j}'`
      #Add the colour to the feature space 
      features="${features} ${col}"
    done 
  done 
fi 
if [ "${colours}" == "SIMPLE" ] 
then 
  #Get the number of neighbouring colours 
  ncol=`echo ${fluxlist} | awk '{print NF-1}'`
  #Loop through the colours 
  for i in `seq 1 ${ncol}`
  do 
    #Construct the colour label 
    col=`echo ${fluxlist} | awk -v i=${i} '{print $i "/" $(i+1)}'`
    #Add the colour to the feature space 
    features="${features} ${col}"
  done 
fi 
if [ "${colours}" == "REL" ] 
then 
  #Get the number of neighbouring colours 
  ncol=`echo ${fluxlist} | awk '{print NF}'`
  #Loop through the colours 
  for i in `seq 1 ${ncol}`
  do 
    #Construct the colour label 
    col=`echo ${fluxlist} | awk -v i=${i} -v ref=@BV:REFFLUXNAME@ '{print $i "/" ref}'`
    #Add the colour to the feature space 
    features="${features} ${col}"
  done 
fi 
if [ "${magnitudes}" == "ALL" ]
then 
  features="${features} ${fluxlist}" 
fi 
if [ "${magnitudes}" == "REF" ]
then 
  features="${features} @BV:REFFLUXNAME@"
fi 

#Assign the feature space to the block variables 
_write_blockvars "SOMFEATURES" "${features}"

