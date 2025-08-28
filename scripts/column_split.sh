#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Mon Aug 25 11:59:51 2025
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
#Get the number of splits 
NSPLIT=`@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/column_split.R \
  -i @DB:DATAHEAD@ \
  -v @BV:SPLITVAR@ --n_only`

#Split catalogues in the DATAHEAD into NSPLIT regions
splitfile=${output//.${outext}/_splits.${outext}}
#Step 1, define the splits 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/column_split.R \
  -i @DB:DATAHEAD@ \
  -v @BV:SPLITVAR@ \
  --id_only -o ${splitfile} 2>&1 


#Merge the split variable column with ldac 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i @DB:DATAHEAD@ \
  -p ${splitfile} \
  -o @DB:DATAHEAD@_tmp \
  -k splitvar -t OBJECTS 2>&1

#cut on the split variable column 
for i in `seq $NSPLIT`
do 
  outname=${outbase}_${i}.${outext}
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacfilter \
    -i @DB:DATAHEAD@_tmp \
    -o ${outname} \
    -c "(splitvar=${i});" -t OBJECTS 2>&1
  outlist="${outlist} ${outname}"
  outlist_trunc="${outlist_trunc} ${outbase##*/}_${i}.${outext}"
done 

#Update the datahead 
_replace_datahead "${input}" "${outlist_trunc}"

