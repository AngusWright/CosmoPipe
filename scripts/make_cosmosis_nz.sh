#=========================================
#
# File Name : make_cosmosis_nz.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 21 Nov 2023 12:55:58 AM CET
#
#=========================================

NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
outputlist=''
found="FALSE"
for patch in @BV:PATCHLIST@ @ALLPATCH@ 
do 
  _message " ->@BLU@ Patch @RED@${patch}@DEF@"
  #Get all the files in this stat and patch {{{
  inputs=`_read_datablock "nz_${patch}"`
  inputs=`_blockentry_to_filelist ${inputs}`
  #}}}
  filelist=''
  #Get the file list {{{
  for ZBIN1 in `seq ${NTOMO}`
  do
    #Define the Z_B limits from the TOMOLIMS {{{
    ZB_lo=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $n}'`
    ZB_hi=`echo @BV:TOMOLIMS@ | awk -v n=$ZBIN1 '{print $(n+1)}'`
    #}}}
    #Define the string to append to the file names {{{
    ZB_lo_str=`echo $ZB_lo | sed 's/\./p/g'`
    ZB_hi_str=`echo $ZB_hi | sed 's/\./p/g'`
    appendstr="_ZB${ZB_lo_str}t${ZB_hi_str}"
    #}}}
    #file=`echo ${inputs} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${appendstr} || echo `
    file=`echo ${inputs} | sed 's/ /\n/g' | grep ${appendstr} || echo `
    #Check if the output file exists {{{
    if [ "${file}" == "" ] 
    then 
      #If not, loop
      continue
    fi 
    #}}}
    filelist="${filelist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_${patch}/${file}"
  done 
  #}}}
  #If filelist is empty, skip {{{
  if [ "${filelist}" == "" ] 
  then 
    _message "@RED@ - skipping! (No matching Nz files)@DEF@\n"
    continue
  fi 
  #}}}
  found='TRUE'
  #Construct the output directory {{{
  if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_${patch} ]
  then 
    mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_${patch}/
  fi 
  #}}}
  _message "@RED@ - OK! (`date +'%a %H:%M'`)@DEF@\n"
  #Construct the output base {{{
  file=${filelist##* }
  output_base=${file##*/}
  output_base=${output_base%%_ZB*}
  output_base="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_${patch}/${output_base}"
  #}}}
  #Remove existing files {{{
  if [ -f ${output_base}_comb_Nz.fits ]
  then 
    _message " > @BLU@Removing previous COSMOSIS Nz file@DEF@ ${output_base##*/}_comb_Nz.fits@DEF@"
    rm ${output_base}_comb_Nz.fits
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  fi 
  #}}}
  #Construct the redshift file {{{
  _message " > @BLU@Constructing COSMOSIS Nz file @RED@${output_base}_comb_Nz.fits@DEF@"
  #Construct the Nz combined fits file and put into covariance/input/
  @PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/MakeNofZForCosmosis_function.py \
    --inputs ${filelist} \
    --neff @DB:cosmosis_neff@ \
    --output_base ${output_base} 2>&1 
  _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
  #}}}
  
  #Update the datablock 
  _write_datablock cosmosis_nz_${patch} "${output_base##*/}_comb_Nz.fits"
done 

#Error if no stat files found {{{ 
if [ "${found}" == "FALSE" ] 
then 
  #If not found, error 
  _message " - @RED@ERROR!@DEF@\n"
  _message "@RED@There are no nz files in any patch?!@DEF@\n"
  _message "@BLU@You probably didn't run rename an 'nz' block for a particular patch?!@DEF@\n"
  exit 1
fi 
#}}}

