#
#
# Script to construct binned w(theta) from 2pt correlation functions
#
#


#Input file 
input=@DB:DATAHEAD@ 
#Output file 
output=${input##*/}
output=${output%_wtcorr*}
output=${output}_wt_binned
#Output folder: gamma_t/x
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/wt_binned/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 

# -i = input file
# -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
# -j = treecorr output w_theta
# --cfoldername = output directory
# -o = filename (outputs En_filename.ascii and Bn_filename.ascii)
# -b = binning "log" or "lin"
# -n = number of COSEBIS modes
# -s = wt minimum theta
# -l = wt maximum theta


_message "    -> @BLU@Rebinning w(theta) for file @RED@${input##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
  -i ${input} \
  -t "meanr" -j "wtheta" \
  --cfoldername ${outfold} \
  -o ${output} -b @BINNING@ --nbins_2pcf @BV:NWT@ \
  -s @BV:THETAMINWT@ -l @BV:THETAMAXWT@  \
 -d "wt" 2>&1
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the files to the datablock 
wtfile="wt_binned_${output}.asc"
wtblock=`_read_datablock wt_binned`
_write_datablock wt_binned "`_blockentry_to_filelist ${wtblock}` ${wtfile}"



