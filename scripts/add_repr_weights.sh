#=========================================
#
# File Name : add_repr_weights.sh
# Created By : awright
# Creation Date : 12-09-2023
# Last Modified : Fri 15 Sep 2023 11:34:27 AM CEST
#
#=========================================

#Script to match an input catalogue to simulated catalogues 
#Get the catalogues to match from the DATAHEAD 
input="@DB:ALLHEAD@"
ninp=`echo ${input} | awk '{print NF}'`
#Simulation catalogues are assumed to be in match_base
sims="@DB:match_base@"
nsim=`echo ${sims} | awk '{print NF}'`
#Check for more mismatch in simulation and data catalogues  {{{
if [ ${nsim} -ne 1 ] && [ ${nsim} -ne ${ninp} ] && [ ${ninp} -ne 1 ]
then 
  _message "@RED@ ERROR!@DEF@\n"
  _message "@RED@ The provided simulation catalogue list is length @BLU@${nsim}@RED@, and@DEF@\n"
  _message "@RED@ the provided target catalogue list is length @BLU@${ninp}@RED@. These @DEF@\n"
  _message "@RED@ should be of the same length, or one should be a single catalogue.@DEF@\n"
  exit 1
elif [ ${nsim} -ne ${ninp} ]
then 
  if [ ${nsim} -ne 1 ] 
  then 
    outlist=''
    for i in `seq ${ninp}` 
    do 
      outlist="${outlist} ${sims}"
    done
    sims="${outlist}"
  elif [ ${ninp} -ne 1 ]
  then 
    outlist=''
    for i in `seq ${nsim}` 
    do 
      outlist="${outlist} ${input}"
    done
    input="${outlist}"
  fi 
fi 
#}}}
#Update the nsim value 
nsim=`echo ${sims} | awk '{print NF}'`

#Construct the data-simulation feature list 
data_features="@BV:DATAFEATURES@"
nfeat_data=`echo ${data_features} | awk '{print NF}'`
sim_features="@BV:SIMFEATURES@"
nfeat_sim=`echo ${sim_features} | awk '{print NF}'`
#Check that the features match 
if [ ${nfeat_data} -ne ${nfeat_sim} ] 
then 
  _message "@RED@ ERROR!@DEF@\n"
  _message "@RED@ The provided feature space in the simulation catalogue is length @BLU@${nfeat_sim}@RED@, and@DEF@\n"
  _message "@RED@ the provided target catalogue feature space is length @BLU@${nfeat_data}@RED@. These @DEF@\n"
  _message "@RED@ should be of the same length.@DEF@\n"
  _message "@RED@ sims: @BLU@${sim_features}@DEF@\n"
  _message "@RED@ data: @BLU@${data_features}@DEF@\n"
  exit 1
fi 
#Construct the feature list
feature_list=''
for i in `seq ${nfeat_data}` 
do 
  current_feat_data=`echo ${data_features} | awk -v col=${i} '{print $col}'`
  current_feat_sims=`echo ${sim_features} | awk -v col=${i} '{print $col}'`
  _message "  > @BLU@ Creating feature match: @RED@${current_feat_data}@BLU@ (data)@DEF@ <-> @RED@${current_feat_sims}@BLU@ (sim)@DEF@\n"
  feature_list="${feature_list} ${current_feat_data} ${current_feat_sims}"
done 


#Loop through the catalogues, constructing the matches 
for i in `seq ${nsim}`
do 
  #Get the current simulation catalogue 
  current_sim=`echo ${sims} | awk -v col=${i} '{print $col}'`
  #Get the current data catalogue 
  current_data=`echo ${input} | awk -v col=${i} '{print $col}'`
  #Construct the output filename 
  output_file=${current_data//.${ext}/_simmatch.${ext}}
  
  #Notify that we are matching these catalogues 
  #_message "   @BLU@@BV:ZSPECDATA@ @BV:ZSPECSIM@@DEF@\n"
  _message " > @BLU@Matching simulation catalogue @RED@${current_sim##*/}@BLU@ to data catalogue @RED@${current_data##*/}@DEF@"
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/add_repr_weights.R \
          -t ${current_data} \
          -r ${current_sim} \
          -o ${output_file} \
          --weightname "@BV:WEIGHTNAME@" \
          -st @BV:ZSPECDATA@ -sr @BV:ZSPECSIM@ \
          -f ${feature_list} -c @BV:NTHREADS@ \
          2>&1 

  #Notify 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  _message " > @BLU@Merging weight back to full simulation file @DEF@"
  #Copy the weightname back to the full simulation catalogue 
  if [ "@BV:WEIGHTNAME@" != "" ]
  then 
    #If we provided a weightname, first delete the original column  
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
      -i ${current_sim} \
      -o ${current_sim}_tmp \
      -k @BV:WEIGHTNAME@ -t OBJECTS 2>&1
    #then merge updated weight back 
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
      -i ${current_sim}_tmp \
      -p ${output_file} \
      -o ${output_file}_tmp \
      -k @BV:WEIGHTNAME@ -t OBJECTS 2>&1
    #And move the intermediate file to the final location 
    mv -f ${output_file}_tmp ${output_file}
    #And delete the intermediate file 
    rm ${current_sim}_tmp
  else 
    #Otherwise, merge the repr_weight column 
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
      -i ${current_sim} \
      -p ${output_file} \
      -o ${output_file}_tmp \
      -k repr_weight -t OBJECTS 2>&1
    #And move the intermediate file to the final location 
    mv -f ${output_file}_tmp ${output_file}
  fi 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #Update the DATAHEAD 
  _replace_datahead "${current_data}" "${output_file}"

done 
  