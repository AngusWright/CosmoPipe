#=========================================
#
# File Name : plot_TPD.sh
# Created By : awright
# Creation Date : 18-04-2023
# Last Modified : Thu 23 Jan 2025 01:47:28 PM UTC
#
#=========================================

#If the sampler is not "list", don't try to do anything! 
if [ "@BV:SAMPLER@" == "list" ] 
then 

  #Define the number of data elements 
  case "@BV:STATISTIC@" in 
    "cosebis") 
      xlabel="italic(n)" 
      ylabel="italic(E)[italic(n)]" 
      xunit=''
      yunit='rad^2'
      labloc='bottomleft'
      datavec=`echo @DB:cosebis_vec@ | awk '{print $1}'`
      xcoord=NONE
      xmultpower=0
      xused="@BV:NMINCOSEBIS@ @BV:NMAXCOSEBIS@"
      covariance=@DB:covariance_cosebis@
      ;; 
    "bandpowers")
      xlabel="italic(l)" 
      ylabel="italic(C)[E](italic(l))" 
      xunit=''
      yunit=''
      labloc='topleft'
      datavec=`echo @DB:bandpowers_vec@ | awk '{print $1}'`
      xcoord="@BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@ @BV:NBANDPOWERS@"
      xused="@BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@"
      xmultpower=-1
      covariance=@DB:covariance_bandpowers@
      ;;
    "xipm") 
      xlabel="theta" 
      ylabel="xi['+']" 
      datavec=`echo @DB:xipm_vec@ | awk '{print $1}'`
      xcoord=`echo @DB:xipm_binned@ | awk '{print $1}'`
      xmultpower=1
      xunit='arcmin'
      yunit='arcmin'
      labloc='topright'
      xused="@BV:THETAMINXI@ @BV:THETAMAXXI@"
      covariance=@DB:covariance_xipm@
      ;;
    *)
      _message "Unknown statistic @BV:STATISTIC@"
  esac
  
  #Create directory if needed
  if [ ! -d @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots ]
  then 
    mkdir -p @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/
  fi 
  
  NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
  
  #Run the R plotting code 
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_TPD_rect.R \
    --datavec ${datavec} \
    --xcoord ${xcoord} \
    --xmultpower ${xmultpower} \
    --xused ${xused} \
    --onlyused \
    --labloc ${labloc} \
    --covariance ${covariance} \
    --tpds @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_list_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@@BV:CHAINSUFFIX@.txt \
    --ntomo ${NTOMO} \
    --sampler @BV:LIST_INPUT_SAMPLER@ \
    --output @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/TPD1_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@@BV:CHAINSUFFIX@.pdf \
    --xlabel "${xlabel}" --ylabel "${ylabel}" \
    --xunit  "${xunit}" --yunit  "${yunit}" \
    2>&1 || echo "Ignore failed plot generation" 
  
  #Define the number of data elements 
  case "@BV:STATISTIC@" in 
    "cosebis") 
      xlabel="italic(n)" 
      xunit=''
      ylabel="italic(B)[italic(n)]" 
      yunit='rad^2'
      labloc='topleft'
      datavec=`echo @DB:cosebis_vec@ | awk '{print $1}'`
      xmultpower=0
      xcoord=NONE
      xused="-1 -1"
      covariance=@DB:covariance_cosebis@
      ;; 
    "bandpowers")
      xlabel="italic(l)" 
      xunit=''
      ylabel="italic(C)[B](italic(l))" 
      yunit=''
      labloc='bottomleft'
      datavec=`echo @DB:bandpowers_vec@ | awk '{print $1}'`
      xcoord="@BV:LMINBANDPOWERS@ @BV:LMAXBANDPOWERS@ @BV:NBANDPOWERS@"
      xmultpower=-1
      xused="1 1"
      covariance=@DB:covariance_bandpowers@
      ;;
    "xipm") 
      xlabel="theta" 
      ylabel="xi['-']" 
      labloc='topright'
      xcoord=`echo @DB:xipm_binned@ | awk '{print $1}'`
      xmultpower=1
      xunit='arcmin'
      yunit='arcmin'
      xused="@BV:THETAMINXIM@ @BV:THETAMAXXI@"
      datavec=`echo @DB:xipm_vec@ | awk '{print $1}'`
      covariance=@DB:covariance_xipm@
      ;;
    *)
      _message "Unknown statistic @BV:STATISTIC@"
  esac
  
  @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/plot_TPD_rect.R \
    --datavec ${datavec} \
    --xcoord ${xcoord} \
    --xmultpower ${xmultpower} \
    --xused ${xused} \
    --labloc ${labloc} \
    --covariance ${covariance} \
    --tpds @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/chain/output_list_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@@BV:CHAINSUFFIX@.txt \
    --ntomo ${NTOMO} \
    --bmode \
    --sampler @BV:LIST_INPUT_SAMPLER@ \
    --output @RUNROOT@/@STORAGEPATH@/MCMC/output/@SURVEY@_@BLINDING@/@BV:BOLTZMAN@/@BV:STATISTIC@/plots/TPD2_@BV:LIST_INPUT_SAMPLER@_@BV:BLIND@@BV:CHAINSUFFIX@.pdf \
    --xlabel "${xlabel}" --ylabel "${ylabel}" \
    --xunit  "${xunit}" --yunit  "${yunit}" \
    2>&1 || echo "Ignore failed plot generation" 
  
fi 

