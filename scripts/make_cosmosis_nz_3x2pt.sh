#=========================================
#
# File Name : make_cosmosis_nz_3x2pt.sh
# Created By : awright
# Creation Date : 30-03-2023
# Last Modified : Tue 21 Nov 2023 12:55:58 AM CET
#
#=========================================

MODES="@BV:MODES@"
NTOMO=`echo @BV:TOMOLIMS@ | awk '{print NF-1}'`
NLENS="@BV:NLENSBINS@"
NOBS="@BV:NSMFLENSBINS@"
outputlist=''
found_source="FALSE"
found_lens="FALSE"
found_obs="FALSE"

need_source="FALSE"
need_lens="FALSE"
need_obs="FALSE"

if [[ .*\ $MODES\ .* =~ " EE " ]] || [[ .*\ $MODES\ .* =~ " NE " ]]
then
  need_source="TRUE"
fi
if [[ .*\ $MODES\ .* =~ " NE " ]] || [[ .*\ $MODES\ .* =~ " NN " ]]
then
  need_lens="TRUE"
fi
if [[ .*\ $MODES\ .* =~ " OBS " ]]
then
  need_obs="TRUE"
fi

if [ ${need_source} == "TRUE" ]
then
  for patch in @BV:PATCHLIST@ @ALLPATCH@
  do 
    _message " ->@BLU@ Patch @RED@${patch}@DEF@"
    #Get all the files in this stat and patch {{{
    inputs=`_read_datablock "nz_source_${patch}"`
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
      filelist="${filelist} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_source_${patch}/${file}"
    done
    #}}}
    #If filelist is empty, skip {{{
    if [ "${filelist}" == "" ] 
    then 
      _message "@RED@ - skipping! (No matching source Nz files)@DEF@\n"
      continue
    fi 
    #}}}
    found_source='TRUE'
    #Construct the output directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_source_${patch} ]
    then
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_source_${patch}/
    fi
    #}}}
    _message "@RED@ - OK! (`date +'%a %H:%M'`)@DEF@\n"
    #Construct the output base {{{
    file=${filelist##* }
    output_base=${file##*/}
    output_base=${output_base%%_ZB*}
    output_base="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_source_${patch}/${output_base}"
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
      --neff @DB:cosmosis_neff_source@ \
      --output_base ${output_base} \
      --suffix "source" 2>&1
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    #}}}

    #Update the datablock 
    _write_datablock cosmosis_nz_source_${patch} "${output_base##*/}_comb_Nz.fits"
  done
fi  
  
if [ ${need_lens} == "TRUE" ]
then
  for patch in @BV:PATCHLIST@ @ALLPATCH@
  do 
    _message " ->@BLU@ Patch @RED@${patch}@DEF@"
    #Get all the files in this stat and patch {{{
    inputs_lens=`_read_datablock "nz_lens_${patch}"`
    inputs_lens=`_blockentry_to_filelist ${inputs_lens}`
    #}}}
    filelist_lens=''
    #Get the file list {{{
    for LBIN in `seq ${NLENS}`
    do
      #Define the string to append to the file names {{{
      appendstr="_LB${LBIN}"
      #}}}
      #file=`echo ${inputs} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${appendstr} || echo `
      file=`echo ${inputs_lens} | sed 's/ /\n/g' | grep ${appendstr} || echo `
      appendstr="_LB${LBIN}"
      #Check if the output file exists {{{
      if [ "${file}" == "" ]
      then
        #If not, loop
        continue
      fi
      #}}}
      filelist_lens="${filelist_lens} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_lens_${patch}/${file}"
    done
    #}}}
    #If filelist is empty, skip {{{
    if [ "${filelist_lens}" == "" ]
    then
      _message "@RED@ - skipping! (No matching lens Nz files)@DEF@\n"
      continue
    fi
    #}}}
    found_lens='TRUE'
    #Construct the output directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_lens_${patch} ]
    then
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_lens_${patch}/
    fi
    #}}}
    _message "@RED@ - OK! (`date +'%a %H:%M'`)@DEF@\n"
    #Construct the output base {{{
    file=${filelist_lens##* }
    output_base=${file##*/}
    output_base=${output_base%%_LB*}
    output_base="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_lens_${patch}/${output_base}"
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
      --inputs ${filelist_lens} \
      --neff @DB:cosmosis_neff_lens@ \
      --output_base ${output_base} \
      --suffix "lens" 2>&1
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    #}}}

    #Update the datablock
    _write_datablock cosmosis_nz_lens_${patch} "${output_base##*/}_comb_Nz.fits"
  done
fi
  
if [ ${need_obs} == "TRUE" ]
then
  for patch in @BV:PATCHLIST@ @ALLPATCH@
  do 
    _message " ->@BLU@ Patch @RED@${patch}@DEF@"
    #Get all the files in this stat and patch {{{
    inputs_obs=`_read_datablock "nz_obs_${patch}"`
    inputs_obs=`_blockentry_to_filelist ${inputs_obs}`
    #}}}
    filelist_obs=''
    #Get the file list {{{
    for LBIN in `seq ${NOBS}`
    do
      #Define the string to append to the file names {{{
      appendstr="_LB${LBIN}"
      #}}}
      #file=`echo ${inputs} | sed 's/ /\n/g' | grep "_${patch}_" | grep ${appendstr} || echo `
      file=`echo ${inputs_obs} | sed 's/ /\n/g' | grep ${appendstr} || echo `
      appendstr="_LB${LBIN}"
      #Check if the output file exists {{{
      if [ "${file}" == "" ]
      then
        #If not, loop
        continue
      fi
      #}}}
      filelist_obs="${filelist_obs} @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/nz_obs_${patch}/${file}"
    done
    #}}}
    #If filelist is empty, skip {{{
    if [ "${filelist_obs}" == "" ]
    then
      _message "@RED@ - skipping! (No matching obs Nz files)@DEF@\n"
      continue
    fi
    #}}}
    found_obs='TRUE'
    #Construct the output directory {{{
    if [ ! -d @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_obs_${patch} ]
    then
      mkdir @RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_obs_${patch}/
    fi
    #}}}
    _message "@RED@ - OK! (`date +'%a %H:%M'`)@DEF@\n"
    #Construct the output base {{{
    file=${filelist_obs##* }
    output_base=${file##*/}
    output_base=${output_base%%_LB*}
    output_base="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/cosmosis_nz_obs_${patch}/${output_base}"
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
      --inputs ${filelist_obs} \
      --neff @DB:cosmosis_neff_obs@ \
      --output_base ${output_base} \
      --suffix "obs" 2>&1
    _message " - @RED@Done! (`date +'%a %H:%M'`)@DEF@\n"
    #}}}

    #Update the datablock
    _write_datablock cosmosis_nz_obs_${patch} "${output_base##*/}_comb_Nz.fits"
  done
fi

#Error if no stat files found {{{ 
if [ "${found_source}" == "FALSE" ] && [ "${need_source}" == "TRUE" ]
then
  #If not found, error 
  _message " - @RED@ERROR!@DEF@\n"
  _message "@RED@There are no nz_source files in any patch?!@DEF@\n"
  _message "@BLU@You probably didn't run rename an 'nz_source' block for a particular patch?!@DEF@\n"
  exit 1
fi

if [ "${found_lens}" == "FALSE" ] && [ "${need_lens}" == "TRUE" ]
then
  #If not found, error
  _message " - @RED@ERROR!@DEF@\n"
  _message "@RED@There are no nz_lens files in any patch?!@DEF@\n"
  _message "@BLU@You probably didn't run rename an 'nz_lens' block for a particular patch?!@DEF@\n"
  exit 1
fi

if [ "${found_obs}" == "FALSE" ] && [ "${need_obs}" == "TRUE" ]
then
  #If not found, error
  _message " - @RED@ERROR!@DEF@\n"
  _message "@RED@There are no nz_obs files in any patch?!@DEF@\n"
  _message "@BLU@You probably didn't run rename an 'nz_obs' block for a particular patch?!@DEF@\n"
  exit 1
fi
#}}}

