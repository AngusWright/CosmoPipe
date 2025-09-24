#=========================================
#
# File Name : apply_fluxscale.sh
# Created By : dvornik
# Creation Date : 19-04-2024
# Last Modified : Fri 19 Apr 2024 08:56:35 AM CEST
#
#=========================================

### Construct fluxscale corrected catalogue ### {{{
_message "Applying fluxscale correction to the KiDS Bright catalogue:"
file_one="@BV:LENS_MAIN@"
#Define the output filename
outname=${file_one##*/}
outname=${outname%%.*}
outname=${outname}_fluxscale_corrected.fits


#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/fluxscale_corrected/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/fluxscale_corrected
fi

#Check if the output file exists
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/fluxscale_corrected/${outname} ]
then
  _message "    -> @BLU@Removing previous fluxscale corrected catalogue for file ${file_one}@DEF@"
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/fluxscale_corrected/${outname}
  fluxscale_correctedblock=`_read_datablock fluxscale_corrected`
  currentblock=`_blockentry_to_filelist ${fluxscale_correctedblock}`
  currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname} | awk '{printf $0 " "}' || echo `
  _write_datablock fluxscale_corrected "${currentblock}"
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/apply_fluxscale.py \
  --file ${file_one} \
  --output_file @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/fluxscale_corrected/${outname} \
  --h0 "@BV:H0_IN@" 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the fluxscale catalogue to the datablock
fluxscale_correctedblock=`_read_datablock fluxscale_corrected`
_write_datablock fluxscale_corrected "`_blockentry_to_filelist ${fluxscale_corrected}` ${outname}"

#Create the FLUXSCALE_CORRECTED block variable
_write_blockvars "FLUXSCALE_CORRECTED" "@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/fluxscale_corrected/${outname}"
#}}}
