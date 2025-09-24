#=========================================
#
# File Name : combine_wt_patches.sh
# Created By : dvornik
# Creation Date : 17-07-2024
# Last Modified : Wed Jul 17 11:31:17 2024
#
#=========================================

### Combine the patch corrrelation functions ### {{{
_message "Combining Galaxy Clustering Correlation Functions by patch\n"
headfiles="@DB:ALLHEAD@"

NBIN="@BV:NLENSBINS@"
#Loop over tomographic/any other lens bins in this patch
#For clustering we only do autocorrelations at this stage!
for LBIN1 in `seq ${NBIN}`
do
  #Define the string to append to the file names {{{
  appendstr="_LB${LBIN1}"
  #}}}
  
  #for LBIN2 in `seq $LBIN1 ${NBIN}`
  #do
  #  appendstr2="_LB${LBIN1}"

    #Define the input file id 
    #filestr="${appendstr}${appendstr2}_wtcorr.txt"
    filestr="${appendstr}_wtcorr.txt"

    #Get the file list {{{
    filelist=''
    for patch in @BV:PATCHLIST@ 
    do 
      file=`echo ${headfiles} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${filestr} || echo `
      #Check if the output file exists 
      if [ "${file}" == "" ] 
      then 
        _message "@RED@ - ERROR!\n"
        _message "A file with the ID string @DEF@${filestr}@RED@ in patch @DEF@${patch}@RED@ does not exist in the data head\n"
        exit 1 
      fi 
      #Add the file to the file list 
      filelist="${filelist} ${file}"

      #Define the output name 
      outname=${file//_${patch}_/_@ALLPATCH@comb_}
    done 
    #}}}

    #Combine the patches for this bin 
    _message "    -> @BLU@Bin $LBIN1 x Bin $LBIN1 @DEF@"
    logfile=${outname##*/}
    @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/combine_wt_patches.R \
      -o ${outname} \
      -i ${filelist} \
      > @RUNROOT@/@LOGPATH@/${logfile//.txt/.log} 2>&1 
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    #Add the new file to the datahead 
    count=0
    for file in ${filelist} 
    do 
      if [ $count -gt 0 ]
      then 
        #Don't replace with anything 
        _replace_datahead "${file}" ""
      else 
        #Replace with new file 
        _replace_datahead "${file}" "${outname}"
        count=1
      fi 
    done 
  #done
done
_message "  }\n"
