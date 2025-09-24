#=========================================
#
# File Name : extract_patch_lens.sh
# Created By : dvornik
# Creation Date : 19-08-2024
# Last Modified : Mon 19 Aug 2024 02:44:52 PM CEST
#
#=========================================


#Input Filename & Extension {{{
inputfile=@DB:DATAHEAD@
decname=@BV:DECNAME@
extn=${inputfile##*.}
#}}}


  inputlist=@DB:DATAHEAD@
  lens_filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist}
  do
    if [[ "$file" =~ .*"_NS_".* ]]
    then
      #Save the output file to the list {{{
      lens_filelist="${lens_filelist} ${file}"
    fi
    #}}}
  done



#Notify
_message "@BLU@Constructing Patch-wise catalogue from:@DEF@ ${lens_filelist##*/}\n"

outputlist=''
for file in ${lens_filelist}
do
  for patch in @BV:PATCHLIST@
  do
    #Define the output file name {{{
    outputname=${file//_@ALLPATCH@_/_${patch}_}
    #Add the output name to the output list {{{
    outputlist="${outputlist} ${outputname##*/}"
    #Check if the outputname file exists {{{
    if [ -f ${outputname} ]
    then
      #If it exists, remove it
      _message "  > @BLU@Removing previous catalogue for patch ${patch}@DEF@ "
      rm -f ${outputname}
      _message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
    fi
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/extract_patch_lens.py \
             --file ${file} \
			 --output_file ${file//_@ALLPATCH@_/_${patch}_} \
		     --dec_name ${decname} \
		     --patch ${patch} \
			 --c -15.0 2>&1
  done
done
  
_message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"

#Update the datahead
_replace_datahead ${inputfile} "${outputlist}"

