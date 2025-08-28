#=========================================
#
# File Name : make_m_covariance.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Mon Jul 21 19:42:42 2025
#
#=========================================

if [ "@BLINDING@" != "UNBLIND" ] 
then 
  blinding=_@BV:BLIND@
else 
  blinding=
fi 

#Loop over the patch list
for patch in @BV:PATCHLIST@ @ALLPATCH@
do 
  #m-bias files 
  mfiles="`_read_datablock mbias_${patch}${blinding}`"
  mfiles="`_blockentry_to_filelist ${mfiles}`"

  #Check if the full covariance was constructed from simulation realisations 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding}/ ] || [ "@BV:ANALYTIC_MCOV@" == "TRUE" ]
  then
    outputlist='' 
    #Make the mcov directory if needed
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding}
    fi 
    #Construct a new covariance 
    #Get the m-bias files for this patch (there should be one, with NTOMO entries)
    mbias=`echo ${mfiles} | sed 's/ /\n/g' | grep "_biases" || echo `
    msigm=`echo ${mfiles} | sed 's/ /\n/g' | grep "_uncertainty" || echo `
    mcorr=`echo ${mfiles} | sed 's/ /\n/g' | grep "_correlation" || echo `

    #If there is no information for this patch, skip it 
    if [ "${mbias}" == "" ] 
    then 
      continue
    fi 

    #Create the m-covariance matrix [NTOMOxNTOMO] 
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/make_m_covariance.py \
      --msigm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/${msigm} \
      --mcorr @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/${mcorr} \
      --output "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding}/m_corr_${patch}${blinding}_r" 2>&1
    
    outputlist="${outputlist} m_corr_${patch}${blinding}_r.ascii m_corr_${patch}${blinding}_r_0p02.ascii m_corr_${patch}${blinding}_r_correl.ascii m_corr_${patch}${blinding}_r_uncorrelated_inflated.ascii m_corr_${patch}${blinding}_r_uncorrelated_inflated_0p02.ascii"

    #Make the cosmosis mcov directory (split per patch) 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}${blinding} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}${blinding}
    fi 

    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding}/m_corr_${patch}${blinding}_r.ascii @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}${blinding}/m_corr_${patch}${blinding}_r.ascii
    _write_datablock cosmosis_mcov_${patch}${blinding} "m_corr_${patch}${blinding}_r.ascii"
    if [ "${outputlist}" != "" ] 
    then 
      #Add the new files to the block
      _write_datablock mcov_${patch}${blinding} "${outputlist}"
    fi  

  else 
    #Use the existing covariance 
    #Make the cosmosis mcov directory (split per patch) 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}${blinding} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}${blinding}
    fi 
    #Existing covariance file 
    file=`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding}/`
    #Duplicate it 
    cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mcov_${patch}${blinding}/${file} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mcov_${patch}${blinding}/m_corr_${patch}${blinding}_r.ascii
    _write_datablock cosmosis_mcov_${patch}${blinding} "m_corr_${patch}${blinding}_r.ascii" 
  fi 
  
  #Make the cosmosis mbias directory (split per patch) 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}${blinding} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}${blinding}
  fi
  mbias=`echo ${mfiles} | sed 's/ /\n/g' | grep "_biases" || echo `
  mbias=${mbias##*/}
  cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/${mbias} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_mbias_${patch}${blinding}/${mbias}
  _write_datablock cosmosis_mbias_${patch}${blinding} "${mbias}"

  #Make the cosmosis mbias directory (split per patch) 
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_msigma_${patch}${blinding} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_msigma_${patch}${blinding}
  fi
  msigma=`echo ${mfiles} | sed 's/ /\n/g' | grep "_uncertainty" || echo `
  msigma=${msigma##*/}
  cp @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mbias_${patch}${blinding}/${msigma} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_msigma_${patch}${blinding}/${msigma}
  _write_datablock cosmosis_msigma_${patch}${blinding} "${msigma}" 

done


