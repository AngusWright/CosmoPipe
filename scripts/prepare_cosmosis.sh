#=========================================
#
# File Name : prepare_cosmosis.sh
# Created By : awright
# Creation Date : 31-03-2023
# Last Modified : Sat Feb 24 08:55:24 2024
#
#=========================================

#For each of the files in the nz directory

MODES="@BV:MODES@"
if [[ .*\ $MODES\ .* =~ " EE " ]]
then
  headfiles_xi="@DB:xipm_comb@"
fi
if [[ .*\ $MODES\ .* =~ " NE " ]]
then
  headfiles_gt="@DB:gt_comb@"
fi
if [[ .*\ $MODES\ .* =~ " NN " ]]
then
  headfiles_wt="@DB:wt_comb@"
fi

#Number of tomographic bins
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENS="@BV:NLENSBINS@"

#Define the patches to loop over {{{
if [ "@BV:COSMOSIS_PATCHLIST@" == "ALL" ]
then 
  patchlist=`echo @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb`
else
  patchlist="@BV:COSMOSIS_PATCHLIST@"
fi 
#}}}

#N_effective & sigmae {{{
for stat in neff_source neff_lens neff_obs sigmae
do
  found="FALSE"
  foundlist=""
  _message " >@BLU@ Compiling ${stat} files {@DEF@\n"
  for patch in ${patchlist}
  do 
    _message " ->@BLU@ Patch @RED@${patch}@DEF@"
    #Get all the files in this stat and patch {{{
    patchinputs=`_read_datablock "${stat}_${patch}_@BV:BLIND@"`
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
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}_@BV:BLIND@ ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}_@BV:BLIND@/
    fi 
    #}}}
    #Create the output statistic file name {{{
    stat_list=""
    for file in ${patchinputs} 
    do 
      stat_list="${stat_list} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/${stat}_${patch}_@BV:BLIND@/${file}"
    done
    stat_file=`echo ${patchinputs} | awk '{print $1}'`
    #}}}
    #Define the output stat file {{{
    stat_file=${stat_file##*/}
    if [ ${stat} == "neff_lens" ] || [ ${stat} == "neff_obs" ]
    then
        stat_file=${stat_file%_LB*}_${stat}.txt
    else
        stat_file=${stat_file%_ZB*}_${stat}.txt
    fi
    #}}}
    #Remove preexisting files {{{
    if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}_@BV:BLIND@/${stat_file} ]
    then 
      _message " > @BLU@Removing previous cosmosis ${stat} file@DEF@"
      rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}_@BV:BLIND@/${stat_file}
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    fi 
    #}}}
    #Construct the output file, maintaining order {{{
    paste ${stat_list} > @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_${stat}_${patch}_@BV:BLIND@/${stat_file}
    #}}}
    #Add the stat file to the datablock {{{
    _write_datablock "cosmosis_${stat}_${patch}_@BV:BLIND@" "${stat_file}"
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

#npair {{{
if [ "${headfiles_xi}" != "" ] || [ "${headfiles_gt}" != "" ] || [ "${headfiles_wt}" != "" ]
then
  _message "Copying 2pcf catalogues from datahead into cosmosis_npair {\n"
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
        filestr="${appendstr}${appendstr2}_ggcorr.txt"
        #}}}
        #Get the file {{{
        file=`echo ${headfiles_xi} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${filestr} || echo `
        #}}}
        #Check if the output file exists {{{
        if [ "${file}" == "" ]
        then
          continue
        fi
        #}}}
        #Create the xipm directory {{{
        if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@ ]
        then
          mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/
        fi
        #}}}
        #Copy the file {{{
        _message " > @BLU@ Patch @DEF@${patch}@BLU@ ZBIN @DEF@${ZBIN1}@BLU@x@DEF@${ZBIN2}"
        cp ${file} \
          @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/XI_@SURVEY@_${patch}_nBins_${NTOMO}_Bin${ZBIN1}_Bin${ZBIN2}.ascii
        gawk -i inplace '{print $1, $2, $3, $NF}' @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/XI_@SURVEY@_${patch}_nBins_${NTOMO}_Bin${ZBIN1}_Bin${ZBIN2}.ascii
        _message " - @RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
        #}}}
        #Save the file to the output list {{{
        outlist="${outlist} XI_@SURVEY@_${patch}_nBins_${NTOMO}_Bin${ZBIN1}_Bin${ZBIN2}.ascii"
        #}}}
      done
      #}}}
    done
    #Update the datablock {{{
    #_write_datablock "cosmosis_npair_${patch}_@BV:BLIND@" "${outlist}"
    outall="${outall} ${outlist}"
    #}}}
    #}}}
    
    
    outlist_gt=''
    #Loop over tomographic bins in this patch {{{
    for LBIN1 in `seq ${NLENS}`
    do
      #Define the Z_B limits from the TOMOLIMS {{{
      appendstr="_LB${LBIN1}"
      #}}}
      #Loop over the second ZB bins {{{
      for ZBIN2 in `seq ${NTOMO}`
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
        filestr="${appendstr}${appendstr2}_gtcorr.txt"
        #}}}
        #Get the file {{{
        file=`echo ${headfiles_gt} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${filestr} || echo `
        #}}}
        #Check if the output file exists {{{
        if [ "${file}" == "" ]
        then
          continue
        fi
        #}}}
        #Create the xipm directory {{{
        if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@ ]
        then
          mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/
        fi
        #}}}
        #Copy the file {{{
        _message " > @BLU@ Patch @DEF@${patch}@BLU@ BIN @DEF@${LBIN1}@BLU@x@DEF@${ZBIN2}"
        cp ${file} \
          @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/GT_@SURVEY@_${patch}_nBins_${NLENS}_Bin${LBIN1}_Bin${ZBIN2}.ascii
        gawk -i inplace '{print $1, $2, $3, $NF}' @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/GT_@SURVEY@_${patch}_nBins_${NLENS}_Bin${LBIN1}_Bin${ZBIN2}.ascii
        _message " - @RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
        #}}}
        #Save the file to the output list {{{
        outlist_gt="${outlist_gt} GT_@SURVEY@_${patch}_nBins_${NLENS}_Bin${ZBIN1}_Bin${ZBIN2}.ascii"
        #}}}
      done
      #}}}
    done
    #Update the datablock {{{
    #_write_datablock "cosmosis_npair_${patch}_@BV:BLIND@" "${outlist_gt}"
    outall="${outall} ${outlist_gt}"
    #}}}
    #}}}
    
    outlist_wt=''
    #Loop over tomographic bins in this patch {{{
    for LBIN1 in `seq ${NLENS}`
    do
      #Define the Z_B limits from the TOMOLIMS {{{
      appendstr="_LB${LBIN1}"
      #}}}
      #Loop over the second ZB bins {{{
      #for LBIN2 in `seq $LBIN1 ${NLENS}`
      #do
      #  appendstr2="_LB${LBIN2}"
        #}}}
        #Define the input file id {{{
        #filestr="${appendstr}${appendstr2}_wtcorr.txt"
        filestr="${appendstr}_wtcorr.txt"
        #}}}
        #Get the file {{{
        file=`echo ${headfiles_wt} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${filestr} || echo `
        #}}}
        #Check if the output file exists {{{
        if [ "${file}" == "" ]
        then
          continue
        fi
        #}}}
        #Create the xipm directory {{{
        if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@ ]
        then
          mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/
        fi
        #}}}
        #Copy the file {{{
        _message " > @BLU@ Patch @DEF@${patch}@BLU@ BIN @DEF@${LBIN1}@BLU@@DEF@"
        cp ${file} \
          @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/WT_@SURVEY@_${patch}_nBins_${NLENS}_Bin${LBIN1}_Bin${LBIN1}.ascii
        gawk -i inplace '{print $1, $2, $3, $NF}' @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_npair_${patch}_@BV:BLIND@/WT_@SURVEY@_${patch}_nBins_${NLENS}_Bin${LBIN1}_Bin${LBIN1}.ascii
        _message " - @RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
        #}}}
        #Save the file to the output list {{{
        outlist_wt="${outlist_wt} WT_@SURVEY@_${patch}_nBins_${NLENS}_Bin${LBIN1}_Bin${LBIN1}.ascii"
        #}}}
      #done
      #}}}
    done
    #Update the datablock {{{
    #_write_datablock "cosmosis_npair_${patch}_@BV:BLIND@" "${outlist_wt}"
    outall="${outall} ${outlist_wt}"
    _write_datablock "cosmosis_npair_${patch}_@BV:BLIND@" "${outall}"
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
