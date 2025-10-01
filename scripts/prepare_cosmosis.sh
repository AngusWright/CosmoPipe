#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Sat Sep  6 11:22:55 2025
#
#=========================================

if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 

#For each of the files in the nz directory 
headfiles="@DB:ALLHEAD@"

#Number of tomographic bins 
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

#Define the patches to loop over {{{
if [ "@BV:COSMOSIS_PATCHLIST@" == "ALL" ]
then 
  patchlist=`echo @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb` 
else 
  patchlist="@BV:COSMOSIS_PATCHLIST@"
fi 
#}}}

#N_effective & sigmae {{{
for stat in neff sigmae
do 
  found="FALSE"
  foundlist=""
  _message " >@BLU@ Compiling ${stat} files {@DEF@\n"
  for patch in ${patchlist}
  do 
    _message " ->@BLU@ Patch @RED@${patch}@DEF@"
    #Get all the files in this stat and patch {{{
    patchinputs=`_read_datablock "${stat}_${patch}${blinding}"`
    patchinputs=`_blockentry_to_filelist ${patchinputs}`
    #}}}
    #If there are no files in this patch, skip {{{
    if [ "${patchinputs}" == "" ] 
    then 
      _message "@RED@ - skipping! (No matching ${stat} files)@DEF@\n"
      continue
    fi 
    #}}}
    found="TRUE"
    foundlist="${foundlist} ${patch}"
    #Create the ${stat} directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}${blinding} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}${blinding}/
    fi 
    #}}}
    #Create the output statistic file name {{{
    stat_list=""
    for file in ${patchinputs} 
    do 
      stat_list="${stat_list} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${stat}_${patch}${blinding}/${file}"
    done
    stat_file=`echo ${patchinputs} | awk '{print $1}'`
    #}}}
    #Define the output stat file {{{
    stat_file=${stat_file##*/}
    stat_file=${stat_file%_ZB*}_${stat}.txt 
    #}}}
    #Remove preexisting files {{{
    if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}${blinding}/${stat_file} ]
    then 
      _message " > @BLU@Removing previous cosmosis ${stat} file@DEF@"
      rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}${blinding}/${stat_file}
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    fi 
    #}}}
    #Construct the output file, maintaining order {{{
    paste ${stat_list} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}${blinding}/${stat_file}
    #}}}
    #Add the stat file to the datablock {{{
    _write_datablock "cosmosis_${stat}_${patch}${blinding}" "${stat_file}"
    #}}}
    _message "@RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"
  done 
  #Error if no stat files found {{{ 
  if [ "${found}" == "FALSE" ] 
  then 
    if [ "@BV:COSMOSIS_PATCHLIST@" == "ALL" ]
    then 
      #If not found, error 
      _message " - @RED@ERROR!@DEF@\n"
      _message "@RED@There are no ${stat} files in any patch?!@DEF@\n"
      _message "@BLU@You probably didn't run the neff_sigmae processing function?!@DEF@\n"
      exit 1
    else 
      #If not found, error 
      _message " - @RED@ERROR!@DEF@\n"
      _message "@RED@There are no ${stat} files in found in the requested BV:COSMOSIS_PATCHLIST @BLU@${patchlist}@DEF@\n"
      _message "@BLU@Either this list was incorrectly set, or you didn't run the neff_sigmae processing function for your patch?@DEF@\n"
      exit 1
    fi 
  fi 
  #}}}
done 
#}}}

#Xipm {{{
if [ "${headfiles}" != "" ]
then 
  _message "Copying XIpm catalogues from datahead into cosmosis_xipm {\n"
  #Loop over patches {{{
  outall=''
  for patch in ${patchlist}
  do 
    outlist=''
    #Loop over tomographic bins in this patch {{{
    for ZBIN1 in `seq ${NTOMO}`
    do
      #Define the Z_B limits from the TOMOLIMS {{{
      ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $n}'`
      ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $(n+1)}'`
      #}}}
      #Define the string to append to the file names {{{
      ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
      ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
      appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
      #}}}
      #Loop over the second ZB bins {{{
      for ZBIN2 in `seq $ZBIN1 ${NTOMO}`
      do
        #Define the Z_B limits from the TOMOLIMS {{{
        ZB_lo2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $n}'`
        ZB_hi2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $(n+1)}'`
        #}}}
        #Define the string to append to the file names {{{
        ZB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
        ZB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
        appendstr2="_ZB${ZB_lo_str2}t${ZB_hi_str2}"
        #}}}
        #Define the input file id {{{
        filestr="${appendstr}${appendstr2}_"
        #}}}
        #Get the file {{{
        file=`echo ${headfiles} | sed 's/ /\n/g' | grep -i "[\^_]${patch}_" | grep ${filestr} || echo `
        #}}}
        #Check if the output file exists {{{
        if [ "${file}" == "" ] 
        then 
          continue
        fi 
        #}}}
        #Create the xipm directory {{{
        if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm_${patch}${blinding} ]
        then 
          mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm_${patch}${blinding}/
        fi 
        #}}}
        #Copy the file {{{
        _message " > @BLU@ Patch @DEF@${patch}@BLU@ ZBIN @DEF@${ZBIN1}@BLU@x@DEF@${ZBIN2}"
        cp ${file} \
          @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_xipm_${patch}${blinding}/XI_@SURVEY@_${patch}_nBins_${NTOMO}_Bin${ZBIN1}_Bin${ZBIN2}.ascii
        _message " - @RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
        #}}}
        #Save the file to the output list {{{
        outlist="${outlist} XI_@SURVEY@_${patch}_nBins_${NTOMO}_Bin${ZBIN1}_Bin${ZBIN2}.ascii"
        #}}}
      done 
      #}}}
    done
    #Update the datablock {{{
    _write_datablock "cosmosis_xipm_${patch}${blinding}" "${outlist}"
    outall="${outall} ${outlist}"
    #}}}
    #}}}
  done
  #}}}
  #Were there any files in any of the patches? {{{
  if [ "${outall}" == "" ] 
  then 
    #If not, error 
    _message " - @RED@ERROR!@DEF@\n"
    _message "@RED@There were no catalogues added to the cosmosis xipm folder?!@DEF@"
    _message "@BLU@You probably didn't load the xipm files into the datahead?!@DEF@"
    exit 1
  fi 
  #}}}
  _message "}\n"
fi 
#}}}

if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis_cov/
fi 

