#=========================================
#
# File Name : smooth_nz.sh
# Created By : awright
# Creation Date : 07-09-2025
# Last Modified : Sun Sep  7 20:45:44 2025
#
#=========================================

#Script to smooth an Nz with a pre-specified gaussian kernel 
inputs="@DB:nz@"
_message " > @BLU@Smoothing all Nz with Gaussian kernel of width @DEF@@BV:SMOOTHING_STDEV@ @BLU@ {\n@DEF@"
for inp in ${inputs}
do 
_message "   @BLU@File @DEF@${inp##*/}@DEF@"
#Construct the data-simulation feature list 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/smooth_nz.R \
        -i ${inp} \
        --stdev @BV:SMOOTHING_STDEV@ \
        2>&1 
#Notify 
_message " @RED@- Done! (`date +'%a %H:%M'`)@DEF@\n"
done 
_message "@BLU@} @RED@-Done! (`date +'%a %H:%M'`)@DEF@\n"
  
