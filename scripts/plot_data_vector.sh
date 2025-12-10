#=========================================
#
# File Name : plot_data_vector.sh
# Created By : awright
# Creation Date : 18-11-2023
# Last Modified : Tue Dec  2 23:03:55 2025
#
#=========================================

if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 

#Define the number of data elements 
case "@BV:STATISTIC@" in 
  "cosebis") 
    xlabel="COSEBIs n" 
    ylabel_upper="E[n]" 
    ylabel_lower="B[n]" 
    xcoord=NONE
    ndata=@BV:NMAXCOSEBIS@
    datavec="@DB:cosebis_vec@"
    covariance="@DB:covariance_cosebis@"
    ;; 
  "bandpowers")
    xlabel="Bandpower n" 
    ylabel_upper="PeeE" 
    ylabel_lower="PeeB" 
    xcoord="@BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@ @BV:NBANDPOWERS@"
    ndata=@BV:NBANDPOWERS@
    datavec="@DB:bandpower_vec@"
    covariance="@DB:covariance_bandpower@"
    ;;
  "xipm") 
    xlabel="Radial Bin i" 
    ylabel_upper="Xi[p]" 
    ylabel_lower="Xi[m]" 
    xcoord=`echo @DB:xipm_binned@ | awk '{print $1}'`
    ndata=@BV:NXIPM@
    datavec="@DB:xipm_vec@"
    covariance="@DB:covariance_xipm@"
    ;;
  "xiE") 
    xlabel="Radial Bin i" 
    ylabel_upper="xi^E['+']" 
    ylabel_lower="xi^E['-']" 
    xcoord=`echo @DB:xipm_binned@ | awk '{print $1}'`
    ndata=@BV:NXIPM@
    datavec="@DB:xiE_vec@"
    covariance="@DB:covariance_xiE@"
    ;;
  "xiB") 
    xlabel="Radial Bin i" 
    ylabel_upper="xi^B['+']" 
    ylabel_lower="xi^B['-']" 
    xcoord=`echo @DB:xipm_binned@ | awk '{print $1}'`
    ndata=@BV:NXIPM@
    datavec="@DB:xiB_vec@"
    covariance="@DB:covariance_xiB@"
    ;;
  *)
    _message "Unknown statistic @BV:STATISTIC@"
esac

#Create directory if needed
if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
then 
  mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
fi 

datavec=`echo ${datavec} | awk '{print $1}'`
covariance=`echo ${covariance} |  awk '{print $1}'`

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`

for ptype in upper lower 
do 
  getlab="ylabel_${ptype}"
  #Run the R plotting code 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_data_vector.R \
    --datavec ${datavec} \
    --covariance ${covariance} \
    --ntomo ${NTOMO} \
    --type ${ptype} \
    --xcoord ${xcoord} \
    --output @RUNROOT@/@STORAGEPATH@/MCMC/input/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/DataVec_${ptype}${blinding}.pdf \
    --xlabel "${xlabel}" --ylabel "${!getlab}" 2>&1
done 


