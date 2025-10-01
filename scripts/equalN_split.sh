#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Wed Jan 10 05:12:21 2024
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
for i in `seq @BV:NSPLIT@`
do 
  outlist="${outlist} ${outbase}_${i}.${outext}"
  outlist_trunc="${outlist_trunc} ${outbase##*/}_${i}.${outext}"
done 

#Split catalogues in the DATAHEAD into NSPLIT regions 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/equalN_split.R \
  -i @DB:DATAHEAD@ \
  -n @BV:NSPLIT@ \
  -v @BV:SPLITVAR@ \
  -o ${outlist} 2>&1

#Update the datahead 
_replace_datahead "${input}" "${outlist_trunc}"

