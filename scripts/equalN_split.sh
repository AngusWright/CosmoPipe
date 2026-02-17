#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Tue Feb 17 15:28:08 2026
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

##Split catalogues in the DATAHEAD into NSPLIT regions 
#@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/equalN_split.R \
#  -i @DB:DATAHEAD@ \
#  -n @BV:NSPLIT@ \
#  -v @BV:SPLITVAR@ \
#  -o ${outlist} 2>&1

#Split catalogues in the DATAHEAD into NSPLIT regions
splitfile=${output//.${outext}/_splits.${outext}}
#Step 1, define the splits 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/equalN_split.R \
  -i @DB:DATAHEAD@ \
  -n @BV:NSPLIT@ \
  -v @BV:SPLITVAR@ \
  --id_only -o ${splitfile} 2>&1 

#Merge the split variable column with ldac 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i @DB:DATAHEAD@ \
  -p ${splitfile} \
  -o @DB:DATAHEAD@_tmp \
  -k BIN_ID BIN_NUM -t OBJECTS 2>&1

#cut on the split variable column 
for i in `seq @BV:NSPLIT@ `
do 
  outname=${outbase}_${i}.${outext}
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
    -i @DB:DATAHEAD@_tmp \
    -o ${outname} \
    -c "(BIN_NUM=${i});" -t OBJECTS 2>&1
  outlist="${outlist} ${outname}"
  outlist_trunc="${outlist_trunc} ${outbase##*/}_${i}.${outext}"
done 

#Update the datahead 
_replace_datahead "${input}" "${outlist_trunc}"

