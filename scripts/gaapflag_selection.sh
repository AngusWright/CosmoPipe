#=========================================
#
# File Name : gaapflag_selection.sh
# Created By : awright
# Creation Date : 27-03-2023
# Last Modified : Tue Apr  4 17:34:16 2023
#
#=========================================

for input in @DB:ALLHEAD@
do 
  _message "Creating Filtered (i.e. good phot) catalogue for @RED@${input##*/}@DEF@"
  logfile=${input##*/}
  logfile=${logfile//.cat/_filt.log}
  #Select only sources with good 9-band photometry
  @PYTHON3BIN@/python3 @RUNROOT@/@SCRIPTPATH@/ldacfilter.py \
    -i ${input} \
    -t OBJECTS \
    -c "(@GAAPFLAG@==0);" \
    -o ${input//.cat/_filt.cat} \
    > @RUNROOT@/@LOGPATH@/${logfile} 2>&1 
  _message " - @RED@Done!@DEF@\n"
  output=${input//.cat/_filt.cat}
  _replace_datahead ${input##*/} ${output##*/}
done 
