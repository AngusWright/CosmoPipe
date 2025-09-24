#=========================================
#
# File Name : add_cosmosis_ini.sh
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
if [ -f @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini ]
then
  _message "  @BLU@Deleting previous values.ini file@DEF@"
  rm @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_values.ini
  _message "@RED@ - Done!@DEF@\n"
fi
cp @BV:COSMOSISINI@ @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_inputs/@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini


_write_datablock "cosmosis_inputs" "@SURVEY@_CosmoPipe_constructed_@BV:STATISTIC@.ini"
#}}}

