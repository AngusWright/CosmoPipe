#=========================================
#
# File Name : spatial_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Wed Jul  8 13:21:04 2026
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
outbase=${output//.${outext}/}
#Construct the list of output names 
outlist=''
outlist_trunc=''
outbins=${outbase}_bins.${outext}

#Split catalogues in the DATAHEAD into NSPLIT regions 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/spatial_split.R \
  -i @DB:DATAHEAD@ \
  -n @BV:NSPLIT@ \
  -k @BV:NSPLITKEEP@ \
  -a @BV:SPLITASP@ \
  -v @BV:RANAME@ @BV:DECNAME@ \
  --sphere --binsonly \
  -o ${outbins} 2>&1

_message "   -> @BLU@Merging spatial bin indices @DEF@"
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i ${input} \
  -p ${outbins} \
  -o ${input}_tmp \
  -k spatial_bins -t OBJECTS 2>&1
_message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
for i in `seq @BV:NSPLITKEEP@`
do 
  #Select sources in this bin {{{
  _message "@BLU@ Selection spatial split ${i}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
           -i ${input}_tmp \
  	       -o ${outbase}_${i}.${outext} \
  	       -t OBJECTS \
  	       -c "(spatial_bins==${i});" 2>&1 
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  outlist="${outlist} ${outbase}_${i}.${outext}"
  outlist_trunc="${outlist_trunc} ${outbase##*/}_${i}.${outext}"
  #}}}
done 

#Update the datahead 
_replace_datahead "${input}" "${outlist_trunc}"

