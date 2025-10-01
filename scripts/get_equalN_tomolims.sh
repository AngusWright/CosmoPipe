#=========================================
#
# File Name : equalN_split.sh
# Created By : awright
# Creation Date : 04-07-2023
# Last Modified : Thu Sep 25 17:17:35 2025
#
#=========================================

#Define the output filename 
input="@DB:ALLHEAD@"
ninp=`echo ${input} | awk '{print NF}'`
if [ $ninp != 1 ]
then 
  _message "@RED@Warning!@BLU@ - get_equalN_tomolims expects a single file in the DATAHEAD@DEF@\n"
  _message "@RED@        @BLU@   Computing tomolims from only the first DATAHEAD file!!@DEF@\n"
  input=`echo ${input} | awk '{print $1}'`
  _message "@RED@        @DEF@   ${input}\n"
fi 
output=${input}
outext=${output##*.}
outbase=${output//.${outext}/}
outlist="${outbase}_tomolims.txt"

#Split catalogues in the DATAHEAD into NSPLIT regions 
@P_RSCRIPT@ @RUNROOT@/@SCRIPTPATH@/equalN_split.R \
  -i ${input} \
  -n @BV:NTOMO@ \
  -v @BV:TOMOVAR@ \
  -w "@BV:WEIGHTNAME@" \
  --limits.only \
  -o ${outlist} 2>&1

limits=`tail -1 ${outlist}`
if [ "${limits}" == '' ]
then 
  _message "@RED@ERROR@BLU@ - No limits produced?!@DEF@\n"
  exit 1 
fi 

#Save the tomolims variable to the datablock 
_write_blockvars "TOMOLIMS" "${limits}"

