#=========================================
#
# File Name : apply_noise_realisations.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Thu Jul 17 20:06:31 2025
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
outbase=${output//.${outext}/}
outlist=''
outlist_trunc=''

#Split catalogues in the DATAHEAD into NSPLIT regions 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/apply_noise_realisations.R \
  -i @DB:DATAHEAD@ \
  --infilt @BV:REALISATION_FILT@ \
  --stdev @BV:REALISATION_STDEV@ \
  --outfilt @BV:WIDEFILT@ \
  --nrealisation @BV:NREALISATION@ \
  --outbase ${outbase} \
  --outext ${outext} 2>&1

objstr=''
for filt in @BV:WIDEFILT@ 
do 
  {
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldactestexist -i ${input} -t OBJECTS -k ${filt} 2>&1 && objstr=${objstr} || objstr="FAIL"
  } >&1
  if [ "${objstr}" == "FAIL" ] 
  then 
    break 
  fi 
done 

if [ "${objstr}" != "FAIL" ] 
then 
  _message "  > @BLU@Removing previous flux columns@DEF@"
  #Remove the original columns 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacdelkey \
    -i ${input} \
    -o ${input}_tmp \
    -k @BV:WIDEFILT@ -t OBJECTS 2>&1
  _message "@RED@ - Done@DEF@\n"
else 
  cp ${input} ${input}_tmp
fi 

for realid in `seq @BV:NREALISATION@` 
do 
  #Output file name 
  output=${outbase}_r${realid}.${outext}
  _message "  > @BLU@Merging flux realisation ${realid} columns@DEF@"
  #Merge new flux columns 
  @RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
    -i ${input}_tmp \
    -p ${output} \
    -o ${output}_tmp \
    -k @BV:WIDEFILT@ -t OBJECTS 2>&1
  _message "@RED@ - Done@DEF@\n"
  
  mv ${output}_tmp ${output}

  outlist="${outlist} ${output}"
  outlist_trunc="${outlist_trunc} ${output##*/}"

done 

#Update the datahead 
_replace_datahead "${input}" "${outlist_trunc}"

