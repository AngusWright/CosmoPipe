#
#
# Script to construct binned xipm from 2pt correlation functions
#
#


#Input file 
input=@DB:DATAHEAD@ 
#Output file 
output=${input##*/}
output=${output%_ggcorr*}
output=${output}_xigpsf_binned
#Output folder: cosebis
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/xigpsf_binned/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 

# -i = input file
# -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
# -p = treecorr output xip_col
# -m = treecorr output xim_col
# --cfoldername = output directory
# -o = filename (outputs En_filename.ascii and Bn_filename.ascii)
# -b = binning "log" or "lin"
# -n = number of COSEBIS modes
# -s = xipm minimum theta
# -l = xipm maximum theta


_message "    -> @BLU@Rebinning xigpsf for file @RED@${input##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
  -i ${input} \
  -t "meanr" -p "xip" -m "xim" \
  --cfoldername ${outfold} \
  -o ${output} -b @BV:BINNING@ --nbins_xipm @BV:NTHETAREBIN@ \
  -s @BV:THETAMIN@ -l @BV:THETAMAX@  \
 -d "xipm" 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the files to the datablock 
xigpsffile="xipm_binned_${output}.asc"
xigpsfblock=`_read_datablock xigpsf_binned`
_write_datablock xigpsf_binned "`_blockentry_to_filelist ${xigpsfblock}` ${xigpsffile}"



