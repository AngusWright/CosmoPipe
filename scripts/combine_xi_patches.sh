#=========================================
#
# File Name : combine_xi_patches.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Wed Jan 10 05:11:12 2024
#
#=========================================

### Combine the patch corrrelation functions ### {{{
_message "Combining Cosmic Shear Correlation Functions by patch\n"
headfiles="@DB:ALLHEAD@"

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
#Loop over tomographic bins in this patch 
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
  
  for ZBIN2 in `seq $ZBIN1 ${NTOMO}`
  do
    ZB_lo2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $n}'`
    ZB_hi2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $(n+1)}'`
    ZB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
    ZB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
    appendstr2="_ZB${ZB_lo_str2}t${ZB_hi_str2}"

    #Define the input file id 
    filestr="${appendstr}${appendstr2}_ggcorr.txt"

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
    _message "    -> @BLU@Bin $ZBIN1 ($ZB_lo < Z_B <= $ZB_hi) x Bin $ZBIN2 ($ZB_lo2 < Z_B <= $ZB_hi2)@DEF@"
    logfile=${outname##*/}
    @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/combine_xi_patches.R \
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
