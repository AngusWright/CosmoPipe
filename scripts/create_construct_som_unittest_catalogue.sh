output_dir=@RUNROOT@/unit_test_fixtures/construct_som
output_file=${output_dir}/som_input.fits

mkdir -p "${output_dir}"
@PYTHON3BIN@ @RUNROOT@/@SCRIPTPATH@/create_construct_som_unittest_catalogue.py "${output_file}"
