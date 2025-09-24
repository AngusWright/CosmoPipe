#=========================================
#
# File Name : compute_m_bias.sh
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Wed 20 Mar 2024 10:43:55 AM CET
#
#=========================================

#For each file in the calib and reference catalogue folders, compute the bias
calib_cats="@DB:som_weight_calib_gold@"
refr_cats="@DB:som_weight_refr_gold@"

for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do
  nfile=`echo ${calib_cats} | grep -c "_${patch}_" || echo `
  if [ ${nfile} -gt 0 ]
  then 
    #Construct the dz folders, if needed 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias_${patch}
    fi 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov_${patch}
    fi 
  fi 
done 

#Construct the tomographic bin catalogue strings {{{
binstrings=''
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
for i in `seq ${NTOMO}`
do
  #Define the Z_B limits from the TOMOLIMS {{{
  ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $n}'`
  ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$i '{print $(n+1)}'`
  #}}}
  #Define the string to append to the file names {{{
  ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
  ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
  appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
  #}}}
  binstrings="${binstrings} ${appendstr}"
done
#}}}

if [ "@BV:CALIBWEIGHTNAME@" != "" ] 
then 
  calibweight="-cw @BV:CALIBWEIGHTNAME@"
else 
  calibweight=''
fi 

#Run the Nz bias construction for each bin {{{
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/compute_dz_priors.R -c ${calib_cats} -r ${refr_cats} \
  --binstrings ${binstrings} \
  --patchstrings @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb \
  ${calibweight} \
  -w @BV:WEIGHTNAME@ \
  --syserr @BV:NZSYSERROR@ \
  -g "SOMweight" \
  -z @BV:ZSPECNAME@ \
  --biasoutbase @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzbias \
  --biasout Nz_biases.txt \
  --covoutbase @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nzcov \
  --covout Nz_covariance.txt 2>&1
#}}}

for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb
do 
  nfile=`echo ${calib_cats} | grep -c "_${patch}_" || echo `
  if [ ${nfile} -gt 0 ]
  then 
    #Add the Nzcov file(s) to the datablock 
    _write_datablock nzcov_${patch} "Nz_covariance.txt"
    #Add the Nzcov file(s) to the datablock 
    _write_datablock nzbias_${patch} "Nz_biases.txt"
  fi 
done 



