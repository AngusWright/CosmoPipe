#=========================================
#
# File Name : map_xicov_to_cosebi.sh
# Created By : awright
# Creation Date : 22-03-2024
# Last Modified : Sun 24 Mar 2024 09:33:24 PM CET
#
#=========================================

#Map a real space correlation function covariance (from, e.g., jackknife) to COSEBIs
input=@DB:DATAHEAD@
#Construct the output name 
ext=${input##*.}
output=${input%%.*}_cosebis.${ext}
output=${output##*/}

#Number of tomographic bins 
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

if [ ! -f @RUNROOT@/@CONFIGPATH@/cosebis/Tplus/Tp_@BV:THETAMINXI@_@BV:THETAMAXXI@_@BV:NMAXCOSEBIS@.table  ] 
then
  #Compute the Tpm files 
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/get_weights_cosebis.py \
    --ncores @BV:NTHREADS@ \
    --nmax @BV:NMAXCOSEBIS@ \
    --tmin @BV:THETAMINXI@ \
    --tmax @BV:THETAMAXXI@ \
    --ntheta @BV:NTHETABINXI@ \
    --outputdir @RUNROOT@/@CONFIGPATH@/cosebis/ \
    --computeWn False \
    --ReFactor False 2>&1 
fi 

#Run the mapping 
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/map_rscf_to_cosebi.py \
  --covariance ${input} \
  --ncores @BV:NTHREADS@ \
  --ntomo ${NTOMO} \
  --nmodes @BV:NMAXCOSEBIS@ \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --ntheta @BV:NTHETABINXI@ \
  --binning @BINNING@ \
  --output_cov_EB @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/ \
  --filename_cov ${output} \
  --tfoldername @RUNROOT@/@CONFIGPATH@/cosebis/ \
  --tplusfile Tplus/Tp \
  --tminusfile Tminus/Tm 2>&1 

#Update datahead 
_replace_datahead ${input} ${output}

