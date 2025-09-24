#
#
# Script to construct xi_E/B from COSEBIs
#
#

#Datavector output folder
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xiE_vec/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xiB_vec/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi
#Covariance output folder
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiE/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiB/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 
BOLTZMAN="@BV:BOLTZMAN@"
if [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020" ] || [ "${BOLTZMAN^^}" == "HALO_MODEL" ]  || [ "${BOLTZMAN^^}" == "COSMOPOWER_HALO_MODEL" ]
then
  non_linear_model=mead2020_feedback
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015" ] || [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2015_S8" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2015" ]
then
  non_linear_model=mead2015
elif [ "${BOLTZMAN^^}" == "COSMOPOWER_HM2020_NOFEEDBACK" ] || [ "${BOLTZMAN^^}" == "CAMB_HM2020_NOFEEDBACK" ]
then
  non_linear_model=mead2020
else
  _message "Boltzmann code not implemented: ${BOLTZMAN^^}\n"
    exit 1
fi
SRCLOC=@RUNROOT@/@CONFIGPATH@/cosebis
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
_message "    -> @BLU@Computing xi_E/B from COSEBIs@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/mapping_cosebis_to_pureEBmode_cf.py \
  --data @DB:cosebis_dimless_vec@ \
  --covariance @DB:covariance_cosebis_dimless@ \
  --ncores @BV:NTHREADS@ \
  --thetamin @BV:THETAMINXI@ \
  --thetamax @BV:THETAMAXXI@ \
  --ntheta @BV:NXIPM@ \
  --binning @BINNING@ \
  --ntomo ${NTOMO} \
  --output_data_E @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xiE_vec \
  --output_data_B @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xiB_vec \
  --output_cov_E @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiE \
  --output_cov_B @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/covariance_xiB \
  --filename_data combined_vector.txt \
  --tfoldername ${SRCLOC}/Tplus_minus_dimless \
  --filename_cov covariance_matrix_${non_linear_model}.mat 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the files to the datablock 
_write_datablock "xiE_vec" "combined_vector.txt combined_vector_no_m_bias.txt"
_write_datablock "xiB_vec" "combined_vector.txt combined_vector_no_m_bias.txt"
_write_datablock "covariance_xiE" "covariance_matrix_${non_linear_model}.mat"
_write_datablock "covariance_xiB" "covariance_matrix_${non_linear_model}.mat"




