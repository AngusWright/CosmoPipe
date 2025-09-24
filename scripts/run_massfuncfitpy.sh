#=========================================
#
# File Name : run_massfuncfitpy.sh
# Created By : dvornik
# Creation Date : 19-04-2024
# Last Modified : Fri 19 Apr 2024 08:56:35 AM CEST
#
#=========================================

### Construct mass limits functions for input stellar mass sample ### {{{
_message "Run stellar mass function limit determination on a sample of stellar masses:"
file_one="@DB:fluxscale_corrected@"
#Define the output filename
outname=${file_one##*/}
outname=${outname%%.*}
outname1="mass_lim.npy"
outname2="mass_lim_low.npy"

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims
fi


#Check if the output file exists
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname1} ]
then
  _message "    -> @BLU@Removing previous mass limit function for file ${file_one}@DEF@"
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname1}
  mass_limsblock=`_read_datablock mass_lims`
  currentblock=`_blockentry_to_filelist ${mass_limsblock}`
  currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname1} | awk '{printf $0 " "}' || echo `
  _write_datablock mass_lims "${currentblock}"
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi

if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname2} ]
then
  _message "    -> @BLU@Removing previous low mass limit function for file ${file_one}@DEF@"
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname2}
  mass_limsblock=`_read_datablock mass_lims`
  currentblock=`_blockentry_to_filelist ${mass_limsblock}`
  currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname2} | awk '{printf $0 " "}' || echo `
  _write_datablock mass_lims "${currentblock}"
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi


MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/massfuncfitpy.py \
  --file ${file_one} \
  --outfile1 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname1} \
  --outfile2 @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/${outname2} \
  --h0 "@BV:H0_IN@" --omegam "@BV:OMEGAM_IN@" --omegav "@BV:OMEGAV_IN@" \
  --min_mass "@BV:MINMASS@" \
  --max_mass "@BV:MAXMASS@" \
  --min_z "@BV:MINZ@" \
  --max_z "@BV:MAXZ@" \
  --stellar_mass_column "@BV:STELLARMASS@" \
  --z_column @BV:REDSHIFT@ 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#--min_mass "@BV:MINMASS@" --max_mass "@BV:MAXMASS@" --min_z "@BV:MINZ@" --max_z "@BV:MAXZ@" 

outlist=""
outlist="${outlist} ${outname1}"
outlist="${outlist} ${outname2}"
#Add the mass limit functions to the datablock
_write_datablock mass_lims "${outlist}"
_write_blockvars "MASS_LIMS" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/mass_lims/"

#}}}
