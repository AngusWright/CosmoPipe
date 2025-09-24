#=========================================
#
# File Name : calc_smf.sh
# Created By : dvornik
# Creation Date : 19-04-2024
# Last Modified : Fri 19 Apr 2024 09:57:46 AM CEST
#
#=========================================

### Estimate corrrelation functions ### {{{
_message "Estimating stellar mass/luminosity functions:"

lensfiles="@BV:SMF_LENS_CATS@"
#Check that the main catalogue(s) exists
if [ -d ${lensfiles} ]
then
  inputlist=`ls @BV:SMF_LENS_CATS@`
  lens_filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist}
  do
    #Save the output file to the list {{{
    lens_filelist="${lens_filelist} ${lensfiles}${file}"
    #}}}
  done
elif [ -f ${lensfiles} ]
then
  lens_filelist=${lensfiles}
else
  _message "${RED} - ERROR: Main input lens catalogue @BV:SMF_LENS_CATS@ does not exist!"
  exit -1
fi

metafiles="@BV:SMF_LENS_CATS_METADATA@"
#Check that the main catalogue(s) exists
if [ -d ${metafiles} ]
then
  inputlist=`ls @BV:SMF_LENS_CATS_METADATA@`
  meta_filelist=""
  #This just makes sure that the files are added correctly
  for file in ${inputlist}
  do
    #Save the output file to the list {{{
    meta_filelist="${meta_filelist} ${metafiles}${file}"
    #}}}
  done
elif [ -f ${metafiles} ]
then
  meta_filelist=${metafiles}
else
  meta_filelist=""
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_vec/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_vec
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vmax/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vmax
fi

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/f_tomo/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/f_tomo
fi
  
NBIN="@BV:NSMFLENSBINS@"
#Loop over lens bins in this patch
for LBIN in `seq ${NBIN}`
do
  appendstr="_LB${LBIN}"
  #}}}
  #Get the input file one
  file_lens_one=`echo ${lens_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
  #Check that the file exists
  if [ "${file_lens_one}" == "" ]
  then
    _message "@RED@ - ERROR!\n"
    _message "A lens file with the bin string @DEF@${appendstr}@RED@ does not exist in the data head\n"
    exit 1
  fi
  
  file_ftomo_one=`echo ${meta_filelist} | sed 's/ /\n/g' | grep ${appendstr} || echo `
  #Check that the file exists
  if [ "${file_ftomo_one}" != "" ]
  then
    ftomo=`grep '^f_tomo' ${file_ftomo_one} | awk '{printf $2}'`
  else
    ftomo=1
  fi
  
  file_nz_tot=`echo ${meta_filelist} | sed 's/ /\n/g' | grep nz_tot || echo `
  #Check that the file exists
  if [ "${file_nz_tot}" != "" ]
  then
    nz_tot=${file_nz_tot}
  else
    nz_tot=""
  fi
  
  #file1="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB1.txt"
  slice=`grep '^slice_in' ${file_ftomo_one} | awk '{printf $2}'`
  if [ "${slice}" == "obs" ]
  then
    for i in `seq @BV:NSMFLENSBINS@`
    do
        #file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
        x_lo=`grep '^x_lims_lo' ${file_ftomo_one} | awk '{printf $2}'`
        x_hi=`grep '^x_lims_hi' ${file_ftomo_one} | awk '{printf $2}'`
        y_lo=`grep '^y_lims_lo' ${file_ftomo_one} | awk '{printf $2}'`
        y_hi=`grep '^y_lims_hi' ${file_ftomo_one} | awk '{printf $2}'`
        obs_mins="${x_lo}"
        obs_maxs="${x_hi}"
        z_mins="${y_lo}"
        z_maxs="${y_hi}"
    done
  elif [ "${slice}" == "z" ]
  then
    for i in `seq @BV:NSMFLENSBINS@`
    do
        #file="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_lens_cats_metadata/stats_LB${i}.txt"
        x_lo=`grep '^x_lims_lo' ${file_ftomo_one} | awk '{printf $2}'`
        x_hi=`grep '^x_lims_hi' ${file_ftomo_one} | awk '{printf $2}'`
        y_lo=`grep '^y_lims_lo' ${file_ftomo_one} | awk '{printf $2}'`
        y_hi=`grep '^y_lims_hi' ${file_ftomo_one} | awk '{printf $2}'`
        obs_mins="${y_lo}"
        obs_maxs="${y_hi}"
        z_mins="${x_lo}"
        z_maxs="${x_hi}"
    done
  else
    _message "Got wrong or no information about slicing of the lens sample.\n"
    #exit 1
  fi
  
  
  
  #Define the output filename
  outname=${file_lens_one##*/}
  outname0=${outname%%${appendstr}*}
  outname1=${outname0}${appendstr}

  #Check if the output file exists
  if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_vec/${outname1}_smf.txt ]
  then
    _message "    -> @BLU@Removing previous @RED@Bin $LBIN@BLU@ stellar mass function function@DEF@"
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf_vec/${outname1}_smf.txt
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/vmax/${outname1}_vmax.txt
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/smf/${outname1}_smf_comp.png
    rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/f_tomo/${outname1}_ftomo.txt
    smfblock=`_read_datablock smf_vec`
    currentblock=`_blockentry_to_filelist ${smfblock}`
    currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname1}_smf.txt | awk '{printf $0 " "}' || echo `
    _write_datablock smf_vec "${currentblock}"
    
    vmaxblock=`_read_datablock vmax`
    currentblock=`_blockentry_to_filelist ${vmaxblock}`
    currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname1}_vmax.txt | awk '{printf $0 " "}' || echo `
    _write_datablock vmax "${currentblock}"
    
    ftomoblock=`_read_datablock f_tomo`
    currentblock=`_blockentry_to_filelist ${ftomoblock}`
    currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname1}_ftomo.txt | awk '{printf $0 " "}' || echo `
    _write_datablock f_tomo "${currentblock}"
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi
      
      
  _message "    -> @BLU@Bin $LBIN @DEF@"
  MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/calc_smf.py \
    --estimator simple \
    --nbins "@BV:NSMFBINS@" --min_mass "${obs_mins}" --max_mass "${obs_maxs}" \
    --h0 "@BV:H0_IN@" --omegam "@BV:OMEGAM_IN@" --omegav "@BV:OMEGAV_IN@" \
    --file ${file_lens_one} \
    --output_path @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/ \
    --output_name ${outname1} \
    --min_z "${z_mins}" --max_z "${z_maxs}" \
    --stellar_mass_column @BV:STELLARMASS@ \
    --z_column @BV:REDSHIFT@ \
    --area @SURVEYAREADEG@ \
    --compare_to_gama \
    --path @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims \
    --f_tomo ${ftomo} \
    --nobs ${NBIN} \
    --nz_file "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_obs/${outname0}_nz_LB${LBIN}.txt" \
    --nz_tot ${nz_tot} 2>&1
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
      
  #Add the smf function to the datablock
  smfblock=`_read_datablock smf_vec`
  vmaxblock=`_read_datablock vmax`
  ftomoblock=`_read_datablock f_tomo`
  _write_datablock smf_vec "`_blockentry_to_filelist ${smfblock}` ${outname1}_smf.txt"
  _write_datablock vmax "`_blockentry_to_filelist ${vmaxblock}` ${outname1}_vmax.txt"
  _write_datablock f_tomo "`_blockentry_to_filelist ${ftomoblock}` ${outname1}_ftomo.txt"
done
_message "  }\n"
#}}}
