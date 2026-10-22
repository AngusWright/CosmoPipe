block_dir=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/tomography_unittest_input
datahead_dir=@RUNROOT@/@STORAGEPATH@/@DATABLOCK@/DATAHEAD
output_file=${block_dir}/tomography_input.cat

mkdir -p "${block_dir}" "${datahead_dir}"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/create_tomography_unittest_catalogue.py "${output_file}"
cp "${output_file}" "${datahead_dir}/"

_write_datablock tomography_unittest_input "tomography_input.cat"
_writelist_datahead "tomography_input.cat"
