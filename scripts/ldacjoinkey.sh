#=========================================
#
# File Name : ldackeepcols.sh
# Created By : awright
# Creation Date : 12-06-2023
# Last Modified : Mon Jul 21 07:15:35 2025
#
#=========================================

#Input catalogue
input=@DB:DATAHEAD@

#Define the output catalogue name 
ext=${input##*.}
output=${input//.${ext}/_calc.${ext}}
matchbase="@DB:match_base@"

#Notify 
_message "@DEF@ > @BLU@Adding @BV:LABELNAME@ column from catalogue ${matchbase##*/} to catalogue ${input##*/}@DEF@"

#Check if input file lengths are ok {{{
links="FALSE"
for file in ${input} ${output} ${matchbase}
do 
  if [ ${#file} -gt 255 ] 
  then 
    links="TRUE"
  fi 
done 

if [ "${links}" == "TRUE" ] 
then
  #Remove existing infile links 
  if [ -e infile_$$.lnk ] || [ -h infile_$$.lnk ]
  then 
    rm infile_$$.lnk
  fi 
  #Remove existing matchbase links
  if [ -e matfile_$$.lnk ] || [ -h matfile_$$.lnk ]
  then 
    rm matfile_$$.lnk
  fi 
  #Remove existing outfile links 
  if [ -e outfile_$$.lnk ] || [ -h outfile_$$.lnk ]
  then 
    rm outfile_$$.lnk
  fi
  #Create input link
  originp=${input}
  ln -s ${input} infile_$$.lnk 
  input="infile_$$.lnk"
  #Create matchbase link
  origmat=${matchbase}
  ln -s ${matchbase} matfile_$$.lnk 
  matchbase="matfile_$$.lnk"
  #Create output links 
  ln -s ${output} outfile_$$.lnk
  origout=${output}
  output=outfile_$$.lnk
fi 
#}}}


#Get the list of all columns 
cols=`@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdesc -i ${input} -t OBJECTS 2>&1 | grep "Key name" | sed 's@Key name:\(\.\)\{1,\}@@' || echo `

if [ "${cols}" == "" ] 
then 
  _message "@RED@ - ERROR! Column read using ldacdesc failed! Is this an LDAC catalogue?@DEF@\n"
  _message "${input}\n"
  exit 1 
fi 

#Check if @BV:LABELNAME@ is one of the columns 
labelname=@BV:LABELNAME@
colcheck=`echo ${cols} | sed 's/ /\n/g' | grep -ci "${labelname}" || echo `

if [ ${colcheck} -ne 0 ]
then 
  _message "@RED@ - ERROR! Column name to add already exists!@DEF@\n"
  _message "@BLU@columns:@DEF@\n"
  _message "${cols}\n"
  _message "@BLU@ldacjoinkey colname:@DEF@"
  _message "${labelname}\n"
  exit 1
else 
  #Calculate the new column 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${input} \
    -p ${matchbase} \
    -o ${output} \
    -t OBJECTS \
    -k ${labelname} \
    2>&1

  _message "@BLU@ - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  if [ "${links}" == "TRUE" ] 
  then 
    rm ${input} ${output} ${matchbase}
    input=${originp}
    output=${origout}
    matchbase=${origmat}
  fi 
  
  #Update the datahead
  _replace_datahead "${input}" "${output}"
fi 

