#=========================================
#
# File Name : combine_patch.sh
# Created By : awright
# Creation Date : 20-03-2023
# Last Modified : Wed 14 Jun 2023 01:55:47 PM CEST
#
#=========================================


#Get the combined catalogue name 
inputcats="@DB:ALLHEAD@"
patches=`echo @PATCHLIST@`

#Select one of the patches
basepatch=${patches##* }
#Get all the files with this patch 
sublist=`echo ${inputcats} | sed 's/ /\n/g' | grep "_${basepatch}_" || echo `
#Check for errors 
if [ "${sublist}" == "" ]
then 
  _message "@RED@ - ERROR!\n"
  _message "@RED@There are no input files with the patch ${basepatch}?!@DEF@\n"
  exit 1 
fi 
#Add a patch label to each catalogue (for subsequent patch extraction, if needed)
for cata in ${inputcats}
do 
  for patch in ${patches}
  do 
    match=`echo ${cata##*/} | grep -c "_${patch}_" || echo`
    if [ "${match}" != "0" ] 
    then 
      break
    fi 
  done
  #Check if input file lengths are ok {{{
  links="FALSE"
  for file in ${cata}
  do 
    if [ ${#file} -gt 255 ] 
    then 
      links="TRUE"
    fi 
  done 
  #}}}
  #If needed, make the links {{{
  if [ "${links}" == "TRUE" ] 
  then 
    #Remove existing infile links 
    if [ -e infile.lnk ] || [ -h infile.lnk ]
    then 
      rm infile.lnk
    fi 
    #Create input link
    originp=${cata}
    ln -s ${cata} infile.lnk
    cata="infile.lnk"
  fi 
  #Check if the patch label exists
  cleared=1
  _message "   > @BLU@Testing existence of Patch ID column in @DEF@${cata##*/}@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${cata} -t OBJECTS -k PATCH 2>&1 || cleared=0
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  #If exists, delete it 
  if [ "${cleared}" == "1" ] 
  then 
    _message "   > @BLU@Removing existing patch ID key from @DEF@${cata##*/}@DEF@ "
    @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey -i ${cata} -o ${cata}_tmp -t OBJECTS -k PATCH 2>&1 
    mv ${cata}_tmp ${cata}
    _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #add the patch label column 
  _message "   > @BLU@Adding patch @DEF@${patch}@BLU@ identification key to @DEF@${cata##*/}@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacaddkey -i ${cata} -o ${cata}_tmp -t OBJECTS -k PATCH ${patch} string "patch identifier" 2>&1
  #move the new catalogue to the original name 
  mv ${cata}_tmp ${cata}
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
done 


#Loop through files 
for basefile in ${sublist}
do 
  #Define the output name 
  outname=`echo ${basefile} | sed "s/_${basepatch}_/_@ALLPATCH@_/g" `

  #Get the list of contributing catalogues 
  inplist=''
  for patch in ${patches} 
  do 
    curfile=`echo ${basefile} | sed "s/_${basepatch}_/_${patch}_/g"` 
    inplist="${inplist} ${curfile}" 
  done 

  #Check if input file lengths are ok 
  links="FALSE"
  for file in ${inplist} ${outname}
  do 
    if [ ${#file} -gt 255 ] 
    then 
      links="TRUE"
    fi 
  done 
  
  if [ "${links}" == "TRUE" ] 
  then 
    count=1
    origlist=${inplist}
    inplist=''
    for file in ${origlist} 
    do 
    #Remove existing infile links 
    if [ -h infile${count}.lnk ]
    then 
      rm infile${count}.lnk
    fi
      ln -s ${file} infile${count}.lnk 
      inplist="${inplist} infile${count}.lnk"
      count=$((count+1))
    done 
      #Remove existing outfile links 
    if [ -e outfile.lnk ] || [ -h outfile.lnk ]
    then 
      rm outfile.lnk
    fi
    #Create output links 
    ln -s ${outname} outfile.lnk
    origoname=${outname}
    outname=outfile.lnk
  fi 

  #Combine the catalogues into one 
  _message "   > @BLU@Constructing patch-combined catalogue @DEF@${outname}@DEF@ "
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacpaste \
    -i ${inplist} \
    -o ${outname} 2>&1 
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

  if [ "${links}" == "TRUE" ] 
  then 
    rm ${inplist} ${outname}
    inplist=${origlist}
    outname=${origoname}
  fi 

  #Add the new file to the datablock 
  #Update datahead 
  for _file in ${inplist}
  do 
    #Replace the first file with the output name, then clear the rest
    _replace_datahead ${_file##*/} "${outname}"
    outname=""
  done 
done 


