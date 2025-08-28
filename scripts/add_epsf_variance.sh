#=========================================
#
# File Name : add_epsf_variance.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Mon Aug 25 11:59:45 2025
#
#=========================================

#Define the output filename 
input="@DB:DATAHEAD@"
output=${input}
outext=${output##*.}
output=${output//.${outext}/_psfvar.${outext}}

#File with output PSF variances 
varfile=${output//.${outext}/_psfvar.${outext}}
#Step 1, compute the epsf variances  
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/epsf_variance.R \
  -i @DB:DATAHEAD@ \
  -v @BV:PSFE1NAME@ @BV:PSFE2NAME@ \
  -o ${varfile} 2>&1 


#Merge the variance columns with ldac 
@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey \
  -i @DB:DATAHEAD@ \
  -p ${varfile} \
  -o ${output} \
  -k @BV:PSFE1NAME@_var @BV:PSFE2NAME@_var -t OBJECTS 2>&1

#Update the datahead 
_replace_datahead "${input}" "${output}"

