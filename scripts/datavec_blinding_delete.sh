#=========================================
#
# File Name : datavec_blinding_delete.sh
# Created By : dvornik
# Creation Date : 30-07-2024
# Last Modified : Tue 30 Jul 2024 10:06:57 PM CEST
#
#=========================================


# Remove all the previous statistic files / datavectors / everything after treecorr runs
datablock_names="`ls @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/`"
to_delete="gt wt xipm cosebis bandpowers psi_stats cosmosis_npair" # Add more if we figure out that is needed
for name in ${datablock_names}
do
  for del in ${to_delete}
  do
    if [[ "${name}" =~ ^"${del}".* ]]
    then
      #_message "Trying to delete ${name}\n"
      name=`_parse_blockvars ${name}`
      _delete_blockitem "${name}"
    fi
  done
  if [[ "smf" =~ "${name}" ]]
  then
    _message "Trying to delete ${name}\n"
    #name=`_parse_blockvars ${name}`
    #_delete_blockitem "${name}"
  fi
done

