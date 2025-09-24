#
#
# Script to construct binned gamma_t/x from 2pt correlation functions
#
#


#Input file 
input=@DB:DATAHEAD@ 
#Output file 
output=${input##*/}
output=${output%_gtcorr*}
output=${output}_gt_binned
#Output folder: gamma_t/x
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/gt_binned/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 

# -i = input file
# -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
# -g = treecorr output gamma_t
# -q = treecorr output gamma_x
# --cfoldername = output directory
# -o = filename (outputs En_filename.ascii and Bn_filename.ascii)
# -b = binning "log" or "lin"
# -n = number of COSEBIS modes
# -s = gt minimum theta
# -l = gt maximum theta


_message "    -> @BLU@Rebinning gamma_t/x for file @RED@${input##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
  -i ${input} \
  -t "meanr" -g "gamT" -q "gamX" \
  --cfoldername ${outfold} \
  -o ${output} -b @BINNING@ --nbins_2pcf @BV:NGT@ \
  -s @BV:THETAMINGT@ -l @BV:THETAMAXGT@  \
 -d "gt" 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the files to the datablock 
gtfile="gt_binned_${output}.asc"
gtblock=`_read_datablock gt_binned`
_write_datablock gt_binned "`_blockentry_to_filelist ${gtblock}` ${gtfile}"



