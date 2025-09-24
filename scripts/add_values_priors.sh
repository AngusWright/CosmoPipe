#=========================================
#
# File Name : add_values_priors.sh
# Created By : dvornik
# Creation Date : 15-08-2024
# Last Modified : Thu Aug 15 15:52:14 2024
#
#=========================================

#Number of tomographic bins 
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENS=`echo @BV:NLENSBINS@`




#Values and prior files {{{
#Create the cosmosis_inputs directory
if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs ]
then 
  mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/
fi

#Add the values.ini and priors.ini files but first remove existing ones in the datablock:
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini ]
then 
  _message "  @BLU@Deleting previous values.ini file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  _message "@RED@ - Done!@DEF@\n"
fi 
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini ]
then 
  _message "  @BLU@Deleting previous priors.ini file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
  _message "@RED@ - Done!@DEF@\n"
fi 
cp @BV:VALUESINI@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
cp @BV:PRIORSINI@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini


#Update the values with the uncorrelated Dz priors {{{
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini 
#Add the uncorrelated tomographic bin shifts 
#Note: we multiply the bin shift by -1 because cosmosis defines the shifts with a relative minus sign!
tomoval_all=`cat @DB:nzbias_uncorr@`
for tomo in `seq ${NTOMO}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
  tomolo=`echo $tomoval | awk '{print $1-5.00}'`
  tomohi=`echo $tomoval | awk '{print $1+5.00}'`
  echo "uncorr_bias_${tomo} = ${tomolo} ${tomoval} ${tomohi} " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
done
#}}}
#Update the priors with the uncorrelated Dz priors {{{
echo "[nofz_shifts]" >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini 
#Add the uncorrelated tomographic bin shifts 
for tomo in `seq ${NTOMO}`
do 
  tomoval=`echo ${tomoval_all} | awk -v n=${tomo} '{print -1*$n}'`
  echo "uncorr_bias_${tomo} = gaussian ${tomoval} 1.0 " >> @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_priors.ini
done
#}}}

_write_datablock "cosmosis_inputs" "@SURVEY@_values.ini @SURVEY@_priors.ini"
#}}}

