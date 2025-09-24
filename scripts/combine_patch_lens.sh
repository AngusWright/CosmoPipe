#=========================================
#
# File Name : combine_patch_lens.sh
# Created By : dvornik
# Creation Date : 19-08-2024
# Last Modified : Mon 19 Aug 2024 02:44:41 PM CEST
#
#=========================================


#Get the combined catalogue name 
inputcats="@DB:ALLHEAD@"
patches=`echo @BV:PATCHLIST@`

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

  #Combine the catalogues into one 
  _message "   > @BLU@Constructing patch-combined catalogue @DEF@${outname##*/}@DEF@ "
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/combine_cats_lens.py \
             --files ${inplist} \
			 --output_file ${outname} 2>&1
  _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

  #Add the new file to the datablock 
  #Update datahead 
  for _file in ${inplist}
  do 
    #Replace the first file with the output name, then clear the rest
    _replace_datahead ${_file} "${outname}"
    outname=""
  done 
done 


