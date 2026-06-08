#=========================================
#
# File Name : compute_m_bias.sh
# Created By : awright
# Creation Date : 08-05-2023
# Last Modified : Tue May 19 11:58:14 2026
#
#=========================================

_datavec=`_read_datablock @BV:INVECBLOCK@`
_datavec=`_blockentry_to_filelist ${_datavec} | awk '{print $1}'`
_covariance=`_read_datablock @BV:INCOVBLOCK@`
_covariance=`_blockentry_to_filelist ${_covariance} | awk '{print $1}'`
_covmod=@BV:COVMODIFIER@

mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:OUTVECBLOCK@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:OUTCOVBLOCK@

#Run the covariance modification script {{{
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/modify_covariance.R \
  --datavec @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:INVECBLOCK@/$_datavec \
  --covariance @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:INCOVBLOCK@/$_covariance \
  --datavec_out @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:OUTVECBLOCK@/$_datavec \
  --covariance_out @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/@BV:OUTCOVBLOCK@/$_covariance \
  --ntomo `echo @BV:TOMOLIMS@ | awk '{print NF-1}'` \
  --nmode @BV:NMAXCOSEBIS@ \
  --covmod $_covmod 2>&1
#}}}

#Add the new data vector to the datablock 
_write_datablock @BV:OUTVECBLOCK@ "${_datavec} ${_datavec}"
#Add the new covariance to the datablock 
_write_datablock @BV:OUTCOVBLOCK@ "${_covariance}"


