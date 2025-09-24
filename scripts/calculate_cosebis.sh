#
#
# Script to construct COSEBIs from 2pt correlation functions
#
#


#Input file 
input=@DB:DATAHEAD@ 
#Output file 
output=${input##*/}
output=${output%_ggcorr*}
output=${output}_cosebis
#Output folder: cosebis
outfold=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosebis/
if [ ! -d ${outfold} ]
then 
  mkdir ${outfold}
fi 

# check whether the pre-computed COSEBIS tables exist
SRCLOC=@RUNROOT@/@CONFIGPATH@/cosebis
normfile=${SRCLOC}/TLogsRootsAndNorms/Normalization_@BV:THETAMINXI@-@BV:THETAMAXXI@.table
rootfile=${SRCLOC}/TLogsRootsAndNorms/Root_@BV:THETAMINXI@-@BV:THETAMAXXI@.table

if [ ! -f ${normfile} ] || [ ! -f ${rootfile} ]
then 
  if [ "@BINNING@" == "log" ]
  then 
    _message "    -> @BLU@Computing COSEBIs root and norm files@DEF@"
    @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/cosebis_compute_log_weight.py \
      --thetamin @BV:THETAMINXI@ \
      --thetamax @BV:THETAMAXXI@ \
      --nmax @BV:NMAXCOSEBIS@ \
      --outputbase ${SRCLOC}/TLogsRootsAndNorms/ 2>&1
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  else 
    _message "- ERROR!\n"
    _message "COSEBIS pre-computed table ${normfile} or ${rootfile} is missing, and pipeline cannot compute them for linear binning. Download from gitrepo!"
    exit 1
  fi 
fi

# Now Integrate output from treecorr with COSEBIS filter functions
# -i = input file
# -t = treecorr output theta_col - the first column is zero so -t 1 uses the meanR from Treecorr
# -p = treecorr output xip_col
# -m = treecorr output xim_col
# --cfoldername = output directory
# -o = filename (outputs En_filename.ascii and Bn_filename.ascii)
# -b = binning "log" or "lin"
# -n = number of COSEBIS modes
# -s = COSEBIS minimum theta
# -l = COSEBIS maximum theta
# location of the required pre-compution tables
# --tfoldername = Tplus_minus    # computes/saves the first time it is run for a fixed theta min/max
# --norm = TLogsRootsAndNorms/Normalization_${tmin}-${tmax}.table
# --root = TLogsRootsAndNorms/Root_${tmin}-${tmax}.table

_message "    -> @BLU@Computing COSEBIs for file @RED@${input##*/}@DEF@"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/run_measure_statistics_cats2stats.py \
  -i ${input} \
  -t "meanr" -p "xip" -m "xim" \
  --cfoldername ${outfold} \
  -o ${output} -b @BINNING@ -n @BV:NMAXCOSEBIS@ -s @BV:THETAMINXI@ \
  -l @BV:THETAMAXXI@ --tfoldername ${SRCLOC}/Tplus_minus \
  --norm ${normfile} --root ${rootfile} \
  -d "cosebis" 2>&1 
_message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"

#Add the files to the datablock 
Enfile="En_${output}.asc"
Bnfile="Bn_${output}.asc"
cosebiblock=`_read_datablock cosebis`
_write_datablock cosebis "`_blockentry_to_filelist ${cosebiblock}` ${Enfile} ${Bnfile}"



