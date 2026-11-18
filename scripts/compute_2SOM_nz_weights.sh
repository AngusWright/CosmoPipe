#=========================================
#
# File Name : compute_2SOM_nz_weights.sh
# Created By : awright
# Creation Date : 18-07-2025
# Last Modified : Tue Nov 17 21:26:22 2026
#
#=========================================

set -e

#Notify
_message "@BLU@ > Assign SOM weights to spec sources {@DEF@\n"

wide_catalogues="@DB:som_weight_wide@"
spec_catalogues="@DB:som_weight_spec@"
transfer="@DB:som_weight_transfer@"

read -r -a wide_files < <(printf '%s\n' "${wide_catalogues}")
read -r -a spec_files < <(printf '%s\n' "${spec_catalogues}")
read -r -a transfer_files < <(printf '%s\n' "${transfer}")
nwid=${#wide_files[@]}
if [ "${nwid}" -eq 0 ] || [ "${nwid}" -ne "${#spec_files[@]}" ] ||
   [ "${nwid}" -ne "${#transfer_files[@]}" ]
then
  _message "@RED@ERROR: wide, spec, and transfer catalogue lists must have equal non-zero lengths.@DEF@\n" >&2
  exit 1
fi
outlist=''
wide_outlist=''
wide_outdir="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/som_weight_wide_gold"
mkdir -p "${wide_outdir}"
spec_basenames=()
for spec in "${spec_files[@]}"
do
  base=${spec##*/}
  for previous in "${spec_basenames[@]}"
  do
    if [ "${base}" = "${previous}" ]
    then
      _message "@RED@ERROR: spec catalogue basenames must be unique to avoid overwriting outputs: ${base}.@DEF@\n" >&2
      exit 1
    fi
  done
  spec_basenames+=("${base}")
done

for ((i=0;i<nwid;i++))
do 
  #input files 
  wide=${wide_files[i]}
  spec=${spec_files[i]}
  tran=${transfer_files[i]}
  #Output files 
  ext=${spec##*.}
  output="@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD/${spec##*/}"
  output=${output%.*}_somweight.${ext}
  wide_base=${wide##*/}
  wide_output="${wide_outdir}/$((i+1))_${wide_base%.*}_somweight.cat"
  
  _message "  @RED@Spec:@DEF@ ${spec##*/}@DEF@\n"
  _message "  @RED@Wide:@DEF@ ${wide##*/}@DEF@\n"
  _message "  @RED@Transfer:@DEF@ ${tran##*/}@DEF@\n"
  _message "   -> @BLU@Computing SOM weights@DEF@"
  @P_RSCRIPT@ "@RUNROOT@/@SCRIPTPATH@/compute_2SOM_nz_weights_weighted.R" \
    --wide "${wide}" \
    -s "${spec}" \
    -t "${tran}" \
    --wide.weight "@BV:WEIGHTNAME@" \
    --spec.weight "@BV:CALIBWEIGHTNAME@" \
    --wide.output "${wide_output}" \
    -o "${output}" 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  _message "   -> @BLU@Merge IDs with original catalogue @DEF@"
  "@RUNROOT@/INSTALL/theli-1.6.1/bin/@MACHINE@/ldacjoinkey" \
    -i "${spec}" \
    -p "${output}" \
    -o "${output}_tmp" \
    -k SOMweight -t OBJECTS 2>&1
  _message " -@RED@ Done! (`date +'%a %H:%M'`)@DEF@\n"
  
  mv "${output}_tmp" "${output}"
  outlist="${outlist} ${output##*/}"
  wide_outlist="${wide_outlist} ${wide_output##*/}"
  

done
_write_datablock som_weight_wide_gold "${wide_outlist}"
_writelist_datahead "${outlist}" 

#Notify
_message "@BLU@ } @RED@ - Done! (`date +'%a %H:%M'`)@DEF@\n"
