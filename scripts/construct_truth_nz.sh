#=========================================
#
# File Name : compute_nz.sh
# Created By : awright
# Creation Date : 22-03-2023
# Last Modified : Sat Sep 13 10:56:36 2025
#
#=========================================

inputlist="@DB:som_weight_refr_gold@"

for patch in @BV:PATCHLIST@ @ALLPATCH@ @ALLPATCH@comb 
do 
  nfile=`echo ${inputlist} | sed 's/ /\n/g' | grep -c "_${patch}_" || echo `
  if [ ${nfile} -gt 0 ]
  then 
    #Construct the nz folder, if needed 
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_truth_${patch} ]
    then 
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_truth_${patch}
    fi 
    _message " > @BLU@Working on Patch @DEF@${patch}@DEF@"
    patchlist=`echo ${inputlist} | sed 's/ /\n/g' | grep "_${patch}_" || echo `
    #For each of the specz_calib_cats files: 
    outlist=""
    for input in ${patchlist} 
    do 
      #Define the output filename 
      output=${input%%_DIRsom*}
      if [ "${output}" == "${input}" ] 
      then 
        #We are not using raw calibration catalogues 
        output=${input%.*}
      fi 
      #Add the Nz file suffice
      output=${output}@NZFILESUFFIX@
      output=${output##*/}
      outlist="${outlist} ${output}"
    
      #Run the Nz construction 
      @P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/construct_nz.R \
        -i ${input} \
        -o @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_truth_${patch}/${output} \
        --zname @BV:ZSPECNAME@ \
        --zstep @BV:NZSTEP@ \
        --somweightname "" \
        --origweightname "@BV:WEIGHTNAME@" 2>&1 
    
    done
    
    #Add the Nz file(s) to the datablock 
    _write_datablock nz_truth_${patch} "${outlist}"
    _message " @RED@ - Done! @DEF@\n"
    
  fi 
done 
