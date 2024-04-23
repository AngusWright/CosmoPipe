#
#
# Script to construct bandpowers from 2pt correlation functions
#
#


#Input file 
input=@DB:DATAHEAD@
#Bandpower mode: EE, NE, or NN
mode=@BV:BANDPOWERMODE@ 
#Output file 
output=${input##*/}
output=${output%_ggcorr*}
output=${output}_bandpowers
#Output folder: bandpowers
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/bandpowers/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 

# Now Integrate output from treecorr with bandpowers filter functions
# -i = input file
# -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
# -p = treecorr output xip_col
# -m = treecorr output xim_col
# --cfoldername = output directory
# -o = filename (outputs CE_filename.ascii and CB_filename.ascii)
# -b = binning "log" or "lin"
# -k = number of bandpower bins
# -s = minimum theta
# -l = maximum theta
# -w = width of apodisation window
# -z = minimum ell
# -x = maximum ell
# -d = statistic (==bandpowers)

if [ "${mode^^}" == "EE" ]
then
  _message "    -> @BLU@Computing EE bandpowers for file @RED@${input##*/}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
    -i ${input} \
    -t "meanr" -p "xip" -m "xim" \
    --cfoldername ${outfold} \
    -o ${output} -b @BINNING@ -s @BV:THETAMINXI@ \
    -l @BV:THETAMAXXI@ \
    -w @BV:APODISATIONWIDTH@ -z @BV:LMINBANDPOWERS@ -x @BV:LMAXBANDPOWERS@ \
    -k @BV:NBANDPOWERS@ \
    -d "bandpowers_ee" 2>&1 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

  #Add the files to the datablock 
  CEEfile="CEE_${output}.asc"
  CBBfile="CBB_${output}.asc"
  bandpowerblock=`_read_datablock bandpowers`
  _write_datablock bandpowers "`_blockentry_to_filelist ${bandpowerblock}` ${CEEfile} ${CBBfile}"

elif [ "${mode^^}" == "NE" ]
then
_message "    -> @BLU@Computing nE bandpowers for file @RED@${input##*/}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
    -i ${input} \
    -t "meanr" -g "gamT" -q "gamX" \
    --cfoldername ${outfold} \
    -o ${output} -b @BINNING@ -s @BV:THETAMINXI@ \
    -l @BV:THETAMAXXI@ \
    -w @BV:APODISATIONWIDTH@ -z @BV:LMINBANDPOWERS@ -x @BV:LMAXBANDPOWERS@ \
    -k @BV:NBANDPOWERS@ \
    -d "bandpowers_ne" 2>&1 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

  #Add the files to the datablock 
  CnEfile="CnE_${output}.asc"
  CnBfile="CnB_${output}.asc"
  bandpowerblock=`_read_datablock bandpowers`
  _write_datablock bandpowers "`_blockentry_to_filelist ${bandpowerblock}` ${CnEfile} ${CnBfile}"

elif [ "${mode^^}" == "NN" ]
then
_message "    -> @BLU@Computing nn bandpowers for file @RED@${input##*/}@DEF@"
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
    -i ${input} \
    -t "meanr" -j "xi" \
    --cfoldername ${outfold} \
    -o ${output} -b @BINNING@ -s @BV:THETAMINXI@ \
    -l @BV:THETAMAXXI@ \
    -w @BV:APODISATIONWIDTH@ -z @BV:LMINBANDPOWERS@ -x @BV:LMAXBANDPOWERS@ \
    -k @BV:NBANDPOWERS@ \
    -d "bandpowers_nn" 2>&1 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

  #Add the files to the datablock 
  Cnnfile="Cnn_${output}.asc"
  bandpowerblock=`_read_datablock bandpowers`
  _write_datablock bandpowers "`_blockentry_to_filelist ${bandpowerblock}` ${Cnnfile}"

else 
  _message "Bandpower mode unknown: ${mode^^}\n"
  exit 1
fi
