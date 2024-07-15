#=========================================
#
# File Name : calc_xi_w_treecorr.sh
# Created By : awright
# Creation Date : 27-03-2023
# Last Modified : Fri 22 Mar 2024 08:55:46 PM CET
#
#=========================================

### Estimate corrrelation functions ### {{{
_message "Estimating Correlation Functions:"
headfiles="@DB:ALLHEAD@"
for patch in @ALLPATCH@ @PATCHLIST@ 
do 
  _message " > Patch ${patch} {\n"
  #Select the catalogues from DATAHEAD in this patch 
  filelist=''
  for file in ${headfiles}
  do 
    if [[ "$file" =~ .*"_${patch}_".* ]] 
    then 
      filelist="${filelist} ${file}" 
    fi 
  done

  #If we don't have any catalogues in the datahead for this patch
  if [ "${filelist}" == "" ]
  then 
    _message "  >> @RED@ NONE @DEF@ << \n"
    continue
  fi

  NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
  #Loop over tomographic bins in this patch 
	for ZBIN1 in `seq ${NTOMO}`
	do
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $n}'`
    ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    #}}}
    #Get the input file one
    file_one=`echo ${filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
    #Check that the file exists 
    if [ "${file_one}" == "" ] 
    then 
      _message "@RED@ - ERROR!\n"
      _message "A file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
      exit 1 
    fi 
	  
	  for ZBIN2 in `seq $ZBIN1 ${NTOMO}`
	  do
      ZB_lo2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $n}'`
      ZB_hi2=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN2 '{print $(n+1)}'`
      ZB_lo_str2=`echo $ZB_lo2 | sed 's/\./p/g'`
      ZB_hi_str2=`echo $ZB_hi2 | sed 's/\./p/g'`
      appendstr2="_ZB${ZB_lo_str2}t${ZB_hi_str2}"

      #Check that the required input files exist 
      file_two=`echo ${filelist} | sed 's/ /\n/g' | grep ${appendstr2} || echo `
      #Check that the file exists 
      if [ "${file_two}" == "" ] 
      then 
        _message "@RED@ - ERROR!\n"
        _message "A file with the bin string @DEF@${appendstr2}@RED@ does not exist in the data head\n"
        exit 1 
      fi 
		
      #Define the output filename 
      outname=${file_one##*/}
      outname=${outname%%${appendstr}*}
      outname=${outname}${appendstr}${appendstr2}_ggcorr.txt

      #Check if the output file exists 
      if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${outname} ]
      then 
        _message "    -> @BLU@Removing previous @RED@Bin $ZBIN1@BLU@ x @RED@Bin $ZBIN2@BLU@ correlation function@DEF@"
        rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${outname}
        xipmblock=`_read_datablock xipm`
        currentblock=`_blockentry_to_filelist ${xipmblock}`
        currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname} | awk '{printf $0 " "}' || echo `
        _write_datablock xipm "${currentblock}"
        _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      fi 

      #Check if the user specified a bin_slop value. If not: use some standard values
      bin_slop=@BV:BINSLOP@
      if [[ $bin_slop =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]
      then
        bin_slop=@BV:BINSLOP@
      else
        if [ @BV:NTHETABIN@ -gt 100 ]
        then
          bin_slop=1.5
        else
          bin_slop=0.08
        fi
      fi

      #Output covariance name (if needed)
      covoutname=${outname%%.*}_cov.mat
      if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov ] 
      then 
        mkdir -p @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov 
      fi 
      _message "    -> @BLU@Bin $ZBIN1 ($ZB_lo < Z_B <= $ZB_hi) x Bin $ZBIN2 ($ZB_lo2 < Z_B <= $ZB_hi2)@DEF@"
      MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
        @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/calc_xi_w_treecorr.py \
        --nbins @BV:NTHETABIN@ --theta_min @BV:THETAMIN@ --theta_max @BV:THETAMAX@ --binning @BINNING@ --bin_slop ${bin_slop}\
        --fileone ${file_one} \
        --filetwo ${file_two} \
        --output @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xipm/${outname} \
        --covoutput @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov/${covoutname} \
        --weighted True \
        --patch_centers @BV:PATCH_CENTERFILE@ \
        --file1e1 "@BV:E1NAME@" --file1e2 "@BV:E2NAME@" --file1w "@BV:WEIGHTNAME@" --file1ra "@BV:RANAME@" --file1dec "@BV:DECNAME@" \
        --file2e1 "@BV:E1NAME@" --file2e2 "@BV:E2NAME@" --file2w "@BV:WEIGHTNAME@" --file2ra "@BV:RANAME@" --file2dec "@BV:DECNAME@" \
        --nthreads @BV:NTHREADS@ 2>&1 
      _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      #Add the correlation function to the datablock 
      xipmblock=`_read_datablock xipm`
      _write_datablock xipm "`_blockentry_to_filelist ${xipmblock}` ${outname}"
      if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/jackknife_cov/${covoutname} ]
      then 
        #Move the jackknife covariance 
        jackknife_covblock=`_read_datablock jackknife_cov`
        _write_datablock jackknife_cov "`_blockentry_to_filelist ${jackknife_covblock}` ${covoutname}"
      fi 
    done
	done
  _message "  }\n"
done
#}}}
