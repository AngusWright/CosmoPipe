#=========================================
#
# File Name : calc_wt_w_treecorr.sh
# Created By : dvornik
# Creation Date : 18-04-2024
# Last Modified : Thu 18 Apr 2024 14:57:46 PM CET
#
#=========================================

### Estimate corrrelation functions ### {{{
_message "Estimating galaxy-clustering correlation functions:"
lensfiles="@BV:LENS_CATS@"
randfiles="@BV:RAND_CATS@"
  
for patch in @ALLPATCH@ @BV:PATCHLIST@
do
  _message " > Patch ${patch} {\n"
  #Select the catalogues from DATAHEAD in this patch
    if [ -d ${lensfiles} ]
  then
    inputlist=`ls @BV:LENS_CATS@`
    lens_filelist=""
    #This just makes sure that the files are added correctly
    for file in ${inputlist}
    do
      if [[ "$file" =~ .*"_${patch}_".* ]]
      then
        #Save the output file to the list {{{
        lens_filelist="${lens_filelist} ${lensfiles}${file}"
      fi
      #}}}
    done
  elif [ -f ${lensfiles} ]
  then
    if [[ "$lensfiles" =~ .*"_${patch}_".* ]]
    then
      lens_filelist=${lensfiles}
    fi
  else
    _message "${RED} - ERROR: Main input lens catalogue @BV:LENS_CATS@ does not exist!"
    exit -1
  fi
  
  if [ -d ${randfiles} ]
  then
    inputlist=`ls @BV:RAND_CATS@`
    rand_filelist=""
    #This just makes sure that the files are added correctly
    for file in ${inputlist}
    do
      if [[ "$file" =~ .*"_${patch}_".* ]]
      then
        #Save the output file to the list {{{
        rand_filelist="${rand_filelist} ${randfiles}${file}"
      fi
      #}}}
    done
  elif [ -f ${randfiles} ]
  then
    if [[ "$randfiles" =~ .*"_${patch}_".* ]]
    then
      rand_filelist=${randfiles}
    fi
  else
    _message "${RED} - ERROR: Main input lens catalogue @BV:RAND_CATS@ does not exist!"
    exit -1
  fi

  #If we don't have any catalogues in the datahead for this patch
  if [ "${lens_filelist}" == "" ]
  then
    _message "  >> @RED@ NONE @DEF@ << \n"
    continue
  fi

  NBIN="@BV:NLENSBINS@"
  #Loop over tomographic/any other lens bins in this patch
  #For clustering we only do autocorrelations at this stage!
  for LBIN1 in `seq ${NBIN}`
  do
    appendstr="_LB${LBIN1}"
    #Get the input file one
    file_lens_one=`echo ${lens_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
    file_rand_one=`echo ${rand_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
    #Check that the file exists
    if [ "${file_lens_one}" == "" ]
    then
      _message "@RED@ - ERROR!\n"
      _message "A lens file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
      exit 1
    fi
    
    if [ "${file_rand_one}" == "" ]
    then
      _message "@RED@ - ERROR!\n"
      _message "A randoms file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
      exit 1
    fi
	  ##Loop over tomographic/any other lens bins in this patch
	  #for LBIN2 in `seq $LBIN1 ${NBIN}`
	  #do
      #appendstr2="_LB${LBIN2}"
      #
      ##Check that the required input files exist
      #file_lens_two=`echo ${lens_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
      #file_rand_two=`echo ${rand_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
      ##Check that the file exists
      #if [ "${file_lens_two}" == "" ]
      #then
      #  _message "@RED@ - ERROR!\n"
      #  _message "A lens file with the bin string @DEF@${appendstr2}@RED@ does not exist in the data head\n"
      #  exit 1
      #fi
      #
      #if [ "${file_rand_two}" == "" ]
      #then
      #  _message "@RED@ - ERROR!\n"
      #  _message "A randoms file with the bin string @DEF@${appendstr2}@RED@ does not exist in the data head\n"
      #  exit 1
      #fi
		
      #Define the output filename 
      outname=${file_lens_one##*/}
      outname=${outname%%${appendstr}*}
      outname=${outname}${appendstr}_wtcorr.txt
      #outname=${outname}${appendstr}${appendstr2}_wtcorr.txt

      #Check if the output file exists 
      if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt/${outname} ]
      then
        _message "    -> @BLU@Removing previous @RED@Bin $LBIN1@BLU@ x @RED@Bin $LBIN1@BLU@ galaxy clustering correlation function@DEF@"
        rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/gt/${outname}
        wtblock=`_read_datablock wt`
        currentblock=`_blockentry_to_filelist ${wtblock}`
        currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname} | awk '{printf $0 " "}' || echo `
        _write_datablock wt "${currentblock}"
        _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      fi
      
      #Check if the user specified a bin_slop value. If not: use some standard values
      bin_slop=@BV:BINSLOPNN@
      if [[ $bin_slop =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
      then
        bin_slop=@BV:BINSLOPNN@
      else
        if [ @BV:NTHETABINWT@ -gt 100 ]
        then
          bin_slop_NN=1.0
        else
          bin_slop_NN=0.03
        fi
      fi
      
      bin_slop=@BV:BINSLOPNG@
      if [[ $bin_slop =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
      then
        bin_slop=@BV:BINSLOPNG@
      else
        if [ @BV:NTHETABINWT@ -gt 100 ]
        then
          bin_slop_NG=1.2
        else
          bin_slop_NG=0.05
        fi
      fi

      #Output covariance name (if needed)
      covoutname=${outname%%.*}_cov.mat
      if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt ]
      then
        mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt
      fi
      _message "    -> @BLU@Bin $LBIN1 x Bin $LBIN1 @DEF@"
      MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
        @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/calc_gt_w_treecorr.py \
        --clustering --nbins @BV:NTHETABINWT@ --theta_min @BV:THETAMINWT@ --theta_max @BV:THETAMAXWT@ --binning @BINNING@ --bin_slop_NN ${bin_slop_NN} --bin_slop_NG ${bin_slop_NG}\
        --lenscat ${file_lens_one} \
        --randcat ${file_rand_one} \
        --output @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt/${outname} \
        --covoutput @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt/${covoutname} \
        --weighted True \
        --patch_centers @BV:PATCH_CENTERFILE@ \
        --lensra "@BV:LENSRANAME@" --lensdec "@BV:LENSDECNAME@" --lensw "@BV:LENSWEIGHTNAME@" \
        --randra "@BV:RANDRANAME@" --randdec "@BV:RANDDECNAME@" \
        --nthreads @BV:NTHREADS@ 2>&1
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      #Add the correlation function to the datablock
      wtblock=`_read_datablock wt`
      _write_datablock wt "`_blockentry_to_filelist ${wtblock}` ${outname}"
      if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov_wt/${covoutname} ]
      then
        #Move the jackknife covariance 
        jackknife_covblock=`_read_datablock jackknife_cov_wt`
        _write_datablock jackknife_cov "`_blockentry_to_filelist ${jackknife_covblock}` ${covoutname}"
      fi
    #done
  done
done
#}}}
