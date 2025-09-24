#=========================================
#
# File Name : combine_gt_patches.sh
# Created By : dvornik
# Creation Date : 17-07-2024
# Last Modified : Wed Jul 17 11:31:17 2024
#
#=========================================

### Combine the patch corrrelation functions ### {{{
_message "Combining Galaxy-galaxy Lensing Correlation Functions by patch\n"
headfiles="@DB:ALLHEAD@"

NBIN="@BV:NLENSBINS@"
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
#Loop over tomographic bins in this patch 
for LBIN in `seq ${NBIN}`
do
  #Define the string to append to the file names {{{
  appendstr="_LB${LBIN}"
  #}}}
  
  for ZBIN2 in `seq ${NTOMO}`
  do
    ZB_lo2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $n}'`
    ZB_hi2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $(n+1)}'`
    ZB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
    ZB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
    appendstr2="_ZB${ZB_lo_str2}t${ZB_hi_str2}"

    #Define the input file id 
    filestr="${appendstr}${appendstr2}_gtcorr.txt"

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
    _message "    -> @BLU@Bin $LBIN x Bin $ZBIN2 ($ZB_lo2 < Z_B <= $ZB_hi2)@DEF@"
    logfile=${outname##*/}
    @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/combine_gt_patches.R \
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
  done
done
_message "  }\n"
