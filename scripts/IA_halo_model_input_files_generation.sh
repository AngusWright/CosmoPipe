#=========================================
#
# File Name : IA_halo_model_input_files_generation.sh
# Created By : dvornik
# Creation Date : 15-10-2024
# Last Modified : Tue 15 Oct 2024 08:56:35 AM CEST
#
#=========================================

### Construct fluxscale corrected catalogue ### {{{
_message "Extracting files needed for IA halo model:"
inputfile="@DB:ALLHEAD@"
ia_observable="@BV:IA_OBSERVABLE@"
z_col="@BV:TOMOVAR@"
s_tag="@BV:IA_SPLIT@"
s_val="@BV:IA_SPLIT_VAL@"
ia_log="@BV:IA_OBSERVABLE_LOG@"

#If needed, make the output folder
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/ ]
then
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data
fi

#Check if the output file exists
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/f_red.txt ]
then
  _message "    -> @BLU@Removing previous IA halo model files@DEF@"
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/f_red.txt
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/red_cen_obs_pdf.txt
  rm -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data/blue_cen_obs_pdf.txt
  IA_hm_datablock=`_read_datablock IA_hm_data`
  currentblock=`_blockentry_to_filelist ${IA_hm_datablock}`
  currentblock=`echo ${currentblock} | sed 's/ /\n/g' | grep -v ${outname} | awk '{printf $0 " "}' || echo `
  _write_datablock IA_hm_data "${currentblock}"
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
fi 

MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 \
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/IA_halo_model_input_files_generation.py \
  --catalogue ${inputfile} \
  --output_path @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/IA_hm_data \
  --nzbins 30 \
  --redshift_column ${z_col} \
  --split_tag ${s_tag} \
  --split_value ${s_val} \
  --log ${ia_log} \
  --observable ${ia_observable} 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the fluxscale catalogue to the datablock
IA_hm_datablock=`_read_datablock IA_hm_data`
_write_datablock IA_hm_data "`_blockentry_to_filelist ${IA_hm_datablock}` f_red.txt"
_write_datablock IA_hm_data "`_blockentry_to_filelist ${IA_hm_datablock}` red_cen_obs_pdf.txt"
_write_datablock IA_hm_data "`_blockentry_to_filelist ${IA_hm_datablock}` blue_cen_obs_pdf.txt"

#}}}
