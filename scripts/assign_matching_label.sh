#=========================================
#
# File Name : match_to_sims.sh
# Created By : awright
# Creation Date : 15-06-2023
# Last Modified : Mon Apr 27 20:55:36 2026
#
#=========================================

#Script to inherit a label from an input catalogue to a target catalogues 
#Get the target catalogues to match from the DATAHEAD 
input="@DB:ALLHEAD@"
ninp=`echo ${input} | awk '{print NF}'`
#Training catalogues are assumed to be in match_base
train="@DB:match_base@"
ntrain=`echo ${train} | awk '{print NF}'`
#Check for more mismatch in training and target catalogues  {{{
if [ ${ntrain} -ne 1 ] && [ ${ntrain} -ne ${ninp} ] && [ ${ninp} -ne 1 ]
then 
  _message "@RED@ ERROR!@DEF@\n"
  _message "@RED@ The provided training catalogue list is length @BLU@${ntrain}@RED@, and@DEF@\n"
  _message "@RED@ the provided target catalogue list is length @BLU@${ninp}@RED@. These @DEF@\n"
  _message "@RED@ should be of the same length, or one should be a single catalogue.@DEF@\n"
  exit 1
elif [ ${ntrain} -ne ${ninp} ]
then 
  if [ ${ninp} -ne 1 ] 
  then 
    outlist=''
    for i in `seq ${ninp}` 
    do 
      outlist="${outlist} ${train}"
    done
    train="${outlist}"
  elif [ ${ntrain} -ne 1 ]
  then 
    outlist=''
    for i in `seq ${ntrain}` 
    do 
      outlist="${outlist} ${input}"
    done
    input="${outlist}"
  fi 
fi 
#}}}
#Update the ntrain value 
ntrain=`echo ${train} | awk '{print NF}'`

#Construct the training-target feature list 
target_features="@BV:DATAFEATURES@"
nfeat_target=`echo ${target_features} | awk '{print NF}'`

#Loop through the catalogues, constructing the matches 
for i in `seq ${ntrain}`
do 
  #Get the current training catalogue 
  current_train=`echo ${train} | awk -v col=${i} '{print $col}'`
  #Get the current target catalogue 
  current_target=`echo ${input} | awk -v col=${i} '{print $col}'`
  #Construct the output filename 
  ext=${current_target##*.}
  output_file=${current_target//.${ext}/_lab.${ext}}

  #If the output file already exists, remove it (pyFITSIO overwrite causes crash)
  if [ -f ${output_file} ] 
  then 
    rm ${output_file}
  fi 
  
  #Notify that we are matching these catalogues 
  _message " > @BLU@Matching label @BV:LABELNAME@ from training catalogue @RED@${current_train##*/}@BLU@ to target catalogue @RED@${current_target##*/}@DEF@"
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/assign_matching_label.R \
     -t ${current_train} \
     -i ${current_target} \
     -o ${output_file} \
     -l @BV:LABELNAME@ \
     @BV:MATCHDUPLICATES@ \
     -f ${target_features} 2>&1
  #Notify 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"

  #Check if the patch label exists {{{
  cleared=1
  _message "   > @BLU@Testing pre-existence of @BV:LABELNAME@ column@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${current_target} -t OBJECTS -k @BV:LABELNAME@ 2>&1 || cleared=0
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  #If exists, delete it {{{
  if [ "${cleared}" == "1" ] 
  then 
    _message "   > @BLU@Removing pre-existing @BV:LABELNAME@ column@DEF@ "
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey -i ${current_target} -o ${current_target}_tmp -t OBJECTS -k @BV:LABELNAME@ 2>&1 
    mv ${current_target}_tmp ${current_target}
    _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #Merge the new column {{{
  _message "   -> @BLU@Merging new @BV:LABELNAME@ column @DEF@"
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${current_target} \
    -p ${output_file} \
    -o ${output_file}_tmp \
    -k @BV:LABELNAME@ \
    2>&1
  #Notify 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  #Delete the temporary output file 
  mv ${output_file}_tmp ${output_file}
  #}}}

  #Update the DATAHEAD 
  _replace_datahead "${current_target}" "${output_file}"

done 
  
